"""Textes des notifications liées aux factures (identiques partout : relevé, seed, import)."""

from datetime import timedelta
from typing import Any

from app.core.money import format_fcfa
from app.core.timezone import local_midnight_utc
from app.modules.bills.models import Bill
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import notification_row

OVERDUE_NOTICE_HOUR = timedelta(hours=9)  # le lendemain de l'échéance, à 9 h (heure du Congo)


def bill_issued_notification(user_id: int, bill: Bill) -> dict[str, Any]:
    return notification_row(
        user_id,
        NotificationType.BILL_ISSUED,
        "Nouvelle facture",
        f"Facture {bill.period_start:%m/%Y}–{bill.period_end:%m/%Y} disponible : "
        f"{format_fcfa(bill.amount_total)}, à payer avant le {bill.due_date:%d/%m/%Y}.",
        {"bill_id": bill.id},
        at=bill.issued_at,
    )


def bill_overdue_notification(user_id: int, bill: Bill) -> dict[str, Any]:
    return notification_row(
        user_id,
        NotificationType.BILL_OVERDUE,
        "Facture en retard",
        f"Votre facture {bill.reference} ({format_fcfa(bill.amount_total)}) a dépassé "
        f"son échéance du {bill.due_date:%d/%m/%Y}.",
        {"bill_id": bill.id},
        at=local_midnight_utc(bill.due_date + timedelta(days=1)) + OVERDUE_NOTICE_HOUR,
    )
