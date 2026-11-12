"""Simulateur de factures (mode démo) : des relevés et un tarif → des factures E²C.

Périodes calées sur le calendrier, comme E²C (« Juillet-Août 2026 ») : pour une durée
de 2 mois, janvier-février, mars-avril, mai-juin… Une période n'est facturée que si
elle est entièrement couverte par les relevés et si sa date d'émission est passée.

Index de facturation : relevé de minuit (heure du Congo) au début du premier jour
(ancien index) et au début du lendemain du dernier jour (nouvel index).
Les montants viennent EXCLUSIVEMENT du moteur `compute_bill` (B2.1) ; périodes et dates
viennent de `app/modules/bills/periods.py` (les mêmes que pour `generate_bill`).
"""

from collections.abc import Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta

from app.core.timezone import local_date
from app.modules.bills.calculator import BillComputation, TariffLike, compute_bill
from app.modules.bills.periods import BillingPeriod, billing_periods, issued_at
from app.simulators.readings import SimulatedReading


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
                issued_at=issued_at(issue_day),
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
