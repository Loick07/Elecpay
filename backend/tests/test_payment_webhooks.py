"""Tests de la confirmation des paiements (B7.3) : webhooks signés et `apply_provider_update`."""

import json
import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from pydantic import SecretStr
from sqlalchemy import select

from app.core.config import get_settings
from app.db.base import utcnow
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.integrations.payment_providers.simulated import SIGNATURE_HEADER, SimulatedPaymentProvider
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import Notification, NotificationType
from app.modules.payments.confirmation import Outcome, apply_provider_update
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from scripts.send_payment_webhook import parse_args, refusal_reason
from tests.factories import make_bill, make_household, make_member, make_meter, make_user

WEBHOOK_URL = "/api/v1/webhooks/payments/simulated"


@pytest.fixture
def family(db_session):
    owner = make_user(db_session, phone="+242061110001", full_name="Arnaud Mavoungou")
    payer = make_user(db_session, phone="+242051110002", full_name="Grâce Ngoma")
    home = make_household(db_session, owner)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home)
    bill = make_bill(db_session, meter, due_date=date(2099, 1, 1))  # échéance lointaine
    return {"owner": owner, "payer": payer, "meter": meter, "bill": bill}


@pytest.fixture
def provider(test_settings):
    """Le prestataire tel que l'API le voit (même secret que l'application de test)."""
    return SimulatedPaymentProvider(test_settings.payment_webhook_secret.get_secret_value())


def start_payment(client, auth_headers, family, who="owner"):
    phone = {"owner": "06 111 00 01", "payer": "05 111 00 02"}[who]
    operator = {"owner": "mtn", "payer": "airtel"}[who]
    response = client.post(
        "/api/v1/payments",
        json={"bill_id": family["bill"].id, "operator": operator, "phone_number": phone},
        headers=auth_headers(family[who]) | {"Idempotency-Key": uuid.uuid4().hex},
    )
    assert response.status_code == 201, response.text
    return response.json()


def transaction_of(session, payment):
    return session.get(PaymentTransaction, payment["id"])


def send(client, provider, transaction, state, **extra):
    update = ProviderUpdate(
        provider_ref=transaction.provider_ref,
        state=state,
        occurred_at=utcnow(),
        amount=extra.pop(
            "amount", transaction.amount if state is ProviderState.SUCCEEDED else None
        ),
        failure_reason=extra.pop("failure_reason", None),
    )
    headers, body = provider.signed_webhook(update)
    return client.post(WEBHOOK_URL, content=body, headers=headers)


def notices(session, user, kind):
    return session.scalars(
        select(Notification).where(Notification.user_id == user.id, Notification.type == kind)
    ).all()


def audit_actions(session, transaction):
    return session.scalars(
        select(AuditLog.action)
        .where(AuditLog.entity_type == "payment_transaction", AuditLog.entity_id == transaction.id)
        .order_by(AuditLog.id)
    ).all()


# --- Succès ------------------------------------------------------------------------------------


def test_a_signed_success_confirms_the_payment(client, auth_headers, db_session, family, provider):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    response = send(client, provider, transaction, ProviderState.SUCCEEDED)
    assert response.status_code == 200
    assert response.json() == {
        "received": True,
        "transaction_status": "reussie",
        "outcome": "succeeded",
    }
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.SUCCEEDED
    assert transaction.confirmed_at is not None and transaction.pin_entered_at is not None
    bill = family["bill"]
    db_session.refresh(bill)
    assert (bill.status, bill.paid_at) == (BillStatus.PAID, transaction.confirmed_at)
    (notice,) = notices(db_session, family["owner"], NotificationType.PAYMENT_SUCCEEDED)
    assert "40 384 FCFA confirmé" in notice.body
    assert audit_actions(db_session, transaction) == ["payment.initiate", "payment.succeeded"]


def test_owner_is_told_when_a_delegate_pays(client, auth_headers, db_session, family, provider):
    payment = start_payment(client, auth_headers, family, who="payer")
    send(client, provider, transaction_of(db_session, payment), ProviderState.SUCCEEDED)
    assert notices(db_session, family["payer"], NotificationType.PAYMENT_SUCCEEDED)
    (notice,) = notices(db_session, family["owner"], NotificationType.PAYMENT_SUCCEEDED)
    assert notice.title == "Facture payée"
    assert notice.body.startswith("Grâce Ngoma a payé votre facture Juil.-Août 2026")


def test_double_webhook_changes_nothing_the_second_time(
    client, auth_headers, db_session, family, provider
):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    send(client, provider, transaction, ProviderState.SUCCEEDED)
    db_session.refresh(transaction)
    confirmed_at = transaction.confirmed_at
    again = send(client, provider, transaction, ProviderState.SUCCEEDED)
    assert (again.status_code, again.json()["outcome"]) == (200, "unchanged")
    db_session.refresh(transaction)
    assert transaction.confirmed_at == confirmed_at
    assert len(notices(db_session, family["owner"], NotificationType.PAYMENT_SUCCEEDED)) == 1


def test_the_paid_bill_cannot_be_paid_again(client, auth_headers, db_session, family, provider):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    send(client, provider, transaction, ProviderState.SUCCEEDED)
    response = client.post(
        "/api/v1/payments",
        json={"bill_id": family["bill"].id, "operator": "mtn", "phone_number": "06 111 00 01"},
        headers=auth_headers(family["owner"]) | {"Idempotency-Key": uuid.uuid4().hex},
    )
    assert (response.status_code, response.json()["error"]["code"]) == (409, "BILL_ALREADY_PAID")


# --- Code PIN et échec -------------------------------------------------------------------------


def test_pin_entry_is_recorded_once(client, auth_headers, db_session, family, provider):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    first = send(client, provider, transaction, ProviderState.PIN_ENTERED)
    assert first.json() == {
        "received": True,
        "transaction_status": "en_attente",
        "outcome": "pin_entered",
    }
    db_session.refresh(transaction)
    pin_at = transaction.pin_entered_at
    assert pin_at is not None
    assert send(client, provider, transaction, ProviderState.PIN_ENTERED).json()["outcome"] == (
        "unchanged"
    )
    db_session.refresh(transaction)
    assert transaction.pin_entered_at == pin_at
    assert family["bill"].status is BillStatus.PENDING_PAYMENT


@pytest.mark.parametrize(
    ("due_date", "status_after"),
    # Facture de mai-juin : échéance encore lointaine, ou déjà passée (18/07/2026).
    [(date(2099, 1, 1), BillStatus.UNPAID), (date(2026, 7, 18), BillStatus.OVERDUE)],
)
def test_a_failure_makes_the_bill_payable_again(
    client, auth_headers, db_session, family, provider, due_date, status_after
):
    # L'échéance d'une facture ne change jamais (la base l'interdit) : une facture dédiée.
    family["bill"] = make_bill(
        db_session,
        family["meter"],
        period_start=date(2026, 5, 1),
        period_end=date(2026, 6, 30),
        due_date=due_date,
    )
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    response = send(
        client, provider, transaction, ProviderState.FAILED, failure_reason="Solde insuffisant"
    )
    assert response.json()["outcome"] == "failed"
    db_session.refresh(transaction)
    assert (transaction.status, transaction.failure_reason) == (
        TransactionStatus.FAILED,
        "Solde insuffisant",
    )
    db_session.refresh(family["bill"])
    assert family["bill"].status is status_after
    (notice,) = notices(db_session, family["owner"], NotificationType.PAYMENT_FAILED)
    assert "Solde insuffisant. Vous pouvez réessayer." in notice.body
    # Échec puis nouvelle tentative : autorisée.
    assert start_payment(client, auth_headers, family)["status"] == "en_attente"


# --- Webhooks refusés ---------------------------------------------------------------------------


def test_a_badly_signed_webhook_changes_nothing(client, auth_headers, db_session, family):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    forger = SimulatedPaymentProvider("secret-devine-par-un-fraudeur-" + "z" * 20)
    response = send(client, forger, transaction, ProviderState.SUCCEEDED)
    assert (response.status_code, response.json()["error"]["code"]) == (
        401,
        "WEBHOOK_SIGNATURE_INVALID",
    )
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.PENDING
    assert family["bill"].status is BillStatus.PENDING_PAYMENT


def test_an_unsigned_webhook_is_refused(client, auth_headers, db_session, family):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    body = json.dumps(
        {
            "provider_ref": transaction.provider_ref,
            "state": "succeeded",
            "occurred_at": utcnow().isoformat(),
            "amount": transaction.amount,
        }
    )
    response = client.post(WEBHOOK_URL, content=body, headers={"Content-Type": "application/json"})
    assert response.status_code == 401


def test_a_replayed_old_webhook_is_refused(client, auth_headers, db_session, family, test_settings):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    secret = test_settings.payment_webhook_secret.get_secret_value()
    old = SimulatedPaymentProvider(secret, now=lambda: utcnow() - timedelta(minutes=10))
    response = send(client, old, transaction, ProviderState.SUCCEEDED)
    assert response.status_code == 401
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.PENDING


def test_webhooks_are_refused_when_no_secret_is_configured(
    app, client, auth_headers, db_session, family, provider, test_settings
):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    no_secret = test_settings.model_copy(update={"payment_webhook_secret": SecretStr("")})
    app.dependency_overrides[get_settings] = lambda: no_secret
    response = send(client, provider, transaction, ProviderState.SUCCEEDED)
    assert response.status_code == 401
    assert "PAYMENT_WEBHOOK_SECRET" in response.json()["error"]["message"]


def test_webhook_for_another_provider_is_refused(
    client, auth_headers, db_session, family, provider
):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    headers, body = provider.signed_webhook(
        ProviderUpdate(transaction.provider_ref, ProviderState.SUCCEEDED, utcnow(), amount=40_384)
    )
    response = client.post("/api/v1/webhooks/payments/mtn", content=body, headers=headers)
    assert (response.status_code, response.json()["error"]["code"]) == (
        404,
        "UNKNOWN_PAYMENT_PROVIDER",
    )


def test_webhook_for_an_unknown_transaction(client, provider):
    headers, body = provider.signed_webhook(
        ProviderUpdate("SIM-INCONNU", ProviderState.SUCCEEDED, utcnow(), amount=1)
    )
    response = client.post(WEBHOOK_URL, content=body, headers=headers)
    assert (response.status_code, response.json()["error"]["code"]) == (404, "PAYMENT_NOT_FOUND")


def test_a_signed_but_invalid_body_is_refused(client, provider):
    body = b'{"provider_ref": "SIM-1", "state": "failed"}'
    headers, _ = provider.signed_webhook(ProviderUpdate("x", ProviderState.PENDING, utcnow()))
    timestamp = headers[SIGNATURE_HEADER].split(",")[0].removeprefix("t=")
    headers[SIGNATURE_HEADER] = f"t={timestamp},v1={provider._sign(int(timestamp), body)}"
    response = client.post(WEBHOOK_URL, content=body, headers=headers)
    assert (response.status_code, response.json()["error"]["code"]) == (
        400,
        "WEBHOOK_PAYLOAD_INVALID",
    )


# --- Anomalies : signalées, jamais appliquées en douce ----------------------------------------


def test_a_different_amount_is_not_confirmed(client, auth_headers, db_session, family, provider):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    response = send(client, provider, transaction, ProviderState.SUCCEEDED, amount=40_000)
    assert response.json()["outcome"] == "amount_mismatch"
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.PENDING
    assert "payment.amount_mismatch" in audit_actions(db_session, transaction)


def test_a_success_after_a_failure_is_flagged_not_applied(
    client, auth_headers, db_session, family, provider
):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    send(client, provider, transaction, ProviderState.FAILED, failure_reason="Solde insuffisant")
    response = send(client, provider, transaction, ProviderState.SUCCEEDED)
    assert (response.status_code, response.json()) == (
        200,
        {"received": True, "transaction_status": "echouee", "outcome": "conflict"},
    )
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.FAILED
    db_session.refresh(family["bill"])
    assert family["bill"].status is BillStatus.UNPAID
    assert audit_actions(db_session, transaction)[-1] == "payment.provider_conflict"


def test_a_late_failure_never_undoes_a_success(client, auth_headers, db_session, family, provider):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    send(client, provider, transaction, ProviderState.SUCCEEDED)
    response = send(client, provider, transaction, ProviderState.FAILED, failure_reason="Refus")
    assert response.json()["outcome"] == "conflict"
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.SUCCEEDED


def test_there_is_no_way_to_force_a_success(client, auth_headers, db_session, family):
    """Aucune route ne modifie une transaction : seul le prestataire confirme."""
    payment = start_payment(client, auth_headers, family)
    headers = auth_headers(family["owner"])
    for method in ("PATCH", "PUT", "DELETE"):
        response = client.request(
            method, f"/api/v1/payments/{payment['id']}", json={"status": "reussie"}, headers=headers
        )
        assert response.status_code in (404, 405)
    assert transaction_of(db_session, payment).status is TransactionStatus.PENDING


# --- Fonction unique (sans HTTP) ------------------------------------------------------------------


def test_announced_dates_are_kept_between_request_and_now(client, auth_headers, db_session, family):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    now = utcnow()
    future = ProviderUpdate(
        transaction.provider_ref, ProviderState.SUCCEEDED, now + timedelta(hours=3), amount=40_384
    )
    applied = apply_provider_update(db_session, transaction.id, future, origin="test", now=now)
    assert applied.outcome is Outcome.SUCCEEDED
    assert applied.transaction.confirmed_at == now  # pas dans le futur


def test_command_refuses_outside_the_demo(test_settings):
    assert refusal_reason(test_settings) is None
    assert refusal_reason(test_settings.model_copy(update={"app_env": "production"}))
    empty = test_settings.model_copy(update={"payment_webhook_secret": SecretStr("")})
    assert "PAYMENT_WEBHOOK_SECRET" in refusal_reason(empty)


def test_command_arguments():
    args = parse_args(["162", "--state", "failed", "--reason", "Refus"])
    assert (args.transaction_id, args.state, args.reason) == (162, "failed", "Refus")
    assert parse_args(["7"]).state == "succeeded"


def test_occurred_at_before_the_request_is_moved_to_the_request(
    client, auth_headers, db_session, family
):
    transaction = transaction_of(db_session, start_payment(client, auth_headers, family))
    early = ProviderUpdate(
        transaction.provider_ref,
        ProviderState.PIN_ENTERED,
        datetime(2000, 1, 1, tzinfo=UTC),
    )
    applied = apply_provider_update(db_session, transaction.id, early, origin="test", now=utcnow())
    assert applied.transaction.pin_entered_at == transaction.initiated_at
