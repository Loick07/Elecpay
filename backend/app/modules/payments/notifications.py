"""Textes des notifications de paiement (B7.3). Le reçu viendra avec B8."""

from typing import Any

from app.core.money import format_fcfa
from app.modules.bills.models import Bill
from app.modules.bills.queries import bill_period_label
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import notification_row
from app.modules.payments.models import PaymentTransaction
from app.modules.users.models import User


def _data(transaction: PaymentTransaction) -> dict[str, Any]:
    return {"bill_id": transaction.bill_id, "transaction_id": transaction.id}


def payment_succeeded_rows(
    transaction: PaymentTransaction, bill: Bill, payer: User, owner_id: int | None
) -> list[dict[str, Any]]:
    """Le payeur est prévenu ; le titulaire aussi, si quelqu'un d'autre a payé pour lui."""
    period = bill_period_label(bill.period_start, bill.period_end)
    amount = format_fcfa(transaction.amount)
    at = transaction.confirmed_at
    rows = [
        notification_row(
            payer.id,
            NotificationType.PAYMENT_SUCCEEDED,
            "Paiement réussi",
            f"Paiement de {amount} confirmé pour la facture {period}.",
            _data(transaction),
            at=at,
        )
    ]
    if owner_id is not None and owner_id != payer.id:
        rows.append(
            notification_row(
                owner_id,
                NotificationType.PAYMENT_SUCCEEDED,
                "Facture payée",
                f"{payer.full_name} a payé votre facture {period} ({amount}).",
                _data(transaction),
                at=at,
            )
        )
    return rows


def payment_failed_row(
    transaction: PaymentTransaction, *, at, reason: str | None = None
) -> dict[str, Any]:
    return notification_row(
        transaction.payer_id,
        NotificationType.PAYMENT_FAILED,
        "Paiement non abouti",
        f"Le paiement de {format_fcfa(transaction.amount)} n'a pas abouti : "
        f"{reason or transaction.failure_reason}. Vous pouvez réessayer.",
        _data(transaction),
        at=at,
    )
