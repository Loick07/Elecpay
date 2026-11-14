"""Tests des écrans Transactions du back-office (B10.6, A7 et A8) : liste, rapprochement,
relance de la vérification auprès de l'opérateur, litiges."""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import delete, select

from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentRequest
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.modules.admin.transactions import AdminTransactions
from app.modules.audit.models import AuditLog
from app.modules.audit.service import record
from app.modules.bills.models import Bill, BillStatus
from app.modules.disputes.models import DisputeResolution, DisputeStatus, PaymentDispute
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.receipts.models import Receipt
from app.modules.users.models import UserRole
from tests.db_helpers import expect_db_rejection
from tests.factories import make_bill, make_household, make_meter, make_transaction, make_user

URL = "/api/v1/admin/transactions"
CLAIM = "Le client affirme avoir été débité"


@pytest.fixture
def provider(test_settings):
    return SimulatedPaymentProvider(test_settings.payment_webhook_secret.get_secret_value())


@pytest.fixture
def team(db_session):
    return {
        "owner": make_user(db_session, full_name="Arnaud Mavoungou", phone="+242061110001"),
        "support": make_user(db_session, role=UserRole.SUPPORT),
        "admin": make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala"),
    }


def pending(
    session, provider, payer, *, age, ending="01", ref=None, operator=MobileOperator.MTN, now=None
):
    """Paiement en attente (sur sa propre facture), lancé `age` avant `now` (maintenant par
    défaut), avec le numéro de test `…00 00 <ending>`."""
    bill = make_bill(
        session, make_meter(session, make_household(session)), due_date=date(2099, 1, 1)
    )
    started = (now or utcnow()) - age
    prefix = "06" if operator is MobileOperator.MTN else "05"
    phone = f"+242{prefix}00000{ending}"
    key = uuid.uuid4().hex
    request = PaymentRequest(key, operator.value, phone, bill.amount_total, started, "test")
    transaction = make_transaction(
        session,
        bill,
        payer,
        operator=operator,
        phone_number=phone,
        idempotency_key=key,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
        provider_ref=ref or provider.initiate(request),
    )
    bill.status = BillStatus.PENDING_PAYMENT
    session.flush()
    return transaction


def finish(session, transaction, status, reason=None):
    """Termine la transaction comme l'aurait fait l'opérateur (succès, échec, expiration)."""
    transaction.status = status
    if status is TransactionStatus.SUCCEEDED:
        transaction.pin_entered_at = transaction.initiated_at + timedelta(seconds=5)
        transaction.confirmed_at = transaction.initiated_at + timedelta(seconds=40)
    else:
        transaction.failure_reason = reason or "Solde insuffisant"
    session.flush()
    bill = session.get(Bill, transaction.bill_id)
    if status is TransactionStatus.SUCCEEDED:
        bill.status, bill.paid_at = BillStatus.PAID, transaction.confirmed_at
    else:
        bill.status = BillStatus.UNPAID
    session.flush()
    return transaction


def listing(client, auth_headers, user, **params):
    response = client.get(URL, params=params, headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def detail(client, auth_headers, user, transaction):
    response = client.get(f"{URL}/{transaction.id}", headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def recheck(client, auth_headers, user, transaction):
    return client.post(f"{URL}/{transaction.id}/recheck", headers=auth_headers(user))


def open_dispute(client, auth_headers, user, transaction, **body):
    return client.post(
        f"{URL}/{transaction.id}/disputes",
        json={"reason": CLAIM} | body,
        headers=auth_headers(user),
    )


# --- Liste (A7) -----------------------------------------------------------------------------


def test_list_and_indicators_of_the_day(
    client, auth_headers, db_session, provider, team, monkeypatch
):
    # Midi à Brazzaville : le test ne dépend pas de l'heure à laquelle il tourne (minuit…).
    noon = local_midnight_utc(local_date(utcnow())) + timedelta(hours=12)
    original = AdminTransactions.__init__
    monkeypatch.setattr(
        AdminTransactions,
        "__init__",
        lambda self, session, now=None: original(self, session, lambda: noon),
    )
    owner = team["owner"]
    paid = finish(
        db_session,
        pending(db_session, provider, owner, age=timedelta(minutes=2), now=noon),
        TransactionStatus.SUCCEEDED,
    )
    finish(
        db_session,
        pending(db_session, provider, owner, age=timedelta(minutes=3), now=noon),
        TransactionStatus.FAILED,
    )
    waiting = pending(db_session, provider, owner, age=timedelta(seconds=30), ending="05", now=noon)
    body = listing(client, auth_headers, team["support"])
    today = body["today"]
    assert today["collected"] == paid.amount
    assert (today["succeeded"], today["failed"], today["pending"]) == (1, 1, 1)
    assert today["average_confirmation_seconds"] == 40
    assert body["items"][0]["id"] == waiting.id  # les plus récentes d'abord
    row = next(item for item in body["items"] if item["id"] == paid.id)
    assert row["reference"] == f"TX-{paid.id:08d}"
    assert row["phone_number"] == "+242 06 *** ** 01"  # toujours masqué
    assert row["payer_name"] == "Arnaud Mavoungou"
    assert row["operator_label"] == "MTN MoMo"


def test_filters_and_search(client, auth_headers, db_session, provider, team):
    owner = team["owner"]
    paid = finish(
        db_session,
        pending(db_session, provider, owner, age=timedelta(minutes=2)),
        TransactionStatus.SUCCEEDED,
    )
    airtel = pending(
        db_session, provider, owner, age=timedelta(seconds=30), operator=MobileOperator.AIRTEL
    )
    viewer = team["support"]

    def found(**params):
        return [item["id"] for item in listing(client, auth_headers, viewer, **params)["items"]]

    assert found(status="reussie") == [paid.id]
    assert found(status="en_attente") == [airtel.id]
    assert found(operator="airtel") == [airtel.id]
    assert found(q=f"TX-{paid.id:08d}") == [paid.id]
    assert set(found(q="mavoungou")) == {paid.id, airtel.id}
    assert found(day=(utcnow() - timedelta(days=3)).date().isoformat()) == []


def test_clients_have_no_access(client, auth_headers, team):
    assert client.get(URL, headers=auth_headers(team["owner"])).status_code == 403


# --- Détail (A8) ----------------------------------------------------------------------------


def test_detail_before_any_check(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(seconds=30))
    body = detail(client, auth_headers, team["support"], transaction)
    assert body["idempotency_key"] == transaction.idempotency_key
    assert body["provider_ref"].startswith("SIM-")
    assert body["bill_lock"]["locked_by_this_transaction"] is True
    assert body["bill_lock"]["bill_status"] == "pending_payment"
    assert body["operator_view"] is None
    assert {line["field"]: line["matches"] for line in body["comparison"]} == {
        "amount": None,
        "phone_number": None,
        "provider_ref": None,
        "status": None,
    }
    assert body["timeline"][0]["action"] == "payment.requested"
    assert (body["can_recheck"], body["can_open_dispute"]) == (True, True)
    assert "mark" not in str(body).lower()  # aucun « marquer comme payée »


def test_timeline_without_journal_uses_the_transaction_dates(
    client, auth_headers, db_session, provider, team
):
    # Comme les paiements de démo : terminés sans ligne au journal.
    paid = finish(
        db_session,
        pending(db_session, provider, team["owner"], age=timedelta(minutes=2)),
        TransactionStatus.SUCCEEDED,
    )
    timeline = detail(client, auth_headers, team["support"], paid)["timeline"]
    assert [event["action"] for event in timeline] == [
        "payment.requested",
        "payment.pin_entered",
        "payment.succeeded",
    ]
    assert timeline[-1]["at"].startswith(paid.confirmed_at.strftime("%Y-%m-%dT%H:%M"))


def test_unknown_transaction(client, auth_headers, team):
    response = client.get(f"{URL}/999999", headers=auth_headers(team["support"]))
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "TRANSACTION_NOT_FOUND"


# --- Relancer la vérification ---------------------------------------------------------------


def test_recheck_applies_a_confirmed_debit(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    response = recheck(client, auth_headers, team["admin"], transaction)
    assert response.status_code == 200, response.text
    body = response.json()
    assert (body["status_before"], body["status_after"]) == ("en_attente", "reussie")
    assert (body["operator_state"], body["outcome"]) == ("succeeded", "succeeded")
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.SUCCEEDED
    assert db_session.scalars(select(Receipt).where(Receipt.transaction_id == transaction.id)).one()
    shown = detail(client, auth_headers, team["support"], transaction)
    assert shown["operator_view"]["checked_by"] == "Christelle Mabiala"
    assert all(line["matches"] in (True, None) for line in shown["comparison"])
    assert shown["bill_lock"]["bill_status"] == "paid"
    actions = [event["action"] for event in shown["timeline"]]
    assert actions.index("payment.succeeded") < actions.index("payment.recheck")
    succeeded = db_session.scalars(
        select(AuditLog).where(
            AuditLog.action == "payment.succeeded", AuditLog.entity_id == transaction.id
        )
    ).one()
    assert succeeded.actor_id is None  # c'est l'opérateur qui confirme, pas l'admin
    assert succeeded.after_json["origin"] == "admin_recheck"


def test_recheck_with_pin_entered_keeps_waiting(client, auth_headers, db_session, provider, team):
    transaction = pending(
        db_session, provider, team["owner"], age=timedelta(minutes=20), ending="05"
    )
    body = recheck(client, auth_headers, team["admin"], transaction).json()
    assert (body["status_after"], body["outcome"]) == ("en_attente", "pin_entered")


def test_recheck_expires_without_pin(client, auth_headers, db_session, provider, team):
    transaction = pending(
        db_session, provider, team["owner"], age=timedelta(minutes=20), ending="04"
    )
    body = recheck(client, auth_headers, team["admin"], transaction).json()
    assert (body["status_after"], body["outcome"]) == ("expiree", "expired")


def test_a_contradiction_changes_nothing_and_is_to_reconcile(
    client, auth_headers, db_session, provider, team
):
    # Expirée chez ElecPay, mais l'opérateur annonce maintenant un débit réussi.
    transaction = finish(
        db_session,
        pending(db_session, provider, team["owner"], age=timedelta(minutes=1)),
        TransactionStatus.EXPIRED,
        reason="Délai de confirmation dépassé (code PIN non saisi)",
    )
    body = recheck(client, auth_headers, team["admin"], transaction).json()
    assert (body["status_after"], body["outcome"]) == ("expiree", "conflict")
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.EXPIRED  # jamais forcée à « réussie »
    shown = detail(client, auth_headers, team["support"], transaction)
    assert shown["to_reconcile"] is True
    assert [a["action"] for a in shown["anomalies"]] == ["payment.provider_conflict"]
    status_line = next(line for line in shown["comparison"] if line["field"] == "status")
    assert (status_line["elecpay"], status_line["operator"], status_line["matches"]) == (
        "expiree",
        "succeeded",
        False,
    )
    assert [
        i["id"]
        for i in listing(client, auth_headers, team["support"], status="to_reconcile")["items"]
    ] == [transaction.id]


def test_unreachable_operator_changes_nothing(client, auth_headers, db_session, provider, team):
    transaction = pending(
        db_session,
        provider,
        team["owner"],
        age=timedelta(minutes=1),
        ending="06",
        ref="SIM-UNREACHABLE",
    )
    response = recheck(client, auth_headers, team["admin"], transaction)
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "PAYMENT_PROVIDER_UNAVAILABLE"
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.PENDING


def test_only_admins_recheck(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    assert recheck(client, auth_headers, team["support"], transaction).status_code == 403


# --- Litiges --------------------------------------------------------------------------------


def test_open_and_close_a_dispute(client, auth_headers, db_session, provider, team):
    transaction = finish(
        db_session,
        pending(db_session, provider, team["owner"], age=timedelta(minutes=3)),
        TransactionStatus.FAILED,
    )
    assert (
        open_dispute(client, auth_headers, team["admin"], transaction, reason="Débité").status_code
        == 422
    )
    response = open_dispute(
        client, auth_headers, team["admin"], transaction, customer_reference="MP261112.1432.A57"
    )
    assert response.status_code == 201, response.text
    dispute = response.json()
    assert (dispute["status"], dispute["opened_by"]) == ("open", "Christelle Mabiala")
    assert open_dispute(client, auth_headers, team["admin"], transaction).status_code == 409
    assert [
        i["id"]
        for i in listing(client, auth_headers, team["support"], status="open_dispute")["items"]
    ] == [transaction.id]

    close = f"{URL}/{transaction.id}/disputes/{dispute['id']}/close"
    body = {"resolution": "no_debit", "note": "MTN confirme : aucun débit sur ce numéro"}
    closed = client.post(close, json=body, headers=auth_headers(team["admin"]))
    assert closed.status_code == 200, closed.text
    assert (closed.json()["status"], closed.json()["resolution"]) == ("closed", "no_debit")
    assert client.post(close, json=body, headers=auth_headers(team["admin"])).status_code == 409
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.FAILED  # le litige ne change rien
    shown = detail(client, auth_headers, team["support"], transaction)
    assert [e["action"] for e in shown["timeline"]][-2:] == ["dispute.open", "dispute.resolve"]
    assert shown["can_open_dispute"] is True


def test_support_cannot_open_or_close_disputes(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    assert open_dispute(client, auth_headers, team["support"], transaction).status_code == 403


def test_closing_without_conclusion_is_refused(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    dispute = open_dispute(client, auth_headers, team["admin"], transaction).json()
    response = client.post(
        f"{URL}/{transaction.id}/disputes/{dispute['id']}/close",
        json={"resolution": "refunded", "note": "court"},
        headers=auth_headers(team["admin"]),
    )
    assert response.status_code == 422
    other = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    wrong = client.post(
        f"{URL}/{other.id}/disputes/{dispute['id']}/close",
        json={"resolution": "refunded", "note": "Remboursé par l'opérateur"},
        headers=auth_headers(team["admin"]),
    )
    assert wrong.status_code == 404


def make_dispute(session, transaction, opener, **overrides):
    dispute = PaymentDispute(
        transaction_id=transaction.id,
        reason=CLAIM,
        opened_by=opener.id,
        opened_at=utcnow(),
        **overrides,
    )
    session.add(dispute)
    session.flush()
    return dispute


def test_the_database_guards_disputes(db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    dispute = make_dispute(db_session, transaction, team["admin"])
    with expect_db_rejection(db_session, "uq_payment_disputes_open_transaction_id"):
        make_dispute(db_session, transaction, team["admin"])
    with expect_db_rejection(db_session, "ck_payment_disputes_closed_is_complete"):
        dispute.status = DisputeStatus.CLOSED  # sans conclusion
    with expect_db_rejection(db_session, "dispute_content_immutable"):
        dispute.reason = "Autre motif, réécrit après coup"
    dispute.status = DisputeStatus.CLOSED
    dispute.resolution = DisputeResolution.REFUNDED
    dispute.resolution_note = "Remboursé par l'opérateur"
    dispute.resolved_by = team["admin"].id
    dispute.resolved_at = utcnow()
    db_session.flush()
    with expect_db_rejection(db_session, "dispute_closed_immutable"):
        dispute.resolution_note = "Finalement autre chose"
    with expect_db_rejection(db_session, "dispute_delete_forbidden"):
        db_session.execute(delete(PaymentDispute).where(PaymentDispute.id == dispute.id))


def test_closed_dispute_ends_the_reconciliation(client, auth_headers, db_session, provider, team):
    transaction = pending(db_session, provider, team["owner"], age=timedelta(minutes=1))
    record(
        db_session,
        action="payment.amount_mismatch",
        entity_type="payment_transaction",
        entity_id=transaction.id,
        actor_id=None,
        after={"announced_amount": "1"},
    )
    db_session.flush()
    assert detail(client, auth_headers, team["support"], transaction)["to_reconcile"] is True
    make_dispute(
        db_session,
        transaction,
        team["admin"],
        status=DisputeStatus.CLOSED,
        resolution=DisputeResolution.NO_DEBIT,
        resolution_note="Aucun débit chez MTN",
        resolved_by=team["admin"].id,
        resolved_at=utcnow(),
    )
    assert detail(client, auth_headers, team["support"], transaction)["to_reconcile"] is False
