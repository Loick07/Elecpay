"""Schémas des écrans Utilisateurs du back-office (A2 liste, A3 détail)."""

from datetime import datetime
from enum import StrEnum
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.validation import clean_text
from app.modules.households.access import HouseholdRole
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.users.models import UserRole


class UserKind(StrEnum):
    """Filtres de l'écran A2."""

    CLIENT = "client"  # comptes clients
    DELEGATED_PAYER = "delegated_payer"  # payeur actif dans au moins un foyer
    TEAM = "team"  # support, admin, super admin


class AccountStatus(StrEnum):
    ACTIVE = "active"
    DISABLED = "disabled"


class UnpaidSummary(BaseModel):
    """Factures à payer des foyers dont la personne est titulaire."""

    count: int
    amount: int = Field(description="FCFA")
    overdue_count: int
    pending_payment_count: int
    oldest_overdue_days: int | None = Field(description="Retard le plus ancien, en jours")


class AdminUserRow(BaseModel):
    id: int
    full_name: str
    phone: str = Field(description="Masqué pour le support")
    email: str | None
    role: UserRole
    is_delegated_payer: bool
    households: int = Field(description="Foyers possédés + foyers où il est membre actif")
    unpaid: UnpaidSummary
    last_login_at: datetime | None
    is_active: bool
    created_at: datetime


class AdminUserList(BaseModel):
    items: list[AdminUserRow]
    total: int
    page: int
    size: int
    accounts: int = Field(description="Tous les comptes, filtres ignorés (« 1 284 comptes »)")
    active_accounts: int


class MeterLine(BaseModel):
    id: int
    reference: str
    label: str | None
    subscribed_power_va: int | None


class HouseholdLine(BaseModel):
    id: int
    name: str
    role: HouseholdRole
    meters: list[MeterLine]
    delegated_payers: list[str] = Field(description="Noms des payeurs délégués actifs")
    unpaid_count: int
    unpaid_amount: int


class TransactionLine(BaseModel):
    id: int
    reference: str = Field(examples=["TX-00000042"])
    bill_id: int
    bill_period_label: str
    household_name: str | None
    amount: int
    operator: MobileOperator
    operator_label: str
    status: TransactionStatus
    failure_reason: str | None
    payer_id: int
    payer_name: str
    initiated_at: datetime
    confirmed_at: datetime | None


class FinancialSummary(BaseModel):
    year: int
    paid_this_year: int = Field(description="Paiements réussis faits par la personne cette année")
    left_to_pay: int = Field(description="Factures à payer de ses foyers")
    not_completed: int = Field(description="Paiements non aboutis cette année")
    attempts: int = Field(description="Paiements terminés cette année")
    preferred_operator: MobileOperator | None


class SessionLine(BaseModel):
    id: int
    user_agent: str | None
    last_activity_at: datetime = Field(description="Dernière ouverture ou rotation du jeton")
    expires_at: datetime


class JournalLine(BaseModel):
    at: datetime
    action: str
    label: str
    actor_name: str | None = Field(description="None : le système")
    is_staff_action: bool


class Deactivation(BaseModel):
    at: datetime
    reason: str
    by: str | None


class AdminUserDetail(BaseModel):
    id: int
    full_name: str
    phone: str = Field(description="Masqué pour le support")
    email: str | None
    role: UserRole
    is_active: bool
    created_at: datetime
    last_login_at: datetime | None
    deactivation: Deactivation | None = Field(description="Dernière désactivation, si désactivé")
    households: list[HouseholdLine]
    recent_transactions: list[TransactionLine]
    summary: FinancialSummary
    open_sessions: list[SessionLine]
    journal: list[JournalLine]


Reason = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=255, min_length=5))]


class DeactivateRequest(BaseModel):
    """Motif obligatoire (maquette A3 : « Demande du titulaire », « Suspicion de fraude »,
    « Compte en double »… ou un motif libre)."""

    model_config = ConfigDict(extra="forbid")

    reason: Reason = Field(examples=["Demande du titulaire"])


class ReactivateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    reason: Reason | None = None


class AccountChange(BaseModel):
    id: int
    is_active: bool
    sessions_closed: int = 0


class ResetCodeSent(BaseModel):
    sent: bool = True
    phone: str = Field(description="Numéro masqué : le code n'est jamais montré à l'équipe")
