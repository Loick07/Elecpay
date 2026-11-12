"""Tests du moteur d'agrégation de la consommation (B5.1)."""

from dataclasses import replace
from datetime import date, timedelta

import pytest

from app.core.calendar import add_months, days_in_month, month_end
from app.modules.consumption.aggregation import (
    Granularity,
    Period,
    aggregate,
    daily_values,
    period_containing,
    periods_between,
)
from app.simulators.readings import PROFILES, ProfileName, generate_readings

FIRST, LAST = date(2025, 5, 1), date(2026, 11, 11)
TODAY = date(2026, 11, 12)


@pytest.fixture(scope="module")
def readings():
    return generate_readings(
        PROFILES[ProfileName.FAMILY], FIRST, LAST, start_index_wh=14_000_000, seed=42
    )


@pytest.fixture(scope="module")
def values(readings):
    return daily_values(readings, starting_reading_at=readings[0].read_at)


# --- Calendrier ---------------------------------------------------------------------


def test_calendar_helpers():
    assert add_months(date(2025, 11, 1), 2) == date(2026, 1, 1)
    assert add_months(date(2026, 1, 1), -3) == date(2025, 10, 1)
    assert month_end(date(2028, 2, 10)) == date(2028, 2, 29)  # bissextile
    assert days_in_month(date(2026, 2, 1)) == 28


# --- Périodes -----------------------------------------------------------------------


@pytest.mark.parametrize(
    ("granularity", "start", "end"),
    [
        (Granularity.DAY, date(2026, 10, 14), date(2026, 10, 14)),
        (Granularity.WEEK, date(2026, 10, 12), date(2026, 10, 18)),  # lundi → dimanche
        (Granularity.MONTH, date(2026, 10, 1), date(2026, 10, 31)),
        (Granularity.BIMESTER, date(2026, 9, 1), date(2026, 10, 31)),  # comme les factures E²C
        (Granularity.QUARTER, date(2026, 10, 1), date(2026, 12, 31)),
        (Granularity.SEMESTER, date(2026, 7, 1), date(2026, 12, 31)),
        (Granularity.YEAR, date(2026, 1, 1), date(2026, 12, 31)),
    ],
)
def test_period_containing_wednesday_14_october_2026(granularity, start, end):
    assert period_containing(date(2026, 10, 14), granularity) == Period(start, end)


def test_bimesters_match_the_real_bill():
    """Facture réelle : « Juillet-Août 2026 »."""
    assert period_containing(date(2026, 8, 20), Granularity.BIMESTER) == Period(
        date(2026, 7, 1), date(2026, 8, 31)
    )


def test_week_across_two_years():
    assert period_containing(date(2027, 1, 1), Granularity.WEEK) == Period(
        date(2026, 12, 28), date(2027, 1, 3)
    )


@pytest.mark.parametrize(
    ("granularity", "count"),
    [
        (Granularity.DAY, 31),
        (Granularity.MONTH, 1),
        (Granularity.WEEK, 5),  # 1er oct. 2026 = jeudi → 5 semaines touchées
    ],
)
def test_periods_between_october_2026(granularity, count):
    periods = periods_between(date(2026, 10, 1), date(2026, 10, 31), granularity)
    assert len(periods) == count
    assert all(
        b.start == a.end + timedelta(days=1) for a, b in zip(periods, periods[1:], strict=False)
    )


def test_periods_between_refuses_reversed_dates():
    with pytest.raises(ValueError, match="postérieure"):
        periods_between(date(2026, 2, 1), date(2026, 1, 1), Granularity.DAY)


# --- Valeurs journalières -----------------------------------------------------------


def test_one_value_per_day_and_the_starting_reading_is_not_a_day(readings, values):
    assert len(values) == (LAST - FIRST).days + 1
    assert min(values) == FIRST  # pas la veille du premier jour
    assert max(values) == LAST


def test_reading_at_midnight_belongs_to_the_previous_day(readings, values):
    # Le relevé du 1er novembre 2026 à 0 h (Brazzaville) porte la journée du 31 octobre.
    reading = next(r for r in readings if r.read_at.date() == date(2026, 10, 31))
    assert values[date(2026, 10, 31)].index_end_wh == reading.index_wh


def test_a_window_in_the_middle_keeps_its_first_day(readings):
    window = [r for r in readings if r.read_at.date() >= date(2026, 9, 30)]
    values = daily_values(window, starting_reading_at=readings[0].read_at)
    assert date(2026, 9, 30) in values  # rien n'est perdu au début de la fenêtre


# --- Agrégation ---------------------------------------------------------------------


@pytest.mark.parametrize("granularity", list(Granularity))
def test_totals_are_identical_whatever_the_granularity(values, granularity):
    """Le total sur la période couverte ne dépend pas du découpage."""
    periods = periods_between(FIRST, LAST, granularity)
    total = sum(p.consumption_wh for p in aggregate(values, periods, today=TODAY))
    assert total == sum(v.consumption_wh for v in values.values())


def test_months_of_2025_add_up_to_the_year(values):
    year = aggregate(
        values, periods_between(date(2025, 1, 1), date(2025, 12, 31), Granularity.YEAR), today=TODAY
    )
    months = aggregate(
        values,
        periods_between(date(2025, 1, 1), date(2025, 12, 31), Granularity.MONTH),
        today=TODAY,
    )
    assert year[0].consumption_wh == sum(m.consumption_wh for m in months)


def test_total_equals_index_difference(readings, values):
    """Ce que mesure le compteur : différence d'index entre deux minuits."""
    october = aggregate(values, [Period(date(2026, 10, 1), date(2026, 10, 31))], today=TODAY)[0]
    by_day = {r.read_at.date(): r for r in readings}  # read_at UTC = veille à 23 h
    start_index = by_day[date(2026, 9, 30)].index_wh  # minuit au début du 1er octobre
    end_index = by_day[date(2026, 10, 31)].index_wh  # minuit au début du 1er novembre
    # Les relevés d'un 1er du mois ne sont jamais des anomalies (garanti par le simulateur).
    assert october.consumption_wh == end_index - start_index


def test_complete_month_flags(values):
    october = aggregate(
        values, [period_containing(date(2026, 10, 1), Granularity.MONTH)], today=TODAY
    )[0]
    assert october.days_with_data == 31
    assert not october.is_partial and not october.is_current
    assert october.daily_average_wh == october.consumption_wh // 31


def test_current_month_is_partial_and_current(values):
    november = aggregate(values, [period_containing(TODAY, Granularity.MONTH)], today=TODAY)[0]
    assert november.days_with_data == 11  # du 1er au 11 : aujourd'hui n'est pas encore relevé
    assert november.is_partial and november.is_current


def test_estimated_and_anomaly_flags(values):
    day = min(values)
    estimated = {**values, day: replace(values[day], is_estimated=True)}
    anomaly = {**values, day: replace(values[day], is_anomaly=True)}
    period = [Period(day, day)]
    assert aggregate(estimated, period, today=TODAY)[0].is_estimated
    flagged = aggregate(anomaly, period, today=TODAY)[0]
    assert flagged.is_estimated and flagged.has_anomaly
    assert not aggregate(values, period, today=TODAY)[0].has_anomaly


def test_period_without_data(values):
    empty = aggregate(values, [Period(date(2024, 1, 1), date(2024, 1, 31))], today=TODAY)[0]
    assert (empty.consumption_wh, empty.days_with_data, empty.daily_average_wh) == (0, 0, 0)
    assert empty.is_partial


def test_kwh_is_for_display_only(values):
    october = aggregate(values, [Period(date(2026, 10, 1), date(2026, 10, 31))], today=TODAY)[0]
    assert october.consumption_kwh == round(october.consumption_wh / 1_000, 3)
    assert isinstance(october.consumption_wh, int)
