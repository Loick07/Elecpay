"""Tests du coût estimé d'une période (B5.2)."""

from dataclasses import dataclass, replace
from datetime import date, timedelta

import pytest

from app.modules.bills.calculator import energy_amount
from app.modules.consumption.aggregation import (
    DailyValue,
    Granularity,
    Period,
    daily_values,
    period_containing,
)
from app.modules.consumption.costs import estimate_cost, tariff_on, whole_months
from app.simulators.bills import generate_bills
from app.simulators.readings import PROFILES, ProfileName, generate_readings


@dataclass(frozen=True)
class Tariff:
    """Tarif de la vraie facture E²C (hypothèses : frais fixes mensuels, RAV par facture)."""

    id: int = 1
    valid_from: date = date(2025, 1, 1)
    valid_to: date | None = None
    is_assumption: bool = True
    price_per_kwh_milli: int = 49_080
    fixed_fee_per_month: int = 2_550
    vat_rate_bp: int = 1_800
    additional_tax_rate_bp: int = 500
    audiovisual_fee: int = 1_000
    stamp_fee: int = 0


E2C = Tariff()
JULY_AUGUST = Period(date(2026, 7, 1), date(2026, 8, 31))


def estimate(values, period, tariffs=(E2C,)):
    return estimate_cost(values, period, list(tariffs), billing_period_months=2)


def days(period, consumption_wh=0):
    values, day = {}, period.start
    while day <= period.end:
        values[day] = DailyValue(day, consumption_wh, 0, False, False)
        day += timedelta(days=1)
    return values


def real_bill_values():
    """571 kWh répartis sur juillet-août 2026, comme la vraie facture."""
    values = days(JULY_AUGUST, 9_209)
    values[date(2026, 8, 31)] = replace(values[date(2026, 8, 31)], consumption_wh=9_251)
    assert sum(v.consumption_wh for v in values.values()) == 571_000
    return values


# --- La vraie facture ---------------------------------------------------------------


def test_reproduces_the_real_e2c_bill():
    cost = estimate(real_bill_values(), JULY_AUGUST)
    assert cost.energy_cost == 28_024  # énergie seule (maquette)
    assert cost.estimated_total == 40_384  # « TOTAL A PAYER » de la facture
    assert cost.months_count == 2
    assert cost.is_assumption  # le tarif n'est pas encore vérifié


@pytest.mark.parametrize("seed", range(5))
def test_estimate_of_a_billed_bimester_equals_the_issued_bill(seed):
    """La facture estimée d'un bimestre complet = la facture émise, au franc près."""
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY],
        date(2025, 5, 1),
        date(2026, 10, 31),
        start_index_wh=10_000_000,
        seed=seed,
    )
    values = daily_values(readings, starting_reading_at=readings[0].read_at)
    bills = generate_bills(
        readings,
        E2C,
        period_months=2,
        issue_delay_days=3,
        due_delay_days=15,
        as_of=date(2026, 11, 12),
    )
    for bill in bills:
        cost = estimate(values, Period(bill.period_start, bill.period_end))
        assert cost.estimated_total == bill.computation.amount_total
        assert cost.energy_cost == bill.computation.lines[0].amount


def test_two_monthly_estimates_are_within_a_few_francs_of_the_bill():
    """Effet attendu de la troncature ligne par ligne (documenté dans le plan)."""
    values = real_bill_values()
    july = estimate(values, Period(date(2026, 7, 1), date(2026, 7, 31)))
    august = estimate(values, Period(date(2026, 8, 1), date(2026, 8, 31)))
    assert abs(july.estimated_total + august.estimated_total - 40_384) <= 5


# --- Prorata des redevances ---------------------------------------------------------


@pytest.mark.parametrize(
    ("period", "months", "expected_total"),
    [
        # Sans consommation : frais fixes + TVA + C.A. + RAV au prorata.
        (Period(date(2026, 7, 1), date(2026, 7, 31)), 1, 2_550 + 459 + 22 + 500),
        (Period(date(2026, 7, 1), date(2026, 9, 30)), 3, 7_650 + 1_377 + 68 + 1_500),
    ],
)
def test_audiovisual_fee_is_spread_over_the_months(period, months, expected_total):
    cost = estimate(days(period), period)
    assert cost.months_count == months
    assert cost.estimated_total == expected_total


# --- Tarifs ---------------------------------------------------------------------------


def test_price_change_in_the_middle_of_a_month():
    """Chaque tranche de jours garde le prix de son tarif."""
    old = replace(E2C, id=1, valid_to=date(2026, 7, 16))
    new = replace(E2C, id=2, valid_from=date(2026, 7, 16), price_per_kwh_milli=52_000)
    july = Period(date(2026, 7, 1), date(2026, 7, 31))
    cost = estimate(days(july, 10_000), july, [old, new])
    assert cost.energy_cost == energy_amount(15 * 10_000, 49_080) + energy_amount(
        16 * 10_000, 52_000
    )


def test_no_tariff_means_no_cost():
    july = Period(date(2026, 7, 1), date(2026, 7, 31))
    cost = estimate(days(july, 10_000), july, [])
    assert (cost.energy_cost, cost.estimated_total) == (None, None)
    assert cost.unpriced_days == 31


def test_days_before_the_first_tariff_are_reported():
    july = Period(date(2026, 7, 1), date(2026, 7, 31))
    late_tariff = replace(E2C, valid_from=date(2026, 7, 10))
    cost = estimate(days(july, 10_000), july, [late_tariff])
    assert (cost.priced_days, cost.unpriced_days) == (22, 9)


def test_verified_tariff_is_not_flagged_as_assumption():
    cost = estimate(real_bill_values(), JULY_AUGUST, [replace(E2C, is_assumption=False)])
    assert cost.is_assumption is False


def test_tariff_on_uses_the_valid_period():
    old = replace(E2C, id=1, valid_to=date(2026, 7, 16))
    new = replace(E2C, id=2, valid_from=date(2026, 7, 16))
    assert tariff_on(date(2026, 7, 15), [old, new]).id == 1
    assert tariff_on(date(2026, 7, 16), [old, new]).id == 2  # valid_to exclu
    assert tariff_on(date(2024, 1, 1), [old, new]) is None


# --- Périodes courtes et périodes incomplètes ---------------------------------------


@pytest.mark.parametrize("granularity", [Granularity.DAY, Granularity.WEEK])
def test_no_estimated_bill_for_less_than_a_month(granularity):
    period = period_containing(date(2026, 7, 15), granularity)
    cost = estimate(days(period, 10_000), period)
    assert cost.energy_cost is not None
    assert (cost.estimated_total, cost.months_count) == (None, None)


def test_current_month_is_estimated_on_the_days_so_far():
    november = Period(date(2026, 11, 1), date(2026, 11, 30))
    so_far = days(Period(date(2026, 11, 1), date(2026, 11, 11)), 10_000)
    cost = estimate(so_far, november)
    assert cost.priced_days == 11
    assert cost.energy_cost == energy_amount(110_000, 49_080)


def test_no_estimated_bill_beyond_twelve_months():
    """Bug trouvé en vérification réelle : une comparaison sur 18 mois provoquait une erreur 500."""
    eighteen_months = Period(date(2025, 5, 1), date(2026, 10, 31))
    cost = estimate(days(eighteen_months, 10_000), eighteen_months)
    assert cost.months_count == 18
    assert cost.estimated_total is None
    assert cost.energy_cost == energy_amount(10_000 * eighteen_months.days, 49_080)


@pytest.mark.parametrize(
    ("period", "months"),
    [
        (Period(date(2026, 1, 1), date(2026, 12, 31)), 12),
        (Period(date(2026, 2, 1), date(2026, 2, 28)), 1),
        (Period(date(2026, 2, 2), date(2026, 2, 28)), None),
        (Period(date(2026, 2, 1), date(2026, 2, 27)), None),
    ],
)
def test_whole_months(period, months):
    assert whole_months(period) == months
