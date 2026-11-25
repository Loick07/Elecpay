"""Seed sûr pour une base exposée (M1.1, condition de sécurité de Loick du 21/11/2026).

« Demo2026! » et le secret 2FA de démo sont PUBLICS : en production, le seed exige un mot de passe
choisi sur le serveur (jamais vide, jamais « Demo2026! ») et tire au hasard un secret 2FA par membre
de l'équipe. Fichier séparé de test_seed.py : deux seeds ne doivent pas être ouverts en même temps.
"""

import pytest
from pydantic import SecretStr
from sqlalchemy import select

from app.core import totp
from app.core.secret_box import decrypt
from app.core.security import verify_password
from app.modules.auth.models import TwoFactorSecret
from app.modules.users.models import User, UserRole
from app.simulators.demo_dataset import DEMO_PASSWORD
from app.simulators.demo_two_factor import DEMO_TOTP_SECRET, enable_team_two_factor
from app.simulators.seed_policy import SeedRefusedError, seed_credentials
from app.simulators.seeder import seed_demo
from scripts import daily_tick
from scripts import seed as seed_command
from tests.conftest import transactional_session
from tests.factories import Billing
from tests.test_seed import TODAY

SERVER_PASSWORD = "Graine-serveur-2026"  # noqa: S105 — mot de passe de test, pas un vrai secret


def settings_for(test_settings, *, env="production", password="", demo_mode=True):
    return test_settings.model_copy(
        update={
            "app_env": env,
            "demo_mode": demo_mode,
            "demo_seed_password": SecretStr(password),
        }
    )


# --- La règle (seed_credentials) -------------------------------------------------------------


def test_development_without_password_keeps_the_public_demo(test_settings):
    credentials = seed_credentials(settings_for(test_settings, env="development"))
    assert credentials.public is True
    assert credentials.password == DEMO_PASSWORD
    assert credentials.totp_secret() == DEMO_TOTP_SECRET


def test_production_with_a_server_password(test_settings):
    credentials = seed_credentials(settings_for(test_settings, password=SERVER_PASSWORD))
    assert credentials.public is False
    assert credentials.password == SERVER_PASSWORD
    secrets = {credentials.totp_secret() for _ in range(20)}
    assert len(secrets) == 20, "un secret différent à chaque membre"
    assert DEMO_TOTP_SECRET not in secrets
    assert all(len(secret) == 32 for secret in secrets)  # 20 octets en base32


@pytest.mark.parametrize(
    ("password", "why"),
    [
        ("", "vide"),
        ("   ", "vide"),
        (DEMO_PASSWORD, "public"),
        ("demo2026!", "public"),
        (" DEMO2026! ", "public"),
        ("motdepasse", "trop faible"),  # sans chiffre
        ("12345678", "trop faible"),  # sans lettre
        ("Court1", "trop faible"),
    ],
)
def test_production_refuses_empty_public_or_weak_passwords(test_settings, password, why):
    with pytest.raises(SeedRefusedError, match=why):
        seed_credentials(settings_for(test_settings, password=password))


def test_production_refuses_without_demo_mode(test_settings):
    settings = settings_for(test_settings, password=SERVER_PASSWORD, demo_mode=False)
    with pytest.raises(SeedRefusedError, match="DEMO_MODE"):
        seed_credentials(settings)


def test_development_with_a_password_follows_the_same_rules(test_settings):
    chosen = seed_credentials(
        settings_for(test_settings, env="development", password=SERVER_PASSWORD)
    )
    assert (chosen.public, chosen.password) == (False, SERVER_PASSWORD)
    with pytest.raises(SeedRefusedError, match="public"):
        seed_credentials(settings_for(test_settings, env="development", password=DEMO_PASSWORD))


def test_the_password_never_appears_in_repr(test_settings):
    credentials = seed_credentials(settings_for(test_settings, password=SERVER_PASSWORD))
    assert SERVER_PASSWORD not in repr(credentials)
    assert SERVER_PASSWORD not in repr(settings_for(test_settings, password=SERVER_PASSWORD))


# --- Seed complet avec le mot de passe du serveur et des secrets tirés au hasard -------------


@pytest.fixture(scope="module")
def server_seed(test_engine):
    with transactional_session(test_engine) as session:
        seed_demo(session, today=TODAY, settings=Billing(), password=SERVER_PASSWORD)
        yield session


def test_every_account_gets_the_server_password_never_the_public_one(server_seed):
    users = server_seed.scalars(select(User)).all()
    assert len(users) >= 10
    for user in users:
        assert verify_password(SERVER_PASSWORD, user.password_hash), user.phone
        assert not verify_password(DEMO_PASSWORD, user.password_hash), user.phone


def test_team_two_factor_secrets_are_random_encrypted_and_working(server_seed, test_settings):
    credentials = seed_credentials(settings_for(test_settings, password=SERVER_PASSWORD))
    secured = enable_team_two_factor(
        server_seed, test_settings, lambda _member: credentials.totp_secret()
    )
    roles = {member.role for member, _ in secured}
    assert roles == {UserRole.ADMIN, UserRole.SUPER_ADMIN}
    secrets = [secret for _, secret in secured]
    assert len(set(secrets)) == len(secrets), "un secret par membre"
    assert DEMO_TOTP_SECRET not in secrets
    for member, secret in secured:
        row = server_seed.scalars(
            select(TwoFactorSecret).where(TwoFactorSecret.user_id == member.id)
        ).one()
        assert secret not in row.secret_encrypted  # chiffré en base
        assert decrypt(row.secret_encrypted, test_settings.two_factor_cipher_key) == secret
        # Le secret affiché par le seed produit bien les codes de l'application d'authentification.
        assert totp.matching_step(secret, totp.hotp(secret, 1000), 1000 * 30) == 1000


# --- La commande : refus AVANT toute écriture en base -------------------------------------------


@pytest.mark.parametrize(
    ("password", "demo_mode"),
    [("", True), (DEMO_PASSWORD, True), ("faible", True), (SERVER_PASSWORD, False)],
)
def test_seed_command_refuses_before_touching_the_database(
    test_settings, monkeypatch, capsys, password, demo_mode
):
    settings = settings_for(test_settings, password=password, demo_mode=demo_mode)
    monkeypatch.setattr(seed_command, "get_settings", lambda: settings)

    def no_database():
        raise AssertionError("la base ne doit pas être ouverte")

    monkeypatch.setattr(seed_command, "get_sessionmaker", no_database)
    assert seed_command.main(["--today", "2026-11-12"]) == 1
    assert "Refusé" in capsys.readouterr().err


# --- Relevé quotidien : permis en production de démonstration seulement --------------------------


@pytest.mark.parametrize(
    ("changes", "refused"),
    [
        ({"app_env": "production"}, False),  # serveur de démonstration (ngrok)
        ({"app_env": "production", "demo_mode": False}, True),
    ],
)
def test_daily_tick_in_production_only_as_a_demo(test_settings, changes, refused):
    settings = test_settings.model_copy(update=changes)
    assert (daily_tick.refusal_reason(settings) is not None) is refused
