"""Tests de la lecture des notifications (B9.1, écran client 13)."""

from datetime import UTC, datetime

import pytest

from app.modules.notifications.models import Notification, NotificationType
from app.modules.notifications.queries import NotificationQueries
from tests.factories import make_notification, make_user

# Jeudi 12 novembre 2026, 11 h à Brazzaville (10 h UTC). Lundi de la semaine : le 9.
NOW = datetime(2026, 11, 12, 10, 0, tzinfo=UTC)
URL = "/api/v1/notifications"


@pytest.fixture(autouse=True)
def fixed_now(monkeypatch):
    original = NotificationQueries.__init__
    monkeypatch.setattr(
        NotificationQueries,
        "__init__",
        lambda self, session, now=None: original(self, session, lambda: NOW),
    )


def at(day, hour, minute=0, month=11):
    return datetime(2026, month, day, hour, minute, tzinfo=UTC)


@pytest.fixture
def inbox(db_session):
    """Les notifications d'Arnaud (heures en UTC ; Brazzaville = UTC+1)."""
    me = make_user(db_session)

    def notice(created_at, *, read=False, kind=NotificationType.BILL_ISSUED, **data):
        return make_notification(
            db_session,
            me,
            type=kind,
            created_at=created_at,
            updated_at=created_at,
            read_at=created_at if read else None,
            data_json=data or None,
        )

    notices = {
        "today": notice(at(12, 8), kind=NotificationType.PAYMENT_SUCCEEDED, receipt_id=3),
        "midnight": notice(at(11, 23)),  # 12/11 à 0 h 00 à Brazzaville : aujourd'hui
        "late_yesterday": notice(at(11, 22, 59)),  # 11/11 à 23 h 59 : cette semaine
        "monday": notice(at(8, 23)),  # lundi 9/11 à 0 h 00 : cette semaine
        "sunday": notice(at(8, 22, 59), read=True),  # dimanche 8/11 à 23 h 59 : plus tôt
        "october": notice(at(1, 9, month=10), read=True),
        "future": notice(at(12, 12)),  # annoncée pour 13 h : pas encore visible
    }
    make_notification(
        db_session, make_user(db_session), created_at=at(12, 9)
    )  # à quelqu'un d'autre
    return me, notices


def get(client, headers, **params):
    return client.get(URL, params=params, headers=headers)


def ids(response):
    return [item["id"] for item in response.json()["items"]]


def notice_ids(notices, *names):
    return [notices[name].id for name in names]


# --- Liste ----------------------------------------------------------------------------------


def test_my_notifications_most_recent_first_with_groups(client, auth_headers, inbox):
    me, notices = inbox
    body = get(client, auth_headers(me)).json()
    order = ("today", "midnight", "late_yesterday", "monday", "sunday", "october")
    assert [item["id"] for item in body["items"]] == notice_ids(notices, *order)
    assert [item["group"] for item in body["items"]] == [
        "today",
        "today",
        "this_week",
        "this_week",
        "earlier",
        "earlier",
    ]
    assert (body["total"], body["unread_count"]) == (6, 4)


def test_a_notification_has_what_the_screen_needs(client, auth_headers, inbox):
    me, notices = inbox
    first = get(client, auth_headers(me)).json()["items"][0]
    assert first["type"] == "payment_succeeded"
    assert (first["title"], first["body"]) == (notices["today"].title, notices["today"].body)
    assert first["data"] == {"receipt_id": 3}
    assert (first["is_read"], first["read_at"]) == (False, None)
    assert first["created_at"] == "2026-11-12T08:00:00Z"


def test_unread_only(client, auth_headers, inbox):
    me, notices = inbox
    response = get(client, auth_headers(me), unread_only=True)
    assert ids(response) == notice_ids(notices, "today", "midnight", "late_yesterday", "monday")
    assert response.json()["unread_count"] == 4


def test_a_notification_appears_only_from_its_time(client, auth_headers, inbox):
    me, notices = inbox
    assert notices["future"].id not in ids(get(client, auth_headers(me)))
    response = client.post(f"{URL}/{notices['future'].id}/read", headers=auth_headers(me))
    assert response.status_code == 404


def test_pagination(client, auth_headers, inbox):
    me, notices = inbox
    response = get(client, auth_headers(me), page=2, size=4)
    assert ids(response) == notice_ids(notices, "sunday", "october")
    assert response.json()["unread_count"] == 4  # le badge ne dépend pas de la page


def test_unread_count_badge(client, auth_headers, inbox):
    me, _ = inbox
    response = client.get(f"{URL}/unread-count", headers=auth_headers(me))
    assert response.json() == {"unread_count": 4}


def test_someone_new_has_an_empty_inbox(client, auth_headers, db_session):
    body = get(client, auth_headers(make_user(db_session))).json()
    assert (body["items"], body["total"], body["unread_count"]) == ([], 0, 0)


# --- Marquer comme lu ----------------------------------------------------------------------------


def test_mark_one_as_read_keeps_the_first_reading_date(client, auth_headers, db_session, inbox):
    me, notices = inbox
    target = notices["monday"]
    first = client.post(f"{URL}/{target.id}/read", headers=auth_headers(me))
    assert first.status_code == 200
    assert (first.json()["is_read"], first.json()["read_at"]) == (True, "2026-11-12T10:00:00Z")
    again = client.post(f"{URL}/{target.id}/read", headers=auth_headers(me))
    assert again.json()["read_at"] == "2026-11-12T10:00:00Z"
    assert client.get(f"{URL}/unread-count", headers=auth_headers(me)).json() == {"unread_count": 3}


def test_an_already_read_notification_stays_as_it_was(client, auth_headers, inbox):
    me, notices = inbox
    response = client.post(f"{URL}/{notices['october'].id}/read", headers=auth_headers(me))
    assert response.json()["read_at"] == "2026-10-01T09:00:00Z"


def test_someone_elses_notification_looks_like_a_missing_one(
    client, auth_headers, db_session, inbox
):
    me, notices = inbox
    stranger = auth_headers(make_user(db_session))
    theirs = client.post(f"{URL}/{notices['today'].id}/read", headers=stranger)
    missing = client.post(f"{URL}/999999999/read", headers=stranger)
    assert theirs.status_code == missing.status_code == 404
    assert theirs.json() == missing.json()
    assert theirs.json()["error"]["code"] == "NOTIFICATION_NOT_FOUND"
    db_session.refresh(notices["today"])
    assert notices["today"].read_at is None


def test_mark_all_as_read(client, auth_headers, db_session, inbox):
    me, notices = inbox
    response = client.post(f"{URL}/read-all", headers=auth_headers(me))
    assert response.json() == {"marked": 4, "unread_count": 0}
    assert client.post(f"{URL}/read-all", headers=auth_headers(me)).json() == {
        "marked": 0,
        "unread_count": 0,
    }
    db_session.expire_all()
    assert db_session.get(Notification, notices["future"].id).read_at is None  # pas encore là
    assert db_session.get(Notification, notices["october"].id).read_at == at(1, 9, month=10)


def test_read_all_never_touches_someone_elses(client, auth_headers, db_session, inbox):
    me, _ = inbox
    other = make_user(db_session)
    theirs = make_notification(db_session, other, created_at=at(12, 9))
    client.post(f"{URL}/read-all", headers=auth_headers(me))
    db_session.refresh(theirs)
    assert theirs.read_at is None


@pytest.mark.parametrize(
    ("method", "path"),
    [("GET", ""), ("GET", "/unread-count"), ("POST", "/read-all"), ("POST", "/1/read")],
)
def test_login_is_required(client, method, path):
    assert client.request(method, URL + path).status_code == 401
