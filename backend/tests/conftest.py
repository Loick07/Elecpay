"""Fixtures partagées par les tests.

- `test_engine` : moteur branché sur la base de TEST (`..._test`), jamais sur la base de dev.
- `db_session`  : session isolée ; tout ce qu'un test écrit est annulé à la fin du test.
- `app` / `client` : application FastAPI dont `get_db` utilise `db_session`, et client HTTP.
"""

from collections.abc import Iterator
from contextlib import contextmanager

import pytest
from alembic import command
from alembic.config import Config
from argon2 import PasswordHasher
from fastapi import FastAPI
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import Engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app.core import security
from app.core.config import Settings, get_settings
from app.db.migrations import alembic_config as app_alembic_config
from app.db.session import build_engine, get_db
from app.main import create_app
from app.modules.auth.tokens import create_access_token


@pytest.fixture(scope="session", autouse=True)
def fast_password_hashing() -> Iterator[None]:
    """Argon2 allégé PENDANT LES TESTS uniquement.

    Argon2 est volontairement lent (~0,3 s par vérification) pour décourager les attaques ;
    les tests font des centaines de connexions. Même algorithme (Argon2id), même code testé,
    seuls le temps et la mémoire sont réduits. L'application réelle garde les réglages forts.
    """
    real_hasher = security._hasher
    security._hasher = PasswordHasher(time_cost=1, memory_cost=1024, parallelism=1)
    yield
    security._hasher = real_hasher


@pytest.fixture(scope="session")
def test_engine() -> Iterator[Engine]:
    """Moteur branché sur la base de TEST (jamais sur la base de développement)."""
    url = get_settings().test_database_url
    if not url:
        pytest.fail("TEST_DATABASE_URL manquant : le définir dans backend/.env (voir .env.example)")
    database = make_url(url).database or ""
    if not database.endswith("_test"):
        pytest.fail(f"Sécurité : la base de test doit finir par '_test' (reçu : {database!r})")
    # La base de test a toujours la structure à jour : on applique les migrations.
    command.upgrade(alembic_config(url), "head")
    engine = build_engine(url)
    yield engine
    engine.dispose()


def alembic_config(database_url: str) -> Config:
    """Configuration Alembic des tests (sans toucher à la capture des logs de pytest)."""
    return app_alembic_config(database_url, configure_logger=False)


@contextmanager
def transactional_session(engine: Engine) -> Iterator[Session]:
    """Session dont tout le travail est annulé à la fin, même les `commit()` du code testé.

    On ouvre une transaction extérieure ; chaque `commit()` de la session ne valide
    qu'un point de sauvegarde (SAVEPOINT) à l'intérieur. À la fin, on annule tout.
    Attention : sous MySQL, une instruction DDL (CREATE/DROP TABLE) valide implicitement ;
    les tables doivent donc exister avant (créées par les migrations).
    """
    connection = engine.connect()
    outer = connection.begin()
    session = Session(
        bind=connection,
        join_transaction_mode="create_savepoint",
        autoflush=False,
        expire_on_commit=False,
    )
    try:
        yield session
    finally:
        session.close()
        outer.rollback()
        connection.close()


@pytest.fixture
def db_session(test_engine: Engine) -> Iterator[Session]:
    with transactional_session(test_engine) as session:
        yield session


TEST_CORS_ORIGIN = "http://localhost:3000"


@pytest.fixture
def test_settings() -> Settings:
    """Configuration fixe des tests : ne dépend pas des réglages du .env du développeur."""
    return get_settings().model_copy(
        update={
            "app_env": "test",
            "demo_mode": True,
            "cors_origins": [TEST_CORS_ORIGIN],
            # Secret propre aux tests, assez long pour HS256 (≥ 32 octets).
            "jwt_secret": SecretStr("secret-de-test-elecpay-" + "x" * 48),
            "payment_webhook_secret": SecretStr("webhooks-de-test-elecpay-" + "w" * 40),
            "payment_provider": "simulated",
        }
    )


@pytest.fixture
def app(test_settings: Settings, db_session: Session) -> FastAPI:
    """Application neuve pour chaque test, branchée sur la base de test."""
    application = create_app(test_settings)
    application.dependency_overrides[get_db] = lambda: db_session
    return application


@pytest.fixture
def auth_headers(test_settings: Settings):
    """Fabrique l'en-tête Authorization d'un utilisateur, sans passer par /auth/login
    (la connexion elle-même est testée dans test_auth_*.py)."""

    def make(user) -> dict[str, str]:
        token, _ = create_access_token(
            user.id,
            user.role.value,
            secret=test_settings.jwt_secret.get_secret_value(),
            minutes=test_settings.access_token_minutes,
        )
        return {"Authorization": f"Bearer {token}"}

    return make


@pytest.fixture
def client(app: FastAPI) -> Iterator[TestClient]:
    # raise_server_exceptions=False : on veut voir la réponse 500 telle que le client la reçoit.
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client
