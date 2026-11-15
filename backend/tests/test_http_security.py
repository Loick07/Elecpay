"""Tests de la sécurité HTTP (B11.1) : en-têtes, CORS strict, limite globale par IP, IP réelle
derrière un proxy de confiance."""

from ipaddress import ip_network

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy import select

from app.core.config import Settings
from app.core.request_context import resolve_client_ip
from app.db.session import get_db
from app.main import create_app
from app.modules.audit.models import AuditLog
from app.modules.users.models import UserRole
from tests.conftest import TEST_CORS_ORIGIN
from tests.factories import make_user

HEALTH = "/api/v1/health"
BILLS = "/api/v1/bills"  # route protégée : 401 sans jeton, pratique et sans base


def make_client(test_settings, db_session, *, peer="196.44.0.1", **overrides) -> TestClient:
    app = create_app(test_settings.model_copy(update=overrides))
    app.dependency_overrides[get_db] = lambda: db_session
    return TestClient(app, raise_server_exceptions=False, client=(peer, 50000))


# --- En-têtes de sécurité -------------------------------------------------------------------


@pytest.mark.parametrize("path", [HEALTH, BILLS, "/api/v1/route-inconnue"])
def test_security_headers_on_every_response(client, path):
    response = client.get(path)
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    assert "camera=()" in response.headers["Permissions-Policy"]
    assert response.headers["Cross-Origin-Opener-Policy"] == "same-origin"
    assert response.headers["Content-Security-Policy"].startswith("default-src 'none'")
    assert response.headers["Cache-Control"] == "no-store"
    assert "Strict-Transport-Security" not in response.headers  # pas en développement


def test_documentation_keeps_working(client):
    response = client.get("/docs")
    assert response.status_code == 200
    assert "Content-Security-Policy" not in response.headers  # Swagger UI charge son CDN
    assert response.headers["X-Content-Type-Options"] == "nosniff"


def test_hsts_in_production(test_settings, db_session):
    with make_client(test_settings, db_session, app_env="production") as production:
        response = production.get(HEALTH)
    assert response.headers["Strict-Transport-Security"] == "max-age=31536000; includeSubDomains"


# --- CORS -----------------------------------------------------------------------------------


def test_cors_answers_only_known_origins(client):
    allowed = client.get(HEALTH, headers={"Origin": TEST_CORS_ORIGIN})
    assert allowed.headers["Access-Control-Allow-Origin"] == TEST_CORS_ORIGIN
    assert allowed.headers["Access-Control-Allow-Credentials"] == "true"
    stranger = client.get(HEALTH, headers={"Origin": "https://pirate.example"})
    assert "Access-Control-Allow-Origin" not in stranger.headers


def test_cors_preflight(client):
    response = client.options(
        BILLS,
        headers={
            "Origin": TEST_CORS_ORIGIN,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "X-CSRF-Token",
        },
    )
    assert response.status_code == 200
    assert "X-CSRF-Token" in response.headers["Access-Control-Allow-Headers"]
    refused = client.options(
        BILLS,
        headers={"Origin": "https://pirate.example", "Access-Control-Request-Method": "POST"},
    )
    assert refused.status_code == 400


@pytest.mark.parametrize(
    ("overrides", "fragment"),
    [
        ({"cors_origins": "*"}, "interdite"),
        ({"cors_origins": "https://admin.elecpay.cg/login"}, "origine CORS invalide"),
        ({"cors_origins": "admin.elecpay.cg"}, "origine CORS invalide"),
        ({"trusted_proxies": "pas-une-ip"}, "proxy de confiance invalide"),
    ],
)
def test_configuration_is_checked(test_settings, overrides, fragment):
    values = test_settings.model_dump() | overrides
    with pytest.raises(ValidationError, match=fragment):
        Settings(**values)


def test_production_requires_https_origins(test_settings):
    values = test_settings.model_dump() | {
        "app_env": "production",
        "jwt_secret": "x" * 40,
        "payment_webhook_secret": "y" * 40,
        "two_factor_key": "z" * 40,
        "team_2fa_required": True,
        "receipt_verify_url": "https://verifier.elecpay.cg",
        "cors_origins": "http://admin.elecpay.cg",
    }
    with pytest.raises(ValidationError, match="https:// en production"):
        Settings(**values)
    Settings(**values | {"cors_origins": "https://admin.elecpay.cg"})  # accepté


# --- Limite globale par IP ------------------------------------------------------------------


def test_global_limit_per_ip(test_settings, db_session):
    with make_client(test_settings, db_session, rate_limit_per_minute=3) as limited:
        assert [limited.get(BILLS).status_code for _ in range(3)] == [401, 401, 401]
        blocked = limited.get(BILLS, headers={"Origin": TEST_CORS_ORIGIN})
    assert blocked.status_code == 429
    body = blocked.json()["error"]
    assert body["code"] == "TOO_MANY_REQUESTS"
    assert 1 <= body["details"]["retry_after_seconds"] <= 60
    assert blocked.headers["Retry-After"] == str(body["details"]["retry_after_seconds"])
    assert blocked.headers["X-Frame-Options"] == "DENY"  # en-têtes posés aussi sur le 429
    assert blocked.headers["Access-Control-Allow-Origin"] == TEST_CORS_ORIGIN  # lisible


def test_health_and_webhooks_are_never_limited(test_settings, db_session):
    with make_client(test_settings, db_session, rate_limit_per_minute=1) as limited:
        assert {limited.get(HEALTH).status_code for _ in range(5)} == {200}
        webhooks = {
            limited.post("/api/v1/webhooks/payments/simulated", content=b"{}").status_code
            for _ in range(3)
        }
        assert 429 not in webhooks


def test_each_ip_has_its_own_counter(test_settings, db_session):
    for peer in ("196.44.0.1", "196.44.0.2"):
        with make_client(test_settings, db_session, peer=peer, rate_limit_per_minute=1) as c:
            assert c.get(BILLS).status_code == 401


def test_limit_zero_disables_it(test_settings, db_session):
    with make_client(test_settings, db_session, rate_limit_per_minute=0) as unlimited:
        assert {unlimited.get(BILLS).status_code for _ in range(10)} == {401}


def test_forged_forwarded_for_does_not_bypass_the_limit(test_settings, db_session):
    with make_client(test_settings, db_session, rate_limit_per_minute=2) as limited:
        codes = [
            limited.get(BILLS, headers={"X-Forwarded-For": f"10.9.0.{n}"}).status_code
            for n in range(3)
        ]
    assert codes == [401, 401, 429]  # sans proxy de confiance, l'en-tête est ignoré


def test_behind_a_trusted_proxy_the_real_ip_counts(test_settings, db_session):
    with make_client(
        test_settings,
        db_session,
        peer="10.0.0.5",
        trusted_proxies=["10.0.0.0/8"],
        rate_limit_per_minute=1,
    ) as proxied:
        first = proxied.get(BILLS, headers={"X-Forwarded-For": "41.202.1.1"})
        other = proxied.get(BILLS, headers={"X-Forwarded-For": "41.202.1.2"})
        again = proxied.get(BILLS, headers={"X-Forwarded-For": "41.202.1.1"})
    assert (first.status_code, other.status_code, again.status_code) == (401, 401, 429)


# --- IP réelle ------------------------------------------------------------------------------

PROXIES = (ip_network("10.0.0.0/8"),)


@pytest.mark.parametrize(
    ("peer", "forwarded", "expected"),
    [
        ("196.44.0.1", "41.202.1.1", "196.44.0.1"),  # pas un proxy : en-tête ignoré
        ("10.0.0.5", None, "10.0.0.5"),
        ("10.0.0.5", "41.202.1.1", "41.202.1.1"),
        ("10.0.0.5", "1.2.3.4, 41.202.1.1, 10.0.0.9", "41.202.1.1"),  # 1.2.3.4 : inventé
        ("10.0.0.5", "10.0.0.7, 10.0.0.9", "10.0.0.7"),  # que des proxys
        ("10.0.0.5", "41.202.1.1, pas-une-ip", "10.0.0.5"),  # en-tête mal formé
        ("10.0.0.5", "2001:db8::1", "2001:db8::1"),
        (None, "41.202.1.1", None),
    ],
)
def test_resolve_client_ip(peer, forwarded, expected):
    assert resolve_client_ip(peer, forwarded, PROXIES) == expected


def test_audit_records_the_real_ip(test_settings, db_session, auth_headers):
    admin = make_user(db_session, role=UserRole.ADMIN)
    target = make_user(db_session)
    with make_client(
        test_settings, db_session, peer="10.0.0.5", trusted_proxies=["10.0.0.0/8"]
    ) as proxied:
        response = proxied.post(
            f"/api/v1/admin/users/{target.id}/deactivate",
            json={"reason": "Demande du titulaire"},
            headers=auth_headers(admin) | {"X-Forwarded-For": "41.202.1.1"},
        )
    assert response.status_code == 200, response.text
    log = db_session.scalars(
        select(AuditLog).where(
            AuditLog.action == "user.deactivate", AuditLog.entity_id == target.id
        )
    ).one()
    assert log.ip == "41.202.1.1"  # le client, pas le proxy
