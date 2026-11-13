"""Table `notifications` : messages affichés dans l'application (push FCM en phase 2)."""

from datetime import datetime
from enum import StrEnum
from typing import Any

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Index,
    String,
    UniqueConstraint,
    false,
    true,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import enum_type, foreign_key


class NotificationType(StrEnum):
    BILL_ISSUED = "bill_issued"  # nouvelle facture
    BILL_DUE_SOON = "bill_due_soon"  # échéance proche
    BILL_OVERDUE = "bill_overdue"  # facture en retard
    PAYMENT_SUCCEEDED = "payment_succeeded"
    PAYMENT_FAILED = "payment_failed"
    INVITATION_RECEIVED = "invitation_received"  # invitation dans un foyer
    CONSUMPTION_ANOMALY = "consumption_anomaly"  # relevé anormal (index en baisse…)
    HIGH_CONSUMPTION = "high_consumption"  # jour au-dessus de la moyenne (B9, désactivable)
    ANNOUNCEMENT = "announcement"  # annonce envoyée par un administrateur


class Notification(IdMixin, TimestampMixin, Base):
    __tablename__ = "notifications"
    __table_args__ = (
        # Liste et badge « non lues » d'un utilisateur.
        Index("ix_notifications_user_id_read_at", "user_id", "read_at"),
        CheckConstraint("CHAR_LENGTH(TRIM(title)) > 0", name="title_not_blank"),
        CheckConstraint("CHAR_LENGTH(TRIM(body)) > 0", name="body_not_blank"),
        # Données complémentaires : un objet JSON (ex. {"bill_id": 42}) pour ouvrir le bon écran.
        CheckConstraint(
            "data_json IS NULL OR JSON_TYPE(data_json) = 'OBJECT'", name="data_is_object"
        ),
    )

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"))
    type: Mapped[NotificationType] = mapped_column(enum_type(NotificationType, "type"))
    title: Mapped[str] = mapped_column(String(120))
    body: Mapped[str] = mapped_column(String(500))
    # none_as_null : Python None → SQL NULL (sinon SQLAlchemy écrirait le texte JSON « null »).
    data_json: Mapped[dict[str, Any] | None] = mapped_column(JSON(none_as_null=True))
    read_at: Mapped[datetime | None] = mapped_column(UTCDateTime())  # NULL = non lue


class NotificationPreference(IdMixin, TimestampMixin, Base):
    """Interrupteurs « Me prévenir » de l'écran 14 (B9.2). Pas de ligne = valeurs par défaut.

    Seules ces trois familles d'alertes se coupent ; les autres messages (nouvelle facture,
    retard, invitation, relevé anormal, annonces de l'équipe) sont toujours envoyés.
    """

    __tablename__ = "notification_preferences"
    __table_args__ = (UniqueConstraint("user_id"),)

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"))
    due_soon: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    payments: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    high_consumption: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
