"""Tests du lancement d'un paiement (B7.2) : POST /payments."""

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.router import PAYMENTS_PER_USER
from app.modules.payments.service import PROVIDER_UNAVAILABLE
from tests.factories import make_bill, make_household, make_member, make_meter, make_user

URL = "/api/v1/payments"
OWNER_PHONE = "+242061110001"


@pytest.fixture
def family(db_session):
    owner = make_user(db_session, phone=OWNER_PHONE)
    payer, viewer = make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home, reference="0412-8833")
    bill = make_bill(db_session, meter)  # 40 384 FCFA, impayée
    return {"owner": owner, "payer": payer, "viewer": viewer, "meter": meter, "bill": bill}


def new_key() -> str:
    return uuid.uuid4().hex


def pay(client, headers, bill, *, phone="06 111 00 01", operator="mtn", key=None, **extra):
    body = {"bill_id": bill.id, "operator": operator, "phone_number": phone} | extra
    return client.post(URL, json=body, headers=headers | {"Idempotency-Key": key or new_key()})


def transactions(session, bill):
    return session.scalars(
        select(PaymentTransaction).where(PaymentTransaction.bill_id == bill.id)
    ).all()


# --- Paiement lancé --------------------------------------------------------------------------


def test_owner_starts_a_payment(client, auth_headers, db_session, family):
    before = datetime.now(UTC)
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert response.status_code == 201
    body = response.json()
    assert body["amount"] == 40_384  # le montant de la facture, jamais choisi par le client
    assert (body["operator"], body["operator_label"]) == ("mtn", "MTN MoMo")
    assert body["phone_number"] == OWNER_PHONE  # le sien : en clair
    assert (body["status"], body["step"], body["failure_reason"]) == (
        "en_attente",
        "requested",
        None,
    )
    assert (body["is_mine"], body["source"]) == (True, "simulated")
    assert body["reference"] == f"TX-{body['id']:08d}"
    assert body["bill_reference"] == family["bill"].reference

    (transaction,) = transactions(db_session, family["bill"])
    assert transaction.provider_ref.startswith("SIM-")
    assert transaction.initiated_at >= before - timedelta(seconds=1)
    assert transaction.expires_at - transaction.initiated_at == timedelta(minutes=10)
    assert family["bill"].status is BillStatus.PENDING_PAYMENT


def test_bill_shows_the_payment_in_progress(client, auth_headers, family):
    headers = auth_headers(family["owner"])
    pay(client, headers, family["bill"])
    bill = client.get(f"/api/v1/bills/{family['bill'].id}", headers=headers).json()
    assert (bill["status"], bill["can_pay"]) == ("pending_payment", False)


def test_initiation_is_audited_without_the_full_number(client, auth_headers, db_session, family):
    payment_id = pay(client, auth_headers(family["owner"]), family["bill"]).json()["id"]
    log = db_session.scalars(
        select(AuditLog).where(
            AuditLog.action == "payment.initiate", AuditLog.entity_id == payment_id
        )
    ).one()
    assert log.actor_id == family["owner"].id
    assert log.after_json["phone_number"] == "+242 06 *** ** 01"
    assert log.after_json["amount"] == 40_384


def test_a_delegated_payer_pays_from_a_relatives_phone(client, auth_headers, family):
    response = pay(
        client,
        auth_headers(family["payer"]),
        family["bill"],
        phone="05 999 88 71",
        operator="airtel",
    )
    assert response.status_code == 201
    assert (response.json()["operator"], response.json()["payer_id"]) == (
        "airtel",
        family["payer"].id,
    )


def test_an_overdue_bill_can_be_paid(client, auth_headers, db_session, family):
    family["bill"].status = BillStatus.OVERDUE
    db_session.flush()
    assert pay(client, auth_headers(family["owner"]), family["bill"]).status_code == 201


# --- Double clic et clé d'idempotence ------------------------------------------------------------


def test_double_click_returns_the_same_transaction(client, auth_headers, db_session, family):
    headers, key = auth_headers(family["owner"]), new_key()
    first = pay(client, headers, family["bill"], key=key)
    second = pay(client, headers, family["bill"], key=key)
    assert (first.status_code, second.status_code) == (201, 200)
    assert first.json() == second.json()
    assert len(transactions(db_session, family["bill"])) == 1


@pytest.mark.parametrize(
    "changes",
    [{"phone": "06 111 00 99"}, {"operator": "airtel", "phone": "05 111 00 01"}],
)
def test_same_key_for_another_request_is_refused(client, auth_headers, family, changes):
    headers, key = auth_headers(family["owner"]), new_key()
    pay(client, headers, family["bill"], key=key)
    response = pay(client, headers, family["bill"], key=key, **changes)
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "IDEMPOTENCY_KEY_REUSED"


def test_someone_elses_key_is_refused_without_revealing_anything(client, auth_headers, family):
    key = new_key()
    pay(client, auth_headers(family["owner"]), family["bill"], key=key)
    response = pay(client, auth_headers(family["payer"]), family["bill"], key=key)
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.parametrize("key", ["court", "a" * 65, "avec des espaces", "cle!invalide#123"])
def test_malformed_key_is_refused(client, auth_headers, family, key):
    response = pay(client, auth_headers(family["owner"]), family["bill"], key=key)
    assert response.status_code == 422


def test_key_is_required(client, auth_headers, family):
    body = {"bill_id": family["bill"].id, "operator": "mtn", "phone_number": OWNER_PHONE}
    response = client.post(URL, json=body, headers=auth_headers(family["owner"]))
    assert response.status_code == 422
    assert "Idempotency-Key" in str(response.json()["error"]["details"])


# --- Verrou de la facture ----------------------------------------------------------------------


def test_a_second_payment_while_one_is_pending_is_refused(client, auth_headers, family):
    first = pay(client, auth_headers(family["owner"]), family["bill"]).json()
    response = pay(client, auth_headers(family["payer"]), family["bill"])
    assert response.status_code == 409
    error = response.json()["error"]
    assert (error["code"], error["details"]) == (
        "PAYMENT_IN_PROGRESS",
        {"transaction_id": first["id"]},
    )


def test_a_paid_bill_cannot_be_paid(client, auth_headers, db_session, family):
    family["bill"].status = BillStatus.PAID
    family["bill"].paid_at = datetime(2026, 9, 10, tzinfo=UTC)
    db_session.flush()
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert (response.status_code, response.json()["error"]["code"]) == (409, "BILL_ALREADY_PAID")
    assert transactions(db_session, family["bill"]) == []


def test_a_cancelled_bill_cannot_be_paid(client, auth_headers, db_session, family):
    family["bill"].status = BillStatus.CANCELLED
    family["bill"].cancelled_at = datetime(2026, 9, 10, tzinfo=UTC)
    family["bill"].cancelled_reason = "Facture émise par erreur"
    db_session.flush()
    response = pay(client, auth_headers(family["owner"]), family["bill"])
    assert (response.status_code, response.json()["error"]["code"]) == (409, "BILL_NOT_PAYABLE")


def test_the_amount_can_never_be_chosen(client, auth_headers, db_session, family):
    response = pay(client, auth_headers(family["owner"]), family["bill"], amount=1)
    assert response.status_code == 422
    assert transactions(db_session, family["bill"]) == []


# --- Numéro et opérateur ------------------------------------------------------------------------


def test_number_must_match_the_operator(client, auth_headers, family):
    response = pay(client, auth_headers(family["owner"]), family["bill"], operator="airtel")
    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "OPERATOR_MISMATCH"
    assert error["details"] == {"expected_operator": "mtn", "chosen_operator": "airtel"}


def test_a_landline_cannot_pay(client, auth_headers, family):
    response = pay(client, auth_headers(family["owner"]), family["bill"], phone="22 211 00 01")
    assert (response.status_code, response.json()["error"]["code"]) == (
        422,
        "PHONE_NOT_MOBILE_MONEY",
    )


@pytest.mark.parametrize("phone", ["123", "07 111 00 01", ""])
def test_invalid_number_is_refused(client, auth_headers, family, phone):
    response = pay(client, auth_headers(family["owner"]), family["bill"], phone=phone)
    assert (response.status_code, response.json()["error"]["code"]) == (422, "VALIDATION_ERROR")


# --- Droits ---------------------------------------------------------------------------------------


def test_a_viewer_cannot_pay(client, auth_headers, db_session, family):
    response = pay(client, auth_headers(family["viewer"]), family["bill"])
    assert (response.status_code, response.json()["error"]["code"]) == (403, "PAYMENT_FORBIDDEN")
    assert transactions(db_session, family["bill"]) == []


def test_a_stranger_cannot_even_see_the_bill(client, auth_headers, db_session, family):
    response = pay(client, auth_headers(make_user(db_session)), family["bill"])
    assert (response.status_code, response.json()["error"]["code"]) == (404, "BILL_NOT_FOUND")


def test_unknown_bill(client, auth_headers, family):
    response = client.post(
        URL,
        json={"bill_id": 999_999_999, "operator": "mtn", "phone_number": OWNER_PHONE},
        headers=auth_headers(family["owner"]) | {"Idempotency-Key": new_key()},
    )
    assert response.status_code == 404


def test_login_is_required(client, family):
    response = client.post(
        URL,
        json={"bill_id": family["bill"].id, "operator": "mtn", "phone_number": OWNER_PHONE},
        headers={"Idempotency-Key": new_key()},
    )
    assert response.status_code == 401


# --- Prestataire injoignable ----------------------------------------------------------------------


def test_unreachable_provider_leaves_the_bill_payable(client, auth_headers, db_session, family):
    family["bill"].status = BillStatus.OVERDUE
    db_session.flush()
    headers = auth_headers(family["owner"])
    response = pay(
        client, headers, family["bill"], phone="06 000 00 06"
    )  # scénario « injoignable »
    assert response.status_code == 201
    body = response.json()
    assert (body["status"], body["step"], body["failure_reason"]) == (
        "echouee",
        "failed",
        PROVIDER_UNAVAILABLE,
    )
    assert family["bill"].status is BillStatus.OVERDUE  # rien n'a changé pour la facture
    retry = pay(client, headers, family["bill"])  # nouvelle tentative, nouvelle clé
    assert retry.status_code == 201
    statuses = sorted(t.status for t in transactions(db_session, family["bill"]))
    assert statuses == sorted([TransactionStatus.FAILED, TransactionStatus.PENDING])


# --- Limite de demandes ---------------------------------------------------------------------


def test_too_many_payment_requests(client, auth_headers, db_session, family):
    headers = auth_headers(family["owner"])
    for _ in range(PAYMENTS_PER_USER.max_events):
        pay(client, headers, family["bill"])  # la 1re crée, les suivantes : « déjà en cours »
    response = pay(client, headers, family["bill"])
    assert response.status_code == 429
    assert response.headers["Retry-After"]
    count = db_session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .where(PaymentTransaction.bill_id == family["bill"].id)
    )
    assert count == 1
