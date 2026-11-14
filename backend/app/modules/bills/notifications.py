"""Textes des notifications liées aux factures (identiques partout : relevé, seed, import)."""

from datetime import timedelta
from typing import Any

from app.core.money import format_fcfa
from app.core.timezone import local_midnight_utc
from app.modules.bills.models import Bill
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import notification_row

OVERDUE_NOTICE_HOUR = timedelta(hours=9)  # le lendemain de l'échéance, à 9 h (heure du Congo)
DUE_SOON_NOTICE_HOUR = timedelta(hours=8)  # rappels d'échéance à 8 h (heure du Congo)


def _amount_and_place(bill: Bill, place: str | None) -> str:
    where = f"{place} : " if place else ""
    return f"{where}{format_fcfa(bill.amount_total)}"


def bill_due_soon_notification(
    user_id: int, bill: Bill, *, today, place: str | None
) -> dict[str, Any]:
    """« Échéance dans 5 jours » … puis « Échéance aujourd'hui » (écran 13)."""
    days_left = (bill.due_date - today).days
    if days_left == 0:
        title, stage = "Échéance aujourd'hui", "due_day"
        when = "aujourd'hui"
    else:
        title = f"Échéance dans {days_left} jour{'s' if days_left > 1 else ''}"
        stage, when = "before", f"avant le {bill.due_date:%d/%m/%Y}"
    return notification_row(
        user_id,
        NotificationType.BILL_DUE_SOON,
        title,
        f"{_amount_and_place(bill, place)} à payer {when}.",
        {"bill_id": bill.id, "stage": stage},
        at=local_midnight_utc(today) + DUE_SOON_NOTICE_HOUR,
    )


def bill_overdue_reminder(user_id: int, bill: Bill, *, today, place: str | None) -> dict[str, Any]:
    """Rappel de retard, tous les 7 jours tant que la facture n'est pas payée (maquette A9)."""
    days_late = (today - bill.due_date).days
    return notification_row(
        user_id,
        NotificationType.BILL_OVERDUE,
        "Rappel : facture en retard",
        f"{_amount_and_place(bill, place)}, en retard de {days_late} jours "
        f"(échéance du {bill.due_date:%d/%m/%Y}).",
        {"bill_id": bill.id, "stage": "reminder"},
        at=local_midnight_utc(today) + OVERDUE_NOTICE_HOUR,
    )


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


def bill_reissued_notification(user_id: int, bill: Bill, cancelled: Bill) -> dict[str, Any]:
    """Facture réémise par l'administration après annulation (B10.5)."""
    return notification_row(
        user_id,
        NotificationType.BILL_ISSUED,
        "Facture corrigée",
        f"Facture {bill.period_start:%m/%Y}–{bill.period_end:%m/%Y} corrigée : "
        f"{format_fcfa(bill.amount_total)}, à payer avant le {bill.due_date:%d/%m/%Y}. "
        f"Elle remplace la facture {cancelled.reference}, annulée.",
        {"bill_id": bill.id, "replaces_bill_id": cancelled.id},
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
