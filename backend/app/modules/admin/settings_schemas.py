"""Schémas de l'écran Paramètres et rôles du back-office (A11) : équipe, tarifs, intégrations.

La matrice des permissions est servie par `GET /admin/permissions` (B10.1).
"""

from datetime import date, datetime
from enum import StrEnum
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.validation import CongoPhone, Email, FullName, clean_text
from app.modules.users.models import UserRole

Note = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=255, min_length=5))]
Code = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=32, min_length=2))]
Label = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=120, min_length=3))]


class TeamRole(StrEnum):
    """Les rôles d'un membre de l'équipe (un compte client n'est jamais promu)."""

    SUPPORT = "support"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"


# --- Équipe ---------------------------------------------------------------------------------


class TeamMember(BaseModel):
    id: int
    full_name: str
    phone: str
    email: str | None
    role: UserRole
    is_active: bool
    invited_at: datetime = Field(description="Création du compte")
    last_login_at: datetime | None
    invitation_pending: bool = Field(description="Jamais connecté : mot de passe pas encore choisi")
    two_factor: str = Field(
        description="Double authentification : « not_available » jusqu'à B11",
        examples=["not_available"],
    )


class TeamInvite(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: FullName = Field(examples=["Patrick Moukala"])
    phone: CongoPhone = Field(examples=["06 555 12 34"])
    email: Email | None = None
    role: TeamRole


class TeamInvited(BaseModel):
    member: TeamMember
    sms_sent_to: str = Field(description="Numéro masqué ; le code n'est jamais montré à l'équipe")


class RoleChange(BaseModel):
    model_config = ConfigDict(extra="forbid")

    role: TeamRole
    reason: Note = Field(examples=["Passe responsable des remboursements"])


# --- Tarifs ---------------------------------------------------------------------------------


class TariffRow(BaseModel):
    id: int
    code: str
    label: str
    price_per_kwh_milli: int = Field(description="Millièmes de FCFA : 49,08 → 49 080")
    fixed_fee_per_month: int
    vat_rate_bp: int = Field(description="Points de base : 18 % → 1 800")
    additional_tax_rate_bp: int
    audiovisual_fee: int
    stamp_fee: int
    valid_from: date
    valid_to: date | None = Field(description="Exclu ; NULL : sans fin")
    is_assumption: bool
    source_note: str | None
    in_force: bool = Field(description="En vigueur aujourd'hui (heure de Brazzaville)")
    bills: int = Field(description="Factures émises avec ce tarif")


class TariffCreate(BaseModel):
    """Nouvelle version DATÉE d'un tarif existant : la version en cours s'arrête au
    `valid_from` de la nouvelle (exclu), sans trou ni chevauchement."""

    model_config = ConfigDict(extra="forbid")

    code: Code = Field(examples=["BT_DOMESTIQUE"])
    label: Label = Field(examples=["Basse tension domestique"])
    price_per_kwh_milli: int = Field(gt=0, le=10_000_000)
    fixed_fee_per_month: int = Field(ge=0, le=10_000_000)
    vat_rate_bp: int = Field(ge=0, le=10_000)
    additional_tax_rate_bp: int = Field(ge=0, le=10_000)
    audiovisual_fee: int = Field(ge=0, le=10_000_000)
    stamp_fee: int = Field(ge=0, le=10_000_000)
    valid_from: date = Field(description="Au plus tôt demain")
    is_assumption: bool = Field(description="Vrai tant que non vérifié sur de vraies factures")
    source_note: Note = Field(examples=["Arrêté tarifaire E²C du 01/01/2027"])


# --- Intégrations ---------------------------------------------------------------------------


class IntegrationMode(StrEnum):
    SIMULATED = "simulated"  # simulateur ElecPay (démo) : rien de réel
    LIVE = "live"  # branché sur le vrai service
    PHASE_2 = "phase_2"  # pas encore construit


class Integration(BaseModel):
    key: str = Field(examples=["mtn_momo"])
    label: str
    mode: IntegrationMode
    detail: str


class IntegrationsStatus(BaseModel):
    environment: str = Field(examples=["development"])
    demo_mode: bool
    integrations: list[Integration]
    webhook_secret_configured: bool
    receipt_verify_url_is_https: bool
