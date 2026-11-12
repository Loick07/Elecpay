"""Tests de la série de consommation (B5.3) : GET /meters/{id}/consumption."""

from datetime import date

import pytest

from app.modules.consumption.aggregation import Granularity, Period
from app.modules.consumption.labels import period_label
from app.modules.consumption.service import ConsumptionService, one_year_earlier
from app.modules.households.models import Household, MemberRole, MemberStatus
from app.simulators.persistence import insert_readings
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.factories import make_household, make_member, make_meter, make_tariff, make_user

TODAY = date(2026, 11, 12)
FIRST, LAST = date(2025, 5, 1), date(2026, 11, 11)


@pytest.fixture(autouse=True)
def fixed_today(monkeypatch):
    original = ConsumptionService.__init__
    monkeypatch.setattr(
        ConsumptionService,
        "__init__",
        lambda self, session, settings, today=None: original(
            self, session, settings, lambda: TODAY
        ),
    )


@pytest.fixture
def owner(db_session):
    return make_user(db_session)


@pytest.fixture
def meter(db_session, owner):
    make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))
    home = make_household(db_session, owner)
    meter = make_meter(db_session, home)
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY], FIRST, LAST, start_index_wh=14_000_000, seed=42
    )
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    return meter


def series(client, headers, meter, **params):
    return client.get(f"/api/v1/meters/{meter.id}/consumption", params=params, headers=headers)


# --- Vue Année (défaut) -------------------------------------------------------------


def test_default_view_is_this_year_by_month(client, auth_headers, owner, meter):
    response = series(client, auth_headers(owner), meter)
    assert response.status_code == 200
    body = response.json()
    assert (body["granularity"], body["start"], body["end"]) == (
        "month",
        "2026-01-01",
        "2026-12-31",
    )
    assert [p["label"] for p in body["points"][:3]] == ["Janv. 2026", "Févr. 2026", "Mars 2026"]
    assert len(body["points"]) == 12
    assert body["measured_until"] == "2026-11-11"  # hier : jamais « temps réel »
    assert body["source"] == "simulated"
    assert body["tariff_is_assumption"] is True


def test_each_point_has_both_costs_and_its_state(client, auth_headers, owner, meter):
    points = series(client, auth_headers(owner), meter).json()["points"]
    october, november, december = points[9], points[10], points[11]
    assert october["days_with_data"] == 31 and not october["is_partial"]
    assert october["energy_cost"] > 0 and october["estimated_total"] > october["energy_cost"]
    assert october["consumption_kwh"] == round(october["consumption_wh"] / 1000, 3)
    assert (november["is_current"], november["is_partial"], november["days_with_data"]) == (
        True,
        True,
        11,
    )
    assert december["consumption_wh"] == 0 and december["days_with_data"] == 0


def test_last_year_comparison_uses_the_same_days(client, auth_headers, owner, meter):
    comparison = series(client, auth_headers(owner), meter).json()["comparison"]
    assert comparison["mode"] == "last_year"
    assert (comparison["current"]["start"], comparison["current"]["end"]) == (
        "2026-01-01",
        "2026-11-11",
    )
    assert (comparison["reference"]["start"], comparison["reference"]["end"]) == (
        "2025-01-01",
        "2025-11-11",
    )
    # Les relevés commencent le 1er mai 2025 : la référence n'a que ces journées-là.
    assert comparison["reference"]["days_with_data"] == (date(2025, 11, 11) - FIRST).days + 1
    current, reference = (
        comparison["current"]["consumption_wh"],
        comparison["reference"]["consumption_wh"],
    )
    assert comparison["variation_percent"] == round((current - reference) * 100 / reference, 1)


# --- Autres vues --------------------------------------------------------------------


def test_month_view_day_by_day(client, auth_headers, owner, meter):
    body = series(client, auth_headers(owner), meter, granularity="day").json()
    assert (body["start"], body["end"]) == ("2026-11-01", "2026-11-30")  # le mois en cours
    assert body["points"][0]["label"] == "Dim. 1 nov."
    assert body["points"][0]["estimated_total"] is None  # pas de facture d'un jour
    assert body["comparison"]["mode"] == "previous"


def test_week_view_compared_with_the_previous_week(client, auth_headers, owner, meter):
    body = series(
        client,
        auth_headers(owner),
        meter,
        granularity="day",
        **{"from": "2026-11-09", "to": "2026-11-15"},
    ).json()
    assert len(body["points"]) == 7
    comparison = body["comparison"]
    assert (comparison["current"]["start"], comparison["current"]["end"]) == (
        "2026-11-09",
        "2026-11-11",
    )
    assert (comparison["reference"]["start"], comparison["reference"]["end"]) == (
        "2026-11-02",
        "2026-11-04",
    )


def test_bimesters_like_the_bills(client, auth_headers, owner, meter):
    body = series(
        client,
        auth_headers(owner),
        meter,
        granularity="bimester",
        **{"from": "2026-07-01", "to": "2026-08-31"},
    ).json()
    (bimester,) = body["points"]
    assert bimester["label"] == "Juil.-Août 2026"


@pytest.mark.parametrize(
    ("granularities", "first", "last"),
    [
        (("day", "month", "quarter"), "2026-01-01", "2026-03-31"),  # premier trimestre
        (("day", "week"), "2026-01-05", "2026-03-29"),  # du lundi 5 janv. au dimanche 29 mars
    ],
)
def test_totals_do_not_depend_on_the_granularity(
    client, auth_headers, owner, meter, granularities, first, last
):
    totals = set()
    for granularity in granularities:
        params = {"granularity": granularity, "from": first, "to": last}
        points = series(client, auth_headers(owner), meter, **params).json()["points"]
        assert (points[0]["start"], points[-1]["end"]) == (first, last)  # plage bien alignée
        totals.add(sum(p["consumption_wh"] for p in points))
    assert len(totals) == 1


# --- Accès --------------------------------------------------------------------------


@pytest.mark.parametrize("role", [MemberRole.PAYER, MemberRole.VIEWER])
def test_every_member_can_see_the_consumption(client, auth_headers, meter, db_session, role):
    member = make_user(db_session)
    household = db_session.get(Household, meter.household_id)
    make_member(db_session, household, member, role=role, status=MemberStatus.ACTIVE)
    assert series(client, auth_headers(member), meter).status_code == 200


def test_stranger_gets_not_found(client, auth_headers, meter, db_session):
    assert series(client, auth_headers(make_user(db_session)), meter).status_code == 404


def test_requires_login(client, meter):
    assert client.get(f"/api/v1/meters/{meter.id}/consumption").status_code == 401


# --- Erreurs de plage ---------------------------------------------------------------


def test_reversed_range(client, auth_headers, owner, meter):
    response = series(
        client, auth_headers(owner), meter, **{"from": "2026-03-01", "to": "2026-01-01"}
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_RANGE"


def test_too_long_range_for_daily_view(client, auth_headers, owner, meter):
    response = series(
        client,
        auth_headers(owner),
        meter,
        granularity="day",
        **{"from": "2025-01-01", "to": "2026-12-31"},
    )
    assert response.status_code == 400
    assert response.json()["error"]["details"] == {"max_days": 400}


@pytest.mark.parametrize(
    "params", [{"granularity": "hour"}, {"from": "pas-une-date"}, {"compare": "demain"}]
)
def test_invalid_parameters(client, auth_headers, owner, meter, params):
    assert series(client, auth_headers(owner), meter, **params).status_code == 422


def test_meter_without_readings(client, auth_headers, owner, db_session):
    empty = make_meter(db_session, make_household(db_session, owner))
    body = series(client, auth_headers(owner), empty).json()
    assert body["measured_until"] is None and body["comparison"] is None
    assert body["source"] == "none"
    assert all(p["consumption_wh"] == 0 for p in body["points"])


# --- Petites fonctions --------------------------------------------------------------


@pytest.mark.parametrize(
    ("granularity", "period", "label"),
    [
        (Granularity.DAY, Period(date(2026, 10, 14), date(2026, 10, 14)), "Mer. 14 oct."),
        (Granularity.WEEK, Period(date(2026, 10, 12), date(2026, 10, 18)), "Sem. du 12 oct."),
        (Granularity.MONTH, Period(date(2026, 10, 1), date(2026, 10, 31)), "Oct. 2026"),
        (Granularity.BIMESTER, Period(date(2026, 7, 1), date(2026, 8, 31)), "Juil.-Août 2026"),
        (Granularity.QUARTER, Period(date(2026, 10, 1), date(2026, 12, 31)), "T4 2026"),
        (Granularity.SEMESTER, Period(date(2026, 1, 1), date(2026, 6, 30)), "S1 2026"),
        (Granularity.YEAR, Period(date(2026, 1, 1), date(2026, 12, 31)), "2026"),
    ],
)
def test_french_labels(granularity, period, label):
    assert period_label(period, granularity) == label


def test_one_year_earlier_handles_leap_days():
    assert one_year_earlier(date(2028, 2, 29)) == date(2027, 2, 28)
    assert one_year_earlier(date(2026, 11, 11)) == date(2025, 11, 11)
