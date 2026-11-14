"""Schémas de l'écran Notifications du back-office (A9) : annonces et alertes automatiques."""

from datetime import datetime
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator

from app.core.validation import clean_text
from app.modules.announcements.models import AnnouncementStatus, Audience

Title = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=120, min_length=3))]
Body = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=500, min_length=10))]
District = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=80, min_length=2))]


class AnnouncementCreate(BaseModel):
    """Envoi immédiat sans `scheduled_at`, sinon programmation (UTC, dans le futur)."""

    model_config = ConfigDict(extra="forbid")

    title: Title = Field(examples=["Coupure programmée à Mpita"])
    body: Body = Field(
        examples=["E²C annonce une coupure jeudi de 8 h à 12 h pour travaux sur le réseau."]
    )
    audience: Audience
    district: District | None = Field(default=None, description="Obligatoire pour « district »")
    user_id: int | None = Field(default=None, gt=0, description="Obligatoire pour « client »")
    scheduled_at: datetime | None = Field(default=None, description="NULL : envoi immédiat")

    @model_validator(mode="after")
    def target_matches_audience(self) -> AnnouncementCreate:
        if (self.audience is Audience.DISTRICT) != (self.district is not None):
            raise ValueError("Le quartier est obligatoire pour « district », et seulement là")
        if (self.audience is Audience.CLIENT) != (self.user_id is not None):
            raise ValueError("Le client est obligatoire pour « client », et seulement là")
        if self.scheduled_at is not None and self.scheduled_at.tzinfo is None:
            raise ValueError("scheduled_at doit préciser son fuseau (UTC)")
        return self


class AnnouncementRow(BaseModel):
    id: int
    title: str
    body: str
    audience: Audience
    audience_label: str = Field(examples=["Tous les clients", "Quartier Mpita"])
    district: str | None
    user_id: int | None
    status: AnnouncementStatus
    scheduled_at: datetime | None
    sent_at: datetime | None
    cancelled_at: datetime | None
    recipients: int | None
    read: int | None = Field(description="Notifications lues (annonces envoyées)")
    read_rate_percent: float | None = Field(description="None : pas encore envoyée, ou 0 envoi")
    created_by: str
    created_at: datetime


class AnnouncementList(BaseModel):
    items: list[AnnouncementRow]
    total: int
    page: int
    size: int


class AudiencePreview(BaseModel):
    audience: Audience
    label: str
    recipients: int = Field(description="Nombre de destinataires si l'annonce partait maintenant")


class DistrictLine(BaseModel):
    district: str
    households: int


class AlertSettingsPublic(BaseModel):
    due_soon: bool = Field(description="Rappels d'échéance (5 jours avant, puis le jour même)")
    overdue: bool = Field(description="Avis de retard puis rappel tous les 7 jours")
    high_consumption: bool = Field(description="Consommation inhabituelle")
    updated_at: datetime | None
    updated_by: str | None


class AlertSettingsUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    due_soon: bool
    overdue: bool
    high_consumption: bool
