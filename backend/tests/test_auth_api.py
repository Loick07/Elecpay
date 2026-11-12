"""Tests des routes d'inscription, de connexion, de /me et des gardiens de rôle (B3.3)."""

from datetime import UTC, datetime, timedelta

import pytest
from fastapi import APIRouter, Depends

from app.core.security import hash_password, verify_password
from app.modules.auth import service as auth_service
from app.modules.auth.dependencies import require_role
from app.modules.auth.tokens import create_access_token
from app.modules.users.models import User, UserRole
from tests.factories import make_user

PASSWORD = "Demo2026!"
REGISTER = "/api/v1/auth/register"
LOGIN = "/api/v1/auth/login"
ME = "/api/v1/me"


@pytest.fixture
def account(db_session):
    """Un compte client avec un vrai mot de passe haché."""
    return make_user(
        db_session,
        phone="+242061112233",
        full_name="Grâce Ngoma",
        password_hash=hash_password(PASSWORD),
    )


def login(client, phone="+242061112233", password=PASSWORD):
    return client.post(LOGIN, json={"phone": phone, "password": password})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def error_code(response):
    return response.json()["error"]["code"]


# --- Inscription --------------------------------------------------------------------


def test_register_creates_a_client_and_logs_in(client, db_session):
    response = client.post(
        REGISTER,
        json={
            "full_name": "  Davy   Bouanga ",
            "phone": "06 999 88 77",
            "email": "Davy@Example.com",
            "password": PASSWORD,
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["expires_in"] == 15 * 60
    assert body["user"]["phone"] == "+242069998877"  # normalisé
    assert body["user"]["email"] == "davy@example.com"
    assert body["user"]["full_name"] == "Davy Bouanga"
    assert body["user"]["role"] == "client"
    assert "password_hash" not in body["user"]

    user = db_session.get(User, body["user"]["id"])
    assert user.password_hash.startswith("$argon2id$")
    assert verify_password(PASSWORD, user.password_hash)
    assert client.get(ME, headers=bearer(body["access_token"])).status_code == 200


def test_register_without_email(client):
    response = client.post(
        REGISTER, json={"full_name": "Sandrine K", "phone": "051234567", "password": PASSWORD}
    )
    assert response.status_code == 201
    assert response.json()["user"]["email"] is None


def test_nobody_can_register_as_admin(client):
    response = client.post(
        REGISTER,
        json={"full_name": "Pirate", "phone": "061234000", "password": PASSWORD, "role": "admin"},
    )
    assert response.status_code == 422  # champ inattendu refusé, pas ignoré


def test_phone_already_used(client, account):
    response = client.post(
        REGISTER, json={"full_name": "Autre", "phone": "06 111 22 33", "password": PASSWORD}
    )
    assert response.status_code == 409
    assert error_code(response) == "PHONE_ALREADY_USED"


def test_email_already_used_whatever_the_case(client, db_session):
    make_user(db_session, email="grace@example.com")
    response = client.post(
        REGISTER,
        json={
            "full_name": "Autre",
            "phone": "061230000",
            "email": "GRACE@example.com",
            "password": PASSWORD,
        },
    )
    assert response.status_code == 409
    assert error_code(response) == "EMAIL_ALREADY_USED"


@pytest.mark.parametrize(
    ("field", "value"),
    [("password", "court1"), ("password", "sanschiffre"), ("phone", "12345"), ("email", "x@y")],
)
def test_invalid_registration_fields(client, field, value):
    data = {"full_name": "Test", "phone": "061230001", "password": PASSWORD} | {field: value}
    response = client.post(REGISTER, json=data)
    assert response.status_code == 422
    fields = {f["field"] for f in response.json()["error"]["details"]["fields"]}
    assert fields == {f"body.{field}"}
    assert value not in response.text or field == "phone"  # le mot de passe n'est jamais renvoyé


# --- Connexion ----------------------------------------------------------------------


def test_login_with_the_right_password(client, account, db_session):
    response = login(client)
    assert response.status_code == 200
    body = response.json()
    assert body["user"]["id"] == account.id
    db_session.refresh(account)
    assert account.last_login_at is not None
    assert datetime.now(UTC) - account.last_login_at < timedelta(minutes=1)


def test_login_accepts_any_way_of_writing_the_number(client, account):
    assert login(client, phone="06 111 22 33").status_code == 200


def test_wrong_password_and_unknown_number_give_the_same_answer(client, account):
    wrong_password = login(client, password="Mauvais2026")
    unknown_number = login(client, phone="069999999")
    assert wrong_password.status_code == unknown_number.status_code == 401
    assert wrong_password.json() == unknown_number.json()
    assert error_code(wrong_password) == "INVALID_CREDENTIALS"


def test_unknown_number_still_checks_a_password(client, monkeypatch):
    """Même travail (donc même durée) qu'un mauvais mot de passe : rien à chronométrer."""
    calls = []
    real_verify = auth_service.verify_password
    monkeypatch.setattr(
        auth_service, "verify_password", lambda p, h: calls.append(h) or real_verify(p, h)
    )
    assert login(client, phone="069999999").status_code == 401
    assert len(calls) == 1


def test_disabled_account_with_the_right_password(client, account, db_session):
    account.is_active = False
    db_session.flush()
    response = login(client)
    assert response.status_code == 403
    assert error_code(response) == "ACCOUNT_DISABLED"


def test_disabled_account_with_a_wrong_password_reveals_nothing(client, account, db_session):
    account.is_active = False
    db_session.flush()
    response = login(client, password="Mauvais2026")
    assert error_code(response) == "INVALID_CREDENTIALS"


def test_login_never_echoes_the_password(client, account):
    response = login(client, password="Mauvais2026")
    assert "Mauvais2026" not in response.text


# --- /me et jeton d'accès -----------------------------------------------------------


def test_me_returns_my_profile(client, account):
    token = login(client).json()["access_token"]
    response = client.get(ME, headers=bearer(token))
    assert response.status_code == 200
    assert response.json()["full_name"] == "Grâce Ngoma"
    assert "password_hash" not in response.json()


def test_me_without_token(client):
    response = client.get(ME)
    assert response.status_code == 401
    assert error_code(response) == "NOT_AUTHENTICATED"
    assert response.headers["www-authenticate"] == "Bearer"


@pytest.mark.parametrize("header", ["Bearer n-importe-quoi", "Basic abc", "Bearer"])
def test_me_with_a_bad_token(client, header):
    response = client.get(ME, headers={"Authorization": header})
    assert response.status_code == 401


def test_me_with_an_expired_token(client, account, test_settings):
    token, _ = create_access_token(
        account.id,
        "client",
        secret=test_settings.jwt_secret.get_secret_value(),
        minutes=15,
        now=datetime.now(UTC) - timedelta(minutes=20),
    )
    response = client.get(ME, headers=bearer(token))
    assert response.status_code == 401
    assert error_code(response) == "TOKEN_EXPIRED"


def test_account_disabled_after_login_is_blocked_immediately(client, account, db_session):
    token = login(client).json()["access_token"]
    account.is_active = False
    db_session.flush()
    response = client.get(ME, headers=bearer(token))  # le jeton n'a pas encore expiré
    assert response.status_code == 403
    assert error_code(response) == "ACCOUNT_DISABLED"


# --- require_role -------------------------------------------------------------------


@pytest.fixture
def role_client(app, client):
    router = APIRouter()

    @router.get(
        "/test/admin-only",
        dependencies=[Depends(require_role(UserRole.ADMIN, UserRole.SUPER_ADMIN))],
    )
    def admin_only():
        return {"ok": True}

    app.include_router(router, prefix="/api/v1")
    return client


@pytest.mark.parametrize(
    ("role", "status_code"),
    [
        (UserRole.CLIENT, 403),
        (UserRole.SUPPORT, 403),
        (UserRole.ADMIN, 200),
        (UserRole.SUPER_ADMIN, 200),
    ],
)
def test_require_role(role_client, db_session, role, status_code):
    make_user(db_session, phone="+242067770000", role=role, password_hash=hash_password(PASSWORD))
    token = login(role_client, phone="+242067770000").json()["access_token"]
    response = role_client.get("/api/v1/test/admin-only", headers=bearer(token))
    assert response.status_code == status_code
    if status_code == 403:
        assert error_code(response) == "FORBIDDEN"


def test_role_removed_after_login_takes_effect_immediately(role_client, db_session):
    admin = make_user(
        db_session,
        phone="+242067770001",
        role=UserRole.ADMIN,
        password_hash=hash_password(PASSWORD),
    )
    token = login(role_client, phone="+242067770001").json()["access_token"]
    admin.role = UserRole.CLIENT  # rôle retiré par un super admin
    db_session.flush()
    response = role_client.get("/api/v1/test/admin-only", headers=bearer(token))
    assert response.status_code == 403  # le rôle est relu en base, pas dans le jeton


# --- Documentation ------------------------------------------------------------------


def test_docs_offer_the_authorize_button(client):
    schema = client.get("/openapi.json").json()
    assert "HTTPBearer" in schema["components"]["securitySchemes"]
    assert {"/api/v1/auth/register", "/api/v1/auth/login", "/api/v1/me"} <= set(schema["paths"])
