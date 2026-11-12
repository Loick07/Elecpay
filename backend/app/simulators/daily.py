"""Relevé quotidien (mode démo) : fait « vivre » la base, une fois par jour.

Pour chaque compteur actif :
1. ajoute les relevés manquants jusqu'à minuit ce matin (rattrape les jours manqués) ;
2. émet les factures des périodes terminées dont la date d'émission est arrivée
   (par `generate_bill`, le service unique de B6) ;
puis passe « en retard » les factures impayées échues (`mark_overdue_bills`).

Idempotent : relancé le même jour, il ne crée rien en double.
Ne refacture JAMAIS une période qui a déjà une facture, même annulée (la correction
d'une facture annulée relève de l'administration, pas d'un automate).
Ne valide pas la transaction (pas de commit) : c'est à l'appelant de le faire.
"""

from collections import Counter
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.modules.bills.errors import BillingError
from app.modules.bills.models import Bill
from app.modules.bills.notifications import bill_issued_notification
from app.modules.bills.periods import BillingSettings, billing_periods, issue_day
from app.modules.bills.service import generate_bill, mark_overdue_bills
from app.modules.consumption.models import MeterReading
from app.modules.households.models import Household
from app.modules.meters.models import Meter, MeterStatus
from app.modules.notifications.service import insert_notifications
from app.simulators.demo_dataset import profile_for
from app.simulators.persistence import anomaly_notification, insert_readings
from app.simulators.readings import PROFILES, generate_readings


@dataclass
class TickReport:
    today: date
    counts: Counter = field(default_factory=Counter)
    skipped: list[str] = field(default_factory=list)  # ce qui n'a pas pu être fait, et pourquoi


def tick_seed(meter_id: int, first_day: date) -> int:
    """Graine déterministe d'un passage : même compteur + même jour → mêmes relevés."""
    return meter_id * 1_000_000 + first_day.toordinal()


class _DailyTick:
    def __init__(self, session: Session, today: date, settings: BillingSettings):
        self.session = session
        self.today = today
        self.settings = settings
        self.report = TickReport(today)
        self.notifications: list[dict[str, Any]] = []

    def run(self) -> TickReport:
        meters = self.session.scalars(
            select(Meter).where(Meter.status == MeterStatus.ACTIVE).order_by(Meter.id)
        ).all()
        for meter in meters:
            owner_id = self._owner_id(meter)
            if self._add_missing_readings(meter, owner_id):
                self._issue_due_bills(meter, owner_id)
        self._mark_overdue_bills()
        self.report.counts["notifications"] += insert_notifications(
            self.session, self.notifications
        )
        self.session.flush()
        return self.report

    def _owner_id(self, meter: Meter) -> int | None:
        if meter.household_id is None:
            return None  # compteur détaché : personne à prévenir
        return self.session.get(Household, meter.household_id).owner_id

    # --- 1. Relevés -----------------------------------------------------------------

    def _add_missing_readings(self, meter: Meter, owner_id: int | None) -> bool:
        """Ajoute les relevés jusqu'à minuit ce matin. Faux si le compteur n'a aucun relevé."""
        last = self._last_reading(meter, valid_only=False)
        if last is None:
            self.report.skipped.append(f"Compteur {meter.reference} : aucun relevé de départ")
            return False
        next_day = local_date(last.read_at)  # journée dont la consommation reste à relever
        last_day = self.today - timedelta(days=1)
        if next_day > last_day:
            return True  # déjà à jour
        last_valid = self._last_reading(meter, valid_only=True)
        start_index = last_valid.index_wh if last_valid is not None else last.index_wh
        generated = generate_readings(
            PROFILES[profile_for(meter.reference, meter.subscribed_power_va)],
            next_day,
            last_day,
            start_index_wh=start_index,
            seed=tick_seed(meter.id, next_day),
            anomaly_on_last_day=True,
        )[1:]  # le premier est le point de départ, déjà en base
        self.report.counts["readings"] += insert_readings(self.session, meter.id, generated)
        for reading in generated:
            if reading.is_anomaly:
                self.report.counts["anomalies"] += 1
                if owner_id is not None:
                    self.notifications.append(
                        anomaly_notification(owner_id, meter.id, meter.reference, reading.read_at)
                    )
        return True

    def _last_reading(self, meter: Meter, *, valid_only: bool) -> MeterReading | None:
        query = select(MeterReading).where(MeterReading.meter_id == meter.id)
        if valid_only:
            query = query.where(MeterReading.is_anomaly.is_(False))
        return self.session.scalars(query.order_by(MeterReading.read_at.desc()).limit(1)).first()

    # --- 2. Factures (toujours par generate_bill) ------------------------------------

    def _issue_due_bills(self, meter: Meter, owner_id: int | None) -> None:
        first, last = self.session.execute(
            select(func.min(MeterReading.read_at), func.max(MeterReading.read_at)).where(
                MeterReading.meter_id == meter.id
            )
        ).one()
        first_day = local_date(first)
        last_day = local_date(last) - timedelta(days=1)  # dernière journée entièrement relevée
        if last_day < first_day:
            return
        already_billed = set(
            self.session.scalars(select(Bill.period_start).where(Bill.meter_id == meter.id))
        )  # toutes les factures, annulées comprises : on ne refacture jamais automatiquement
        for period in billing_periods(first_day, last_day, self.settings.billing_period_months):
            if period.start in already_billed or issue_day(period, self.settings) > self.today:
                continue
            try:
                issued = generate_bill(
                    self.session, meter, period.start, today=self.today, settings=self.settings
                )
            except BillingError as problem:  # tarif absent, relevé manquant ou en anomalie…
                self.report.skipped.append(
                    f"Compteur {meter.reference}, période du {period.start:%d/%m/%Y} : "
                    f"{problem.message}"
                )
                continue
            if issued.created:
                self.report.counts["bills"] += 1
                if owner_id is not None:
                    self.notifications.append(bill_issued_notification(owner_id, issued.bill))

    # --- 3. Retards -----------------------------------------------------------------

    def _mark_overdue_bills(self) -> None:
        overdue = mark_overdue_bills(self.session, today=self.today)
        self.report.counts["overdue"] += len(overdue.bills)
        self.report.counts["notifications"] += overdue.notifications


def run_daily_tick(session: Session, *, today: date, settings: BillingSettings) -> TickReport:
    """Un passage quotidien pour la date locale `today`."""
    return _DailyTick(session, today, settings).run()
