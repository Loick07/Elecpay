"""Historique simulé d'un compteur ajouté par un abonné (mode démo).

Reproduit ce qu'E²C connaîtrait du compteur : 18 mois de relevés et les factures émises.
Les anciennes factures ont été payées HORS ElecPay (en agence…) : elles sont marquées payées,
SANS transaction ni reçu ElecPay inventés. La dernière reste à payer (ou en retard).
Déterministe : même compteur + même date → même historique.
"""

import hashlib
import random
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

from sqlalchemy.orm import Session

from app.core.timezone import CONGO_TZ
from app.modules.bills.models import BillStatus
from app.modules.meters.models import Meter
from app.simulators.bills import BillingSettings, generate_bills
from app.simulators.daily import tariff_at
from app.simulators.demo_dataset import profile_for
from app.simulators.persistence import insert_bill, insert_readings, next_bill_sequence
from app.simulators.readings import PROFILES, generate_readings
from app.simulators.seeder import history_start


@dataclass(frozen=True, slots=True)
class ImportedHistory:
    readings: int
    bills: int
    first_day: date


def meter_seed(meter: Meter) -> int:
    """Graine stable tirée de la référence (pas de l'id, qui change d'une base à l'autre)."""
    return int(hashlib.sha256(meter.reference.encode()).hexdigest()[:12], 16)


def backfill_meter_history(
    session: Session, meter: Meter, *, today: date, settings: BillingSettings
) -> ImportedHistory:
    seed = meter_seed(meter)
    rng = random.Random(seed)
    first_day = history_start(today, settings.billing_period_months)
    readings = generate_readings(
        PROFILES[profile_for(meter.reference, meter.subscribed_power_va)],
        first_day,
        today - timedelta(days=1),
        start_index_wh=rng.randint(1_000_000, 30_000_000),
        seed=seed,
    )
    imported_readings = insert_readings(session, meter.id, readings)

    tariff = tariff_at(session, first_day)
    if tariff is None:  # aucun tarif en vigueur : relevés seulement
        return ImportedHistory(imported_readings, 0, first_day)
    bills = generate_bills(
        readings,
        tariff,
        period_months=settings.billing_period_months,
        issue_delay_days=settings.bill_issue_delay_days,
        due_delay_days=settings.bill_due_delay_days,
        as_of=today,
        billed_power_va=meter.subscribed_power_va,
    )
    for position, simulated in enumerate(bills, start=1):
        bill = insert_bill(
            session,
            meter_id=meter.id,
            tariff_id=tariff.id,
            simulated=simulated,
            sequence=next_bill_sequence(session),
        )
        if position < len(bills):  # payée hors ElecPay, quelques jours avant l'échéance
            paid_day = simulated.due_date - timedelta(days=rng.randint(1, 10))
            bill.status = BillStatus.PAID
            bill.paid_at = max(
                datetime.combine(paid_day, time(10, 0), tzinfo=CONGO_TZ),
                simulated.issued_at + timedelta(hours=1),
            )
        elif simulated.due_date < today:
            bill.status = BillStatus.OVERDUE
        session.flush()
    return ImportedHistory(imported_readings, len(bills), first_day)
