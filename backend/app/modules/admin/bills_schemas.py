"""Schémas des écrans Factures du back-office (A5 liste, A6 détail).

Montants en FCFA entiers, énergies en Wh entiers. Les montants d'une facture ne sont JAMAIS
modifiables : l'équipe peut seulement annuler (motif) puis réémettre la période.
"""

from datetime import date, datetime
from enum import StrEnum
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.validation import clean_text
from app.modules.bills.models import BillSource, BillStatus
from app.modules.bills.schemas import BillLinePublic, TariffPublic
from app.modules.consumption.models import ReadingSource
from app.modules.payments.models import MobileOperator, TransactionStatus


class AdminBillFilter(StrEnum):
    """Filtres de l'écran A5 (le retard est calculé à la lecture, comme côté abonné)."""

    UNPAID = "unpaid"  # à payer, échéance pas encore dépassée
    OVERDUE = "overdue"
    PENDING_PAYMENT = "pending_payment"
    PAID = "paid"
    CANCELLED = "cancelled"


class MonthTotals(BaseModel):
    """Factures ÉMISES dans le mois choisi (heure de Brazzaville), annulées à part."""

    month: str = Field(examples=["2026-11"])
    issued: int = Field(description="Factures émises (hors annulées)")
    billed: int = Field(description="Montant facturé, FCFA")
    collected: int = Field(description="Montant de ces factures déjà payé, FCFA")
    remaining: int = Field(description="Facturé − encaissé, FCFA")
    overdue: int = Field(description="Parmi elles, factures en retard")
    cancelled: int = Field(description="Factures émises ce mois puis annulées")


class AdminBillRow(BaseModel):
    id: int
    reference: str
    meter_id: int
    meter_reference: str
    household_id: int | None = Field(description="NULL : compteur détaché depuis")
    household_name: str | None
    owner_name: str | None
    period_label: str
    period_start: date
    consumption_wh: int
    amount_total: int
    issued_at: datetime
    due_date: date
    status: BillStatus = Field(description="Statut affiché (en retard si échéance dépassée)")
    days_overdue: int
    paid_at: datetime | None


class AdminBillList(BaseModel):
    items: list[AdminBillRow]
    total: int
    page: int
    size: int
    totals: MonthTotals


class BillingReading(BaseModel):
    """Relevé de facturation (index de début ou de fin de période)."""

    read_at: datetime
    index_wh: int
    source: ReadingSource
    is_estimated: bool


class ReadingSources(BaseModel):
    """D'où viennent les relevés de la période (maquette A6 : « source des relevés »)."""

    bill_source: BillSource = Field(description="« simulated » : données simulées (démo)")
    previous: BillingReading | None
    current: BillingReading | None
    daily_readings: int
    estimated: int = Field(description="Relevés estimés (non transmis)")
    anomalies: int = Field(description="Relevés en anomalie, exclus du calcul")
    by_source: dict[ReadingSource, int]


class AuthorizedPayer(BaseModel):
    user_id: int
    full_name: str
    phone: str = Field(description="Masqué pour le support")
    role: str = Field(description="owner (titulaire) ou payer (payeur délégué)")


class BillTransaction(BaseModel):
    id: int
    reference: str = Field(examples=["TX-00000042"])
    amount: int
    operator: MobileOperator
    operator_label: str
    phone_number: str = Field(description="Toujours masqué")
    status: TransactionStatus
    failure_reason: str | None
    payer_id: int
    payer_name: str
    initiated_at: datetime
    confirmed_at: datetime | None


class HistoryEvent(BaseModel):
    at: datetime
    action: str = Field(examples=["bill.issued", "payment.succeeded", "bill.cancel"])
    label: str
    actor_name: str | None = Field(description="NULL : le système ou l'opérateur")
    detail: str | None


class RelatedBill(BaseModel):
    id: int
    reference: str
    status: BillStatus
    amount_total: int


class AdminBillDetail(AdminBillRow):
    meter_label: str | None
    customer_number: str | None
    contract_number: str | None
    e2c_center: str | None
    period_end: date
    months_count: int
    previous_index_wh: int
    current_index_wh: int
    billed_power_va: int | None
    amount_ht: int
    amount_tax: int
    amount_fees: int
    lines: list[BillLinePublic]
    tariff: TariffPublic
    readings: ReadingSources
    authorized_payers: list[AuthorizedPayer]
    transactions: list[BillTransaction]
    history: list[HistoryEvent]
    cancelled_at: datetime | None
    cancelled_reason: str | None
    cancelled_by: str | None
    replaces: RelatedBill | None = Field(description="Facture annulée que celle-ci remplace")
    replaced_by: RelatedBill | None = Field(description="Facture réémise pour cette période")
    can_cancel: bool = Field(
        description="État de la facture seulement (le rôle est vérifié à part)"
    )
    can_reissue: bool


CancelReason = Annotated[
    str, AfterValidator(lambda raw: clean_text(raw, max_length=255, min_length=10))
]


class CancelRequest(BaseModel):
    """Motif obligatoire, au moins 10 caractères (maquette A6)."""

    model_config = ConfigDict(extra="forbid")

    reason: CancelReason = Field(examples=["Index de fin de période erroné (relevé de contrôle)"])


class BillCancelled(BaseModel):
    id: int
    status: BillStatus
    cancelled_at: datetime
    cancelled_reason: str


class ReissueRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    reason: CancelReason = Field(examples=["Réémission après correction de l'index"])


class BillReissued(BaseModel):
    cancelled_bill_id: int
    bill: AdminBillRow
    notifications: int = Field(description="Titulaire et payeurs délégués prévenus")
