"""Historique simulé d'un compteur ajouté par un abonné (mode démo).

Reproduit ce qu'E²C connaîtrait du compteur : 18 mois de relevés et les factures émises
(par `generate_bill`, le service unique de B6).
Les anciennes factures ont été payées HORS ElecPay (en agence…) : elles sont marquées payées,
SANS transaction ni reçu ElecPay inventés. La dernière reste à payer (ou en retard).
Déterministe : même compteur + même date → même historique.
"""

import hashlib
import random
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

from sqlalchemy.orm import Session

from app.core.timezone import CONGO_TZ, local_date
from app.modules.bills.models import BillStatus
from app.modules.bills.periods import BillingSettings, billing_periods, issue_day
from app.modules.bills.service import generate_bill, tariff_at
from app.modules.meters.models import Meter
from app.simulators.demo_dataset import profile_for
from app.simulators.persistence import insert_readings
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

    if tariff_at(session, first_day) is None:  # aucun tarif en vigueur : relevés seulement
        return ImportedHistory(imported_readings, 0, first_day)
    last_day = local_date(readings[-1].read_at) - timedelta(days=1)
    periods = [
        period
        for period in billing_periods(first_day, last_day, settings.billing_period_months)
        if issue_day(period, settings) <= today
    ]
    for position, period in enumerate(periods, start=1):
        bill = generate_bill(session, meter, period.start, today=today, settings=settings).bill
        if position < len(periods):  # payée hors ElecPay, quelques jours avant l'échéance
            paid_day = bill.due_date - timedelta(days=rng.randint(1, 10))
            bill.status = BillStatus.PAID
            bill.paid_at = max(
                datetime.combine(paid_day, time(10, 0), tzinfo=CONGO_TZ),
                bill.issued_at + timedelta(hours=1),
            )
        elif bill.due_date < today:
            bill.status = BillStatus.OVERDUE
        session.flush()
    return ImportedHistory(imported_readings, len(periods), first_day)
