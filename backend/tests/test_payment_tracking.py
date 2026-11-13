"""Tests du suivi des paiements et de l'expiration (B7.4) : GET /payments/{id}."""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import select

from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentRequest
from app.integrations.payment_providers.simulated import (
    INSUFFICIENT_FUNDS,
    SimulatedPaymentProvider,
)
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import Notification, NotificationType
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.payments.tracking import EXPIRY_REASON, expire_if_due
from scripts.check_pending_payments import check_pending
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_transaction,
    make_user,
)

OWNER_PHONE = "+242061110001"


@pytest.fixture
def family(db_session):
    owner = make_user(db_session, phone=OWNER_PHONE)
    payer, viewer = make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home)
    bill = make_bill(db_session, meter, due_date=date(2099, 1, 1))
    return {"owner": owner, "payer": payer, "viewer": viewer, "meter": meter, "bill": bill}


@pytest.fixture
def provider(test_settings):
    return SimulatedPaymentProvider(test_settings.payment_webhook_secret.get_secret_value())


def pending(session, provider, family, *, age, ending="01", bill=None, ref=None, payer=None):
    """Paiement en attente lancé il y a `age`, avec le scénario du numéro `…<ending>`."""
    bill = bill or family["bill"]
    payer = payer or family["owner"]
    started = utcnow() - age
    phone = f"+2420600000{ending}"  # numéro de test : « 06 000 00 0N »
    key = uuid.uuid4().hex
    request = PaymentRequest(key, "mtn", phone, bill.amount_total, started, "test")
    transaction = make_transaction(
        session,
        bill,
        payer,
        operator=MobileOperator.MTN,
        phone_number=phone,
        idempotency_key=key,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
        provider_ref=ref or provider.initiate(request),
    )
    bill.status = BillStatus.PENDING_PAYMENT
    session.flush()
    return transaction


def track(client, headers, transaction):
    return client.get(f"/api/v1/payments/{transaction.id}", headers=headers)


def notices(session, user, kind):
    return session.scalars(
        select(Notification).where(Notification.user_id == user.id, Notification.type == kind)
    ).all()


# --- Les étapes de l'écran 9 ---------------------------------------------------------------------


@pytest.mark.parametrize(
    ("seconds", "status", "step"),
    [
        (1, "en_attente", "requested"),
        (6, "en_attente", "pin_entered"),
        (11, "reussie", "succeeded"),
    ],
)
def test_steps_of_a_successful_payment(
    client, auth_headers, db_session, family, provider, seconds, status, step
):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=seconds))
    response = track(client, auth_headers(family["owner"]), transaction)
    assert response.status_code == 200
    body = response.json()
    assert (body["status"], body["step"]) == (status, step)
    assert body["reference"] == f"TX-{transaction.id:08d}"


def test_success_found_while_tracking_pays_the_bill(
    client, auth_headers, db_session, family, provider
):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=11))
    track(client, auth_headers(family["owner"]), transaction)
    db_session.refresh(family["bill"])
    assert family["bill"].status is BillStatus.PAID
    assert notices(db_session, family["owner"], NotificationType.PAYMENT_SUCCEEDED)
    # Relire ne change plus rien.
    again = track(client, auth_headers(family["owner"]), transaction).json()
    assert again["status"] == "reussie"
    assert len(notices(db_session, family["owner"], NotificationType.PAYMENT_SUCCEEDED)) == 1


def test_failure_found_while_tracking(client, auth_headers, db_session, family, provider):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=11), ending="02")
    body = track(client, auth_headers(family["owner"]), transaction).json()
    assert (body["status"], body["step"], body["failure_reason"]) == (
        "echouee",
        "failed",
        INSUFFICIENT_FUNDS,
    )
    db_session.refresh(family["bill"])
    assert family["bill"].status is BillStatus.UNPAID


# --- Expiration ----------------------------------------------------------------------------


def test_no_pin_after_10_minutes_expires(client, auth_headers, db_session, family, provider):
    transaction = pending(db_session, provider, family, age=timedelta(minutes=11), ending="04")
    body = track(client, auth_headers(family["owner"]), transaction).json()
    assert (body["status"], body["step"], body["failure_reason"]) == (
        "expiree",
        "expired",
        EXPIRY_REASON,
    )
    db_session.refresh(family["bill"])
    assert family["bill"].status is BillStatus.UNPAID
    (notice,) = notices(db_session, family["owner"], NotificationType.PAYMENT_FAILED)
    assert EXPIRY_REASON in notice.body
    assert (
        db_session.scalars(
            select(AuditLog.action).where(AuditLog.entity_id == transaction.id)
        ).all()[-1]
        == "payment.expired"
    )


def test_no_pin_but_still_within_10_minutes(client, auth_headers, db_session, family, provider):
    transaction = pending(db_session, provider, family, age=timedelta(minutes=9), ending="04")
    assert track(client, auth_headers(family["owner"]), transaction).json()["step"] == "requested"


def test_pin_entered_never_expires(client, auth_headers, db_session, family, provider):
    """Maquette A8 : PIN saisi, débit non confirmé → reste en attente, sans limite."""
    transaction = pending(db_session, provider, family, age=timedelta(hours=2), ending="05")
    body = track(client, auth_headers(family["owner"]), transaction).json()
    assert (body["status"], body["step"]) == ("en_attente", "pin_entered")
    assert family["bill"].status is BillStatus.PENDING_PAYMENT


def test_an_unreachable_provider_does_not_block_expiry(
    client, auth_headers, db_session, family, provider
):
    transaction = pending(
        db_session, provider, family, age=timedelta(minutes=11), ending="06", ref="SIM-PANNE"
    )
    assert track(client, auth_headers(family["owner"]), transaction).json()["status"] == "expiree"


def test_expired_bill_already_overdue_goes_back_to_overdue(
    client, auth_headers, db_session, family, provider
):
    overdue = make_bill(
        db_session,
        family["meter"],
        period_start=date(2026, 5, 1),
        period_end=date(2026, 6, 30),
        due_date=date(2026, 7, 18),
    )
    transaction = pending(
        db_session, provider, family, age=timedelta(minutes=11), ending="04", bill=overdue
    )
    track(client, auth_headers(family["owner"]), transaction)
    db_session.refresh(overdue)
    assert overdue.status is BillStatus.OVERDUE


@pytest.mark.parametrize(("minutes", "expired"), [(9.99, False), (10, True)])
def test_expiry_boundary(db_session, family, provider, minutes, expired):
    transaction = pending(db_session, provider, family, age=timedelta(0), ending="04")
    now = transaction.initiated_at + timedelta(minutes=minutes)
    assert expire_if_due(db_session, transaction.id, now=now) is expired


# --- Nouvelle tentative --------------------------------------------------------------------


def pay(client, headers, bill):
    return client.post(
        "/api/v1/payments",
        json={"bill_id": bill.id, "operator": "mtn", "phone_number": OWNER_PHONE},
        headers=headers | {"Idempotency-Key": uuid.uuid4().hex},
    )


def test_a_new_payment_is_allowed_once_the_old_one_has_expired(
    client, auth_headers, db_session, family, provider
):
    """Personne n'a regardé la transaction expirée : la nouvelle demande fait le point."""
    old = pending(db_session, provider, family, age=timedelta(minutes=11), ending="04")
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert response.status_code == 201
    db_session.refresh(old)
    assert old.status is TransactionStatus.EXPIRED


def test_a_new_payment_learns_that_the_old_one_succeeded(
    client, auth_headers, db_session, family, provider
):
    old = pending(db_session, provider, family, age=timedelta(seconds=11))
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert (response.status_code, response.json()["error"]["code"]) == (409, "BILL_ALREADY_PAID")
    db_session.refresh(old)
    assert old.status is TransactionStatus.SUCCEEDED  # ce qu'on a appris est gardé


def test_a_new_payment_while_the_old_one_is_still_running(
    client, auth_headers, db_session, family, provider
):
    old = pending(db_session, provider, family, age=timedelta(seconds=6))
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert response.status_code == 409
    assert response.json()["error"]["details"] == {"transaction_id": old.id}
    db_session.refresh(old)
    assert old.pin_entered_at is not None  # le point fait au passage est gardé


# --- Qui voit quoi -------------------------------------------------------------------------


def test_household_members_see_the_payment_with_a_masked_number(
    client, auth_headers, db_session, family, provider
):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=1))
    mine = track(client, auth_headers(family["owner"]), transaction).json()
    assert (mine["is_mine"], mine["phone_number"]) == (True, transaction.phone_number)
    for person in ("payer", "viewer"):
        theirs = track(client, auth_headers(family[person]), transaction).json()
        assert (theirs["is_mine"], theirs["phone_number"]) == (False, "+242 06 *** ** 01")


def test_a_stranger_gets_not_found(client, auth_headers, db_session, family, provider):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=1))
    headers = auth_headers(make_user(db_session))
    theirs = track(client, headers, transaction)
    missing = client.get("/api/v1/payments/999999999", headers=headers)
    assert theirs.status_code == missing.status_code == 404
    assert theirs.json() == missing.json()
    assert theirs.json()["error"]["code"] == "PAYMENT_NOT_FOUND"


def test_the_payer_still_sees_a_payment_after_leaving_the_household(
    client, auth_headers, db_session, family, provider
):
    former_member = make_user(db_session)  # a payé, puis a été retiré du foyer
    transaction = pending(
        db_session, provider, family, age=timedelta(seconds=1), payer=former_member
    )
    body = track(client, auth_headers(former_member), transaction).json()
    assert (body["id"], body["is_mine"]) == (transaction.id, True)


def test_login_is_required(client, db_session, family, provider):
    transaction = pending(db_session, provider, family, age=timedelta(seconds=1))
    assert client.get(f"/api/v1/payments/{transaction.id}").status_code == 401


# --- Commande planifiée --------------------------------------------------------------------


def test_command_checks_every_pending_payment(db_session, family, provider):
    other_bill = make_bill(
        db_session,
        family["meter"],
        period_start=date(2026, 5, 1),
        period_end=date(2026, 6, 30),
        due_date=date(2099, 1, 1),
    )
    succeeded = pending(db_session, provider, family, age=timedelta(seconds=11))
    expired = pending(
        db_session, provider, family, age=timedelta(minutes=11), ending="04", bill=other_bill
    )
    counts = check_pending(db_session, provider, utcnow())
    assert counts == {TransactionStatus.SUCCEEDED: 1, TransactionStatus.EXPIRED: 1}
    assert (succeeded.status, expired.status) == (
        TransactionStatus.SUCCEEDED,
        TransactionStatus.EXPIRED,
    )
    assert check_pending(db_session, provider, utcnow()) == {}  # plus rien en attente
