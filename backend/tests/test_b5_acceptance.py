"""Critères de l'étape B5 (backend/PLAN.md), testés à travers l'API.

- « Chaque valeur indique si elle est estimée. Jamais présentée comme « temps réel ». »
- « Estimation de fin de mois en kWh et en FCFA, avec le tarif en vigueur. »
- Vue par période (demande de Loick) : mois, bimestre, trimestre, semestre, année,
  en kWh et en coût estimé.
+ le parcours de l'écran Consommation (maquette client 11) : Année → Mois → Semaine → Jour.
Chaque point est aussi testé en détail dans test_consumption_*.py et test_readings_api.py.
"""

from datetime import date

import pytest

from app.modules.consumption.service import ConsumptionService
from app.simulators.persistence import insert_readings
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.factories import make_household, make_meter, make_tariff, make_user

TODAY = date(2026, 11, 12)


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
    meter = make_meter(db_session, make_household(db_session, owner))
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY],
        date(2025, 5, 1),
        date(2026, 11, 11),
        start_index_wh=9_000_000,
        seed=7,
    )
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    return meter


def get(client, headers, meter, path="", **params):
    response = client.get(
        f"/api/v1/meters/{meter.id}/consumption{path}", params=params, headers=headers
    )
    assert response.status_code == 200, response.text
    return response.json()


# --- Critère 1 : chaque valeur dit si elle est estimée ; jamais « temps réel » -------


def test_criterion_every_value_states_whether_it_is_estimated(client, auth_headers, owner, meter):
    headers = auth_headers(owner)
    series = get(
        client, headers, meter, granularity="day", **{"from": "2026-10-01", "to": "2026-11-30"}
    )
    for point in series["points"]:
        assert {"is_estimated", "has_anomaly", "is_partial", "is_current"} <= set(point)
    assert series["measured_until"] == "2026-11-11"  # la veille : des relevés, pas du direct
    assert series["source"] == "simulated"  # mode démo : jamais présenté comme réel
    day = get(client, headers, meter, "/days/2026-11-10")
    assert "is_estimated" in day and "is_anomaly" in day


# --- Critère 2 : estimation de fin de mois en kWh ET en FCFA ------------------------


def test_criterion_month_end_estimate_in_kwh_and_fcfa(client, auth_headers, owner, meter):
    estimate = get(client, auth_headers(owner), meter, "/summary")["month_end_estimate"]
    assert estimate["consumption_kwh"] > 0
    assert estimate["energy_cost"] > 0 and estimate["estimated_total"] > estimate["energy_cost"]
    assert isinstance(estimate["energy_cost"], int) and isinstance(estimate["estimated_total"], int)


# --- Critère 3 : la vue par période, en kWh et en coût estimé -----------------------


@pytest.mark.parametrize(
    ("granularity", "count"),
    [("month", 12), ("bimester", 6), ("quarter", 4), ("semester", 2), ("year", 2)],
)
def test_criterion_period_views(client, auth_headers, owner, meter, granularity, count):
    series = get(
        client,
        auth_headers(owner),
        meter,
        granularity=granularity,
        # Juillet 2025 → juin 2026 : aligné sur mois, bimestres, trimestres et semestres.
        **{"from": "2025-07-01", "to": "2026-06-30"},
    )
    full = [p for p in series["points"] if not p["is_partial"]]
    assert all(p["energy_cost"] > 0 and p["estimated_total"] > p["energy_cost"] for p in full)
    assert len(series["points"]) == count  # « year » : 2025 et 2026 sont touchées


def test_long_range_with_comparison_does_not_crash(client, auth_headers, owner, meter):
    """Bug trouvé en vérification réelle : 18 mois en bimestres renvoyait une erreur 500
    (la comparaison tentait une « facture estimée » de 18 mois)."""
    series = get(
        client,
        auth_headers(owner),
        meter,
        granularity="bimester",
        **{"from": "2025-05-01", "to": "2026-10-31"},
    )
    assert len(series["points"]) == 9
    assert series["comparison"]["current"]["energy_cost"] > 0


# --- Le parcours de l'écran Consommation --------------------------------------------


def test_consumption_screen_journey_year_month_week_day(client, auth_headers, owner, meter):
    headers = auth_headers(owner)

    year = get(client, headers, meter)  # onglet Année (par défaut)
    october = next(p for p in year["points"] if p["label"] == "Oct. 2026")
    assert year["comparison"]["mode"] == "last_year"

    month = get(
        client,
        headers,
        meter,
        granularity="day",
        **{"from": october["start"], "to": october["end"]},
    )
    assert len(month["points"]) == 31
    assert sum(p["consumption_wh"] for p in month["points"]) == october["consumption_wh"]

    week = get(
        client, headers, meter, granularity="day", **{"from": "2026-10-12", "to": "2026-10-18"}
    )
    wednesday = week["points"][2]
    assert wednesday["label"] == "Mer. 14 oct."
    assert week["comparison"]["mode"] == "previous"

    day = get(client, headers, meter, "/days/2026-10-14")
    assert day["consumption_wh"] == wednesday["consumption_wh"]
    assert 1 <= day["rank_in_month"] <= 31
    assert day["index_end_wh"] - day["index_start_wh"] == day["consumption_wh"] or day["is_anomaly"]
