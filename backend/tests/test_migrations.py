"""Tests des migrations Alembic sur la base de test."""

from alembic import command
from alembic.script import ScriptDirectory
from sqlalchemy import inspect

from app.db.base import Base
from tests.conftest import alembic_config


def application_tables(engine) -> set[str]:
    return set(inspect(engine).get_table_names()) - {"alembic_version"}


def test_migrations_have_a_single_head(test_engine):
    script = ScriptDirectory.from_config(alembic_config(str(test_engine.url)))
    assert len(script.get_heads()) <= 1, "Plusieurs têtes : fusionner les migrations"


def test_upgrade_and_downgrade_round_trip(test_engine):
    config = alembic_config(test_engine.url.render_as_string(hide_password=False))

    command.downgrade(config, "base")
    assert application_tables(test_engine) == set()

    command.upgrade(config, "head")
    assert application_tables(test_engine) == set(Base.metadata.tables)


def test_models_and_migrations_are_in_sync(test_engine):
    """Échoue si un modèle a changé sans migration correspondante."""
    config = alembic_config(test_engine.url.render_as_string(hide_password=False))
    command.upgrade(config, "head")
    command.check(config)  # lève une erreur si --autogenerate détecterait des différences
