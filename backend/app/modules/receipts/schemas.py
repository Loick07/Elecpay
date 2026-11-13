"""Schémas d'API des reçus (écran client 10 « Reçu »).

Un reçu est fait pour être partagé : le numéro débité y est TOUJOURS masqué, même pour le
payeur (comme sur la maquette). `source: simulated` en mode démo : aucun débit réel.
"""

from datetime import datetime

from pydantic import BaseModel, Field

from app.modules.payments.models import MobileOperator


class ReceiptVerification(BaseModel):
    """Vérification publique : le minimum, sans nom ni numéro de téléphone."""

    valid: bool = Field(default=True, description="Toujours vrai (sinon : erreur 404)")
    number: str = Field(examples=["EP-2026-000123"])
    issued_at: datetime
    amount: int = Field(description="Montant payé, FCFA")
    bill_period_label: str = Field(examples=["Sept.-Oct. 2026"])
    meter_reference: str = Field(
        description="N° Branchement partiellement masqué", examples=["0412-••33"]
    )
    demo: bool = Field(description="Paiement simulé (mode démo) : aucun débit réel")
    message: str


class ReceiptPublic(BaseModel):
    id: int
    number: str = Field(examples=["EP-2026-000123"])
    issued_at: datetime = Field(description="Date du paiement confirmé")
    amount: int = Field(description="Montant payé, FCFA")
    verification_code: str = Field(
        description="Code à afficher (groupes de 4) et à saisir sur la vérification publique",
        examples=["8F3K-2Q9M-7XHT"],
    )
    bill_id: int
    bill_reference: str
    bill_period_label: str = Field(examples=["Sept.-Oct. 2026"])
    meter_id: int
    meter_reference: str = Field(description="N° Branchement")
    household_id: int | None
    household_name: str | None
    payer_id: int
    payer_name: str
    is_mine: bool = Field(description="C'est moi qui ai payé")
    operator: MobileOperator
    operator_label: str = Field(examples=["MTN MoMo"])
    phone_number: str = Field(description="Toujours masqué", examples=["+242 06 *** ** 67"])
    transaction_id: int
    transaction_reference: str = Field(examples=["TX-00000042"])
    source: str = Field(description="« simulated » en mode démo : aucun débit réel")
