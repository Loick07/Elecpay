"""Contraintes et garde-fous des tables `payment_transactions` et `receipts` (B1.6)."""

from datetime import timedelta

import pytest
from sqlalchemy import text
from sqlalchemy.exc import StatementError

from app.modules.bills.models import BillStatus
from app.modules.payments.models import TransactionStatus
from tests.db_helpers import expect_db_rejection
from tests.factories import (
    PAYMENT_START,
    confirm,
    make_bill,
    make_receipt,
    make_transaction,
    make_user,
)


def update_transaction(session, transaction, **values):
    """UPDATE en SQL brut : contourne Python pour tester la base elle-même."""
    assignments = ", ".join(f"{column} = :{column}" for column in values)
    session.execute(
        text(f"UPDATE payment_transactions SET {assignments} WHERE id = :id"),
        values | {"id": transaction.id},
    )


def fail(session, transaction, reason="Solde insuffisant"):
    transaction.status = TransactionStatus.FAILED
    transaction.failure_reason = reason
    session.flush()
    return transaction


# --- Création -----------------------------------------------------------------------


def test_transaction_starts_pending(db_session):
    transaction = make_transaction(db_session)
    db_session.expire(transaction)
    assert transaction.status is TransactionStatus.PENDING
    assert transaction.pending_bill_id == transaction.bill_id
    assert transaction.succeeded_bill_id is None


def test_delegated_payer_can_pay_someone_elses_bill(db_session):
    """Le payeur n'est pas forcément le titulaire (droit vérifié par le service en B7)."""
    make_transaction(db_session, payer=make_user(db_session, full_name="Fils à Paris"))


@pytest.mark.parametrize(
    ("values", "constraint"),
    [
        ({"status": TransactionStatus.SUCCEEDED}, "payment_must_start_pending"),
        ({"amount": 40_000}, "payment_amount_mismatch"),
        ({"amount": 40_385}, "payment_amount_mismatch"),
        ({"phone_number": "060000001"}, "ck_payment_transactions_phone_format"),
        ({"idempotency_key": " "}, "ck_payment_transactions_idempotency_key_not_blank"),
        ({"expires_at": PAYMENT_START}, "ck_payment_transactions_expires_after_initiation"),
        ({"failure_reason": "motif sans échec"}, "ck_payment_transactions_failure_has_reason"),
    ],
)
def test_invalid_transaction_is_refused(db_session, values, constraint):
    with expect_db_rejection(db_session, constraint):
        make_transaction(db_session, **values)


def test_amount_must_be_positive(db_session):
    bill = make_bill(db_session)
    with expect_db_rejection(db_session):
        make_transaction(db_session, bill, amount=0)


def test_float_amount_is_refused(db_session):
    with pytest.raises(StatementError, match="Entier attendu"):
        make_transaction(db_session, amount=40_384.0)
    db_session.rollback()


def test_unknown_provider_is_refused(db_session):
    # INSERT en SQL brut (sur un UPDATE, le trigger « contenu figé » refuserait avant le CHECK).
    bill = make_bill(db_session)
    payer = make_user(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_provider"):
        db_session.execute(
            text(
                "INSERT INTO payment_transactions (bill_id, payer_id, provider, operator,"
                " phone_number, amount, status, idempotency_key, initiated_at, expires_at,"
                " created_at, updated_at) VALUES (:b, :p, 'orange', 'mtn', '+242060000001', :a,"
                " 'en_attente', 'cle-orange', NOW(6), NOW(6) + INTERVAL 10 MINUTE, NOW(6), NOW(6))"
            ),
            {"b": bill.id, "p": payer.id, "a": bill.amount_total},
        )


def test_unknown_operator_is_refused(db_session):
    bill = make_bill(db_session)
    payer = make_user(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_operator"):
        db_session.execute(
            text(
                "INSERT INTO payment_transactions (bill_id, payer_id, provider, operator,"
                " phone_number, amount, status, idempotency_key, initiated_at, expires_at,"
                " created_at, updated_at) VALUES (:b, :p, 'simulated', 'orange', '+242060000001',"
                " :a, 'en_attente', 'cle-op', NOW(6), NOW(6) + INTERVAL 10 MINUTE, NOW(6), NOW(6))"
            ),
            {"b": bill.id, "p": payer.id, "a": bill.amount_total},
        )


# --- Code PIN saisi (B7.1) ------------------------------------------------------------------


def test_pin_entry_is_recorded_while_pending(db_session):
    transaction = make_transaction(db_session)
    transaction.pin_entered_at = PAYMENT_START + timedelta(seconds=5)
    db_session.flush()
    confirm(db_session, transaction)  # puis le débit est confirmé


def test_pin_entry_never_changes_once_recorded(db_session):
    transaction = make_transaction(db_session)
    transaction.pin_entered_at = PAYMENT_START + timedelta(seconds=5)
    db_session.flush()
    for value in (None, PAYMENT_START + timedelta(seconds=9)):
        with expect_db_rejection(db_session, "payment_content_immutable"):
            update_transaction(db_session, transaction, pin_entered_at=value)


def test_pin_cannot_be_entered_before_the_request(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_pin_after_initiation"):
        update_transaction(
            db_session, transaction, pin_entered_at=PAYMENT_START - timedelta(seconds=1)
        )


@pytest.mark.parametrize(
    ("status", "extra"),
    [
        (BillStatus.PAID, {"paid_at": PAYMENT_START}),
        (
            BillStatus.CANCELLED,
            {"cancelled_at": PAYMENT_START, "cancelled_reason": "Facture émise en double"},
        ),
    ],
)
def test_paid_or_cancelled_bill_cannot_be_paid(db_session, status, extra):
    bill = make_bill(db_session, status=status, **extra)
    with expect_db_rejection(db_session, "bill_not_payable"):
        make_transaction(db_session, bill)


def test_overdue_bill_can_be_paid(db_session):
    make_transaction(db_session, make_bill(db_session, status=BillStatus.OVERDUE))


# --- Idempotence et verrous ---------------------------------------------------------


def test_same_idempotency_key_never_creates_a_second_transaction(db_session):
    """Double clic sur « Payer » : la même clé est refusée par la base."""
    first = make_transaction(db_session)
    other_bill = make_bill(db_session)
    with expect_db_rejection(db_session, "uq_payment_transactions_idempotency_key"):
        make_transaction(db_session, other_bill, idempotency_key=first.idempotency_key)


def test_only_one_pending_transaction_per_bill(db_session):
    bill = make_bill(db_session)
    make_transaction(db_session, bill)
    with expect_db_rejection(db_session, "uq_payment_transactions_pending_bill_id"):
        make_transaction(db_session, bill)


def test_failed_then_new_attempt_is_allowed(db_session):
    bill = make_bill(db_session)
    fail(db_session, make_transaction(db_session, bill))
    retry = make_transaction(db_session, bill)
    confirm(db_session, retry)


def test_a_bill_can_never_be_paid_twice(db_session):
    bill = make_bill(db_session)
    confirm(db_session, make_transaction(db_session, bill))
    second = make_transaction(db_session, bill)  # la facture n'est pas encore marquée payée
    with expect_db_rejection(db_session, "uq_payment_transactions_succeeded_bill_id"):
        confirm(db_session, second)


def test_provider_reference_cannot_confirm_two_transactions(db_session):
    """Double webhook / rejeu : une même référence prestataire ne sert qu'une fois."""
    first = confirm(db_session, make_transaction(db_session))
    other = make_transaction(db_session)
    with expect_db_rejection(db_session, "uq_payment_transactions_provider_provider_ref"):
        update_transaction(
            db_session,
            other,
            status="reussie",
            provider_ref=first.provider_ref,
            confirmed_at=PAYMENT_START + timedelta(seconds=40),
        )


# --- Cohérence du statut ------------------------------------------------------------


def test_success_requires_confirmation_date_and_reference(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_success_is_confirmed"):
        update_transaction(db_session, transaction, status="reussie")


def test_failure_requires_a_reason(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_failure_has_reason"):
        update_transaction(db_session, transaction, status="echouee")


def test_expiry_requires_a_reason(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_failure_has_reason"):
        update_transaction(db_session, transaction, status="expiree")


def test_confirmation_cannot_precede_initiation(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "ck_payment_transactions_confirmed_after_initiation"):
        update_transaction(
            db_session,
            transaction,
            status="reussie",
            provider_ref="SIM-X",
            confirmed_at=PAYMENT_START - timedelta(seconds=1),
        )


# --- Garde-fous (triggers) ----------------------------------------------------------


def expire(session, transaction):
    transaction.status = TransactionStatus.EXPIRED
    transaction.failure_reason = "Délai de confirmation dépassé"
    session.flush()
    return transaction


@pytest.mark.parametrize("finish", [confirm, fail, expire])
def test_finished_transaction_is_frozen(db_session, finish):
    transaction = make_transaction(db_session)
    finish(db_session, transaction)
    with expect_db_rejection(db_session, "payment_closed_immutable"):
        update_transaction(
            db_session,
            transaction,
            status="en_attente",
            confirmed_at=None,
            failure_reason=None,
        )


def test_failed_payment_can_never_be_turned_into_success(db_session):
    """Un admin ne peut pas forcer un paiement confirmé, même en SQL."""
    transaction = fail(db_session, make_transaction(db_session))
    with expect_db_rejection(db_session, "payment_closed_immutable"):
        update_transaction(
            db_session,
            transaction,
            status="reussie",
            provider_ref="FORCE-ADMIN",
            confirmed_at=PAYMENT_START + timedelta(minutes=1),
            failure_reason=None,
        )


@pytest.mark.parametrize(
    "values",
    [
        {"amount": 1},
        {"phone_number": "+242069999999"},
        {"bill_id": 999_999},
        {"operator": "airtel"},  # B7.1 : l'opérateur est fixé à la création
    ],
)
def test_pending_transaction_content_never_changes(db_session, values):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "payment_content_immutable"):
        update_transaction(db_session, transaction, **values)


def test_transaction_can_never_be_deleted(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session, "payment_delete_forbidden"):
        db_session.execute(
            text("DELETE FROM payment_transactions WHERE id = :id"), {"id": transaction.id}
        )


def test_bill_with_transactions_cannot_be_deleted(db_session):
    transaction = make_transaction(db_session)
    with expect_db_rejection(db_session):
        db_session.execute(text("DELETE FROM bills WHERE id = :id"), {"id": transaction.bill_id})


# --- Reçus --------------------------------------------------------------------------


def test_receipt_for_successful_payment(db_session):
    receipt = make_receipt(db_session)
    db_session.expire(receipt)
    assert receipt.number.startswith("EP-2026-")
    assert receipt.pdf_path is None


@pytest.mark.parametrize("finish", [None, fail])
def test_receipt_requires_a_successful_payment(db_session, finish):
    transaction = make_transaction(db_session)
    if finish:
        finish(db_session, transaction)
    with expect_db_rejection(db_session, "receipt_requires_success"):
        make_receipt(db_session, transaction)


def test_one_receipt_per_transaction(db_session):
    receipt = make_receipt(db_session)
    with expect_db_rejection(db_session, "uq_receipts_transaction_id"):
        db_session.execute(
            text(
                "INSERT INTO receipts (transaction_id, number, issued_at, verification_code,"
                " created_at, updated_at) VALUES (:t, 'EP-2026-999999', NOW(6),"
                " 'ZZZZZZZZZZZZ', NOW(6), NOW(6))"
            ),
            {"t": receipt.transaction_id},
        )


@pytest.mark.parametrize(
    ("column", "value", "constraint"),
    [
        ("number", "EP-26-000001", "ck_receipts_number_format"),
        ("number", "REC-2026-000001", "ck_receipts_number_format"),
        ("verification_code", "abc", "ck_receipts_verification_code_format"),
        ("verification_code", "abcdefghijkl", "ck_receipts_verification_code_format"),
    ],
)
def test_receipt_formats(db_session, column, value, constraint):
    with expect_db_rejection(db_session, constraint):
        make_receipt(db_session, **{column: value})


def test_receipt_number_and_code_are_unique(db_session):
    first = make_receipt(db_session)
    with expect_db_rejection(db_session, "uq_receipts_number"):
        make_receipt(db_session, number=first.number)
    with expect_db_rejection(db_session, "uq_receipts_verification_code"):
        make_receipt(db_session, verification_code=first.verification_code)


def test_pdf_can_be_attached_once(db_session):
    receipt = make_receipt(db_session)
    receipt.pdf_path = "receipts/2026/EP-2026-000001.pdf"
    db_session.flush()
    with expect_db_rejection(db_session, "receipt_immutable"):
        db_session.execute(
            text("UPDATE receipts SET pdf_path = 'autre.pdf' WHERE id = :id"), {"id": receipt.id}
        )


def test_receipt_content_never_changes(db_session):
    receipt = make_receipt(db_session)
    with expect_db_rejection(db_session, "receipt_immutable"):
        db_session.execute(
            text("UPDATE receipts SET number = 'EP-2026-999998' WHERE id = :id"),
            {"id": receipt.id},
        )


def test_receipt_can_never_be_deleted(db_session):
    receipt = make_receipt(db_session)
    with expect_db_rejection(db_session, "receipt_immutable"):
        db_session.execute(text("DELETE FROM receipts WHERE id = :id"), {"id": receipt.id})
