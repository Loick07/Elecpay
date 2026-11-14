"""Schémas des écrans Transactions du back-office (A7 liste, A8 détail et rapprochement).

Numéros de téléphone TOUJOURS masqués dans ces écrans (décision B10). Aucune réponse ne
propose de « marquer comme payée » : seul l'opérateur confirme un paiement.
"""

from datetime import date, datetime
from enum import StrEnum
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.validation import clean_text
from app.integrations.payment_providers.base import ProviderState
from app.modules.bills.models import BillStatus
from app.modules.disputes.models import DisputeResolution, DisputeStatus
from app.modules.payments.models import MobileOperator, PaymentProvider, TransactionStatus


class TransactionFilter(StrEnum):
    """Filtres de l'écran A7 : les 4 statuts, plus deux listes de travail."""

    PENDING = "en_attente"
    SUCCEEDED = "reussie"
    FAILED = "echouee"
    EXPIRED = "expiree"
    TO_RECONCILE = "to_reconcile"  # anomalie signalée par l'opérateur (journal), à rapprocher
    OPEN_DISPUTE = "open_dispute"  # litige ouvert


class DayIndicators(BaseModel):
    """Indicateurs du jour (heure de Brazzaville)."""

    day: date
    collected: int = Field(description="FCFA encaissés aujourd'hui (paiements réussis)")
    succeeded: int
    failed: int = Field(description="Échouées ou expirées, lancées aujourd'hui")
    pending: int = Field(description="En attente en ce moment (toutes dates)")
    average_confirmation_seconds: int | None = Field(
        description="Délai moyen demande → confirmation des réussies du jour"
    )
    to_reconcile: int = Field(description="Transactions avec une anomalie à rapprocher")
    open_disputes: int


class AdminTransactionRow(BaseModel):
    id: int
    reference: str = Field(examples=["TX-00000042"])
    bill_id: int
    bill_reference: str
    payer_id: int
    payer_name: str
    phone_number: str = Field(description="Toujours masqué")
    operator: MobileOperator
    operator_label: str
    amount: int
    status: TransactionStatus
    failure_reason: str | None
    initiated_at: datetime
    confirmed_at: datetime | None
    pin_entered: bool
    to_reconcile: bool = Field(description="Anomalie signalée (montant, contradiction…)")
    open_dispute: bool


class AdminTransactionList(BaseModel):
    items: list[AdminTransactionRow]
    total: int
    page: int
    size: int
    today: DayIndicators


class OperatorView(BaseModel):
    """Ce que l'opérateur a répondu lors de la dernière vérification par l'équipe."""

    checked_at: datetime
    checked_by: str | None
    state: ProviderState
    provider_ref: str
    amount: int | None
    failure_reason: str | None


class Comparison(BaseModel):
    """Une ligne « ElecPay ↔ opérateur » (maquette A8)."""

    field: str = Field(examples=["amount", "provider_ref", "status"])
    label: str
    elecpay: str | None
    operator: str | None
    matches: bool | None = Field(description="None : l'opérateur ne l'a pas indiqué")


class BillLock(BaseModel):
    """Verrou de facture : une seule transaction en attente par facture."""

    bill_id: int
    bill_reference: str
    bill_status: BillStatus
    amount_total: int
    locked_by_this_transaction: bool


class TimelineEvent(BaseModel):
    at: datetime
    action: str
    label: str
    actor_name: str | None = Field(description="NULL : le système ou l'opérateur")
    detail: str | None


class Anomaly(BaseModel):
    at: datetime
    action: str = Field(examples=["payment.amount_mismatch", "payment.provider_conflict"])
    label: str
    detail: dict[str, str]


class DisputePublic(BaseModel):
    id: int
    status: DisputeStatus
    reason: str
    customer_reference: str | None
    opened_by: str
    opened_at: datetime
    resolution: DisputeResolution | None
    resolution_note: str | None
    resolved_by: str | None
    resolved_at: datetime | None


class AdminTransactionDetail(AdminTransactionRow):
    provider: PaymentProvider
    provider_ref: str | None
    idempotency_key: str
    pin_entered_at: datetime | None
    expires_at: datetime
    bill_lock: BillLock
    operator_view: OperatorView | None = Field(description="NULL : jamais vérifiée par l'équipe")
    comparison: list[Comparison]
    anomalies: list[Anomaly]
    timeline: list[TimelineEvent]
    disputes: list[DisputePublic]
    can_recheck: bool = Field(description="État de la transaction seulement (rôle vérifié à part)")
    can_open_dispute: bool


class RecheckResult(BaseModel):
    transaction_id: int
    status_before: TransactionStatus
    status_after: TransactionStatus
    operator_state: ProviderState
    outcome: str = Field(
        description="unchanged, pin_entered, succeeded, failed, expired, amount_mismatch, conflict"
    )
    message: str


Text10 = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=255, min_length=10))]
Reference = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=64, min_length=3))]


class DisputeOpenRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    reason: Text10 = Field(examples=["Le client affirme avoir été débité de 40 384 FCFA"])
    customer_reference: Reference | None = Field(
        default=None, description="ID de transaction du SMS reçu par le client"
    )


class DisputeCloseRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    resolution: DisputeResolution
    note: Text10 = Field(examples=["MTN confirme : aucun débit sur ce numéro le 12/11"])
