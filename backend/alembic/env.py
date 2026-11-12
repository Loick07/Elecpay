"""Environnement d'exécution des migrations Alembic.

L'URL de la base vient de la configuration de l'application (`DATABASE_URL` du .env),
sauf si l'appelant en fournit une (`sqlalchemy.url`), ce que font les tests pour viser
la base `elecpay_test`.
"""

from logging.config import fileConfig

from alembic import context
from alembic.operations import ops
from sqlalchemy import create_engine, pool

import app.db.models  # noqa: F401 — enregistre toutes les tables dans Base.metadata
from app.core.config import get_settings
from app.db.base import Base, UTCDateTime
from app.db.types import StrictBigInteger

config = context.config

if config.config_file_name is not None and config.attributes.get("configure_logger", True):
    fileConfig(config.config_file_name, disable_existing_loggers=False)

target_metadata = Base.metadata


def drop_redundant_index_drops(context, revision, directives) -> None:
    """Retire les `drop_index` d'une table qui est de toute façon supprimée.

    Alembic génère « drop_index puis drop_table » dans downgrade(). Sous MySQL, retirer
    un index utilisé par une clé étrangère échoue : le downgrade casserait. Supprimer la
    table suffit (ses index partent avec elle).
    """
    for script in directives:
        for downgrade_ops in script.downgrade_ops_list:
            dropped = {op.table_name for op in downgrade_ops.ops if isinstance(op, ops.DropTableOp)}
            kept = []
            for op in downgrade_ops.ops:
                # Alembic range les drop_index d'une table dans un groupe ModifyTableOps.
                if isinstance(op, ops.ModifyTableOps) and op.table_name in dropped:
                    op.ops = [sub for sub in op.ops if not isinstance(sub, ops.DropIndexOp)]
                    if not op.ops:
                        continue
                elif isinstance(op, ops.DropIndexOp) and op.table_name in dropped:
                    continue
                kept.append(op)
            downgrade_ops.ops = kept


def render_portable_types(type_, obj, autogen_context):
    """Écrit nos types maison sous leur forme MySQL réelle dans les migrations.

    Une migration doit rester valable même si le code de l'application change :
    elle ne doit donc pas dépendre de `app.db.base.UTCDateTime` ou `app.db.types.StrictBigInteger`.
    """
    if type_ != "type":
        return False
    if isinstance(obj, UTCDateTime):
        autogen_context.imports.add("from sqlalchemy.dialects import mysql")
        return "mysql.DATETIME(fsp=6)"
    if isinstance(obj, StrictBigInteger):
        return "sa.BigInteger()"
    return False


def database_url() -> str:
    return config.get_main_option("sqlalchemy.url") or get_settings().database_url


def run_migrations_offline() -> None:
    """Génère le SQL sans se connecter (alembic upgrade head --sql)."""
    context.configure(
        url=database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Applique les migrations sur la base."""
    engine = create_engine(database_url(), poolclass=pool.NullPool)
    with engine.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,  # détecte aussi les changements de type de colonne
            process_revision_directives=drop_redundant_index_drops,
            render_item=render_portable_types,
        )
        with context.begin_transaction():
            context.run_migrations()
    engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
