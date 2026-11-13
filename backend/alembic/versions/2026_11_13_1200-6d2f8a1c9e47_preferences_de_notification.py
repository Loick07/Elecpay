"""preferences de notification

Revision ID: 6d2f8a1c9e47
Revises: 3a7c91e04b52
Create Date: 2026-11-13 12:00:00

B9.2 :
- table `notification_preferences` : interrupteurs « Me prévenir » de l'écran 14 (échéances,
  paiements, consommation inhabituelle) ; pas de ligne = valeurs par défaut ;
- nouveau type de notification `high_consumption` (consommation inhabituelle, B9.3).
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import mysql

# Migration autonome : n'importe jamais le code de l'application (app.*).

# Identifiants de révision, utilisés par Alembic.
revision: str = "6d2f8a1c9e47"
down_revision: str | Sequence[str] | None = "3a7c91e04b52"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

OLD_TYPES = (
    "bill_issued",
    "bill_due_soon",
    "bill_overdue",
    "payment_succeeded",
    "payment_failed",
    "invitation_received",
    "consumption_anomaly",
    "announcement",
)
NEW_TYPES = (*OLD_TYPES[:7], "high_consumption", OLD_TYPES[7])
TYPE_CHECK = "ck_notifications_type"


def type_condition(types: Sequence[str]) -> str:
    return "type IN (" + ", ".join(f"'{value}'" for value in types) + ")"


def upgrade() -> None:
    op.create_table(
        "notification_preferences",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("due_soon", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("payments", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("high_consumption", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("created_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.Column("updated_at", mysql.DATETIME(fsp=6), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name=op.f("fk_notification_preferences_user_id_users"),
            onupdate="RESTRICT",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_notification_preferences")),
        sa.UniqueConstraint("user_id", name=op.f("uq_notification_preferences_user_id")),
    )
    op.drop_constraint(op.f(TYPE_CHECK), "notifications", type_="check")
    op.create_check_constraint(op.f(TYPE_CHECK), "notifications", type_condition(NEW_TYPES))


def downgrade() -> None:
    # Les notifications du nouveau type n'auraient plus de type valide : on les retire d'abord.
    op.execute("DELETE FROM notifications WHERE type = 'high_consumption'")
    op.drop_constraint(op.f(TYPE_CHECK), "notifications", type_="check")
    op.create_check_constraint(op.f(TYPE_CHECK), "notifications", type_condition(OLD_TYPES))
    op.drop_table("notification_preferences")
