"""Schémas d'API des notifications (écran client 13)."""

from datetime import datetime
from enum import StrEnum
from typing import Any, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core.pagination import Page
from app.modules.notifications.models import NotificationType


class NotificationGroup(StrEnum):
    """Groupes de l'écran 13, en heure de Brazzaville."""

    TODAY = "today"  # « Aujourd'hui » : depuis minuit
    THIS_WEEK = "this_week"  # « Cette semaine » : depuis lundi (hors aujourd'hui)
    EARLIER = "earlier"  # « Plus tôt »


class NotificationPublic(BaseModel):
    id: int
    type: NotificationType
    title: str = Field(examples=["Paiement réussi"])
    body: str
    data: dict[str, Any] | None = Field(
        description="De quoi ouvrir le bon écran : bill_id, transaction_id, receipt_id, "
        "meter_id, household_id…",
        examples=[{"bill_id": 42, "transaction_id": 7, "receipt_id": 3}],
    )
    created_at: datetime
    read_at: datetime | None
    is_read: bool
    group: NotificationGroup


class NotificationList(Page[NotificationPublic]):
    unread_count: int = Field(description="Non lues, tous filtres confondus (badge)")


class UnreadCount(BaseModel):
    unread_count: int


class NotificationPreferences(BaseModel):
    """Interrupteurs « Me prévenir » de l'écran 14. Les autres messages (nouvelle facture,
    retard, invitation, relevé anormal, annonces) sont toujours envoyés."""

    due_soon: bool = Field(description="Échéances : 5 jours avant, puis le jour même")
    payments: bool = Field(description="Paiements : réussis, échoués, reçus disponibles")
    high_consumption: bool = Field(
        description="Consommation inhabituelle : un jour au-dessus de la moyenne de 30 %"
    )


class PreferencesUpdate(BaseModel):
    """Seuls les interrupteurs envoyés changent."""

    model_config = ConfigDict(extra="forbid")

    due_soon: bool | None = None
    payments: bool | None = None
    high_consumption: bool | None = None

    @model_validator(mode="after")
    def something_to_change(self) -> Self:
        if not self.model_fields_set:
            raise ValueError("Indiquez au moins un interrupteur à changer")
        if any(getattr(self, name) is None for name in self.model_fields_set):
            raise ValueError("Un interrupteur vaut true ou false")
        return self


class ReadAllResult(BaseModel):
    marked: int = Field(description="Notifications passées à « lue » par cet appel")
    unread_count: int = 0
