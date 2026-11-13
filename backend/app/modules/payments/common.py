"""Petites fonctions partagées par le lancement, le suivi et l'affichage des paiements."""

from app.integrations.payment_providers.base import PaymentRequest
from app.modules.bills.models import Bill
from app.modules.payments.models import PaymentTransaction


def public_reference(transaction: PaymentTransaction) -> str:
    """Référence affichée à l'abonné et à l'assistance (écran 9)."""
    return f"TX-{transaction.id:08d}"


def payment_request(transaction: PaymentTransaction, bill: Bill) -> PaymentRequest:
    """Ce que le prestataire reçoit pour cette transaction (demande et suivi)."""
    return PaymentRequest(
        reference=transaction.idempotency_key,
        operator=transaction.operator.value,
        phone_number=transaction.phone_number,
        amount=transaction.amount,
        initiated_at=transaction.initiated_at,
        description=f"Facture E²C {bill.reference}",
    )
