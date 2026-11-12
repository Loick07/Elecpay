"""Contraintes des tables `users` et `refresh_tokens` (B1.2)."""

from datetime import timedelta

import pytest
from sqlalchemy import text
from sqlalchemy.exc import StatementError

from app.db.base import utcnow
from app.modules.users.models import User, UserRole
from tests.db_helpers import expect_db_rejection
from tests.factories import make_refresh_token, make_user

# --- users : valeurs par défaut -----------------------------------------------------


def test_new_user_defaults(db_session):
    user = make_user(db_session)
    db_session.expire(user)  # relire depuis MySQL
    assert user.role is UserRole.CLIENT
    assert user.is_active is True
    assert user.email is None
    assert user.last_login_at is None
    assert user.created_at.tzinfo is not None


def test_is_active_defaults_to_true_in_database(db_session):
    db_session.execute(
        text(
            "INSERT INTO users (phone, full_name, password_hash, role, created_at, updated_at) "
            "VALUES ('+242069999999', 'SQL brut', 'h', 'client', NOW(6), NOW(6))"
        )
    )
    is_active = db_session.execute(
        text("SELECT is_active FROM users WHERE phone = '+242069999999'")
    ).scalar_one()
    assert is_active == 1


def test_repr_never_shows_phone_or_hash(db_session):
    user = make_user(db_session, phone="+242061234567")
    assert "061234567" not in repr(user)
    assert "argon2" not in repr(user)


# --- users : téléphone --------------------------------------------------------------


def test_phone_is_unique(db_session):
    make_user(db_session, phone="+242061111111")
    with expect_db_rejection(db_session, "uq_users_phone"):
        make_user(db_session, phone="+242061111111")


@pytest.mark.parametrize(
    "phone",
    [
        "061234567",  # sans indicatif
        "+24206123456",  # 8 chiffres
        "+2420612345678",  # 10 chiffres (trop long pour la colonne aussi)
        "+243061234567",  # indicatif RDC
        "242061234567",  # sans le +
        "+24206123456a",  # lettre
    ],
)
def test_badly_formatted_phone_is_refused(db_session, phone):
    with expect_db_rejection(db_session):
        make_user(db_session, phone=phone)


def test_valid_phone_formats_are_accepted(db_session):
    for phone in ("+242061234567", "+242051234567", "+242221234567"):
        make_user(db_session, phone=phone)


# --- users : e-mail, nom, rôle ------------------------------------------------------


def test_email_is_unique_case_insensitive(db_session):
    make_user(db_session, email="loick@example.cg")
    with expect_db_rejection(db_session, "uq_users_email"):
        make_user(db_session, email="LOICK@example.cg")


def test_several_users_without_email_are_allowed(db_session):
    make_user(db_session, email=None)
    make_user(db_session, email=None)


@pytest.mark.parametrize("name", ["", "   "])
def test_blank_full_name_is_refused(db_session, name):
    with expect_db_rejection(db_session, "ck_users_full_name_not_blank"):
        make_user(db_session, full_name=name)


@pytest.mark.parametrize("role", list(UserRole))
def test_every_role_is_accepted(db_session, role):
    assert make_user(db_session, role=role).role is role


def test_unknown_role_is_refused_by_python(db_session):
    with pytest.raises(StatementError):
        make_user(db_session, role="payer")  # payeur délégué = rôle dans un foyer, pas de compte
    db_session.rollback()


def test_unknown_role_is_refused_by_mysql(db_session):
    user = make_user(db_session)
    with expect_db_rejection(db_session, "ck_users_role"):
        db_session.execute(text("UPDATE users SET role = 'root' WHERE id = :id"), {"id": user.id})


@pytest.mark.parametrize("column", ["phone", "full_name", "password_hash"])
def test_required_columns(db_session, column):
    values = {"phone": "+242067777777", "full_name": "X", "password_hash": "h"}
    values[column] = None
    with expect_db_rejection(db_session):
        db_session.add(User(**values))


def test_user_with_tokens_cannot_be_deleted(db_session):
    user = make_user(db_session)
    make_refresh_token(db_session, user)
    with expect_db_rejection(db_session, "fk_refresh_tokens_user_id_users"):
        db_session.execute(text("DELETE FROM users WHERE id = :id"), {"id": user.id})


# --- refresh_tokens -----------------------------------------------------------------


def test_refresh_token_is_stored(db_session):
    user = make_user(db_session)
    token = make_refresh_token(db_session, user, user_agent="ElecPay Android 1.0")
    db_session.expire(token)
    assert token.revoked_at is None
    assert token.replaced_by_id is None
    assert len(token.token_hash) == 64
    assert token.expires_at > token.created_at


def test_token_hash_is_unique(db_session):
    user = make_user(db_session)
    first = make_refresh_token(db_session, user)
    with expect_db_rejection(db_session, "uq_refresh_tokens_token_hash"):
        make_refresh_token(db_session, user, token_hash=first.token_hash)


@pytest.mark.parametrize("token_hash", ["abc", "a" * 63])
def test_token_hash_must_be_a_sha256(db_session, token_hash):
    user = make_user(db_session)
    with expect_db_rejection(db_session, "ck_refresh_tokens_token_hash_length"):
        make_refresh_token(db_session, user, token_hash=token_hash)


def test_token_must_expire_after_creation(db_session):
    user = make_user(db_session)
    with expect_db_rejection(db_session, "ck_refresh_tokens_expires_after_creation"):
        make_refresh_token(db_session, user, expires_at=utcnow() - timedelta(seconds=1))


def test_token_requires_existing_user(db_session):
    with expect_db_rejection(db_session, "fk_refresh_tokens_user_id_users"):
        db_session.execute(
            text(
                "INSERT INTO refresh_tokens (user_id, token_hash, family_id, expires_at, "
                "created_at, updated_at) VALUES (999999, :h, :f, NOW(6) + INTERVAL 1 DAY, "
                "NOW(6), NOW(6))"
            ),
            {"h": "a" * 64, "f": "f" * 36},
        )


def test_rotation_chain_and_family(db_session):
    user = make_user(db_session)
    first = make_refresh_token(db_session, user)
    second = make_refresh_token(db_session, user, family_id=first.family_id)
    first.revoked_at = utcnow()
    first.replaced_by_id = second.id
    db_session.flush()

    family = db_session.execute(
        text("SELECT COUNT(*) FROM refresh_tokens WHERE family_id = :f"),
        {"f": first.family_id},
    ).scalar_one()
    assert family == 2
    assert first.replaced_by_id == second.id


def test_replacement_must_exist(db_session):
    user = make_user(db_session)
    token = make_refresh_token(db_session, user)
    with expect_db_rejection(db_session, "fk_refresh_tokens_replaced_by_id_refresh_tokens"):
        token.replaced_by_id = 999_999
        db_session.flush()
