"""Tests des routes de rafraîchissement et de déconnexion (B3.4)."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select, update

from app.core.security import hash_password
from app.modules.auth.models import RefreshToken
from app.modules.auth.tokens import hash_refresh_token
from tests.factories import make_user

PASSWORD = "Demo2026!"
REFRESH = "/api/v1/auth/refresh"
LOGOUT = "/api/v1/auth/logout"
LOGOUT_ALL = "/api/v1/auth/logout-all"
ME = "/api/v1/me"


@pytest.fixture
def account(db_session):
    return make_user(db_session, phone="+242061112233", password_hash=hash_password(PASSWORD))


def login(client, phone="+242061112233", user_agent="ElecPay Android"):
    response = client.post(
        "/api/v1/auth/login",
        json={"phone": phone, "password": PASSWORD},
        headers={"User-Agent": user_agent},
    )
    assert response.status_code == 200
    return response.json()


def refresh(client, token):
    return client.post(REFRESH, json={"refresh_token": token})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def code(response):
    return response.json()["error"]["code"]


# --- Rafraîchissement ---------------------------------------------------------------


def test_refresh_gives_a_new_pair_of_tokens(client, account):
    first = login(client)
    response = refresh(client, first["refresh_token"])
    assert response.status_code == 200
    second = response.json()
    assert second["refresh_token"] != first["refresh_token"]
    assert second["access_token"] != first["access_token"]
    assert second["user"]["id"] == account.id
    assert client.get(ME, headers=bearer(second["access_token"])).status_code == 200


def test_a_whole_day_of_refreshes(client, account):
    tokens = login(client)
    for _ in range(10):  # l'app rafraîchit toutes les 15 minutes
        tokens = refresh(client, tokens["refresh_token"]).json()
    assert client.get(ME, headers=bearer(tokens["access_token"])).status_code == 200


def test_stolen_refresh_token_scenario(client, account):
    """Le voleur rejoue un ancien jeton : TOUTES les sessions de cette connexion sautent."""
    stolen = login(client)["refresh_token"]
    victim = refresh(client, stolen).json()["refresh_token"]  # la victime a déjà rafraîchi

    thief = refresh(client, stolen)
    assert thief.status_code == 401
    assert code(thief) == "REFRESH_TOKEN_REUSED"

    victim_again = refresh(client, victim)  # la session de la victime est fermée aussi
    assert victim_again.status_code == 401
    assert code(victim_again) == "REFRESH_TOKEN_REUSED"


def test_reuse_does_not_touch_another_device(client, account):
    phone = login(client, user_agent="Android")["refresh_token"]
    laptop = login(client, user_agent="Navigateur")["refresh_token"]
    refresh(client, phone)
    assert code(refresh(client, phone)) == "REFRESH_TOKEN_REUSED"
    assert refresh(client, laptop).status_code == 200


def test_access_token_is_refused_as_refresh_token(client, account):
    access = login(client)["access_token"]
    response = refresh(client, access)
    assert response.status_code == 401
    assert code(response) == "TOKEN_INVALID"


@pytest.mark.parametrize(
    ("token", "status_code"), [("inconnu", 401), ("", 422), ("x" * 300, 401), ("x" * 2_000, 422)]
)
def test_unknown_or_malformed_refresh_token(client, token, status_code):
    assert refresh(client, token).status_code == status_code


def test_expired_refresh_token(client, account, db_session):
    token = login(client)["refresh_token"]
    long_ago = datetime.now(UTC) - timedelta(days=40)
    db_session.execute(
        update(RefreshToken)
        .where(RefreshToken.token_hash == hash_refresh_token(token))
        .values(created_at=long_ago, expires_at=long_ago + timedelta(days=30))
    )
    response = refresh(client, token)
    assert response.status_code == 401
    assert code(response) == "TOKEN_EXPIRED"


def test_disabled_account_cannot_refresh(client, account, db_session):
    token = login(client)["refresh_token"]
    account.is_active = False
    db_session.flush()
    response = refresh(client, token)
    assert response.status_code == 403
    assert code(response) == "ACCOUNT_DISABLED"


def test_refresh_records_the_device(client, account, db_session):
    token = login(client)["refresh_token"]
    client.post(REFRESH, json={"refresh_token": token}, headers={"User-Agent": "ElecPay iOS 2.0"})
    agents = set(
        db_session.scalars(
            select(RefreshToken.user_agent).where(RefreshToken.user_id == account.id)
        )
    )
    assert agents == {"ElecPay Android", "ElecPay iOS 2.0"}


# --- Déconnexion --------------------------------------------------------------------


def test_logout_closes_this_session(client, account):
    tokens = login(client)
    response = client.post(LOGOUT, json={"refresh_token": tokens["refresh_token"]})
    assert response.status_code == 204
    assert response.content == b""
    assert refresh(client, tokens["refresh_token"]).status_code == 401


def test_logout_always_succeeds(client):
    assert client.post(LOGOUT, json={"refresh_token": "deja-invalide"}).status_code == 204


def test_logout_twice_is_fine(client, account):
    token = login(client)["refresh_token"]
    assert client.post(LOGOUT, json={"refresh_token": token}).status_code == 204
    assert client.post(LOGOUT, json={"refresh_token": token}).status_code == 204


def test_logout_only_closes_this_device(client, account):
    phone = login(client, user_agent="Android")
    laptop = login(client, user_agent="Navigateur")
    client.post(LOGOUT, json={"refresh_token": phone["refresh_token"]})
    assert refresh(client, laptop["refresh_token"]).status_code == 200


def test_logout_all_devices(client, account, db_session):
    devices = [login(client, user_agent=f"Appareil {i}") for i in range(3)]
    other = make_user(db_session, phone="+242064445566", password_hash=hash_password(PASSWORD))
    other_tokens = login(client, phone=other.phone)

    response = client.post(LOGOUT_ALL, headers=bearer(devices[0]["access_token"]))
    assert response.status_code == 200
    assert response.json() == {"revoked_sessions": 3}
    for device in devices:
        assert refresh(client, device["refresh_token"]).status_code == 401
    assert refresh(client, other_tokens["refresh_token"]).status_code == 200  # pas touché


def test_logout_all_requires_being_logged_in(client):
    response = client.post(LOGOUT_ALL)
    assert response.status_code == 401
    assert code(response) == "NOT_AUTHENTICATED"
