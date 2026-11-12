"""Critères « Terminé quand » de l'étape B3 (backend/PLAN.md), testés à travers l'API.

« Tests de tous les cas (mauvais mot de passe, compte désactivé, jeton expiré,
refresh réutilisé, rôle insuffisant). » + deux parcours complets.
Chaque cas est aussi testé en détail dans les fichiers test_auth_*.py et test_password_api.py.
"""

from datetime import UTC, datetime, timedelta

import pytest
from fastapi import APIRouter, Depends

from app.core.security import hash_password
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.auth.dependencies import require_role
from app.modules.auth.tokens import create_access_token
from app.modules.users.models import UserRole
from tests.factories import make_user

PASSWORD = "Demo2026!"
PHONE = "+242061112233"


@pytest.fixture
def account(db_session):
    return make_user(db_session, phone=PHONE, password_hash=hash_password(PASSWORD))


def login(client, password=PASSWORD, phone=PHONE):
    return client.post("/api/v1/auth/login", json={"phone": phone, "password": password})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def error(response):
    return response.status_code, response.json()["error"]["code"]


# --- Les cinq cas exigés par le plan ------------------------------------------------


def test_criterion_wrong_password(client, account):
    assert error(login(client, password="Mauvais2026")) == (401, "INVALID_CREDENTIALS")


def test_criterion_disabled_account(client, account, db_session):
    account.is_active = False
    db_session.flush()
    assert error(login(client)) == (403, "ACCOUNT_DISABLED")


def test_criterion_expired_token(client, account, test_settings):
    expired, _ = create_access_token(
        account.id,
        "client",
        secret=test_settings.jwt_secret.get_secret_value(),
        minutes=15,
        now=datetime.now(UTC) - timedelta(minutes=16),
    )
    assert error(client.get("/api/v1/me", headers=bearer(expired))) == (401, "TOKEN_EXPIRED")


def test_criterion_reused_refresh_token(client, account):
    first = login(client).json()["refresh_token"]
    client.post("/api/v1/auth/refresh", json={"refresh_token": first})
    replay = client.post("/api/v1/auth/refresh", json={"refresh_token": first})
    assert error(replay) == (401, "REFRESH_TOKEN_REUSED")


def test_criterion_insufficient_role(app, client, account):
    router = APIRouter()

    @router.get("/acceptance/admin", dependencies=[Depends(require_role(UserRole.ADMIN))])
    def admin_only():
        return {"ok": True}

    app.include_router(router, prefix="/api/v1")
    token = login(client).json()["access_token"]
    response = client.get("/api/v1/acceptance/admin", headers=bearer(token))
    assert error(response) == (403, "FORBIDDEN")


# --- Parcours complets --------------------------------------------------------------


def test_full_client_journey(client):
    """Inscription → profil → rafraîchissement → changement de mot de passe → déconnexion."""
    registered = client.post(
        "/api/v1/auth/register",
        json={"full_name": "Davy Bouanga", "phone": "06 444 55 66", "password": PASSWORD},
    )
    assert registered.status_code == 201
    tokens = registered.json()

    me = client.get("/api/v1/me", headers=bearer(tokens["access_token"]))
    assert me.json()["phone"] == "+242064445566"

    updated = client.patch(
        "/api/v1/me", json={"email": "davy@example.com"}, headers=bearer(tokens["access_token"])
    )
    assert updated.json()["email"] == "davy@example.com"

    tokens = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
    ).json()

    changed = client.post(
        "/api/v1/me/password",
        json={"current_password": PASSWORD, "new_password": "Nouveau2026"},
        headers=bearer(tokens["access_token"]),
    )
    assert changed.status_code == 200
    tokens = changed.json()

    logout = client.post("/api/v1/auth/logout", json={"refresh_token": tokens["refresh_token"]})
    assert logout.status_code == 204
    assert login(client, phone="064445566").status_code == 401  # ancien mot de passe
    assert login(client, phone="064445566", password="Nouveau2026").status_code == 200


def test_forgotten_password_journey(app, client, account):
    """Numéro → code (affiché en mode démo) → nouveau mot de passe → reconnexion."""
    sms = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sms
    session_before = login(client).json()

    code = client.post("/api/v1/auth/password/forgot", json={"phone": "06 111 22 33"}).json()[
        "demo_code"
    ]
    assert code in sms.outbox[-1].message
    reset = client.post(
        "/api/v1/auth/password/reset",
        json={"phone": PHONE, "code": code, "new_password": "Retrouve2026"},
    )
    assert reset.status_code == 204

    stale = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": session_before["refresh_token"]}
    )
    assert stale.status_code == 401  # « autres appareils déconnectés »
    assert login(client, password="Retrouve2026").status_code == 200
