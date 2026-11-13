"""Critères de l'étape B9 (backend/PLAN.md), testés de bout en bout à travers l'API.

- Routes : liste, marquer lu / tout lu, badge des non lues.
- « Événements : nouvelle facture, échéance proche, facture en retard, paiement réussi / échoué,
  invitation reçue, consommation anormale. »
+ les interrupteurs de l'écran 14, réglés par l'API, qui changent ce qui arrive dans l'écran 13.
Chaque point est aussi testé en détail dans test_notifications_api.py,
test_notification_preferences.py et test_daily_alerts.py.
"""

import re
from datetime import date, timedelta
from pathlib import Path

import pytest

from app.core.timezone import local_midnight_utc
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.daily_alerts import run_daily_alerts
from app.modules.notifications.models import NotificationType
from app.modules.notifications.queries import NotificationQueries
from app.modules.payments.confirmation import apply_provider_update
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_reading,
    make_transaction,
    make_user,
)

APP = Path(__file__).resolve().parents[1] / "app"
DUE = date(2026, 11, 20)
TODAY = DUE - timedelta(days=5)  # dimanche 15/11 : rappel « dans 5 jours »
NOW = local_midnight_utc(TODAY) + timedelta(hours=10)  # 10 h à Brazzaville


@pytest.fixture(autouse=True)
def fixed_now(monkeypatch):
    original = NotificationQueries.__init__
    monkeypatch.setattr(
        NotificationQueries,
        "__init__",
        lambda self, session, now=None: original(self, session, lambda: NOW),
    )


@pytest.fixture
def family(db_session):
    owner, payer = make_user(db_session), make_user(db_session, full_name="Grâce Ngoma")
    home = make_household(db_session, owner, name="Maison Mpita")
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home)
    bill = make_bill(
        db_session,
        meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=DUE,
    )
    return {"owner": owner, "payer": payer, "meter": meter, "bill": bill}


def inbox(client, headers, **params):
    return client.get("/api/v1/notifications", params=params, headers=headers).json()


def badge(client, headers):
    return client.get("/api/v1/notifications/unread-count", headers=headers).json()["unread_count"]


# --- De l'événement à l'écran 13 -----------------------------------------------------------


def test_from_due_date_reminder_to_read(client, auth_headers, db_session, family):
    headers = auth_headers(family["owner"])
    run_daily_alerts(db_session, today=TODAY)

    body = inbox(client, headers)
    (notice,) = body["items"]
    assert (notice["type"], notice["title"], notice["group"]) == (
        "bill_due_soon",
        "Échéance dans 5 jours",
        "today",
    )
    assert notice["data"]["bill_id"] == family["bill"].id  # ouvre la facture (écran 7)
    assert body["unread_count"] == badge(client, headers) == 1

    client.post(f"/api/v1/notifications/{notice['id']}/read", headers=headers)
    assert badge(client, headers) == 0
    assert inbox(client, headers, unread_only=True)["items"] == []


def test_a_payment_shows_up_with_its_receipt_then_read_all(
    client, auth_headers, db_session, family
):
    payer = auth_headers(family["payer"])
    transaction = make_transaction(db_session, family["bill"], family["payer"])
    at = NOW - timedelta(hours=1)
    update = ProviderUpdate("SIM-B9", ProviderState.SUCCEEDED, at, amount=40_384)
    apply_provider_update(db_session, transaction.id, update, origin="test", now=at)

    titles = {item["title"]: item for item in inbox(client, payer)["items"]}
    assert set(titles) == {"Paiement réussi"}
    assert titles["Paiement réussi"]["data"]["receipt_id"]  # ouvre le reçu (écran 10)
    owner_titles = [item["title"] for item in inbox(client, auth_headers(family["owner"]))["items"]]
    assert owner_titles == ["Facture payée"]

    assert client.post("/api/v1/notifications/read-all", headers=payer).json() == {
        "marked": 1,
        "unread_count": 0,
    }


# --- Les interrupteurs de l'écran 14 changent ce qui arrive ------------------------------------


def test_switches_set_through_the_api_change_what_arrives(client, auth_headers, db_session, family):
    owner = auth_headers(family["owner"])
    client.patch("/api/v1/me/notification-preferences", json={"due_soon": False}, headers=owner)
    run_daily_alerts(db_session, today=TODAY)
    assert inbox(client, owner)["items"] == []  # rappel coupé : rien
    assert badge(client, auth_headers(family["payer"])) == 1  # le payeur, lui, est prévenu


def test_unusual_consumption_arrives_once_switched_on(client, auth_headers, db_session, family):
    owner = auth_headers(family["owner"])
    index = 1_000_000
    for offset in range(31):  # 30 journées à 10 kWh, puis hier à 15 kWh
        wh = 15_000 if offset == 30 else 10_000
        index += wh
        make_reading(
            db_session,
            family["meter"],
            read_at=local_midnight_utc(TODAY - timedelta(days=30 - offset)),
            index_wh=index,
            consumption_wh=wh,
        )
    run_daily_alerts(db_session, today=TODAY)
    assert [i["type"] for i in inbox(client, owner)["items"]] == ["bill_due_soon"]  # coupée

    client.patch(
        "/api/v1/me/notification-preferences", json={"high_consumption": True}, headers=owner
    )
    run_daily_alerts(db_session, today=TODAY)
    types = sorted(item["type"] for item in inbox(client, owner)["items"])
    assert types == ["bill_due_soon", "high_consumption"]


# --- Tous les événements du plan ont une source --------------------------------------------


@pytest.mark.parametrize(
    "kind",
    [
        NotificationType.BILL_ISSUED,  # nouvelle facture (relevé quotidien)
        NotificationType.BILL_DUE_SOON,  # échéance proche (B9.3)
        NotificationType.BILL_OVERDUE,  # retard + rappels (B6, B9.3)
        NotificationType.PAYMENT_SUCCEEDED,  # paiement réussi (B7, avec le reçu en B8)
        NotificationType.PAYMENT_FAILED,  # paiement échoué ou expiré (B7)
        NotificationType.INVITATION_RECEIVED,  # invitation dans un foyer (B4)
        NotificationType.CONSUMPTION_ANOMALY,  # relevé anormal (relevé quotidien)
        NotificationType.HIGH_CONSUMPTION,  # consommation inhabituelle (B9.3)
    ],
)
def test_every_planned_event_is_produced_somewhere(kind):
    """Garde-fou : chaque type d'événement du plan est émis quelque part dans app/
    (les annonces de l'équipe arrivent avec B10)."""
    pattern = re.compile(rf"NotificationType\.{kind.name}\b")
    producers = [
        path
        for path in APP.rglob("*.py")
        if path.name != "models.py"
        and "notifications/service.py" not in path.as_posix()
        and pattern.search(path.read_text(encoding="utf-8"))
    ]
    assert producers, f"aucune source pour {kind.value}"
