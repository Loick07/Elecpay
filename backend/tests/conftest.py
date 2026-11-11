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
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import Engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app.core.config import BACKEND_DIR, Settings, get_settings
from app.db.session import build_engine, get_db
from app.main import create_app


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
    """Configuration Alembic pointée sur une base donnée (au lieu du DATABASE_URL du .env)."""
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", database_url)
    config.attributes["configure_logger"] = False  # ne pas écraser la capture des logs de pytest
    return config


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
        update={"app_env": "test", "demo_mode": True, "cors_origins": [TEST_CORS_ORIGIN]}
    )


@pytest.fixture
def app(test_settings: Settings, db_session: Session) -> FastAPI:
    """Application neuve pour chaque test, branchée sur la base de test."""
    application = create_app(test_settings)
    application.dependency_overrides[get_db] = lambda: db_session
    return application


@pytest.fixture
def client(app: FastAPI) -> Iterator[TestClient]:
    # raise_server_exceptions=False : on veut voir la réponse 500 telle que le client la reçoit.
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client
