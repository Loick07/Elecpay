"""Tests du simulateur de factures (B2.3)."""

from dataclasses import asdict, replace
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.core.timezone import local_date
from app.modules.bills.models import Bill, BillLine, BillSource
from app.simulators.bills import (
    BillingPeriod,
    add_months,
    bill_reference,
    billing_periods,
    generate_bills,
)
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.factories import make_meter, make_tariff
from tests.test_bill_calculator import E2C

FIRST = date(2025, 5, 1)
LAST = date(2026, 10, 31)  # 18 mois de relevés


def readings_for(seed=42, profile=ProfileName.FAMILY, first=FIRST, last=LAST):
    return generate_readings(PROFILES[profile], first, last, start_index_wh=14_000_000, seed=seed)


def bills_for(readings, *, months=2, as_of=date(2026, 11, 12), **kwargs):
    return generate_bills(
        readings,
        E2C,
        period_months=months,
        issue_delay_days=3,
        due_delay_days=15,
        as_of=as_of,
        **kwargs,
    )


# --- Périodes -----------------------------------------------------------------------


def test_add_months_crosses_years():
    assert add_months(date(2025, 11, 1), 2) == date(2026, 1, 1)
    assert add_months(date(2026, 1, 1), 12) == date(2027, 1, 1)


def test_bimonthly_periods_are_calendar_aligned():
    periods = billing_periods(FIRST, LAST, 2)
    assert [(p.start, p.end) for p in periods[:2]] == [
        (date(2025, 5, 1), date(2025, 6, 30)),
        (date(2025, 7, 1), date(2025, 8, 31)),
    ]
    assert periods[-1] == BillingPeriod(date(2026, 9, 1), date(2026, 10, 31), 2)
    assert len(periods) == 9  # 4 en 2025 (mai → déc.) + 5 en 2026 (janv. → oct.)


def test_february_of_a_leap_year_ends_on_the_29th():
    (period,) = billing_periods(date(2028, 1, 1), date(2028, 2, 29), 2)
    assert period.end == date(2028, 2, 29)


def test_partial_periods_are_never_billed():
    # Relevés du 15 mai au 20 octobre : mai-juin et septembre-octobre sont incomplets.
    periods = billing_periods(date(2025, 5, 15), date(2026, 10, 20), 2)
    assert periods[0].start == date(2025, 7, 1)
    assert periods[-1].end == date(2026, 8, 31)


@pytest.mark.parametrize(("months", "count"), [(1, 18), (3, 6), (6, 3), (12, 1)])
def test_other_period_lengths(months, count):
    periods = billing_periods(date(2025, 1, 1), date(2026, 6, 30), months)
    assert len(periods) == count
    assert all(p.start.day == 1 and (p.start.month - 1) % months == 0 for p in periods)


@pytest.mark.parametrize("months", [0, 5, 7, 13])
def test_period_length_must_divide_the_year(months):
    with pytest.raises(ValueError, match="doit diviser 12"):
        billing_periods(FIRST, LAST, months)


# --- Numéro de facture --------------------------------------------------------------


def test_reference_has_14_digits_like_e2c():
    assert bill_reference(date(2026, 9, 3), 21_604) == "20260903021604"


@pytest.mark.parametrize("sequence", [0, 1_000_000])
def test_reference_sequence_is_bounded(sequence):
    with pytest.raises(ValueError):
        bill_reference(date(2026, 9, 3), sequence)


# --- Factures -----------------------------------------------------------------------


@pytest.mark.parametrize("seed", range(10))
def test_billed_consumption_is_the_sum_of_daily_readings(seed):
    """Critère du plan B2 : consommation facturée = somme des relevés de la période."""
    readings = readings_for(seed)
    for bill in bills_for(readings):
        in_period = [
            r for r in readings if bill.period_start < local_date(r.read_at) <= _after(bill)
        ]
        assert sum(r.consumption_wh for r in in_period) == bill.consumption_wh
        assert bill.consumption_wh == bill.current_index_wh - bill.previous_index_wh


@pytest.mark.parametrize("seed", range(10))
def test_bill_total_is_the_sum_of_its_lines(seed):
    """Critère du plan B2 : total de la facture = somme de ses lignes."""
    for bill in bills_for(readings_for(seed)):
        lines = bill.computation.lines
        assert bill.computation.amount_total == sum(line.amount for line in lines)


def test_billing_indexes_come_from_midnight_readings():
    readings = readings_for()
    by_day = {local_date(r.read_at): r for r in readings}
    bill = bills_for(readings)[1]  # juillet-août 2025
    assert (bill.period_start, bill.period_end) == (date(2025, 7, 1), date(2025, 8, 31))
    assert bill.previous_index_wh == by_day[date(2025, 7, 1)].index_wh
    assert bill.current_index_wh == by_day[date(2025, 9, 1)].index_wh


def test_issue_and_due_dates_follow_the_real_bill():
    """Vraie facture : période close le 31/08, émise le 03/09 (+ 3 jours) ; échéance + 15 j."""
    bill = bills_for(readings_for())[1]
    assert bill.issued_at == datetime(2025, 9, 3, 7, 0, tzinfo=UTC)  # 8 h à Brazzaville
    assert bill.due_date == date(2025, 9, 18)


def test_bills_not_yet_issued_are_not_generated():
    readings = readings_for()
    # Septembre-octobre 2026 se termine le 31/10, émission le 03/11.
    assert bills_for(readings, as_of=date(2026, 11, 2))[-1].period_end == date(2026, 8, 31)
    assert bills_for(readings, as_of=date(2026, 11, 3))[-1].period_end == date(2026, 10, 31)


def test_family_bill_is_in_the_range_of_the_real_one():
    """Ordre de grandeur : vraie facture juillet-août 2026 = 571 kWh, 40 384 FCFA."""
    bill = next(b for b in bills_for(readings_for()) if b.period_start == date(2026, 7, 1))
    assert 400_000 <= bill.consumption_wh <= 700_000
    assert 30_000 <= bill.computation.amount_total <= 50_000


def test_billed_power_is_carried_over():
    assert all(b.billed_power_va == 3_000 for b in bills_for(readings_for(), billed_power_va=3_000))


def test_monthly_billing_is_possible():
    bills = bills_for(readings_for(), months=1)
    assert len(bills) == 18
    assert all(b.months_count == 1 for b in bills)
    assert bills[0].computation.lines[1].amount == 2_550  # droit à la consommation sur 1 mois


def test_no_readings_no_bills():
    assert bills_for([]) == []


def test_anomaly_on_a_billing_reading_is_refused():
    readings = readings_for()
    index = next(i for i, r in enumerate(readings) if local_date(r.read_at) == date(2025, 7, 1))
    readings[index] = replace(
        readings[index], is_anomaly=True, anomaly_reason="test", consumption_wh=0
    )
    with pytest.raises(ValueError, match="anomalie"):
        bills_for(readings)


def test_missing_billing_reading_is_refused():
    readings = [r for r in readings_for() if local_date(r.read_at) != date(2025, 9, 1)]
    with pytest.raises(ValueError, match="manquant"):
        bills_for(readings)


# --- Les factures s'enregistrent telles quelles en base -----------------------------


def test_simulated_bills_are_accepted_by_the_database(db_session):
    meter = make_meter(db_session)
    tariff = make_tariff(db_session)
    simulated = bills_for(readings_for(), billed_power_va=3_000)
    for sequence, sim in enumerate(simulated, start=1):
        computation = sim.computation
        bill = Bill(
            meter_id=meter.id,
            tariff_id=tariff.id,
            reference=bill_reference(local_date(sim.issued_at), sequence),
            period_start=sim.period_start,
            period_end=sim.period_end,
            months_count=sim.months_count,
            previous_index_wh=sim.previous_index_wh,
            current_index_wh=sim.current_index_wh,
            consumption_wh=sim.consumption_wh,
            billed_power_va=sim.billed_power_va,
            amount_ht=computation.amount_ht,
            amount_tax=computation.amount_tax,
            amount_fees=computation.amount_fees,
            amount_total=computation.amount_total,
            due_date=sim.due_date,
            issued_at=sim.issued_at,
            source=BillSource.SIMULATED,
        )
        db_session.add(bill)
        db_session.flush()
        db_session.add_all(BillLine(bill_id=bill.id, **asdict(line)) for line in computation.lines)
    db_session.flush()

    stored = db_session.scalar(
        select(func.count()).select_from(Bill).where(Bill.meter_id == meter.id)
    )
    assert stored == len(simulated) == 9


def _after(bill):
    return bill.period_end + timedelta(days=1)
