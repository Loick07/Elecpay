"""Tests des migrations Alembic et de la structure complète de la base (B0 + B1)."""

import pytest
from alembic import command
from alembic.script import ScriptDirectory
from sqlalchemy import Float, Numeric, inspect, text

import app.db.models  # noqa: F401 — enregistre toutes les tables
from app.db.base import Base
from app.db.types import StrictBigInteger
from tests.conftest import alembic_config

# Les 13 tables prévues par le plan (CLAUDE.md, backend/PLAN.md) et celles ajoutées depuis.
PLANNED_TABLES = {
    "users",
    "refresh_tokens",
    "households",
    "household_members",
    "meters",
    "meter_readings",
    "tariffs",
    "bills",
    "bill_lines",
    "payment_transactions",
    "receipts",
    "notifications",
    "audit_logs",
    "password_reset_codes",  # ajoutée en B3.5 (code SMS de réinitialisation, maquette client 4)
}

# Garde-fous métier écrits en triggers MySQL.
EXPECTED_TRIGGERS = {
    "trg_tariffs_no_overlap_INSERT",
    "trg_tariffs_no_overlap_UPDATE",
    "trg_bills_no_delete",
    "trg_bills_immutable",
    "trg_bill_lines_insert",
    "trg_bill_lines_no_update",
    "trg_bill_lines_no_delete",
    "trg_payment_transactions_insert",
    "trg_payment_transactions_update",
    "trg_payment_transactions_no_delete",
    "trg_receipts_insert",
    "trg_receipts_update",
    "trg_receipts_no_delete",
    "trg_audit_logs_no_update",
    "trg_audit_logs_no_delete",
}

# Index exigés par le plan : (table, colonnes dans l'ordre).
PLANNED_INDEXES = [
    ("meter_readings", ("meter_id", "read_at")),
    ("bills", ("meter_id", "period_start")),
    ("bills", ("status", "due_date")),
    ("payment_transactions", ("status", "initiated_at")),
    ("notifications", ("user_id", "read_at")),
]


def config_for(engine):
    return alembic_config(engine.url.render_as_string(hide_password=False))


def application_tables(engine) -> set[str]:
    return set(inspect(engine).get_table_names()) - {"alembic_version"}


def triggers(engine) -> set[str]:
    with engine.connect() as connection:
        return set(
            connection.execute(
                text(
                    "SELECT TRIGGER_NAME FROM information_schema.TRIGGERS"
                    " WHERE TRIGGER_SCHEMA = DATABASE()"
                )
            ).scalars()
        )


# --- Migrations ---------------------------------------------------------------------


def test_migrations_have_a_single_head(test_engine):
    script = ScriptDirectory.from_config(config_for(test_engine))
    assert len(script.get_heads()) == 1, "Plusieurs têtes : fusionner les migrations"


def test_upgrade_and_downgrade_round_trip(test_engine):
    """Critère B1 : base vide → tout → vide, sans rien oublier (tables ET triggers)."""
    config = config_for(test_engine)

    command.downgrade(config, "base")
    assert application_tables(test_engine) == set()
    assert triggers(test_engine) == set()

    command.upgrade(config, "head")
    assert application_tables(test_engine) == PLANNED_TABLES
    assert triggers(test_engine) == EXPECTED_TRIGGERS


def test_models_and_migrations_are_in_sync(test_engine):
    """Échoue si un modèle a changé sans migration correspondante."""
    config = config_for(test_engine)
    command.upgrade(config, "head")
    command.check(config)  # lève une erreur si --autogenerate détecterait des différences


# --- Structure ----------------------------------------------------------------------


def test_models_define_exactly_the_planned_tables():
    assert set(Base.metadata.tables) == PLANNED_TABLES


@pytest.mark.parametrize(("table", "columns"), PLANNED_INDEXES)
def test_planned_index_exists(test_engine, table, columns):
    inspector = inspect(test_engine)
    indexed = {tuple(index["column_names"]) for index in inspector.get_indexes(table)}
    indexed |= {tuple(uq["column_names"]) for uq in inspector.get_unique_constraints(table)}
    assert columns in indexed, f"Index {table}{columns} manquant"


def test_no_float_or_decimal_column_anywhere():
    """Règle ElecPay : jamais de float (ni de décimal) pour stocker une valeur."""
    offenders = [
        f"{table.name}.{column.name}"
        for table in Base.metadata.tables.values()
        for column in table.columns
        if isinstance(column.type, Float | Numeric)
    ]
    assert offenders == []


# Toutes les colonnes d'argent (FCFA, millièmes de FCFA) et d'énergie (Wh) de la base.
MONEY_AND_ENERGY_COLUMNS = {
    "bills.previous_index_wh",
    "bills.current_index_wh",
    "bills.consumption_wh",
    "bills.amount_ht",
    "bills.amount_tax",
    "bills.amount_fees",
    "bills.amount_total",
    "bill_lines.quantity_milli",
    "bill_lines.unit_price_milli",
    "bill_lines.base_amount",
    "bill_lines.amount",
    "meter_readings.index_wh",
    "meter_readings.consumption_wh",
    "payment_transactions.amount",
    "tariffs.price_per_kwh_milli",
    "tariffs.fixed_fee_per_month",
    "tariffs.audiovisual_fee",
    "tariffs.stamp_fee",
}


def test_money_and_energy_columns_are_strict_integers():
    """Montants, prix et énergie : toujours des entiers stricts (refusent les float).

    Vérifié dans les deux sens : une nouvelle colonne d'argent doit être ajoutée à la liste,
    et rien d'autre n'utilise ce type par erreur.
    """
    strict_columns = {
        f"{table.name}.{column.name}"
        for table in Base.metadata.tables.values()
        for column in table.columns
        if isinstance(column.type, StrictBigInteger)
    }
    assert strict_columns == MONEY_AND_ENERGY_COLUMNS

    hints = ("amount", "fee", "price", "_wh", "_milli")
    named_like_money = {
        f"{table.name}.{column.name}"
        for table in Base.metadata.tables.values()
        for column in table.columns
        if any(hint in column.name for hint in hints)
    }
    assert named_like_money <= MONEY_AND_ENERGY_COLUMNS
