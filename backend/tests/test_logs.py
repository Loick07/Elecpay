"""Tests des journaux techniques (B11.2) : JSON, identifiant de requête, journal d'accès sans
paramètres, et AUCUNE donnée sensible (numéro, jeton, mot de passe) même dans une trace d'erreur."""

import json
import logging

import pytest
from fastapi.testclient import TestClient

from app.core.logs import redact
from app.db.session import get_db
from app.main import create_app

PHONE = "+242061110001"


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("vers +242061110001", "vers +242 06 *** ** 01"),
        ("vers +242 06 111 00 01", "vers +242 06 *** ** 01"),
        ("q=0611100 01".replace(" ", ""), "q=06 *** ** 01"),  # 9 chiffres, numéro local
        ("q=06 111 00 01", "q=06 *** ** 01"),
        ("Authorization: Bearer abc.def.ghi", "Authorization: Bearer [jeton]"),
        ("jeton eyJhbGciOi.eyJzdWIiOiI3.sig_nature-1", "jeton [jeton]"),
        ('{"password": "Demo2026!", "phone": "x"}', '{"password": [masqué], "phone": "x"}'),
        ("new_password=Secret123!", "new_password=[masqué]"),
        ("refresh_token='abc'", "refresh_token=[masqué]"),
    ],
)
def test_redact(raw, expected):
    assert redact(raw) == expected


@pytest.mark.parametrize(
    "harmless",
    [
        "Facture 20261103000015 : 40 384 FCFA",  # numéro de facture, montant
        "compteur 0412-8833, 571000 Wh",
        "TX-00000042 réussie en 40 s",
        "error code BILL_NOT_FOUND",
    ],
)
def test_redact_leaves_business_data_alone(harmless):
    assert redact(harmless) == harmless


@pytest.fixture
def json_app(capsys, test_settings, db_session):
    # capsys AVANT l'application : son gestionnaire de journal écrit dans la sortie capturée.
    app = create_app(test_settings.model_copy(update={"log_format": "json"}))
    app.dependency_overrides[get_db] = lambda: db_session

    @app.get("/api/v1/test-boom")
    def boom():  # simule une erreur SQL qui recopie les valeurs de la requête
        raise RuntimeError(f"INSERT INTO users (phone) VALUES ('{PHONE}') : doublon")

    return app


def lines(capsys) -> list[dict]:
    return [json.loads(line) for line in capsys.readouterr().out.splitlines() if line.strip()]


def test_json_lines_with_request_id_and_no_sensitive_data(json_app, capsys):
    with TestClient(json_app, raise_server_exceptions=False) as client:
        capsys.readouterr()  # ignore le démarrage
        response = client.get(
            "/api/v1/bills",
            params={"q": "0611100 01".replace(" ", "")},
            headers={"Authorization": "Bearer eyJhbGciOi.eyJzdWIiOiI3.signature"},
        )
        error = client.get("/api/v1/test-boom")
    events = lines(capsys)
    output = json.dumps(events, ensure_ascii=False)
    assert "061110001" not in output and PHONE not in output
    assert "eyJ" not in output

    access = [e for e in events if e["logger"] == "elecpay.http"]
    first, second = access
    assert first["request_id"] == response.headers["X-Request-ID"]
    assert first["http"] == {
        "method": "GET",
        "path": "/api/v1/bills",  # sans « ?q=… »
        "status": 401,
        "duration_ms": first["http"]["duration_ms"],
        "ip": "testclient",
    }
    assert second["http"]["status"] == 500
    assert error.json()["error"]["code"] == "INTERNAL_ERROR"
    assert error.headers["X-Frame-Options"] == "DENY"  # la 500 traverse aussi la sécurité
    crash = next(e for e in events if e["logger"] == "elecpay.errors")
    assert crash["level"] == "ERROR"
    assert crash["request_id"] == error.headers["X-Request-ID"] == second["request_id"]
    assert "RuntimeError" in crash["error"]
    assert "+242 06 *** ** 01" in crash["error"]  # le numéro de la trace est masqué


def test_request_id_from_the_client_is_kept_when_safe(client):
    kept = client.get("/api/v1/health", headers={"X-Request-ID": "mobile-7f3a9c21"})
    assert kept.headers["X-Request-ID"] == "mobile-7f3a9c21"
    for unsafe in ("court", "a" * 65, "id avec espaces", "<script>alert(1)</script>"):
        replaced = client.get("/api/v1/health", headers={"X-Request-ID": unsafe})
        assert replaced.headers["X-Request-ID"] != unsafe
        assert len(replaced.headers["X-Request-ID"]) == 32


def test_each_request_gets_its_own_id(client):
    ids = {client.get("/api/v1/health").headers["X-Request-ID"] for _ in range(3)}
    assert len(ids) == 3


def test_health_checks_do_not_flood_the_logs(client, caplog):
    with caplog.at_level(logging.INFO, logger="elecpay.http"):
        client.get("/api/v1/health")
        client.get("/api/v1/bills")
    paths = [record.http["path"] for record in caplog.records if record.name == "elecpay.http"]
    assert paths == ["/api/v1/bills"]  # la santé est au niveau DEBUG


def test_text_format_in_development(test_settings, db_session, capsys):
    app = create_app(test_settings.model_copy(update={"log_format": "text"}))
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as client:
        capsys.readouterr()
        response = client.get("/api/v1/bills", params={"q": PHONE})
    out = capsys.readouterr().out
    assert f"[{response.headers['X-Request-ID']}] GET /api/v1/bills 401" in out
    assert PHONE not in out


def test_uvicorn_access_log_is_replaced(json_app):
    assert logging.getLogger("uvicorn.access").disabled is True


def test_request_id_is_readable_by_the_back_office(client):
    from tests.conftest import TEST_CORS_ORIGIN

    response = client.get("/api/v1/health", headers={"Origin": TEST_CORS_ORIGIN})
    assert "X-Request-ID" in response.headers["Access-Control-Expose-Headers"]
