"""Tests de la pagination commune et des relevés bruts (B5.5)."""

from datetime import date, timedelta

import pytest

from app.core.pagination import MAX_PAGE_SIZE, Page, PageParams
from app.core.timezone import local_midnight_utc
from app.modules.households.models import Household, MemberRole, MemberStatus
from app.simulators.persistence import insert_readings
from app.simulators.readings import SimulatedReading
from tests.factories import make_household, make_member, make_meter, make_user

FIRST_DAY, LAST_DAY = date(2026, 10, 1), date(2026, 11, 11)  # 42 journées + le relevé de départ
READINGS = (LAST_DAY - FIRST_DAY).days + 2


@pytest.fixture
def owner(db_session):
    return make_user(db_session)


@pytest.fixture
def meter(db_session, owner):
    meter = make_meter(db_session, make_household(db_session, owner))
    readings, index, day = (
        [SimulatedReading(local_midnight_utc(FIRST_DAY), 1_000_000, 0)],
        1_000_000,
        FIRST_DAY,
    )
    while day <= LAST_DAY:
        index += 10_000
        is_anomaly = day == date(2026, 11, 5)
        readings.append(
            SimulatedReading(
                local_midnight_utc(day + timedelta(days=1)),
                index,
                10_000,
                is_estimated=day == date(2026, 11, 2),
                is_anomaly=is_anomaly,
                anomaly_reason="Index lu en baisse" if is_anomaly else None,
            )
        )
        day += timedelta(days=1)
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    return meter


def readings(client, headers, meter, **params):
    return client.get(f"/api/v1/meters/{meter.id}/readings", params=params, headers=headers)


# --- Format de pagination -----------------------------------------------------------


def test_default_page_follows_the_common_format(client, auth_headers, owner, meter):
    body = readings(client, auth_headers(owner), meter).json()
    assert set(body) == {"items", "total", "page", "size"}
    assert (body["total"], body["page"], body["size"]) == (READINGS, 1, 20)
    assert len(body["items"]) == 20


def test_most_recent_first(client, auth_headers, owner, meter):
    items = readings(client, auth_headers(owner), meter).json()["items"]
    assert items[0]["day"] == "2026-11-11"
    assert items[0]["read_at"].startswith("2026-11-11T23:00:00")  # minuit au Congo, en UTC
    days = [item["day"] for item in items]
    assert days == sorted(days, reverse=True)


def test_pages_cover_everything_without_duplicates(client, auth_headers, owner, meter):
    seen = []
    for page in (1, 2, 3):
        seen += [
            i["id"]
            for i in readings(client, auth_headers(owner), meter, page=page, size=20).json()[
                "items"
            ]
        ]
    assert len(seen) == len(set(seen)) == READINGS


def test_last_page_is_incomplete(client, auth_headers, owner, meter):
    body = readings(client, auth_headers(owner), meter, page=3, size=20).json()
    assert len(body["items"]) == READINGS - 40


def test_page_after_the_end_is_empty_not_an_error(client, auth_headers, owner, meter):
    response = readings(client, auth_headers(owner), meter, page=99)
    assert response.status_code == 200
    assert response.json()["items"] == [] and response.json()["total"] == READINGS


@pytest.mark.parametrize(
    "params", [{"page": 0}, {"size": 0}, {"size": MAX_PAGE_SIZE + 1}, {"page": "un"}]
)
def test_invalid_pagination(client, auth_headers, owner, meter, params):
    assert readings(client, auth_headers(owner), meter, **params).status_code == 422


def test_maximum_page_size(client, auth_headers, owner, meter):
    assert len(readings(client, auth_headers(owner), meter, size=100).json()["items"]) == READINGS


def test_page_params_offset():
    assert PageParams(page=3, size=20).offset == 40
    assert Page[int](items=[1], total=1, page=1, size=20).model_dump() == {
        "items": [1],
        "total": 1,
        "page": 1,
        "size": 20,
    }


# --- Contenu d'un relevé ------------------------------------------------------------


def test_reading_content(client, auth_headers, owner, meter):
    items = readings(client, auth_headers(owner), meter, size=100).json()["items"]
    by_day = {item["day"]: item for item in items}
    assert by_day["2026-11-02"]["is_estimated"] is True
    assert (by_day["2026-11-05"]["is_anomaly"], by_day["2026-11-05"]["anomaly_reason"]) == (
        True,
        "Index lu en baisse",
    )
    first = by_day["2026-10-01"]
    assert (first["index_wh"], first["consumption_wh"], first["consumption_kwh"]) == (
        1_010_000,
        10_000,
        10.0,
    )
    assert first["source"] == "simulated"


# --- Filtres ------------------------------------------------------------------------


def test_filter_on_consumed_days(client, auth_headers, owner, meter):
    body = readings(
        client, auth_headers(owner), meter, **{"from": "2026-11-01", "to": "2026-11-07"}
    ).json()
    assert body["total"] == 7
    assert [i["day"] for i in body["items"]] == [f"2026-11-0{d}" for d in range(7, 0, -1)]


def test_reversed_filter(client, auth_headers, owner, meter):
    response = readings(
        client, auth_headers(owner), meter, **{"from": "2026-11-07", "to": "2026-11-01"}
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "INVALID_RANGE"


# --- Accès --------------------------------------------------------------------------


def test_viewer_can_read_and_stranger_cannot(client, auth_headers, meter, db_session):
    viewer = make_user(db_session)
    household = db_session.get(Household, meter.household_id)
    make_member(db_session, household, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    assert readings(client, auth_headers(viewer), meter).status_code == 200
    assert readings(client, auth_headers(make_user(db_session)), meter).status_code == 404


def test_requires_login(client, meter):
    assert client.get(f"/api/v1/meters/{meter.id}/readings").status_code == 401
