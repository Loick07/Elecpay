"""Tests du simulateur de relevés (B2.2)."""

from dataclasses import asdict
from datetime import UTC, date, datetime, timedelta
from statistics import mean

import pytest
from sqlalchemy import func, select

from app.core.timezone import CONGO_TZ, local_date, local_midnight_utc
from app.modules.consumption.models import MeterReading, ReadingSource
from app.simulators.readings import PROFILES, ProfileName, generate_readings, seasonal_factor
from tests.factories import make_meter

FIRST = date(2025, 5, 1)
LAST = date(2026, 10, 31)  # 18 mois
DAYS = (LAST - FIRST).days + 1


def simulate(profile=ProfileName.FAMILY, seed=42, first=FIRST, last=LAST, start=14_000_000):
    return generate_readings(PROFILES[profile], first, last, start_index_wh=start, seed=seed)


def daily(readings):
    """Les relevés journaliers non anormaux (sans le relevé de départ)."""
    return [r for r in readings[1:] if not r.is_anomaly]


# --- Fuseau horaire -----------------------------------------------------------------


def test_local_midnight_in_congo_is_23h_utc_the_day_before():
    assert local_midnight_utc(date(2026, 9, 1)) == datetime(2026, 8, 31, 23, 0, tzinfo=UTC)
    assert local_date(datetime(2026, 8, 31, 23, 0, tzinfo=UTC)) == date(2026, 9, 1)
    assert CONGO_TZ.utcoffset(None) == timedelta(hours=1)


# --- Structure ----------------------------------------------------------------------


@pytest.mark.parametrize("profile", list(ProfileName))
def test_one_reading_per_day_plus_the_starting_one(profile):
    readings = simulate(profile)
    assert len(readings) == DAYS + 1
    assert readings[0].read_at == local_midnight_utc(FIRST)
    assert readings[0].consumption_wh == 0
    assert readings[-1].read_at == local_midnight_utc(LAST + timedelta(days=1))
    for previous, current in zip(readings, readings[1:], strict=False):
        assert current.read_at - previous.read_at == timedelta(days=1)
        assert current.read_at.tzinfo is not None


@pytest.mark.parametrize("profile", list(ProfileName))
def test_values_are_integers(profile):
    for reading in simulate(profile):
        assert type(reading.index_wh) is int
        assert type(reading.consumption_wh) is int
        assert reading.consumption_wh >= 0


# --- Index et consommation ----------------------------------------------------------


@pytest.mark.parametrize("seed", range(10))
def test_real_index_never_decreases(seed):
    valid = [r for r in simulate(seed=seed) if not r.is_anomaly]
    assert all(b.index_wh >= a.index_wh for a, b in zip(valid, valid[1:], strict=False))


@pytest.mark.parametrize("seed", range(10))
def test_consumption_is_the_difference_with_the_last_valid_index(seed):
    readings = simulate(seed=seed)
    last_valid = readings[0].index_wh
    for reading in readings[1:]:
        if reading.is_anomaly:
            assert reading.consumption_wh == 0
            continue
        assert reading.consumption_wh == reading.index_wh - last_valid
        last_valid = reading.index_wh


@pytest.mark.parametrize("seed", range(10))
def test_consumption_sums_match_index_differences_between_month_starts(seed):
    """Ce que vérifiera la facturation : somme des relevés = nouvel index − ancien index."""
    readings = simulate(seed=seed)
    month_starts = [r for r in readings if local_date(r.read_at).day == 1]
    for start, end in zip(month_starts, month_starts[1:], strict=False):
        assert not start.is_anomaly and not end.is_anomaly
        in_month = [r for r in readings if start.read_at < r.read_at <= end.read_at]
        assert sum(r.consumption_wh for r in in_month) == end.index_wh - start.index_wh


# --- Anomalies, coupures, estimations -----------------------------------------------


def test_anomalies_are_rare_marked_and_readable_as_decreasing():
    all_anomalies = []
    for seed in range(20):
        readings = simulate(seed=seed)
        for previous_valid, reading in _with_last_valid(readings):
            if reading.is_anomaly:
                all_anomalies.append(reading)
                assert reading.index_wh < previous_valid.index_wh
                assert reading.anomaly_reason
                assert local_date(reading.read_at).day != 1
    assert 0 < len(all_anomalies) < 20 * DAYS * 0.01  # il y en a, mais rarement


def test_last_reading_is_never_an_anomaly():
    assert all(not simulate(seed=seed)[-1].is_anomaly for seed in range(30))


def test_some_readings_are_estimated_but_few():
    readings = simulate()
    estimated = [r for r in readings if r.is_estimated]
    assert 0 < len(estimated) < 0.05 * len(readings)
    assert not any(r.is_estimated and r.is_anomaly for r in readings)


def test_outages_produce_low_consumption_days():
    readings = daily(simulate())
    assert any(r.consumption_wh < 0.6 * 9_200 * 0.8 for r in readings)


# --- Réalisme des profils -----------------------------------------------------------


@pytest.mark.parametrize(
    ("profile", "low", "high"),
    [
        (ProfileName.SMALL_HOUSEHOLD, 3_000, 5_000),
        (ProfileName.FAMILY, 8_000, 11_000),  # vraie facture : ~9,2 kWh/jour
        (ProfileName.SHOP, 17_000, 27_000),
    ],
)
def test_average_daily_consumption_matches_the_profile(profile, low, high):
    readings = simulate(profile)
    total = readings[-1].index_wh - readings[0].index_wh
    assert low <= total / DAYS <= high


def test_shop_consumes_much_less_on_sunday():
    readings = daily(simulate(ProfileName.SHOP))
    by_weekday = {
        weekday: mean(
            r.consumption_wh
            for r in readings
            if (local_date(r.read_at) - timedelta(days=1)).weekday() == weekday
        )
        for weekday in range(7)
    }
    assert by_weekday[6] < 0.6 * by_weekday[2]  # dimanche << mercredi


def test_hot_season_consumes_more_than_dry_season():
    readings = daily(simulate(ProfileName.FAMILY))

    def average(months):
        return mean(
            r.consumption_wh
            for r in readings
            if (local_date(r.read_at) - timedelta(days=1)).month in months
        )

    assert average({2, 3, 4}) > average({7, 8, 9}) * 1.1


def test_seasonal_factor_peaks_in_march_and_is_lowest_in_september():
    assert seasonal_factor(date(2026, 3, 15), 0.15) == pytest.approx(1.15)
    assert seasonal_factor(date(2026, 9, 14), 0.15) == pytest.approx(0.85, abs=0.01)


# --- Reproductibilité ---------------------------------------------------------------


def test_same_seed_gives_exactly_the_same_readings():
    assert simulate(seed=7) == simulate(seed=7)


def test_different_seeds_give_different_readings():
    assert simulate(seed=7) != simulate(seed=8)


# --- Entrées refusées ---------------------------------------------------------------


def test_reversed_dates_are_refused():
    with pytest.raises(ValueError, match="last_day"):
        simulate(first=date(2026, 2, 1), last=date(2026, 1, 31))


@pytest.mark.parametrize(
    ("start", "error"), [(-1, ValueError), (1.5, TypeError), (True, TypeError)]
)
def test_invalid_start_index_is_refused(start, error):
    with pytest.raises(error):
        simulate(start=start)


def test_single_day_gives_two_readings():
    readings = simulate(first=date(2026, 1, 10), last=date(2026, 1, 10))
    assert len(readings) == 2
    assert not readings[-1].is_anomaly


# --- Les relevés s'enregistrent tels quels en base ----------------------------------


def test_simulated_readings_are_accepted_by_the_database(db_session):
    meter = make_meter(db_session)
    readings = simulate(seed=3)
    db_session.add_all(
        MeterReading(meter_id=meter.id, source=ReadingSource.SIMULATED, **asdict(r))
        for r in readings
    )
    db_session.flush()
    stored = db_session.scalar(
        select(func.count()).select_from(MeterReading).where(MeterReading.meter_id == meter.id)
    )
    assert stored == DAYS + 1


def _with_last_valid(readings):
    """(dernier relevé valide avant, relevé) pour chaque relevé journalier."""
    last_valid = readings[0]
    for reading in readings[1:]:
        yield last_valid, reading
        if not reading.is_anomaly:
            last_valid = reading
