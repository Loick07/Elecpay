"""paiements : operateur et pin saisi

Revision ID: 3a7c91e04b52
Revises: fdc32ed50aad
Create Date: 2026-11-13 09:00:00

B7.1 :
- `operator` (mtn / airtel), distinct de `provider` (qui vaut « simulated » en démo) ;
- `pin_entered_at` : code PIN saisi, la transaction n'expire plus d'elle-même (maquette A8) ;
- le trigger de mise à jour fige aussi l'opérateur, et « PIN saisi » une fois renseigné.
Les transactions existantes reçoivent l'opérateur déduit de leur numéro (06 → MTN, 04/05 → Airtel).
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

# Migration autonome : n'importe jamais le code de l'application (app.*).

# Identifiants de révision, utilisés par Alembic.
revision: str = "3a7c91e04b52"
down_revision: str | Sequence[str] | None = "fdc32ed50aad"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLE = "payment_transactions"

# Colonnes fixées à la création (version B1, puis version B7.1 avec l'opérateur).
OLD_CONTENT_COLUMNS = (
    "bill_id",
    "payer_id",
    "provider",
    "phone_number",
    "amount",
    "idempotency_key",
    "initiated_at",
    "expires_at",
)
NEW_CONTENT_COLUMNS = (*OLD_CONTENT_COLUMNS, "operator")


def update_trigger(content_columns: Sequence[str], *, freeze_pin: bool) -> str:
    changed = " OR ".join(f"NOT (NEW.{c} <=> OLD.{c})" for c in content_columns)
    if freeze_pin:  # une fois renseigné, « PIN saisi » ne change plus
        changed += " OR (OLD.pin_entered_at IS NOT NULL AND NOT (NEW.pin_entered_at <=> OLD.pin_entered_at))"
    return f"""
    CREATE TRIGGER trg_payment_transactions_update BEFORE UPDATE ON payment_transactions
    FOR EACH ROW
    BEGIN
        IF OLD.status <> 'en_attente' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_closed_immutable';
        ELSEIF {changed} THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_content_immutable';
        END IF;
    END
    """


def upgrade() -> None:
    # Le trigger interdit de toucher une transaction terminée : on le retire le temps
    # de renseigner l'opérateur des transactions existantes.
    op.execute("DROP TRIGGER IF EXISTS trg_payment_transactions_update")

    op.add_column(TABLE, sa.Column("operator", sa.String(length=6), nullable=True))
    op.add_column(TABLE, sa.Column("pin_entered_at", mysql.DATETIME(fsp=6), nullable=True))
    op.execute(
        f"UPDATE {TABLE} SET operator = CASE "
        "WHEN phone_number LIKE '+24204%' OR phone_number LIKE '+24205%' THEN 'airtel' "
        "ELSE 'mtn' END"
    )
    op.alter_column(TABLE, "operator", existing_type=sa.String(length=6), nullable=False)
    op.create_check_constraint(
        op.f("ck_payment_transactions_operator"), TABLE, "operator IN ('mtn', 'airtel')"
    )
    op.create_check_constraint(
        op.f("ck_payment_transactions_pin_after_initiation"),
        TABLE,
        "pin_entered_at >= initiated_at",
    )

    op.execute(update_trigger(NEW_CONTENT_COLUMNS, freeze_pin=True))


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_payment_transactions_update")
    op.drop_constraint(op.f("ck_payment_transactions_pin_after_initiation"), TABLE, type_="check")
    op.drop_constraint(op.f("ck_payment_transactions_operator"), TABLE, type_="check")
    op.drop_column(TABLE, "pin_entered_at")
    op.drop_column(TABLE, "operator")
    op.execute(update_trigger(OLD_CONTENT_COLUMNS, freeze_pin=False))
