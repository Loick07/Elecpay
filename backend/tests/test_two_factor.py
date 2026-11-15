"""Double authentification de l'équipe (B11.3) : activation, connexion en deux étapes (mobile et
back-office), codes de secours, obligation pour admin et super admin, réinitialisation, journal."""

from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core import totp
from app.core.security import hash_password
from app.db.session import get_db
from app.main import create_app
from app.modules.audit.models import AuditLog
from app.modules.auth.models import TwoFactorSecret
from app.modules.auth.tokens import create_challenge_token
from app.modules.auth.two_factor import TwoFactorService
from app.modules.users.models import UserRole
from app.simulators.demo_two_factor import DEMO_TOTP_SECRET, enable_demo_two_factor
from tests.factories import make_user

PASSWORD = "Equipe2026!"
ME = "/api/v1/me/2fa"


class Clock:
    """Horloge de la 2FA, avancée à la main (un code ne sert qu'une fois par tranche de 30 s)."""

    def __init__(self) -> None:
        self.now = datetime(2026, 11, 14, 9, 0, tzinfo=UTC)

    def tick(self, seconds: int = 30) -> None:
        self.now += timedelta(seconds=seconds)

    def code(self, secret: str) -> str:
        return totp.hotp(secret, totp.time_step(self.now.timestamp()))


@pytest.fixture
def clock(monkeypatch) -> Clock:
    clock = Clock()
    original = TwoFactorService.__init__

    def patched(self, session, settings, now=None):
        original(self, session, settings, lambda: clock.now)

    monkeypatch.setattr(TwoFactorService, "__init__", patched)
    return clock


@pytest.fixture
def strict(test_settings, db_session):
    """Application avec la 2FA OBLIGATOIRE pour admin et super admin (réglage de production)."""
    app = create_app(test_settings.model_copy(update={"team_2fa_required": True}))
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def staff(session, role=UserRole.SUPPORT, **extra):
    return make_user(session, role=role, password_hash=hash_password(PASSWORD), **extra)


def password_login(client, user, path="/api/v1/auth/login"):
    return client.post(path, json={"phone": user.phone, "password": PASSWORD})


def bearer(client, user):
    """Connexion par mot de passe seul (membre sans 2FA) → en-tête Authorization."""
    body = password_login(client, user).json()
    return {"Authorization": f"Bearer {body['access_token']}"}


def enroll(client, headers, clock) -> tuple[str, list[str]]:
    """Active la 2FA par l'API ; renvoie le secret et les codes de secours."""
    setup = client.post(f"{ME}/setup", headers=headers)
    assert setup.status_code == 200, setup.text
    secret = setup.json()["secret"]
    enabled = client.post(f"{ME}/enable", json={"code": clock.code(secret)}, headers=headers)
    assert enabled.status_code == 200, enabled.text
    clock.tick()
    return secret, enabled.json()["backup_codes"]


def second_step(client, challenge, code, path="/api/v1/auth/login/2fa"):
    return client.post(path, json={"challenge_token": challenge, "code": code})


def actions(session, user):
    return [
        log.action
        for log in session.scalars(
            select(AuditLog).where(AuditLog.entity_id == user.id).order_by(AuditLog.id)
        )
    ]


# --- Activation -----------------------------------------------------------------------------


def test_enrollment(client, db_session, clock):
    member = staff(db_session)
    headers = bearer(client, member)
    status = client.get(ME, headers=headers).json()
    assert (status["enabled"], status["pending_setup"], status["required"]) == (False, False, False)

    setup = client.post(f"{ME}/setup", headers=headers).json()
    assert setup["otpauth_uri"].startswith("otpauth://totp/ElecPay")
    assert setup["qr_svg"].startswith("<svg")
    assert client.get(ME, headers=headers).json()["pending_setup"] is True
    wrong = client.post(f"{ME}/enable", json={"code": "000000"}, headers=headers)
    assert wrong.status_code == 401
    assert wrong.json()["error"]["code"] == "TWO_FACTOR_CODE_INVALID"

    enabled = client.post(
        f"{ME}/enable", json={"code": clock.code(setup["secret"])}, headers=headers
    )
    assert enabled.status_code == 200, enabled.text
    codes = enabled.json()["backup_codes"]
    assert len(codes) == 10 and len(set(codes)) == 10
    status = client.get(ME, headers=headers).json()
    assert (status["enabled"], status["backup_codes_left"]) == (True, 10)

    row = db_session.scalars(
        select(TwoFactorSecret).where(TwoFactorSecret.user_id == member.id)
    ).one()
    assert setup["secret"] not in row.secret_encrypted  # chiffré en base
    assert "team.two_factor_enable" in actions(db_session, member)
    again = client.post(f"{ME}/setup", headers=headers)
    assert again.status_code == 409  # déjà active


def test_clients_have_no_two_factor(client, auth_headers, db_session):
    assert client.get(ME, headers=auth_headers(make_user(db_session))).status_code == 403


# --- Connexion en deux étapes ---------------------------------------------------------------


def test_mobile_login_in_two_steps(client, db_session, clock):
    member = staff(db_session)
    secret, _ = enroll(client, bearer(client, member), clock)

    first = password_login(client, member)
    assert first.status_code == 200
    body = first.json()
    assert body["two_factor_required"] is True
    assert "access_token" not in body
    code = clock.code(secret)
    done = second_step(client, body["challenge_token"], code)
    assert done.status_code == 200, done.text
    assert done.json()["user"]["id"] == member.id

    # Le même code ne resservira jamais, même avec un nouveau défi.
    replay = password_login(client, member).json()["challenge_token"]
    assert second_step(client, replay, code).status_code == 401
    assert actions(db_session, member)[-2:] == ["team.login", "team.two_factor_failed"]
    logins = db_session.scalars(
        select(AuditLog).where(AuditLog.action == "team.login").order_by(AuditLog.id)
    ).all()
    # Avant l'activation : mot de passe seul ; après : mot de passe + code.
    assert [log.after_json["method"] for log in logins] == ["password", "password+totp"]


def test_backup_code_works_once(client, db_session, clock):
    member = staff(db_session)
    _, codes = enroll(client, bearer(client, member), clock)
    challenge = password_login(client, member).json()["challenge_token"]
    assert second_step(client, challenge, codes[0].lower()).status_code == 200  # casse libre
    challenge = password_login(client, member).json()["challenge_token"]
    assert second_step(client, challenge, codes[0]).status_code == 401
    assert (
        client.get(ME, headers=bearer_after_2fa(client, member, codes[1])).json()[
            "backup_codes_left"
        ]
        == 8
    )


def bearer_after_2fa(client, member, code):
    challenge = password_login(client, member).json()["challenge_token"]
    token = second_step(client, challenge, code).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_back_office_login_in_two_steps(client, db_session, clock):
    member = staff(db_session)
    secret, _ = enroll(client, bearer(client, member), clock)
    first = password_login(client, member, "/api/v1/auth/web/login")
    assert first.json()["two_factor_required"] is True
    assert "elecpay_access" not in first.cookies  # aucune session avant le code
    done = second_step(
        client, first.json()["challenge_token"], clock.code(secret), "/api/v1/auth/web/login/2fa"
    )
    assert done.status_code == 200, done.text
    assert "elecpay_access" in done.cookies


def test_wrong_codes_are_limited(client, db_session, clock):
    member = staff(db_session)
    enroll(client, bearer(client, member), clock)
    challenge = password_login(client, member).json()["challenge_token"]
    codes = [second_step(client, challenge, "000000").status_code for _ in range(6)]
    assert codes == [401, 401, 401, 401, 401, 429]


def test_challenge_cannot_be_forged_or_used_elsewhere(client, db_session, clock, test_settings):
    member = staff(db_session)
    enroll(client, bearer(client, member), clock)
    challenge = password_login(client, member).json()["challenge_token"]
    # Un défi n'ouvre aucune autre route.
    assert client.get(ME, headers={"Authorization": f"Bearer {challenge}"}).status_code == 401
    expired, _ = create_challenge_token(
        member.id,
        secret=test_settings.jwt_secret.get_secret_value(),
        minutes=5,
        now=datetime.now(UTC) - timedelta(minutes=10),
    )
    for bad in (expired, challenge[:-4] + "abcd", "x" * 40):
        response = second_step(client, bad, "123456")
        assert response.status_code == 401
        assert response.json()["error"]["code"] == "TWO_FACTOR_CHALLENGE_INVALID"


def test_clients_and_members_without_2fa_log_in_directly(client, db_session):
    member = staff(db_session)
    assert "access_token" in password_login(client, member).json()
    customer = make_user(db_session, password_hash=hash_password(PASSWORD))
    assert "access_token" in password_login(client, customer).json()
    login = db_session.scalars(select(AuditLog).where(AuditLog.entity_id == member.id)).one()
    assert (login.action, login.after_json) == ("team.login", {"method": "password"})
    assert (
        actions(db_session, customer) == []
    )  # les connexions des clients ne sont pas journalisées


def test_failed_team_login_is_journaled(client, db_session):
    member = staff(db_session)
    response = client.post(
        "/api/v1/auth/login", json={"phone": member.phone, "password": "Faux2026!"}
    )
    assert response.status_code == 401
    assert actions(db_session, member) == ["team.login_failed"]


# --- Obligation pour admin et super admin ---------------------------------------------------


def test_admins_must_enable_it(strict, db_session, clock):
    admin = staff(db_session, role=UserRole.ADMIN)
    headers = bearer(strict, admin)
    blocked = strict.get("/api/v1/admin/stats", headers=headers)
    assert blocked.status_code == 403
    assert blocked.json()["error"]["code"] == "TWO_FACTOR_SETUP_REQUIRED"
    assert strict.get(ME, headers=headers).json()["required"] is True  # l'activation reste ouverte
    enroll(strict, headers, clock)
    assert strict.get("/api/v1/admin/stats", headers=headers).status_code == 200


def test_support_is_not_forced(strict, db_session):
    support = staff(db_session, role=UserRole.SUPPORT)
    assert strict.get("/api/v1/admin/stats", headers=bearer(strict, support)).status_code == 200


def test_disable(strict, db_session, clock):
    admin = staff(db_session, role=UserRole.ADMIN)
    admin_headers = bearer(strict, admin)
    admin_secret, _ = enroll(strict, admin_headers, clock)
    refused = strict.post(
        f"{ME}/disable",
        json={"password": PASSWORD, "code": clock.code(admin_secret)},
        headers=admin_headers,
    )
    assert refused.status_code == 403
    assert refused.json()["error"]["code"] == "TWO_FACTOR_REQUIRED_FOR_ROLE"

    support = staff(db_session)
    headers = bearer(strict, support)
    secret, _ = enroll(strict, headers, clock)
    wrong = strict.post(
        f"{ME}/disable", json={"password": "Faux2026!", "code": clock.code(secret)}, headers=headers
    )
    assert wrong.status_code == 401
    ok = strict.post(
        f"{ME}/disable", json={"password": PASSWORD, "code": clock.code(secret)}, headers=headers
    )
    assert ok.status_code == 204
    assert strict.get(ME, headers=headers).json()["enabled"] is False
    assert "team.two_factor_disable" in actions(db_session, support)


def test_regenerate_backup_codes(client, db_session, clock):
    member = staff(db_session)
    headers = bearer(client, member)
    secret, old = enroll(client, headers, clock)
    new = client.post(f"{ME}/backup-codes", json={"code": clock.code(secret)}, headers=headers)
    assert new.status_code == 200
    challenge = password_login(client, member).json()["challenge_token"]
    assert second_step(client, challenge, old[0]).status_code == 401
    assert second_step(client, challenge, new.json()["backup_codes"][0]).status_code == 200


# --- Comptes de démo (option 1 validée par Loick) -------------------------------------------


def test_demo_admins_get_a_ready_two_factor(strict, db_session, clock, test_settings):
    admin = staff(db_session, role=UserRole.ADMIN)
    boss = staff(db_session, role=UserRole.SUPER_ADMIN)
    support = staff(db_session, role=UserRole.SUPPORT)
    secured = enable_demo_two_factor(db_session, test_settings)
    assert {member.id for member in secured} >= {admin.id, boss.id}
    assert support.id not in {member.id for member in secured}  # facultative pour le support
    row = db_session.scalars(
        select(TwoFactorSecret).where(TwoFactorSecret.user_id == admin.id)
    ).one()
    assert DEMO_TOTP_SECRET not in row.secret_encrypted  # chiffré, même en démo
    # Le code calculé depuis le secret imprimé par le seed ouvre le back-office.
    headers = bearer_after_2fa(strict, admin, clock.code(DEMO_TOTP_SECRET))
    assert strict.get("/api/v1/admin/stats", headers=headers).status_code == 200


# --- Réinitialisation par un super admin ----------------------------------------------------


def test_super_admin_resets_a_lost_phone(strict, db_session, clock):
    boss = staff(db_session, role=UserRole.SUPER_ADMIN)
    boss_secret, _ = enroll(strict, bearer(strict, boss), clock)
    boss_headers = bearer_after_2fa(strict, boss, clock.code(boss_secret))
    clock.tick()
    admin = staff(db_session, role=UserRole.ADMIN)
    admin_headers = bearer(strict, admin)
    enroll(strict, admin_headers, clock)

    team = {
        m["id"]: m["two_factor"]
        for m in strict.get("/api/v1/admin/team", headers=boss_headers).json()
    }
    assert team[admin.id] == "enabled"
    path = f"/api/v1/admin/team/{admin.id}/2fa/reset"
    response = strict.post(
        path, json={"reason": "Téléphone perdu, identité vérifiée"}, headers=boss_headers
    )
    assert response.status_code == 200, response.text
    assert response.json()["two_factor"] == "disabled"
    # Ses sessions sont fermées et il doit la réactiver pour revenir dans le back-office.
    assert strict.post("/api/v1/auth/refresh", json={"refresh_token": "x" * 64}).status_code == 401
    blocked = strict.get("/api/v1/admin/stats", headers=bearer(strict, admin))
    assert blocked.json()["error"]["code"] == "TWO_FACTOR_SETUP_REQUIRED"
    log = db_session.scalars(
        select(AuditLog).where(AuditLog.action == "team.two_factor_reset")
    ).one()
    assert (log.actor_id, log.entity_id) == (boss.id, admin.id)
    assert log.after_json["reason"] == "Téléphone perdu, identité vérifiée"

    again = strict.post(path, json={"reason": "Encore une fois"}, headers=boss_headers)
    assert again.status_code == 409  # plus rien à réinitialiser
    own = strict.post(
        f"/api/v1/admin/team/{boss.id}/2fa/reset",
        json={"reason": "Pour voir"},
        headers=boss_headers,
    )
    assert own.status_code == 409
