"""Tests de l'émission des reçus (B8.1) : `issue_receipt` et son appel au succès d'un paiement."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.notifications.models import Notification, NotificationType
from app.modules.payments.confirmation import apply_provider_update
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.receipts import service
from app.modules.receipts.models import Receipt
from app.modules.receipts.service import (
    VERIFICATION_CODE_ALPHABET,
    ReceiptNumbersExhaustedError,
    format_verification_code,
    issue_receipt,
    new_verification_code,
    normalize_verification_code,
)
from tests.factories import (
    PAYMENT_START,
    confirm,
    make_bill,
    make_household,
    make_meter,
    make_receipt,
    make_transaction,
    make_user,
)


def succeed(session, transaction, at):
    """Ce que fait le prestataire : succès appliqué par la fonction unique de B7.3."""
    update = ProviderUpdate(
        transaction.provider_ref or f"SIM-TEST-{transaction.id}",  # une référence par débit
        ProviderState.SUCCEEDED,
        at,
        amount=transaction.amount,
    )
    return apply_provider_update(session, transaction.id, update, origin="test", now=at)


@pytest.fixture
def owner(db_session):
    return make_user(db_session)


@pytest.fixture
def bill(db_session, owner):
    return make_bill(db_session, make_meter(db_session, make_household(db_session, owner)))


def receipts_of(session, transaction):
    return session.scalars(select(Receipt).where(Receipt.transaction_id == transaction.id)).all()


# --- Émission au succès ------------------------------------------------------------------------


def test_a_successful_payment_gets_its_receipt(db_session, bill, owner):
    transaction = make_transaction(db_session, bill, owner)
    confirmed = PAYMENT_START + timedelta(seconds=10)
    succeed(db_session, transaction, confirmed)
    (receipt,) = receipts_of(db_session, transaction)
    assert receipt.number == "EP-2026-000001"
    assert receipt.issued_at == confirmed == transaction.confirmed_at
    assert len(receipt.verification_code) == 12
    assert receipt.pdf_path is None  # généré à la demande (B8.3), jamais stocké


def test_the_same_success_twice_gives_one_receipt(db_session, bill, owner):
    transaction = make_transaction(db_session, bill, owner)
    succeed(db_session, transaction, PAYMENT_START + timedelta(seconds=10))
    succeed(db_session, transaction, PAYMENT_START + timedelta(seconds=20))  # double webhook
    assert len(receipts_of(db_session, transaction)) == 1
    again = issue_receipt(db_session, transaction)
    assert again.id == receipts_of(db_session, transaction)[0].id


def test_a_failed_payment_has_no_receipt(db_session, bill, owner):
    transaction = make_transaction(db_session, bill, owner)
    update = ProviderUpdate("SIM-X", ProviderState.FAILED, PAYMENT_START, failure_reason="Refus")
    apply_provider_update(db_session, transaction.id, update, origin="test", now=PAYMENT_START)
    assert receipts_of(db_session, transaction) == []


def test_no_receipt_for_a_payment_that_did_not_succeed(db_session, bill, owner):
    transaction = make_transaction(db_session, bill, owner)
    with pytest.raises(ValueError, match="paiement réussi"):
        issue_receipt(db_session, transaction)


def test_the_notification_points_to_the_receipt(db_session, bill, owner):
    transaction = make_transaction(db_session, bill, owner)
    succeed(db_session, transaction, PAYMENT_START + timedelta(seconds=10))
    (receipt,) = receipts_of(db_session, transaction)
    (notice,) = db_session.scalars(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == NotificationType.PAYMENT_SUCCEEDED,
        )
    ).all()
    assert notice.body.endswith(f"Reçu {receipt.number} disponible.")
    assert notice.data_json["receipt_id"] == receipt.id


# --- Numérotation ---------------------------------------------------------------------------------


def test_numbers_follow_each_other(db_session, owner):
    numbers = []
    for _ in range(3):
        bill = make_bill(db_session, make_meter(db_session, make_household(db_session, owner)))
        transaction = make_transaction(db_session, bill, owner)
        succeed(db_session, transaction, PAYMENT_START + timedelta(seconds=10))
        numbers.append(receipts_of(db_session, transaction)[0].number)
    assert numbers == ["EP-2026-000001", "EP-2026-000002", "EP-2026-000003"]


def test_numbers_continue_after_existing_ones(db_session, bill, owner):
    make_receipt(db_session, number="EP-2026-000041")  # par ex. créé par le seed
    transaction = make_transaction(db_session, bill, owner)
    succeed(db_session, transaction, PAYMENT_START + timedelta(seconds=10))
    assert receipts_of(db_session, transaction)[0].number == "EP-2026-000042"


def test_numbering_restarts_each_year_in_brazzaville_time(db_session, bill, owner):
    make_receipt(db_session, number="EP-2026-000500")
    # 31/12/2026 à 23 h 30 UTC = 1er janvier 2027 à 0 h 30 à Brazzaville.
    started = datetime(2026, 12, 31, 23, 29, tzinfo=UTC)
    transaction = make_transaction(
        db_session, bill, owner, initiated_at=started, expires_at=started + timedelta(minutes=10)
    )
    succeed(db_session, transaction, datetime(2026, 12, 31, 23, 30, tzinfo=UTC))
    assert receipts_of(db_session, transaction)[0].number == "EP-2027-000001"


def test_no_number_left_for_the_year(db_session, bill, owner):
    make_receipt(db_session, number="EP-2026-999999")
    transaction = confirm(db_session, make_transaction(db_session, bill, owner))
    with pytest.raises(ReceiptNumbersExhaustedError):
        issue_receipt(db_session, transaction)


# --- Code de vérification -----------------------------------------------------------------------


def test_codes_avoid_confusing_characters():
    assert not set("0O1IL") & set(VERIFICATION_CODE_ALPHABET)
    codes = {new_verification_code() for _ in range(200)}
    assert len(codes) == 200  # tirés au hasard (secrets) : jamais deux fois le même ici
    assert all(len(code) == 12 and set(code) <= set(VERIFICATION_CODE_ALPHABET) for code in codes)


def test_a_code_already_taken_is_drawn_again(db_session, bill, owner, monkeypatch):
    taken = make_receipt(db_session).verification_code
    draws = iter([taken, "ABCDEFGHJKMN"])
    monkeypatch.setattr(service, "new_verification_code", lambda: next(draws))
    transaction = confirm(db_session, make_transaction(db_session, bill, owner))
    assert issue_receipt(db_session, transaction).verification_code == "ABCDEFGHJKMN"


def test_code_display_and_typing():
    assert format_verification_code("8F3K2Q9M7XHT") == "8F3K-2Q9M-7XHT"
    assert normalize_verification_code(" 8f3k-2q9m 7xht ") == "8F3K2Q9M7XHT"


# --- Cohérence générale --------------------------------------------------------------------


def test_as_many_receipts_as_successful_payments(db_session, owner):
    for _ in range(4):
        bill = make_bill(db_session, make_meter(db_session, make_household(db_session, owner)))
        succeed(
            db_session,
            make_transaction(db_session, bill, owner),
            PAYMENT_START + timedelta(seconds=10),
        )
    receipts = db_session.scalar(select(func.count()).select_from(Receipt))
    successes = db_session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .where(PaymentTransaction.status == TransactionStatus.SUCCEEDED)
    )
    assert receipts == successes == 4
