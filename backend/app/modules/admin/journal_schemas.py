"""Schémas du journal d'activité du back-office (A10). Lecture seule : rien ne s'y modifie."""

from datetime import datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, Field

from app.modules.users.models import UserRole


class ActorKind(StrEnum):
    TEAM = "team"  # support, admin, super admin
    CLIENT = "client"  # un abonné (connexion, paiement, foyer…)
    SYSTEM = "system"  # la plateforme ou l'opérateur (tâche planifiée, webhook…)


class JournalActor(BaseModel):
    id: int
    full_name: str
    role: UserRole


class JournalEntry(BaseModel):
    id: int
    at: datetime
    action: str = Field(examples=["bill.cancel"])
    label: str = Field(examples=["a annulé une facture"])
    domain: str = Field(examples=["bill"])
    domain_label: str = Field(examples=["Factures"])
    actor: JournalActor | None = Field(description="NULL : le système ou l'opérateur")
    entity_type: str
    entity_id: int | None
    before: dict[str, Any] | None = Field(description="État avant (détail dépliable)")
    after: dict[str, Any] | None = Field(description="État après")
    ip: str | None
    user_agent: str | None


class JournalPage(BaseModel):
    items: list[JournalEntry]
    total: int
    page: int
    size: int


class DomainCount(BaseModel):
    domain: str
    label: str
    count: int
