"""Tests du résumé et du détail d'une journée (B5.4).

Relevés construits à la main pour que chaque attendu se calcule de tête :
10 kWh par jour du 1er octobre au 11 novembre 2026, sauf le mardi 3 novembre : 20 kWh.
"""

from datetime import date, timedelta

import pytest
from sqlalchemy import select

from app.core.timezone import local_midnight_utc
from app.modules.bills.calculator import energy_amount
from app.modules.consumption.costs import estimated_bill_total
from app.modules.consumption.models import MeterReading
from app.modules.consumption.service import ConsumptionService
from app.simulators.persistence import insert_readings
from app.simulators.readings import SimulatedReading
from tests.factories import make_household, make_meter, make_tariff, make_user

FIRST_DAY, LAST_DAY = date(2026, 10, 1), date(2026, 11, 11)
PEAK_DAY = date(2026, 11, 3)  # un mardi
START_INDEX = 1_000_000


def consumption_of(day):
    return 20_000 if day == PEAK_DAY else 10_000


@pytest.fixture
def clock(monkeypatch):
    """Date du jour réglable test par test (12 novembre par défaut)."""
    state = {"today": date(2026, 11, 12)}
    original = ConsumptionService.__init__
    monkeypatch.setattr(
        ConsumptionService,
        "__init__",
        lambda self, session, settings, today=None: original(
            self, session, settings, lambda: state["today"]
        ),
    )
    return state


@pytest.fixture
def owner(db_session):
    return make_user(db_session)


@pytest.fixture
def tariff(db_session):
    return make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))


@pytest.fixture
def meter(db_session, owner, tariff):
    meter = make_meter(db_session, make_household(db_session, owner))
    readings, index, day = (
        [SimulatedReading(local_midnight_utc(FIRST_DAY), START_INDEX, 0)],
        START_INDEX,
        FIRST_DAY,
    )
    while day <= LAST_DAY:
        index += consumption_of(day)
        readings.append(
            SimulatedReading(
                local_midnight_utc(day + timedelta(days=1)), index, consumption_of(day)
            )
        )
        day += timedelta(days=1)
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    return meter


def summary(client, headers, meter):
    return client.get(f"/api/v1/meters/{meter.id}/consumption/summary", headers=headers)


def day(client, headers, meter, value):
    return client.get(f"/api/v1/meters/{meter.id}/consumption/days/{value}", headers=headers)


# --- Résumé -------------------------------------------------------------------------


def test_this_month_so_far(client, auth_headers, owner, meter, clock):
    this_month = summary(client, auth_headers(owner), meter).json()["this_month"]
    assert (this_month["start"], this_month["end"]) == ("2026-11-01", "2026-11-11")
    assert this_month["days_with_data"] == 11
    assert this_month["consumption_wh"] == 10 * 10_000 + 20_000
    assert this_month["daily_average_wh"] == 120_000 // 11
    assert this_month["energy_cost"] == energy_amount(120_000, 49_080)
    assert this_month["highest_day"] == {
        "day": "2026-11-03",
        "consumption_wh": 20_000,
        "consumption_kwh": 20.0,
    }


def test_month_end_estimate(client, auth_headers, owner, meter, tariff, clock):
    estimate = summary(client, auth_headers(owner), meter).json()["month_end_estimate"]
    projected = 120_000 + (120_000 // 11) * 19  # relevé + moyenne × 19 jours restants
    assert estimate["basis"] == "current_month"
    assert estimate["remaining_days"] == 19
    assert estimate["consumption_wh"] == projected
    assert estimate["energy_cost"] == energy_amount(projected, 49_080)
    assert estimate["estimated_total"] == estimated_bill_total(
        projected, 1, tariff, billing_period_months=2
    )


def test_last_month_and_same_days_variation(client, auth_headers, owner, meter, tariff, clock):
    body = summary(client, auth_headers(owner), meter).json()
    last = body["last_month"]
    assert (last["start"], last["end"], last["days_with_data"]) == ("2026-10-01", "2026-10-31", 31)
    assert last["consumption_wh"] == 310_000
    assert last["estimated_total"] == estimated_bill_total(
        310_000, 1, tariff, billing_period_months=2
    )
    # Du 1er au 11 novembre (120 kWh) contre du 1er au 11 octobre (110 kWh).
    assert body["variation_percent"] == round((120_000 - 110_000) * 100 / 110_000, 1)


def test_first_day_of_the_month_uses_the_last_7_days(client, auth_headers, owner, meter, clock):
    clock["today"] = date(2026, 11, 1)  # le 1er : rien de relevé ce mois-ci
    body = summary(client, auth_headers(owner), meter).json()
    assert body["this_month"]["days_with_data"] == 0
    assert body["this_month"]["end"] is None and body["this_month"]["highest_day"] is None
    estimate = body["month_end_estimate"]
    assert estimate["basis"] == "last_7_days"
    assert (estimate["remaining_days"], estimate["consumption_wh"]) == (30, 30 * 10_000)
    assert body["variation_percent"] is None


def test_summary_is_flagged_as_not_real_time(client, auth_headers, owner, meter, clock):
    body = summary(client, auth_headers(owner), meter).json()
    assert body["measured_until"] == "2026-11-11"
    assert body["source"] == "simulated"
    assert body["tariff_is_assumption"] is True


def test_summary_of_a_meter_without_readings(
    client, auth_headers, owner, tariff, db_session, clock
):
    empty = make_meter(db_session, make_household(db_session, owner))
    body = summary(client, auth_headers(owner), empty).json()
    assert body["month_end_estimate"] is None
    assert body["this_month"]["consumption_wh"] == 0
    assert body["measured_until"] is None


# --- Détail d'une journée -----------------------------------------------------------


def test_day_detail(client, auth_headers, owner, meter, clock):
    body = day(client, auth_headers(owner), meter, "2026-11-03").json()
    index_start = START_INDEX + (PEAK_DAY - FIRST_DAY).days * 10_000
    assert body["label"] == "Mar. 3 nov."
    assert body["consumption_wh"] == 20_000
    assert body["energy_cost"] == energy_amount(20_000, 49_080)
    assert (body["index_start_wh"], body["index_end_wh"]) == (index_start, index_start + 20_000)
    assert (body["rank_in_month"], body["days_ranked"]) == (1, 11)
    assert body["is_estimated"] is False and body["is_anomaly"] is False
    assert body["source"] == "simulated"


def test_same_weekday_average(client, auth_headers, owner, meter, clock):
    body = day(client, auth_headers(owner), meter, "2026-11-03").json()
    # Mardis précédents relevés : 27, 20, 13 et 6 octobre (les relevés commencent le 1er oct.).
    assert (body["weekday_samples"], body["weekday_average_wh"]) == (4, 10_000)


def test_rank_with_ties(client, auth_headers, owner, meter, clock):
    body = day(client, auth_headers(owner), meter, "2026-11-05").json()
    assert body["rank_in_month"] == 2  # seul le 3 novembre consomme plus


def test_first_day_has_its_starting_index(client, auth_headers, owner, meter, clock):
    body = day(client, auth_headers(owner), meter, "2026-10-01").json()
    assert body["index_start_wh"] == START_INDEX
    assert body["weekday_samples"] == 0 and body["weekday_average_wh"] is None


def test_anomaly_is_shown_with_its_reason(client, auth_headers, owner, meter, db_session, clock):
    reading = db_session.scalars(
        select(MeterReading).where(
            MeterReading.meter_id == meter.id,
            MeterReading.read_at == local_midnight_utc(date(2026, 11, 10)),
        )
    ).one()
    reading.is_anomaly, reading.anomaly_reason = True, "Index lu en baisse"
    db_session.flush()
    body = day(client, auth_headers(owner), meter, "2026-11-09").json()
    assert (body["is_anomaly"], body["anomaly_reason"]) == (True, "Index lu en baisse")


@pytest.mark.parametrize("value", ["2026-11-12", "2026-09-30", "2030-01-01"])
def test_day_without_reading(client, auth_headers, owner, meter, clock, value):
    response = day(client, auth_headers(owner), meter, value)
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "CONSUMPTION_DAY_NOT_FOUND"


def test_invalid_day(client, auth_headers, owner, meter, clock):
    assert day(client, auth_headers(owner), meter, "32-13-2026").status_code == 422


# --- Accès --------------------------------------------------------------------------


def test_stranger_gets_not_found(client, auth_headers, meter, db_session, clock):
    stranger = auth_headers(make_user(db_session))
    assert summary(client, stranger, meter).status_code == 404
    assert day(client, stranger, meter, "2026-11-03").status_code == 404
