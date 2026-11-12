"""Accès programmatique aux migrations Alembic (utilisé par scripts.reset_db et les tests)."""

from alembic import command
from alembic.config import Config

from app.core.config import BACKEND_DIR


def alembic_config(database_url: str, *, configure_logger: bool = True) -> Config:
    """Configuration Alembic pointée sur une base donnée (au lieu du DATABASE_URL du .env)."""
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", database_url)
    config.attributes["configure_logger"] = configure_logger
    return config


def rebuild_database(database_url: str) -> None:
    """Supprime toutes les tables (et triggers) puis les recrée par les migrations.

    On passe par `downgrade base` plutôt que par des DELETE : les triggers interdisent
    de supprimer factures, paiements, reçus et journaux d'audit, même pour une remise à zéro.
    """
    config = alembic_config(database_url, configure_logger=False)
    command.downgrade(config, "base")
    command.upgrade(config, "head")
