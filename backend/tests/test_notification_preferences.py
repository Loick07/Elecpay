"""Tests des préférences d'alertes (B9.2, interrupteurs « Me prévenir » de l'écran 14)."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import (
    Notification,
    NotificationPreference,
    NotificationType,
)
from app.modules.notifications.service import insert_notifications, notification_row
from app.modules.payments.confirmation import apply_provider_update
from app.modules.receipts.models import Receipt
from tests.db_helpers import expect_db_rejection
from tests.factories import (
    PAYMENT_START,
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_transaction,
    make_user,
)

URL = "/api/v1/me/notification-preferences"
DEFAULTS = {"due_soon": True, "payments": True, "high_consumption": False}
AT = datetime(2026, 11, 12, 9, tzinfo=UTC)


def row(user, kind):
    return notification_row(user.id, kind, "Titre", "Message", None, at=AT)


def received(session, user):
    return set(session.scalars(select(Notification.type).where(Notification.user_id == user.id)))


def switch(session, user, **values):
    session.add(NotificationPreference(user_id=user.id, **(DEFAULTS | values)))
    session.flush()


# --- Routes --------------------------------------------------------------------------------


def test_defaults_follow_the_mockup(client, auth_headers, db_session):
    me = make_user(db_session)
    response = client.get(URL, headers=auth_headers(me))
    assert (response.status_code, response.json()) == (200, DEFAULTS)
    stored = db_session.scalar(select(func.count()).select_from(NotificationPreference))
    assert stored == 0  # lire ne crée rien


def test_only_the_switches_sent_change(client, auth_headers, db_session):
    me = make_user(db_session)
    headers = auth_headers(me)
    first = client.patch(URL, json={"payments": False}, headers=headers)
    assert first.json() == DEFAULTS | {"payments": False}
    second = client.patch(URL, json={"high_consumption": True}, headers=headers)
    assert second.json() == {"due_soon": True, "payments": False, "high_consumption": True}
    assert client.get(URL, headers=headers).json() == second.json()


def test_each_person_has_their_own_switches(client, auth_headers, db_session):
    me, other = make_user(db_session), make_user(db_session)
    client.patch(URL, json={"due_soon": False}, headers=auth_headers(me))
    assert client.get(URL, headers=auth_headers(other)).json() == DEFAULTS


@pytest.mark.parametrize(
    "body",
    [{}, {"payments": None}, {"payments": "peut-être"}, {"sms": True}, {"announcements": False}],
)
def test_invalid_changes_are_refused(client, auth_headers, db_session, body):
    response = client.patch(URL, json=body, headers=auth_headers(make_user(db_session)))
    assert (response.status_code, response.json()["error"]["code"]) == (422, "VALIDATION_ERROR")


@pytest.mark.parametrize("method", ["GET", "PATCH"])
def test_login_is_required(client, method):
    assert client.request(method, URL, json={"payments": False}).status_code == 401


def test_one_row_per_person_at_most(db_session):
    me = make_user(db_session)
    switch(db_session, me)
    with expect_db_rejection(db_session, "uq_notification_preferences_user_id"):
        switch(db_session, me, payments=False)


# --- Effet sur la création des notifications ---------------------------------------------------


ALWAYS_SENT = (
    NotificationType.BILL_ISSUED,
    NotificationType.BILL_OVERDUE,
    NotificationType.INVITATION_RECEIVED,
    NotificationType.CONSUMPTION_ANOMALY,
    NotificationType.ANNOUNCEMENT,
)


def test_by_default_unusual_consumption_is_not_sent(db_session):
    me = make_user(db_session)
    created = insert_notifications(
        db_session,
        [
            row(me, NotificationType.BILL_DUE_SOON),
            row(me, NotificationType.PAYMENT_SUCCEEDED),
            row(me, NotificationType.HIGH_CONSUMPTION),
        ],
    )
    assert created == 2
    assert received(db_session, me) == {
        NotificationType.BILL_DUE_SOON,
        NotificationType.PAYMENT_SUCCEEDED,
    }


@pytest.mark.parametrize(
    ("switch_off", "blocked"),
    [
        ("due_soon", {NotificationType.BILL_DUE_SOON}),
        ("payments", {NotificationType.PAYMENT_SUCCEEDED, NotificationType.PAYMENT_FAILED}),
    ],
)
def test_a_switched_off_alert_is_not_created(db_session, switch_off, blocked):
    me = make_user(db_session)
    switch(db_session, me, **{switch_off: False})
    kinds = [
        NotificationType.BILL_DUE_SOON,
        NotificationType.PAYMENT_SUCCEEDED,
        NotificationType.PAYMENT_FAILED,
    ]
    insert_notifications(db_session, [row(me, kind) for kind in kinds])
    assert received(db_session, me) == set(kinds) - blocked


def test_unusual_consumption_once_switched_on(db_session):
    me = make_user(db_session)
    switch(db_session, me, high_consumption=True)
    insert_notifications(db_session, [row(me, NotificationType.HIGH_CONSUMPTION)])
    assert received(db_session, me) == {NotificationType.HIGH_CONSUMPTION}


def test_other_messages_are_always_sent(db_session):
    me = make_user(db_session)
    switch(db_session, me, due_soon=False, payments=False, high_consumption=False)
    created = insert_notifications(db_session, [row(me, kind) for kind in ALWAYS_SENT])
    assert created == len(ALWAYS_SENT)
    assert received(db_session, me) == set(ALWAYS_SENT)


def test_one_persons_switches_never_affect_another(db_session):
    quiet, other = make_user(db_session), make_user(db_session)
    switch(db_session, quiet, payments=False)
    insert_notifications(
        db_session,
        [row(quiet, NotificationType.PAYMENT_FAILED), row(other, NotificationType.PAYMENT_FAILED)],
    )
    assert received(db_session, quiet) == set()
    assert received(db_session, other) == {NotificationType.PAYMENT_FAILED}


def test_a_payment_still_succeeds_and_gets_its_receipt_without_alerts(db_session):
    """Couper « Paiements » ne coupe que le message : le reçu existe, le titulaire est prévenu."""
    owner, delegate = make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner)
    make_member(db_session, home, delegate, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    transaction = make_transaction(
        db_session, make_bill(db_session, make_meter(db_session, home)), delegate
    )
    switch(db_session, delegate, payments=False)

    confirmed = PAYMENT_START + timedelta(seconds=10)
    update = ProviderUpdate("SIM-PREFS", ProviderState.SUCCEEDED, confirmed, amount=40_384)
    apply_provider_update(db_session, transaction.id, update, origin="test", now=confirmed)

    assert db_session.scalar(select(Receipt.id).where(Receipt.transaction_id == transaction.id))
    assert received(db_session, delegate) == set()
    assert received(db_session, owner) == {NotificationType.PAYMENT_SUCCEEDED}


def test_the_new_type_is_accepted_by_the_database(db_session):
    me = make_user(db_session)
    switch(db_session, me, high_consumption=True)
    insert_notifications(db_session, [row(me, NotificationType.HIGH_CONSUMPTION)])
    db_session.flush()
    assert received(db_session, me) == {NotificationType.HIGH_CONSUMPTION}
