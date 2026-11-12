"""Tests du mot de passe oublié, de la réinitialisation, du changement de mot de passe et de
la modification du profil (B3.5)."""

import re
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, update

from app.core.security import hash_password, verify_password
from app.db.session import get_db
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.main import create_app
from app.modules.audit.models import AuditLog
from app.modules.audit.service import record
from app.modules.auth.models import PasswordResetCode
from app.modules.auth.passwords import generate_reset_code, reset_code_hash
from tests.factories import make_user

PASSWORD = "Demo2026!"
NEW_PASSWORD = "Nouveau2026"
PHONE = "+242061112233"
FORGOT = "/api/v1/auth/password/forgot"
RESET = "/api/v1/auth/password/reset"


@pytest.fixture
def sms(app):
    sender = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sender
    return sender


@pytest.fixture
def account(db_session):
    return make_user(
        db_session, phone=PHONE, full_name="Grâce Ngoma", password_hash=hash_password(PASSWORD)
    )


def login(client, password=PASSWORD, phone=PHONE):
    return client.post("/api/v1/auth/login", json={"phone": phone, "password": password})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def code_of(response):
    return response.json()["error"]["code"]


def forgot(client, phone=PHONE):
    return client.post(FORGOT, json={"phone": phone})


def reset(client, code, password=NEW_PASSWORD, phone=PHONE):
    return client.post(RESET, json={"phone": phone, "code": code, "new_password": password})


def audit_actions(db_session, user):
    return list(db_session.scalars(select(AuditLog.action).where(AuditLog.entity_id == user.id)))


# --- Mot de passe oublié ------------------------------------------------------------


def test_forgot_sends_a_code_and_shows_it_in_demo_mode(client, account, sms, db_session):
    response = forgot(client, phone="06 111 22 33")
    assert response.status_code == 200
    body = response.json()
    assert re.fullmatch(r"[0-9]{6}", body["demo_code"])
    assert body["expires_in"] == 600

    (sent,) = sms.outbox
    assert sent.phone == PHONE
    assert body["demo_code"] in sent.message

    (row,) = db_session.scalars(select(PasswordResetCode)).all()
    assert body["demo_code"] not in row.code_hash  # jamais stocké en clair
    assert row.expires_at - row.created_at == timedelta(minutes=10)


def test_unknown_number_gets_the_same_message_and_no_sms(client, account, sms):
    known, unknown = forgot(client), forgot(client, phone="069999999")
    assert known.json()["message"] == unknown.json()["message"]
    assert unknown.json()["demo_code"] is None
    assert len(sms.outbox) == 1


def test_disabled_account_gets_no_code(client, account, sms, db_session):
    account.is_active = False
    db_session.flush()
    assert forgot(client).json()["demo_code"] is None
    assert sms.outbox == []


def test_outside_demo_mode_the_code_only_goes_by_sms(test_settings, db_session, account):
    real_mode = create_app(test_settings.model_copy(update={"demo_mode": False}))
    real_mode.dependency_overrides[get_db] = lambda: db_session
    sender = SimulatedSmsSender()
    real_mode.dependency_overrides[get_sms_sender] = lambda: sender
    with TestClient(real_mode) as client:
        body = forgot(client).json()
    assert body["demo_code"] is None
    assert len(sender.outbox) == 1


def test_a_new_code_cancels_the_previous_one(client, account, sms):
    first = forgot(client).json()["demo_code"]
    second = forgot(client).json()["demo_code"]
    if first != second:  # (une chance sur un million qu'ils soient égaux)
        assert code_of(reset(client, first)) == "RESET_CODE_INVALID"
    assert reset(client, second).status_code == 204


# --- Réinitialisation ---------------------------------------------------------------


def test_reset_changes_the_password_and_logs_out_everywhere(client, account, sms, db_session):
    refresh_token = login(client).json()["refresh_token"]
    code = forgot(client).json()["demo_code"]

    assert reset(client, code).status_code == 204
    assert login(client).status_code == 401  # l'ancien mot de passe ne marche plus
    assert login(client, password=NEW_PASSWORD).status_code == 200
    stale = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert stale.status_code == 401  # « autres appareils déconnectés »
    assert "user.password_reset" in audit_actions(db_session, account)


def test_a_code_works_only_once(client, account, sms):
    code = forgot(client).json()["demo_code"]
    assert reset(client, code).status_code == 204
    assert code_of(reset(client, code, password="Encore2026")) == "RESET_CODE_INVALID"


def test_wrong_code(client, account, sms):
    code = forgot(client).json()["demo_code"]
    wrong = f"{(int(code) + 1) % 1_000_000:06d}"
    response = reset(client, wrong)
    assert response.status_code == 400
    assert code_of(response) == "RESET_CODE_INVALID"


def test_five_wrong_codes_burn_the_code(client, account, sms, db_session):
    code = forgot(client).json()["demo_code"]
    wrong = f"{(int(code) + 1) % 1_000_000:06d}"
    for _ in range(5):
        assert reset(client, wrong).status_code == 400
    assert code_of(reset(client, code)) == "RESET_CODE_INVALID"  # même le bon code est refusé
    row = db_session.scalars(select(PasswordResetCode)).one()
    assert row.attempts == 5 and row.invalidated_at is not None


def test_expired_code(client, account, sms, db_session):
    code = forgot(client).json()["demo_code"]
    long_ago = datetime.now(UTC) - timedelta(minutes=30)
    db_session.execute(
        update(PasswordResetCode).values(
            created_at=long_ago, expires_at=long_ago + timedelta(minutes=10)
        )
    )
    assert code_of(reset(client, code)) == "RESET_CODE_INVALID"


def test_unknown_number_on_reset(client):
    assert code_of(reset(client, "123456", phone="069999999")) == "RESET_CODE_INVALID"


def test_code_of_another_account_does_not_work(client, account, sms, db_session):
    make_user(db_session, phone="+242064445566", password_hash=hash_password(PASSWORD))
    other_code = forgot(client, phone="+242064445566").json()["demo_code"]
    my_code = forgot(client).json()["demo_code"]  # mon compte a aussi un code en cours
    if other_code == my_code:  # une chance sur un million : le test n'a alors pas de sens
        pytest.skip("les deux codes tirés au hasard sont identiques")
    assert code_of(reset(client, other_code)) == "RESET_CODE_INVALID"


@pytest.mark.parametrize(
    ("code", "password"), [("12345", NEW_PASSWORD), ("abcdef", NEW_PASSWORD), ("123456", "faible")]
)
def test_malformed_reset_requests(client, code, password):
    assert reset(client, code, password=password).status_code == 422


# --- Changement de mot de passe depuis le compte ------------------------------------


def test_change_password_keeps_this_device_and_logs_out_the_others(client, account, db_session):
    other_device = login(client).json()
    this_device = login(client).json()
    response = client.post(
        "/api/v1/me/password",
        json={"current_password": PASSWORD, "new_password": NEW_PASSWORD},
        headers=bearer(this_device["access_token"]),
    )
    assert response.status_code == 200
    new_tokens = response.json()
    assert client.get("/api/v1/me", headers=bearer(new_tokens["access_token"])).status_code == 200
    refresh = "/api/v1/auth/refresh"
    assert (
        client.post(refresh, json={"refresh_token": other_device["refresh_token"]}).status_code
        == 401
    )
    assert (
        client.post(refresh, json={"refresh_token": this_device["refresh_token"]}).status_code
        == 401
    )
    assert (
        client.post(refresh, json={"refresh_token": new_tokens["refresh_token"]}).status_code == 200
    )
    db_session.refresh(account)
    assert verify_password(NEW_PASSWORD, account.password_hash)
    assert "user.password_change" in audit_actions(db_session, account)


@pytest.mark.parametrize(
    ("current", "new", "status_code", "error"),
    [
        ("Mauvais2026", NEW_PASSWORD, 400, "WRONG_CURRENT_PASSWORD"),
        (PASSWORD, PASSWORD, 400, "SAME_PASSWORD"),
        (PASSWORD, "faible", 422, "VALIDATION_ERROR"),
    ],
)
def test_change_password_errors(client, account, current, new, status_code, error):
    token = login(client).json()["access_token"]
    response = client.post(
        "/api/v1/me/password",
        json={"current_password": current, "new_password": new},
        headers=bearer(token),
    )
    assert response.status_code == status_code
    assert code_of(response) == error


def test_change_password_requires_login(client):
    response = client.post(
        "/api/v1/me/password", json={"current_password": PASSWORD, "new_password": NEW_PASSWORD}
    )
    assert response.status_code == 401


# --- Modification du profil ---------------------------------------------------------


def patch_me(client, data):
    token = login(client).json()["access_token"]
    return client.patch("/api/v1/me", json=data, headers=bearer(token))


def test_update_name_and_email(client, account, db_session):
    response = patch_me(
        client, {"full_name": "  Grâce   Ngoma-Mbou ", "email": "Grace@Example.com"}
    )
    assert response.status_code == 200
    assert response.json()["full_name"] == "Grâce Ngoma-Mbou"
    assert response.json()["email"] == "grace@example.com"
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "user.profile_update")).one()
    assert log.before_json == {"full_name": "Grâce Ngoma", "email": None}
    assert log.after_json == {"full_name": "Grâce Ngoma-Mbou", "email": "grace@example.com"}


def test_remove_email(client, db_session):
    make_user(db_session, phone=PHONE, email="a@example.com", password_hash=hash_password(PASSWORD))
    assert patch_me(client, {"email": None}).json()["email"] is None


def test_no_real_change_writes_no_audit(client, account, db_session):
    assert patch_me(client, {"full_name": "Grâce Ngoma"}).status_code == 200
    assert "user.profile_update" not in audit_actions(db_session, account)


@pytest.mark.parametrize(
    "data",
    [{}, {"full_name": None}, {"phone": "069999999"}, {"role": "admin"}, {"email": "pas-un-email"}],
)
def test_invalid_profile_updates(client, account, data):
    assert patch_me(client, data).status_code == 422


def test_email_of_someone_else(client, account, db_session):
    make_user(db_session, email="pris@example.com")
    response = patch_me(client, {"email": "PRIS@example.com"})
    assert response.status_code == 409
    assert code_of(response) == "EMAIL_ALREADY_USED"


# --- Petites fonctions --------------------------------------------------------------


def test_reset_codes_are_six_random_digits():
    codes = {generate_reset_code() for _ in range(2_000)}
    assert all(re.fullmatch(r"[0-9]{6}", c) for c in codes)
    assert len(codes) > 1_900  # presque tous différents


def test_same_code_has_a_different_hash_for_each_account():
    assert reset_code_hash("cle", 1, "123456") != reset_code_hash("cle", 2, "123456")
    assert reset_code_hash("cle", 1, "123456") != reset_code_hash("autre-cle", 1, "123456")


@pytest.mark.parametrize("secret_key", ["password", "password_hash", "refresh_token", "code"])
def test_audit_refuses_secrets(db_session, secret_key):
    with pytest.raises(ValueError, match="secrète"):
        record(
            db_session,
            action="user.test",
            entity_type="user",
            entity_id=1,
            actor_id=None,
            after={secret_key: "xxx"},
        )
