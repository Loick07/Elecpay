"""Tests de l'écran Compteurs du back-office (B10.4, A4)."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.core.timezone import local_midnight_utc
from app.modules.admin.meters import AdminMeters
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.consumption.models import AnomalyStatus
from app.modules.meters.models import MeterStatus
from app.modules.users.models import UserRole
from tests.db_helpers import expect_db_rejection
from tests.factories import make_bill, make_household, make_meter, make_reading, make_user

# Jeudi 12 novembre 2026, 14 h 45 à Brazzaville (13 h 45 UTC).
NOW = datetime(2026, 11, 12, 13, 45, tzinfo=UTC)
TODAY = local_midnight_utc(date(2026, 11, 12))  # relevé de ce matin (minuit)
YESTERDAY = TODAY - timedelta(days=1)
URL = "/api/v1/admin/meters"
REASON = "Index relevé inférieur au relevé précédent (erreur de lecture probable)"


@pytest.fixture(autouse=True)
def fixed_now(monkeypatch):
    original = AdminMeters.__init__
    monkeypatch.setattr(
        AdminMeters,
        "__init__",
        lambda self, session, now=None: original(self, session, lambda: NOW),
    )


def anomaly(session, meter, read_at=TODAY, index_wh=14_850_000):
    return make_reading(
        session,
        meter,
        read_at=read_at,
        index_wh=index_wh,
        consumption_wh=0,
        is_anomaly=True,
        anomaly_reason=REASON,
    )


@pytest.fixture
def world(db_session):
    owner = make_user(db_session, full_name="Arnaud Mavoungou")
    home = make_household(db_session, owner, name="Maison Mpita", district="Mpita")
    received = make_meter(db_session, home, reference="0412-8833", label="Maison")
    make_reading(db_session, received, read_at=YESTERDAY, index_wh=14_844_000)
    make_reading(db_session, received, read_at=TODAY, index_wh=14_854_000, consumption_wh=10_000)
    broken = make_meter(db_session, home, reference="0219-7741")
    make_reading(db_session, broken, read_at=YESTERDAY, index_wh=14_854_000)
    bad = anomaly(db_session, broken)
    missing = make_meter(db_session, make_household(db_session), reference="0377-1209")
    suspended = make_meter(
        db_session, make_household(db_session), reference="0500-0001", status=MeterStatus.SUSPENDED
    )
    loose = make_meter(db_session, None, reference="0600-0002")
    return {
        "owner": owner,
        "home": home,
        "received": received,
        "broken": broken,
        "bad": bad,
        "missing": missing,
        "suspended": suspended,
        "loose": loose,
        "support": make_user(db_session, role=UserRole.SUPPORT),
        "admin": make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala"),
    }


def listing(client, auth_headers, user, **params):
    response = client.get(URL, params=params, headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def references(body):
    return [item["reference"] for item in body["items"]]


def post(client, auth_headers, user, path, body):
    return client.post(URL + path, json=body, headers=auth_headers(user))


# --- Liste ----------------------------------------------------------------------------------


def test_each_meter_has_its_state_of_the_day(client, auth_headers, world):
    body = listing(client, auth_headers, world["support"])
    states = {item["reference"]: item["today_status"] for item in body["items"]}
    assert states == {
        "0219-7741": "anomaly",
        "0377-1209": "missing",
        "0412-8833": "received",
        "0500-0001": "inactive",
        "0600-0002": "inactive",
    }
    assert body["day"] == "2026-11-12"
    row = next(item for item in body["items"] if item["reference"] == "0412-8833")
    assert row["household_name"] == "Maison Mpita"
    assert row["district"] == "Mpita"
    assert row["owner_name"] == "Arnaud Mavoungou"
    assert row["today_index_wh"] == 14_854_000
    assert next(i for i in body["items"] if i["reference"] == "0219-7741")["open_anomalies"] == 1


def test_counters_at_the_top_of_the_screen(client, auth_headers, world, db_session):
    # Anomalie à traiter mais vieille de plus de 30 jours : hors du compteur du haut,
    # toujours visible dans le détail du compteur.
    anomaly(db_session, world["broken"], read_at=TODAY - timedelta(days=31), index_wh=1_000)
    counters = listing(client, auth_headers, world["support"], today="missing")["counters"]
    assert counters == {
        "attached": 4,
        "received_today": 2,
        "missing_today": 1,
        "open_anomalies": 1,
        "control_requested": 0,
        "inactive": 2,
    }


@pytest.mark.parametrize(
    ("params", "expected"),
    [
        ({"today": "anomaly"}, ["0219-7741"]),
        ({"today": "missing"}, ["0377-1209"]),
        ({"today": "received"}, ["0412-8833"]),
        ({"today": "inactive"}, ["0500-0001", "0600-0002"]),
        ({"attached": "false"}, ["0600-0002"]),
        ({"q": "mavoungou"}, ["0219-7741", "0412-8833"]),
        ({"q": "8833"}, ["0412-8833"]),
        ({"q": "Mpita"}, ["0219-7741", "0412-8833"]),
    ],
)
def test_filters_and_search(client, auth_headers, world, params, expected):
    assert references(listing(client, auth_headers, world["support"], **params)) == expected


def test_clients_have_no_access(client, auth_headers, world):
    assert client.get(URL, headers=auth_headers(world["owner"])).status_code == 403


# --- Détail ---------------------------------------------------------------------------------


def test_detail_of_a_meter_in_anomaly(client, auth_headers, world, db_session):
    make_bill(db_session, world["broken"], due_date=date(2026, 9, 30))
    response = client.get(f"{URL}/{world['broken'].id}", headers=auth_headers(world["support"]))
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["today_status"] == "anomaly"
    assert body["yesterday"]["index_wh"] == 14_854_000
    assert body["today"]["index_wh"] == 14_850_000
    assert body["explanation"].startswith(
        "Index lu ce matin : 14 850 kWh, inférieur au précédent (14 854 kWh hier)."
    )
    assert body["household"]["owner_name"] == "Arnaud Mavoungou"
    assert body["last_bill"]["status"] == "overdue"
    assert body["last_bill"]["period_label"] == "Juil.-Août 2026"
    (line,) = body["anomalies"]
    assert line["reading_id"] == world["bad"].id
    assert line["previous_index_wh"] == 14_854_000
    assert line["status"] is None
    assert len(body["recent_readings"]) == 2


@pytest.mark.parametrize(
    ("meter", "start"),
    [
        ("received", "Relevé normal : 10 kWh consommés hier."),
        ("missing", "Aucun relevé reçu ce matin"),
        ("loose", "Compteur détaché de tout foyer"),
        ("suspended", "Compteur suspendu ou résilié"),
    ],
)
def test_explanations(client, auth_headers, world, meter, start):
    body = client.get(f"{URL}/{world[meter].id}", headers=auth_headers(world["support"])).json()
    assert body["explanation"].startswith(start)


def test_unknown_meter(client, auth_headers, world):
    response = client.get(f"{URL}/999999", headers=auth_headers(world["support"]))
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "METER_NOT_FOUND"


# --- Anomalies ------------------------------------------------------------------------------


def anomaly_path(world, action):
    return f"/{world['broken'].id}/anomalies/{world['bad'].id}/{action}"


def test_request_a_control_reading(client, auth_headers, world, db_session):
    response = post(
        client, auth_headers, world["admin"], anomaly_path(world, "control"), {"note": None}
    )
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "control_requested"
    db_session.refresh(world["bad"])
    assert world["bad"].anomaly_status is AnomalyStatus.CONTROL_REQUESTED
    assert world["bad"].anomaly_handled_by == world["admin"].id
    assert world["bad"].is_anomaly  # le relevé lui-même ne change pas
    assert world["bad"].index_wh == 14_850_000
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "meter.anomaly_control"))
    assert log.one().after_json == {
        "reading_id": world["bad"].id,
        "status": "control_requested",
        "note": None,
    }
    counters = listing(client, auth_headers, world["support"])["counters"]
    assert (counters["open_anomalies"], counters["control_requested"]) == (0, 1)
    # Une seule demande : la seconde est refusée.
    again = post(client, auth_headers, world["admin"], anomaly_path(world, "control"), {})
    assert again.status_code == 409


def test_dismiss_needs_a_note_and_hides_the_anomaly(client, auth_headers, world, db_session):
    path = anomaly_path(world, "dismiss")
    assert post(client, auth_headers, world["admin"], path, {}).status_code == 422
    assert post(client, auth_headers, world["admin"], path, {"note": "ok"}).status_code == 422
    note = "Erreur de lecture ponctuelle"
    response = post(client, auth_headers, world["admin"], path, {"note": note})
    assert response.status_code == 200, response.text
    db_session.refresh(world["bad"])
    assert (world["bad"].anomaly_status, world["bad"].anomaly_note) == (
        AnomalyStatus.DISMISSED,
        note,
    )
    detail = client.get(
        f"{URL}/{world['broken'].id}", headers=auth_headers(world["support"])
    ).json()
    assert detail["anomalies"] == []
    assert detail["recent_readings"][0]["anomaly_status"] == "dismissed"
    assert post(client, auth_headers, world["admin"], path, {"note": note}).status_code == 409


def test_dismiss_after_a_control_request(client, auth_headers, world):
    post(client, auth_headers, world["admin"], anomaly_path(world, "control"), {})
    response = post(
        client,
        auth_headers,
        world["admin"],
        anomaly_path(world, "dismiss"),
        {"note": "Contrôle E²C : index correct"},
    )
    assert response.json()["status"] == "dismissed"


def test_anomaly_actions_are_checked(client, auth_headers, world):
    normal = f"/{world['received'].id}/anomalies/{world['bad'].id}/control"  # pas son compteur
    assert post(client, auth_headers, world["admin"], normal, {}).status_code == 404
    meter = world["received"]  # un compteur sans anomalie : son relevé du jour
    detail = client.get(f"{URL}/{meter.id}", headers=auth_headers(world["admin"])).json()
    not_anomaly = f"/{meter.id}/anomalies/{detail['today']['id']}/control"
    response = post(client, auth_headers, world["admin"], not_anomaly, {})
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "METER_ACTION_REFUSED"
    support = post(client, auth_headers, world["support"], anomaly_path(world, "control"), {})
    assert support.status_code == 403


def test_the_database_refuses_a_handling_on_a_normal_reading(db_session, world):
    normal = make_reading(db_session, world["missing"], read_at=YESTERDAY)
    with expect_db_rejection(db_session, "ck_meter_readings_anomaly_status_needs_anomaly"):
        normal.anomaly_status = AnomalyStatus.DISMISSED
        normal.anomaly_handled_by = world["admin"].id
        normal.anomaly_handled_at = NOW


def test_the_database_refuses_a_handling_without_author(db_session, world):
    with expect_db_rejection(db_session, "ck_meter_readings_anomaly_handling_complete"):
        world["bad"].anomaly_status = AnomalyStatus.DISMISSED


# --- Rattacher / détacher -------------------------------------------------------------------


def test_detach_then_attach_elsewhere(client, auth_headers, world, db_session):
    meter = world["received"]
    make_bill(db_session, meter, due_date=date(2099, 1, 1))
    reason = {"reason": "Déménagement du titulaire"}
    response = post(client, auth_headers, world["admin"], f"/{meter.id}/detach", reason)
    assert response.status_code == 200, response.text
    assert response.json() == {"meter_id": meter.id, "household_id": None, "unpaid_bills": 1}
    db_session.refresh(meter)
    assert meter.household_id is None

    target = make_household(db_session, name="Nouvel appartement")
    response = post(
        client,
        auth_headers,
        world["admin"],
        f"/{meter.id}/attach",
        {"household_id": target.id, "reason": "Nouveau titulaire"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["household_id"] == target.id
    actions = db_session.scalars(
        select(AuditLog.action).where(
            AuditLog.entity_type == "meter", AuditLog.entity_id == meter.id
        )
    ).all()
    assert sorted(actions) == ["meter.attach", "meter.detach"]


def test_detach_needs_a_reason_and_an_attached_meter(client, auth_headers, world):
    meter = world["received"]
    assert post(client, auth_headers, world["admin"], f"/{meter.id}/detach", {}).status_code == 422
    loose = post(
        client, auth_headers, world["admin"], f"/{world['loose'].id}/detach", {"reason": "Essai x"}
    )
    assert loose.status_code == 409
    support = post(
        client, auth_headers, world["support"], f"/{meter.id}/detach", {"reason": "Essai x"}
    )
    assert support.status_code == 403


def test_no_detach_while_a_payment_is_in_progress(client, auth_headers, world, db_session):
    make_bill(db_session, world["received"], status=BillStatus.PENDING_PAYMENT)
    response = post(
        client,
        auth_headers,
        world["admin"],
        f"/{world['received'].id}/detach",
        {"reason": "Déménagement"},
    )
    assert response.status_code == 409
    assert "paiement est en cours" in response.json()["error"]["message"]


def test_attach_checks_the_target(client, auth_headers, world, db_session):
    loose = world["loose"]
    attached = post(
        client,
        auth_headers,
        world["admin"],
        f"/{world['received'].id}/attach",
        {"household_id": world["home"].id, "reason": "Essai x"},
    )
    assert attached.status_code == 409  # déjà rattaché
    unknown = post(
        client,
        auth_headers,
        world["admin"],
        f"/{loose.id}/attach",
        {"household_id": 999_999, "reason": "Essai x"},
    )
    assert unknown.status_code == 404
    full = make_household(db_session)
    for _ in range(5):
        make_meter(db_session, full)
    limit = post(
        client,
        auth_headers,
        world["admin"],
        f"/{loose.id}/attach",
        {"household_id": full.id, "reason": "Essai x"},
    )
    assert limit.status_code == 409
    assert limit.json()["error"]["code"] == "METER_LIMIT_REACHED"
