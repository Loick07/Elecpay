"""Écriture en base des données simulées, commune au seed (B2.5) et au relevé quotidien (B2.6).

Un seul endroit pour : insérer des relevés, émettre une facture avec ses lignes, et rédiger
les notifications liées aux factures. Les textes sont donc identiques partout.
"""

from collections.abc import Sequence
from dataclasses import asdict
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import func, insert, select
from sqlalchemy.orm import Session

from app.core.timezone import local_date, local_midnight_utc
from app.modules.bills.models import Bill, BillLine, BillSource
from app.modules.consumption.models import MeterReading, ReadingSource
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import notification_row
from app.simulators.bills import SimulatedBill, bill_reference
from app.simulators.readings import SimulatedReading


def format_fcfa(amount: int) -> str:
    """40384 → « 40 384 FCFA » (séparateur de milliers comme sur la facture E²C)."""
    return f"{amount:,}".replace(",", " ") + " FCFA"


def insert_readings(session: Session, meter_id: int, readings: Sequence[SimulatedReading]) -> int:
    """Insertion groupée (rapide) de relevés simulés. Renvoie le nombre inséré."""
    rows = [
        {"meter_id": meter_id, "source": ReadingSource.SIMULATED, **asdict(r)} for r in readings
    ]
    if rows:
        session.execute(insert(MeterReading), rows)
    return len(rows)


def next_bill_sequence(session: Session) -> int:
    """Numéro de séquence de la prochaine facture (les factures ne sont jamais supprimées)."""
    return (session.scalar(select(func.count()).select_from(Bill)) or 0) + 1


def insert_bill(
    session: Session, *, meter_id: int, tariff_id: int, simulated: SimulatedBill, sequence: int
) -> Bill:
    """Émet une facture simulée et ses lignes, telles que calculées par `compute_bill`."""
    computation = simulated.computation
    bill = Bill(
        meter_id=meter_id,
        tariff_id=tariff_id,
        reference=bill_reference(local_date(simulated.issued_at), sequence),
        period_start=simulated.period_start,
        period_end=simulated.period_end,
        months_count=simulated.months_count,
        previous_index_wh=simulated.previous_index_wh,
        current_index_wh=simulated.current_index_wh,
        consumption_wh=simulated.consumption_wh,
        billed_power_va=simulated.billed_power_va,
        amount_ht=computation.amount_ht,
        amount_tax=computation.amount_tax,
        amount_fees=computation.amount_fees,
        amount_total=computation.amount_total,
        due_date=simulated.due_date,
        issued_at=simulated.issued_at,
        source=BillSource.SIMULATED,
    )
    session.add(bill)
    session.flush()
    session.execute(
        insert(BillLine), [{"bill_id": bill.id, **asdict(line)} for line in computation.lines]
    )
    return bill


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
        at=local_midnight_utc(bill.due_date + timedelta(days=1)) + timedelta(hours=9),
    )


def anomaly_notification(user_id: int, meter_id: int, reference: str, read_at: datetime):
    return notification_row(
        user_id,
        NotificationType.CONSUMPTION_ANOMALY,
        "Relevé inhabituel",
        f"Le relevé du {local_date(read_at):%d/%m/%Y} sur le compteur {reference} semble "
        "erroné. Il a été signalé pour vérification.",
        {"meter_id": meter_id},
        at=read_at + timedelta(hours=7),
    )
