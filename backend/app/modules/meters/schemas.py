"""Schémas d'API des compteurs (feuille « Ajouter un compteur » de la maquette client 15)."""

from datetime import date, datetime
from functools import partial
from typing import Annotated, Self

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator

from app.core.validation import clean_text
from app.integrations.billing_sources.base import normalize_customer_number, normalize_reference
from app.modules.households.access import HouseholdRole
from app.modules.meters.models import MeterStatus, MeterType

MeterLabel = Annotated[str, AfterValidator(partial(clean_text, max_length=60))]


class MeterAddRequest(BaseModel):
    """Les deux numéros figurent sur la facture E²C : les demander prouve qu'on l'a en main."""

    model_config = ConfigDict(extra="forbid")

    reference: Annotated[str, AfterValidator(normalize_reference)] = Field(
        description="N° Branchement (sur la facture)", examples=["0018 09 5408"]
    )
    customer_number: Annotated[str, AfterValidator(normalize_customer_number)] = Field(
        description="N° Client (sur la facture)", examples=["0758340H"]
    )
    label: MeterLabel | None = Field(default=None, examples=["Maison"])


class MeterUpdate(BaseModel):
    """Seul le nom choisi par l'abonné se modifie ; `null` l'efface."""

    model_config = ConfigDict(extra="forbid")

    label: MeterLabel | None = None

    @model_validator(mode="after")
    def something_to_change(self) -> Self:
        if "label" not in self.model_fields_set:
            raise ValueError("Indiquez le nouveau nom (label)")
        return self


class MeterDetail(BaseModel):
    id: int
    household_id: int
    reference: str  # N° Branchement
    label: str | None
    type: MeterType
    status: MeterStatus
    contract_number: str | None  # N° Police
    customer_number: str | None  # N° Client
    e2c_center: str | None
    subscribed_power_va: int | None
    installed_at: date | None
    my_role: HouseholdRole
    can_manage: bool
    created_at: datetime


class HistoryImportPublic(BaseModel):
    readings: int
    bills: int
    source: str = Field(description="« simulated » en mode démo : données simulées")


class MeterAddResponse(BaseModel):
    meter: MeterDetail
    history: HistoryImportPublic
