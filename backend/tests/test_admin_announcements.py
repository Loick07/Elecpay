"""Tests de l'écran Notifications du back-office (B10.7, A9) : annonces (cibles, envoi,
programmation, taux de lecture) et interrupteurs généraux des alertes automatiques."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.db.base import utcnow
from app.modules.announcements.models import Announcement, AnnouncementStatus, Audience
from app.modules.announcements.service import send_due_announcements
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.daily_alerts import run_daily_alerts
from app.modules.notifications.models import Notification, NotificationType
from app.modules.users.models import UserRole
from tests.db_helpers import expect_db_rejection
from tests.factories import make_bill, make_household, make_member, make_meter, make_user

URL = "/api/v1/admin/announcements"
SETTINGS_URL = "/api/v1/admin/alert-settings"
BODY = "E²C annonce une coupure jeudi de 8 h à 12 h pour travaux sur le réseau."


@pytest.fixture
def world(db_session):
    arnaud = make_user(db_session, full_name="Arnaud Mavoungou")
    grace = make_user(db_session, full_name="Grâce Ngoma")
    victor = make_user(db_session, full_name="Victor Malanda")
    paul = make_user(db_session, full_name="Paul Ibara")
    make_user(db_session, full_name="Compte Fermé", is_active=False)
    home = make_household(db_session, arnaud, name="Maison Mpita", district="Mpita")
    make_member(db_session, home, grace, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, victor, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    shop = make_household(db_session, paul, name="Boutique", district="Tié-Tié")
    make_bill(  # facture en retard depuis longtemps
        db_session, make_meter(db_session, shop), due_date=date(2026, 9, 30)
    )
    return {
        "arnaud": arnaud,
        "grace": grace,
        "victor": victor,
        "paul": paul,
        "support": make_user(db_session, role=UserRole.SUPPORT),
        "admin": make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala"),
    }


def preview(client, auth_headers, user, **params):
    return client.get(f"{URL}/audience", params=params, headers=auth_headers(user))


def create(client, auth_headers, user, **body):
    payload = {"title": "Coupure programmée", "body": BODY, "audience": "all"} | body
    return client.post(URL, json=payload, headers=auth_headers(user))


def announcements_of(session, user):
    return session.scalars(
        select(Notification).where(
            Notification.user_id == user.id, Notification.type == NotificationType.ANNOUNCEMENT
        )
    ).all()


# --- Cibles ---------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("params", "expected", "label"),
    [
        ({"audience": "all"}, 4, "Tous les clients"),  # ni l'équipe, ni le compte fermé
        ({"audience": "overdue"}, 1, "Clients avec une facture en retard"),
        ({"audience": "district", "district": " mpita "}, 3, "Quartier  mpita "),
    ],
)
def test_audience_preview(client, auth_headers, world, params, expected, label):
    response = preview(client, auth_headers, world["support"], **params)
    assert response.status_code == 200, response.text
    assert response.json()["recipients"] == expected
    assert response.json()["label"] == label


def test_one_client_preview(client, auth_headers, world):
    body = preview(
        client, auth_headers, world["support"], audience="client", user_id=world["paul"].id
    ).json()
    assert (body["recipients"], body["label"]) == (1, "Client : Paul Ibara")
    team = preview(
        client, auth_headers, world["support"], audience="client", user_id=world["admin"].id
    )
    assert team.status_code == 422


def test_districts(client, auth_headers, world):
    response = client.get(f"{URL}/districts", headers=auth_headers(world["support"]))
    assert {line["district"]: line["households"] for line in response.json()} == {
        "Mpita": 1,
        "Tié-Tié": 1,
    }


# --- Envoi immédiat -------------------------------------------------------------------------


def test_send_to_a_district_now(client, auth_headers, db_session, world):
    response = create(client, auth_headers, world["admin"], audience="district", district="Mpita")
    assert response.status_code == 201, response.text
    body = response.json()
    assert (body["status"], body["recipients"], body["read_rate_percent"]) == ("sent", 3, 0.0)
    assert body["audience_label"] == "Quartier Mpita"
    for name in ("arnaud", "grace", "victor"):
        (notice,) = announcements_of(db_session, world[name])
        assert (notice.title, notice.body) == ("Coupure programmée", BODY)
        assert notice.data_json == {"announcement_id": body["id"]}
    assert announcements_of(db_session, world["paul"]) == []

    # Grâce lit l'annonce dans l'application : le taux de lecture suit.
    read = client.post(
        f"/api/v1/notifications/{announcements_of(db_session, world['grace'])[0].id}/read",
        headers=auth_headers(world["grace"]),
    )
    assert read.status_code in (200, 204), read.text
    listed = client.get(URL, headers=auth_headers(world["support"])).json()["items"][0]
    assert (listed["read"], listed["read_rate_percent"]) == (1, 33.3)
    actions = db_session.scalars(
        select(AuditLog.action).where(AuditLog.entity_type == "announcement")
    ).all()
    assert sorted(actions) == ["announcement.create", "announcement.sent"]


def test_overdue_clients_only(client, auth_headers, db_session, world):
    create(client, auth_headers, world["admin"], audience="overdue")
    assert len(announcements_of(db_session, world["paul"])) == 1
    assert announcements_of(db_session, world["arnaud"]) == []


def test_nobody_to_send_to(client, auth_headers, world):
    response = create(client, auth_headers, world["admin"], audience="district", district="Inconnu")
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "ANNOUNCEMENT_REFUSED"


@pytest.mark.parametrize(
    "body",
    [
        {"audience": "district"},  # quartier manquant
        {"audience": "client"},  # client manquant
        {"audience": "all", "district": "Mpita"},  # quartier en trop
        {"title": "ab"},
        {"body": "Trop court"[:5]},
    ],
)
def test_invalid_announcements(client, auth_headers, world, body):
    assert create(client, auth_headers, world["admin"], **body).status_code == 422


def test_support_reads_but_does_not_send(client, auth_headers, world):
    assert client.get(URL, headers=auth_headers(world["support"])).status_code == 200
    assert create(client, auth_headers, world["support"]).status_code == 403
    assert client.get(URL, headers=auth_headers(world["arnaud"])).status_code == 403


# --- Programmation --------------------------------------------------------------------------


def test_scheduled_announcement_is_sent_by_the_task(client, auth_headers, db_session, world):
    at = (utcnow() + timedelta(hours=1)).replace(microsecond=0)
    response = create(client, auth_headers, world["admin"], scheduled_at=at.isoformat())
    assert response.status_code == 201, response.text
    body = response.json()
    assert (body["status"], body["recipients"], body["read_rate_percent"]) == (
        "scheduled",
        None,
        None,
    )
    assert announcements_of(db_session, world["paul"]) == []

    assert send_due_announcements(db_session, now=at - timedelta(minutes=1)) == []
    (sent,) = send_due_announcements(db_session, now=at)
    assert (sent.id, sent.status, sent.recipients) == (body["id"], AnnouncementStatus.SENT, 4)
    assert len(announcements_of(db_session, world["paul"])) == 1
    assert send_due_announcements(db_session, now=at + timedelta(hours=1)) == []  # une fois


def test_cancel_a_scheduled_announcement(client, auth_headers, db_session, world):
    at = utcnow() + timedelta(days=2)
    created = create(client, auth_headers, world["admin"], scheduled_at=at.isoformat()).json()
    path = f"{URL}/{created['id']}/cancel"
    response = client.post(path, headers=auth_headers(world["admin"]))
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "cancelled"
    assert send_due_announcements(db_session, now=at + timedelta(hours=1)) == []
    assert client.post(path, headers=auth_headers(world["admin"])).status_code == 409
    sent = create(client, auth_headers, world["admin"]).json()
    refused = client.post(f"{URL}/{sent['id']}/cancel", headers=auth_headers(world["admin"]))
    assert refused.status_code == 409


@pytest.mark.parametrize("delay", [timedelta(minutes=1), timedelta(days=91)])
def test_schedule_window(client, auth_headers, world, delay):
    at = utcnow() + delay
    response = create(client, auth_headers, world["admin"], scheduled_at=at.isoformat())
    assert response.status_code == 422


def test_the_database_guards_announcements(db_session, world):
    with expect_db_rejection(db_session, "ck_announcements_audience_is_complete"):
        db_session.add(
            Announcement(
                title="Titre",
                body=BODY,
                audience=Audience.DISTRICT,  # sans quartier
                status=AnnouncementStatus.SCHEDULED,
                scheduled_at=utcnow(),
                created_by=world["admin"].id,
            )
        )
    with expect_db_rejection(db_session, "ck_announcements_status_is_complete"):
        db_session.add(
            Announcement(
                title="Titre",
                body=BODY,
                audience=Audience.ALL,
                status=AnnouncementStatus.SENT,  # sans date ni destinataires
                created_by=world["admin"].id,
            )
        )


# --- Alertes automatiques -------------------------------------------------------------------


def test_alert_settings_default_and_update(client, auth_headers, db_session, world):
    body = client.get(SETTINGS_URL, headers=auth_headers(world["support"])).json()
    assert (body["due_soon"], body["overdue"], body["high_consumption"]) == (True, True, True)
    assert body["updated_by"] is None
    switches = {"due_soon": False, "overdue": True, "high_consumption": False}
    support = client.put(SETTINGS_URL, json=switches, headers=auth_headers(world["support"]))
    assert support.status_code == 403
    response = client.put(SETTINGS_URL, json=switches, headers=auth_headers(world["admin"]))
    assert response.status_code == 200, response.text
    assert response.json()["due_soon"] is False
    assert response.json()["updated_by"] == "Christelle Mabiala"
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "alerts.settings")).one()
    assert (log.before_json["due_soon"], log.after_json["due_soon"]) == (True, False)


def test_switched_off_alerts_are_not_sent(client, auth_headers, db_session, world):
    today = date(2026, 11, 12)
    due_soon = make_bill(
        db_session,
        make_meter(db_session, make_household(db_session, world["arnaud"])),
        issued_at=datetime(2026, 11, 3, 7, tzinfo=UTC),
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=today + timedelta(days=5),
    )
    late = make_bill(  # échue hier : passe en retard aujourd'hui
        db_session,
        make_meter(db_session, make_household(db_session, world["victor"])),
        issued_at=datetime(2026, 10, 20, 7, tzinfo=UTC),
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=today - timedelta(days=1),
    )
    client.put(
        SETTINGS_URL,
        json={"due_soon": False, "overdue": False, "high_consumption": True},
        headers=auth_headers(world["admin"]),
    )
    counts = run_daily_alerts(db_session, today=today)
    db_session.refresh(late)
    assert late.status is BillStatus.OVERDUE  # le statut change quand même
    assert (counts["overdue"], counts["overdue_notices"], counts["due_soon"]) == (2, 0, 0)
    sent = db_session.scalars(
        select(Notification.type).where(
            Notification.user_id.in_([world["arnaud"].id, world["victor"].id, world["paul"].id])
        )
    ).all()
    assert sent == []
    assert due_soon.status is BillStatus.UNPAID
