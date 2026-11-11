"""Connexion à la base : moteur SQLAlchemy, fabrique de sessions et dépendance `get_db`."""

from collections.abc import Iterator
from functools import lru_cache

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings


def build_engine(database_url: str) -> Engine:
    """Crée un moteur avec un pool de connexions adapté à MySQL.

    La création ne se connecte pas encore : la première connexion a lieu au premier usage.
    """
    return create_engine(
        database_url,
        pool_pre_ping=True,  # vérifie qu'une connexion du pool est encore vivante avant usage
        pool_recycle=3600,  # renouvelle les connexions avant que MySQL ne les coupe (wait_timeout)
        pool_size=5,
        max_overflow=10,
    )


def build_sessionmaker(engine: Engine) -> sessionmaker[Session]:
    # expire_on_commit=False : les objets restent lisibles après commit (utile pour les réponses).
    return sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


@lru_cache
def get_engine() -> Engine:
    return build_engine(get_settings().database_url)


@lru_cache
def get_sessionmaker() -> sessionmaker[Session]:
    return build_sessionmaker(get_engine())


def get_db() -> Iterator[Session]:
    """Dépendance FastAPI : une session par requête, toujours fermée à la fin.

    En cas d'erreur, tout ce qui n'a pas été validé est annulé (rollback).
    Les services décident eux-mêmes quand valider (commit).
    """
    session = get_sessionmaker()()
    try:
        yield session
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def database_is_reachable(session: Session) -> bool:
    """Vrai si la base répond à une requête triviale (utilisé par /health)."""
    try:
        session.execute(text("SELECT 1"))
    except SQLAlchemyError:
        session.rollback()
        return False
    return True
