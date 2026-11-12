"""Simulateur de factures (mode démo) : des relevés et un tarif → des factures E²C.

Périodes calées sur le calendrier, comme E²C (« Juillet-Août 2026 ») : pour une durée
de 2 mois, janvier-février, mars-avril, mai-juin… Une période n'est facturée que si
elle est entièrement couverte par les relevés et si sa date d'émission est passée.

Index de facturation : relevé de minuit (heure du Congo) au début du premier jour
(ancien index) et au début du lendemain du dernier jour (nouvel index).
Les montants viennent EXCLUSIVEMENT du moteur `compute_bill` (B2.1).
"""

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from typing import Protocol

from app.core.calendar import MONTHS_PER_YEAR, add_months
from app.core.timezone import CONGO_TZ, local_date
from app.modules.bills.calculator import BillComputation, TariffLike, compute_bill
from app.simulators.readings import SimulatedReading

ISSUE_HOUR = time(8, 0)  # factures émises à 8 h, heure du Congo


class BillingSettings(Protocol):
    """Réglages de facturation nécessaires aux simulateurs (`Settings` convient tel quel)."""

    billing_period_months: int
    bill_issue_delay_days: int
    bill_due_delay_days: int


@dataclass(frozen=True, slots=True)
class BillingPeriod:
    start: date  # premier jour (inclus)
    end: date  # dernier jour (inclus)
    months_count: int


@dataclass(frozen=True, slots=True)
class SimulatedBill:
    """Une facture simulée (mêmes noms de champs que `Bill`, plus le détail du calcul)."""

    period_start: date
    period_end: date
    months_count: int
    previous_index_wh: int
    current_index_wh: int
    consumption_wh: int
    billed_power_va: int | None
    issued_at: datetime  # UTC
    due_date: date
    computation: BillComputation


def billing_periods(first_day: date, last_day: date, months: int) -> list[BillingPeriod]:
    """Périodes calendaires complètes comprises entre `first_day` et `last_day` (inclus)."""
    if months < 1 or MONTHS_PER_YEAR % months != 0:
        raise ValueError(f"Durée de période invalide : {months} (doit diviser 12)")
    # Premier début de période aligné (mois 1, 1 + n, 1 + 2n…) au plus tôt le first_day.
    start = date(first_day.year, 1, 1)
    while start < first_day:
        start = add_months(start, months)
    periods = []
    while True:
        next_start = add_months(start, months)
        end = next_start - timedelta(days=1)
        if end > last_day:
            return periods
        periods.append(BillingPeriod(start, end, months))
        start = next_start


def bill_reference(issue_day: date, sequence: int) -> str:
    """Numéro de facture sur 14 chiffres, comme E²C : date d'émission AAAAMMJJ + 6 chiffres."""
    if not 0 < sequence < 1_000_000:
        raise ValueError("Le numéro de séquence doit être compris entre 1 et 999 999")
    return f"{issue_day:%Y%m%d}{sequence:06d}"


def generate_bills(
    readings: Sequence[SimulatedReading],
    tariff: TariffLike,
    *,
    period_months: int,
    issue_delay_days: int,
    due_delay_days: int,
    as_of: date,
    billed_power_va: int | None = None,
) -> list[SimulatedBill]:
    """Factures des périodes complètes déjà émises à la date `as_of` (date locale)."""
    if not readings:
        return []
    by_day = {local_date(r.read_at): r for r in readings}
    days = sorted(by_day)
    # Les relevés vont de minuit du premier jour à minuit du lendemain du dernier jour.
    periods = billing_periods(days[0], days[-1] - timedelta(days=1), period_months)

    bills = []
    for period in periods:
        issue_day = period.end + timedelta(days=issue_delay_days)
        if issue_day > as_of:
            break  # pas encore émise (et les suivantes non plus)
        previous = _billing_reading(by_day, period.start)
        current = _billing_reading(by_day, period.end + timedelta(days=1))
        consumption = current.index_wh - previous.index_wh
        _check_matches_daily_readings(by_day, period, consumption)
        bills.append(
            SimulatedBill(
                period_start=period.start,
                period_end=period.end,
                months_count=period.months_count,
                previous_index_wh=previous.index_wh,
                current_index_wh=current.index_wh,
                consumption_wh=consumption,
                billed_power_va=billed_power_va,
                issued_at=datetime.combine(issue_day, ISSUE_HOUR, tzinfo=CONGO_TZ).astimezone(UTC),
                due_date=issue_day + timedelta(days=due_delay_days),
                computation=compute_bill(consumption, period.months_count, tariff),
            )
        )
    return bills


def _billing_reading(by_day: dict[date, SimulatedReading], day: date) -> SimulatedReading:
    reading = by_day.get(day)
    if reading is None:
        raise ValueError(f"Relevé de facturation manquant au {day:%d/%m/%Y}")
    if reading.is_anomaly:
        raise ValueError(f"Relevé de facturation en anomalie au {day:%d/%m/%Y}")
    return reading


def _check_matches_daily_readings(
    by_day: dict[date, SimulatedReading], period: BillingPeriod, expected: int
) -> None:
    """Garde-fou : consommation facturée = somme des relevés journaliers de la période.

    Les relevés pris du lendemain du premier jour au lendemain du dernier jour portent
    la consommation des journées de la période.
    """
    after_end = period.end + timedelta(days=1)
    total = sum(r.consumption_wh for day, r in by_day.items() if period.start < day <= after_end)
    if total != expected:
        raise ValueError(
            f"Période {period.start}–{period.end} : relevés {total} Wh ≠ index {expected} Wh"
        )
