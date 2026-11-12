"""Schémas d'API des foyers (carte « foyer » de la maquette client 15)."""

from datetime import datetime
from functools import partial
from typing import Annotated, Self

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator

from app.core.validation import CongoPhone, clean_text
from app.modules.households.access import HouseholdRole
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.meters.models import MeterStatus, MeterType

# Textes nettoyés (espaces superflus retirés), longueurs = celles des colonnes.
HouseholdName = Annotated[str, AfterValidator(partial(clean_text, max_length=80))]
City = Annotated[str, AfterValidator(partial(clean_text, max_length=80))]
District = Annotated[str, AfterValidator(partial(clean_text, max_length=80))]
Address = Annotated[str, AfterValidator(partial(clean_text, max_length=255))]


class HouseholdCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: HouseholdName = Field(examples=["Maison de maman"])
    city: City = Field(examples=["Pointe-Noire"])
    district: District | None = Field(default=None, examples=["Mpita"])
    address: Address | None = Field(default=None, examples=["Rue Mboukou, n° 12"])


class HouseholdUpdate(BaseModel):
    """Champs modifiables. Absent = inchangé ; `null` efface le quartier ou l'adresse."""

    model_config = ConfigDict(extra="forbid")

    name: HouseholdName | None = None
    city: City | None = None
    district: District | None = None
    address: Address | None = None

    @model_validator(mode="after")
    def something_to_change(self) -> Self:
        if not self.model_fields_set:
            raise ValueError("Indiquez au moins un champ à modifier")
        for required in ("name", "city"):
            if required in self.model_fields_set and getattr(self, required) is None:
                raise ValueError(f"« {required} » ne peut pas être vide")
        return self


class PersonPublic(BaseModel):
    """Une personne vue par les autres membres : nom et numéro MASQUÉ."""

    id: int
    full_name: str
    phone_masked: str


class MeterSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reference: str
    label: str | None
    type: MeterType
    status: MeterStatus
    subscribed_power_va: int | None
    e2c_center: str | None


class MemberPublic(BaseModel):
    id: int  # identifiant de l'adhésion (pour la retirer)
    person: PersonPublic
    role: MemberRole
    status: MemberStatus
    created_at: datetime


class InviteRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: CongoPhone = Field(examples=["06 000 01 04"])
    role: MemberRole = Field(examples=["payer"], description="payer (payeur délégué) ou viewer")


class HouseholdBrief(BaseModel):
    id: int
    name: str
    city: str


class InvitationPublic(BaseModel):
    """Une invitation reçue (écran « Compteurs et foyers » de la personne invitée)."""

    id: int
    household: HouseholdBrief
    role: MemberRole
    invited_by: PersonPublic
    created_at: datetime


class HouseholdSummary(BaseModel):
    """Une ligne de « Mes foyers »."""

    id: int
    name: str
    city: str
    district: str | None
    my_role: HouseholdRole
    owner_name: str
    meters_count: int
    members_count: int  # membres actifs, propriétaire non compris


class HouseholdDetail(BaseModel):
    id: int
    name: str
    city: str
    district: str | None
    address: str | None
    my_role: HouseholdRole
    can_pay: bool
    can_manage: bool
    owner: PersonPublic
    meters: list[MeterSummary]
    # Membres actifs pour tous ; invitations en attente en plus pour le propriétaire.
    members: list[MemberPublic]
    created_at: datetime
