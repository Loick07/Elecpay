"""Tests du service de sessions (B3.2) : ouverture, rotation, réutilisation, fermeture."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from app.modules.auth.errors import (
    AccountDisabledError,
    RefreshTokenReusedError,
    TokenExpiredError,
    TokenInvalidError,
)
from app.modules.auth.models import RefreshToken
from app.modules.auth.sessions import SessionService
from app.modules.auth.tokens import decode_access_token, hash_refresh_token
from app.modules.users.models import UserRole
from tests.factories import make_user


class Clock:
    """Horloge de test qu'on peut avancer à la main."""

    def __init__(self):
        # Part de l'heure réelle : un jeton daté « dans le futur » serait refusé (iat > maintenant).
        self.current = datetime.now(UTC).replace(microsecond=0)

    def __call__(self):
        return self.current

    def advance(self, **delta):
        self.current += timedelta(**delta)


@pytest.fixture
def clock():
    return Clock()


@pytest.fixture
def service(db_session, test_settings, clock):
    return SessionService(db_session, test_settings, now=clock)


def tokens_of(session, user):
    return session.scalars(select(RefreshToken).where(RefreshToken.user_id == user.id)).all()


# --- Ouverture ----------------------------------------------------------------------


def test_open_session_gives_both_tokens(db_session, service, test_settings, clock):
    user = make_user(db_session, role=UserRole.ADMIN)
    issued = service.open_session(user, user_agent="ElecPay Android 1.0")

    claims = decode_access_token(
        issued.access_token, secret=test_settings.jwt_secret.get_secret_value()
    )
    assert (claims.user_id, claims.role) == (user.id, "admin")
    assert issued.access_expires_at == clock() + timedelta(minutes=15)
    assert issued.refresh_expires_at == clock() + timedelta(days=30)

    (row,) = tokens_of(db_session, user)
    assert row.token_hash == hash_refresh_token(issued.refresh_token)
    assert issued.refresh_token not in row.token_hash  # jamais stocké en clair
    assert row.user_agent == "ElecPay Android 1.0"
    assert row.revoked_at is None


def test_each_login_starts_a_new_family(db_session, service):
    user = make_user(db_session)
    service.open_session(user)
    service.open_session(user)  # un deuxième appareil
    assert len({t.family_id for t in tokens_of(db_session, user)}) == 2


def test_very_long_user_agent_is_truncated(db_session, service):
    user = make_user(db_session)
    service.open_session(user, user_agent="x" * 1_000)
    assert len(tokens_of(db_session, user)[0].user_agent) == 255


# --- Rotation -----------------------------------------------------------------------


def test_rotation_replaces_the_refresh_token(db_session, service, clock):
    user = make_user(db_session)
    first = service.open_session(user)
    clock.advance(minutes=20)
    second = service.rotate(first.refresh_token)

    assert second.refresh_token != first.refresh_token
    old, new = sorted(tokens_of(db_session, user), key=lambda t: t.id)
    assert old.revoked_at == clock() and old.replaced_by_id == new.id
    assert new.revoked_at is None and new.family_id == old.family_id


def test_rotation_chain_works_many_times(db_session, service, clock):
    user = make_user(db_session)
    issued = service.open_session(user)
    for _ in range(5):
        clock.advance(hours=1)
        issued = service.rotate(issued.refresh_token)
    active = [t for t in tokens_of(db_session, user) if t.revoked_at is None]
    assert len(active) == 1


def test_reusing_an_old_refresh_token_revokes_the_whole_family(db_session, service, clock):
    """Scénario de vol : le voleur et la victime utilisent le même jeton."""
    user = make_user(db_session)
    stolen = service.open_session(user)
    clock.advance(minutes=5)
    legit = service.rotate(stolen.refresh_token)  # la victime rafraîchit normalement

    clock.advance(minutes=5)
    with pytest.raises(RefreshTokenReusedError):
        service.rotate(stolen.refresh_token)  # le voleur rejoue l'ancien jeton

    assert all(t.revoked_at is not None for t in tokens_of(db_session, user))
    with pytest.raises(RefreshTokenReusedError):
        service.rotate(legit.refresh_token)  # la session de la victime est fermée aussi


def test_reuse_only_revokes_that_family(db_session, service):
    user = make_user(db_session)
    phone = service.open_session(user)
    laptop = service.open_session(user)
    service.rotate(phone.refresh_token)
    with pytest.raises(RefreshTokenReusedError):
        service.rotate(phone.refresh_token)
    service.rotate(laptop.refresh_token)  # l'autre appareil n'est pas touché


def test_expired_refresh_token_is_refused(db_session, service, clock):
    user = make_user(db_session)
    issued = service.open_session(user)
    clock.advance(days=30)
    with pytest.raises(TokenExpiredError):
        service.rotate(issued.refresh_token)


def test_refresh_token_still_valid_just_before_expiry(db_session, service, clock):
    user = make_user(db_session)
    issued = service.open_session(user)
    clock.advance(days=30, seconds=-1)
    service.rotate(issued.refresh_token)


@pytest.mark.parametrize("token", ["", "inconnu", "x" * 64])
def test_unknown_refresh_token_is_invalid(service, token):
    with pytest.raises(TokenInvalidError):
        service.rotate(token)


def test_access_token_is_not_a_refresh_token(db_session, service):
    user = make_user(db_session)
    issued = service.open_session(user)
    with pytest.raises(TokenInvalidError):
        service.rotate(issued.access_token)


def test_disabled_account_cannot_refresh_and_loses_its_sessions(db_session, service):
    user = make_user(db_session)
    issued = service.open_session(user)
    user.is_active = False
    db_session.flush()
    with pytest.raises(AccountDisabledError):
        service.rotate(issued.refresh_token)
    assert all(t.revoked_at is not None for t in tokens_of(db_session, user))


# --- Fermeture ----------------------------------------------------------------------


def test_logout_closes_the_session(db_session, service):
    user = make_user(db_session)
    issued = service.open_session(user)
    service.close_session(issued.refresh_token)
    with pytest.raises(RefreshTokenReusedError):  # jeton révoqué : plus utilisable
        service.rotate(issued.refresh_token)


def test_logout_with_unknown_token_does_nothing(service):
    service.close_session("jeton-inconnu")  # pas d'erreur : déconnexion idempotente


def test_close_all_sessions_logs_out_every_device_of_one_user_only(db_session, service):
    user, other = make_user(db_session), make_user(db_session)
    for _ in range(3):
        service.open_session(user)
    other_session = service.open_session(other)

    assert service.close_all_sessions(user.id) == 3
    assert all(t.revoked_at is not None for t in tokens_of(db_session, user))
    service.rotate(other_session.refresh_token)  # l'autre utilisateur n'est pas touché
