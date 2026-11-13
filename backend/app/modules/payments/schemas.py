"""Schémas d'API des paiements (écrans client 8 « Paiement », 9 « Attente », 12 « Historique »).

Montants en FCFA entiers. Le montant n'est JAMAIS envoyé par l'application : c'est celui de
la facture. `source: simulated` en mode démo : aucun débit réel n'a lieu.
"""

from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field

from app.core.validation import CongoPhone
from app.modules.payments.models import MobileOperator, TransactionStatus

IDEMPOTENCY_KEY_PATTERN = r"^[A-Za-z0-9_-]{8,64}$"
MONTH_PATTERN = r"^20[0-9]{2}-(0[1-9]|1[0-2])$"  # AAAA-MM (2000 à 2099)


class PaymentCreate(BaseModel):
    """Écran 8 : la facture, l'opérateur et le numéro à débiter (modifiable : payer depuis le
    téléphone d'un proche)."""

    model_config = ConfigDict(extra="forbid")

    bill_id: int = Field(ge=1)
    operator: MobileOperator
    phone_number: CongoPhone = Field(examples=["06 123 45 67"])


class PaymentStep(StrEnum):
    """Les étapes de l'écran 9, déduites du statut."""

    REQUESTED = "requested"  # demande envoyée : « Confirmez sur votre téléphone »
    PIN_ENTERED = "pin_entered"  # code PIN saisi, en attente de l'opérateur
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    EXPIRED = "expired"


class WebhookAck(BaseModel):
    """Réponse au prestataire : la notification est reçue et traitée."""

    received: bool = True
    transaction_status: TransactionStatus
    outcome: str = Field(
        examples=["succeeded"],
        description="unchanged, pin_entered, succeeded, failed, amount_mismatch, conflict",
    )


class PaymentPublic(BaseModel):
    id: int
    reference: str = Field(
        description="Référence à communiquer à l'assistance", examples=["TX-00000042"]
    )
    bill_id: int
    bill_reference: str
    bill_period_label: str = Field(examples=["Juil.-Août 2026"])
    meter_id: int
    meter_reference: str = Field(description="N° Branchement")
    household_id: int | None = Field(description="None si le compteur est détaché depuis")
    household_name: str | None
    amount: int = Field(description="FCFA (= total de la facture)")
    operator: MobileOperator
    operator_label: str = Field(examples=["MTN MoMo"])
    phone_number: str = Field(description="Numéro débité (masqué si ce n'est pas le vôtre)")
    status: TransactionStatus
    step: PaymentStep
    failure_reason: str | None
    initiated_at: datetime
    pin_entered_at: datetime | None
    confirmed_at: datetime | None
    expires_at: datetime = Field(description="Sans code PIN saisi avant cette heure : expirée")
    payer_id: int
    payer_name: str = Field(description="Qui a payé (titulaire ou payeur délégué)")
    is_mine: bool = Field(description="C'est moi qui ai lancé ce paiement")
    source: str = Field(description="« simulated » en mode démo : aucun débit réel")
