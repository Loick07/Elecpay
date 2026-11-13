"""Rappels automatiques sur les factures (B9.3), lancés une fois par jour.

Destinataires : les personnes qui PEUVENT payer la facture — le titulaire du foyer et ses
payeurs délégués actifs (décision B9.3). Compteur détaché : personne. Les interrupteurs de
l'écran 14 s'appliquent (« Échéances » coupe les rappels d'échéance ; le retard est toujours
envoyé).

- Échéance proche : à partir de 5 jours avant l'échéance (« dans N jours », une seule fois),
  puis le jour même (« aujourd'hui », une seule fois). Seulement pour une facture à payer
  (`unpaid`) : en cours de paiement, payée ou annulée, rien. Si le rappel « avant » n'a pas pu
  partir le jour J-5 (relevé non lancé), il part dès le jour suivant, avec le bon nombre de jours.
- Retard : le premier avis part au passage en retard (`mark_overdue_bills`) ; ensuite un rappel
  dès que le dernier avis reçu par la personne pour cette facture a 7 jours ou plus.
Idempotent : relancé le même jour, rien n'est envoyé deux fois.
"""

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.notifications import bill_due_soon_notification, bill_overdue_reminder
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.notifications.models import Notification, NotificationType
from app.modules.notifications.service import insert_notifications

DUE_SOON_DAYS = 5
REMINDER_EVERY = timedelta(days=7)


def bill_recipients(session: Session, bill: Bill) -> list[int]:
    """Titulaire + payeurs délégués actifs du foyer du compteur (vide si détaché)."""
    household = session.scalar(
        select(Household)
        .join(Meter, Meter.household_id == Household.id)
        .where(Meter.id == bill.meter_id)
    )
    if household is None:
        return []
    payers = session.scalars(
        select(HouseholdMember.user_id).where(
            HouseholdMember.household_id == household.id,
            HouseholdMember.role == MemberRole.PAYER,
            HouseholdMember.status == MemberStatus.ACTIVE,
        )
    ).all()
    return [household.owner_id, *sorted(set(payers) - {household.owner_id})]


def bill_place(session: Session, bill: Bill) -> str | None:
    """« Maison Mpita » : le foyer, pour distinguer les factures de plusieurs foyers."""
    return session.scalar(
        select(Household.name)
        .join(Meter, Meter.household_id == Household.id)
        .where(Meter.id == bill.meter_id)
    )


def send_due_soon_reminders(session: Session, *, today: date) -> int:
    """Rappels d'échéance du jour. Renvoie le nombre de notifications créées."""
    bills = session.scalars(
        select(Bill)
        .where(
            Bill.status == BillStatus.UNPAID,
            Bill.due_date >= today,
            Bill.due_date <= today + timedelta(days=DUE_SOON_DAYS),
        )
        .order_by(Bill.id)
    ).all()
    rows = []
    for bill in bills:
        stage = "due_day" if bill.due_date == today else "before"
        already = _already_notified(session, bill, NotificationType.BILL_DUE_SOON, stage)
        place = bill_place(session, bill)
        rows += [
            bill_due_soon_notification(user_id, bill, today=today, place=place)
            for user_id in bill_recipients(session, bill)
            if user_id not in already
        ]
    return insert_notifications(session, rows)


def send_overdue_reminders(session: Session, *, today: date) -> int:
    """Rappels de retard du jour (tous les 7 jours). Renvoie le nombre de notifications créées."""
    bills = session.scalars(
        select(Bill).where(Bill.status == BillStatus.OVERDUE).order_by(Bill.id)
    ).all()
    rows = []
    for bill in bills:
        last_notice = _last_overdue_notice(session, bill)
        place = bill_place(session, bill)
        for user_id in bill_recipients(session, bill):
            last = last_notice.get(user_id)
            if last is None or today - local_date(last) >= REMINDER_EVERY:
                rows.append(bill_overdue_reminder(user_id, bill, today=today, place=place))
    return insert_notifications(session, rows)


# --- Outils ------------------------------------------------------------------------------------


def _bill_notices(session: Session, bill: Bill, kind: NotificationType):
    return select(Notification).where(
        Notification.type == kind,
        Notification.data_json["bill_id"].as_integer() == bill.id,
    )


def _already_notified(session: Session, bill: Bill, kind: NotificationType, stage: str) -> set[int]:
    notices = session.scalars(
        _bill_notices(session, bill, kind).where(
            Notification.data_json["stage"].as_string() == stage
        )
    )
    return {notice.user_id for notice in notices}


def _last_overdue_notice(session: Session, bill: Bill) -> dict:
    """Dernier avis de retard (premier avis ou rappel) reçu par chaque personne."""
    last: dict = {}
    for notice in session.scalars(_bill_notices(session, bill, NotificationType.BILL_OVERDUE)):
        if notice.user_id not in last or notice.created_at > last[notice.user_id]:
            last[notice.user_id] = notice.created_at
    return last
