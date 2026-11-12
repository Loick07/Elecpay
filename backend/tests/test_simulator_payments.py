"""Tests du simulateur d'historique de paiements (B2.4)."""

import re
from collections import Counter
from dataclasses import asdict
from datetime import UTC, date, datetime

import pytest

from app.modules.bills.models import Bill, BillLine, BillSource, BillStatus
from app.modules.bills.periods import bill_reference
from app.modules.payments.models import PaymentProvider, PaymentTransaction, TransactionStatus
from app.modules.receipts.models import Receipt
from app.simulators.bills import generate_bills
from app.simulators.payments import (
    PAYMENT_TIMEOUT,
    BillOutcome,
    Payer,
    PaymentBehaviour,
    simulate_payments,
)
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.factories import make_meter, make_tariff, make_user
from tests.test_bill_calculator import E2C

AS_OF = datetime(2026, 11, 12, 9, 0, tzinfo=UTC)
OWNER = Payer("owner", "+242061111111")
DELEGATE = Payer("delegate", "+242052222222")


def simulated_bills(seed=42):
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY],
        date(2025, 5, 1),
        date(2026, 11, 11),
        start_index_wh=14_000_000,
        seed=seed,
    )
    return generate_bills(
        readings, E2C, period_months=2, issue_delay_days=3, due_delay_days=15, as_of=AS_OF.date()
    )


def stories_for(seed=42, delegate=DELEGATE, behaviour=None):
    return simulate_payments(
        simulated_bills(seed),
        owner=OWNER,
        delegate=delegate,
        as_of=AS_OF,
        seed=seed,
        behaviour=behaviour,
    )


def all_stories(seeds=range(30)):
    return [story for seed in seeds for story in stories_for(seed)]


# --- Règles du plan B2 --------------------------------------------------------------


def test_old_bills_are_all_paid():
    for seed in range(30):
        for story in stories_for(seed)[:-2]:  # toutes sauf les deux plus récentes
            assert story.outcome is BillOutcome.PAID


def test_some_recent_bills_stay_unpaid_or_overdue():
    outcomes = Counter(story.outcome for story in all_stories())
    assert outcomes[BillOutcome.UNPAID] > 0
    assert outcomes[BillOutcome.OVERDUE] > 0
    assert outcomes[BillOutcome.PAID] > 0.8 * sum(outcomes.values())


def test_unpaid_means_not_yet_due_and_overdue_means_due_date_passed():
    for story in all_stories():
        if story.outcome is BillOutcome.UNPAID:
            assert story.bill.due_date >= AS_OF.date()
        if story.outcome is BillOutcome.OVERDUE:
            assert story.bill.due_date < AS_OF.date()


def test_some_payments_are_made_by_the_delegated_payer():
    payers = Counter(a.payer_key for s in all_stories() for a in s.attempts)
    assert payers["delegate"] > 0
    assert payers["owner"] > payers["delegate"]


def test_no_delegate_means_the_owner_always_pays():
    for seed in range(10):
        for story in stories_for(seed, delegate=None):
            assert all(a.payer_key == "owner" for a in story.attempts)


def test_failures_and_expirations_happen():
    statuses = Counter(a.status for s in all_stories() for a in s.attempts)
    assert statuses[TransactionStatus.FAILED] > 0
    assert statuses[TransactionStatus.EXPIRED] > 0


# --- Cohérence de chaque histoire ---------------------------------------------------


def test_paid_bill_has_exactly_one_success_and_it_comes_last():
    for story in all_stories():
        successes = [a for a in story.attempts if a.status is TransactionStatus.SUCCEEDED]
        if story.outcome is BillOutcome.PAID:
            assert len(successes) == 1
            assert story.attempts[-1] is successes[0]
            assert story.paid_at == successes[0].confirmed_at
        else:
            assert successes == []
            assert story.paid_at is None


def test_attempts_never_overlap_and_never_happen_in_the_future():
    for story in all_stories():
        for previous, current in zip(story.attempts, story.attempts[1:], strict=False):
            assert current.initiated_at > previous.finished_at  # une seule « en attente » à la fois
        for attempt in story.attempts:
            assert story.bill.issued_at < attempt.initiated_at
            assert attempt.finished_at <= AS_OF


def test_attempt_fields_are_consistent():
    references = []
    for story in all_stories():
        for attempt in story.attempts:
            assert attempt.amount == story.bill.computation.amount_total
            assert attempt.expires_at == attempt.initiated_at + PAYMENT_TIMEOUT
            assert re.fullmatch(r"[0-9a-f]{32}", attempt.idempotency_key)
            if attempt.status is TransactionStatus.SUCCEEDED:
                assert attempt.initiated_at < attempt.confirmed_at <= attempt.expires_at
                assert re.fullmatch(r"[A-Z0-9]{12}", attempt.receipt_verification_code)
                references.append(attempt.provider_ref)
            else:
                assert attempt.failure_reason
                assert attempt.confirmed_at is None and attempt.receipt_verification_code is None
    assert len(references) == len(set(references))  # références opérateur uniques


def test_payment_is_close_to_the_due_date():
    for story in all_stories():
        if story.outcome is BillOutcome.PAID:
            delay = (story.paid_at.date() - story.bill.due_date).days
            assert delay <= 6  # au plus quelques jours après l'échéance


def test_same_seed_same_history():
    assert stories_for(7) == stories_for(7)


def test_bill_issued_after_as_of_is_refused():
    bills = simulated_bills()
    with pytest.raises(ValueError, match="émise après"):
        simulate_payments(
            bills, owner=OWNER, delegate=None, as_of=datetime(2025, 7, 1, tzinfo=UTC), seed=1
        )


def test_behaviour_can_force_everything_paid():
    always_pay = PaymentBehaviour(recent_unpaid_probability=0, overdue_probability=0)
    assert all(s.outcome is BillOutcome.PAID for s in stories_for(behaviour=always_pay))


# --- L'historique s'enregistre en base en respectant le cycle de vie ----------------


def test_history_is_accepted_by_the_database_and_its_triggers(db_session):
    """Insertion « en attente » puis passage au statut final, comme le fera le webhook."""
    owner, delegate = make_user(db_session), make_user(db_session)
    user_ids = {"owner": owner.id, "delegate": delegate.id}
    meter, tariff = make_meter(db_session), make_tariff(db_session)
    stories = stories_for(seed=3)
    receipt_number = 0

    for sequence, story in enumerate(stories, start=1):
        sim = story.bill
        bill = Bill(
            meter_id=meter.id,
            tariff_id=tariff.id,
            reference=bill_reference(sim.issued_at.date(), sequence),
            period_start=sim.period_start,
            period_end=sim.period_end,
            months_count=sim.months_count,
            previous_index_wh=sim.previous_index_wh,
            current_index_wh=sim.current_index_wh,
            consumption_wh=sim.consumption_wh,
            amount_ht=sim.computation.amount_ht,
            amount_tax=sim.computation.amount_tax,
            amount_fees=sim.computation.amount_fees,
            amount_total=sim.computation.amount_total,
            due_date=sim.due_date,
            issued_at=sim.issued_at,
            source=BillSource.SIMULATED,
        )
        db_session.add(bill)
        db_session.flush()
        db_session.add_all(
            BillLine(bill_id=bill.id, **asdict(line)) for line in sim.computation.lines
        )
        db_session.flush()

        for attempt in story.attempts:
            transaction = PaymentTransaction(
                bill_id=bill.id,
                payer_id=user_ids[attempt.payer_key],
                provider=PaymentProvider.SIMULATED,
                phone_number=attempt.phone_number,
                amount=attempt.amount,
                idempotency_key=attempt.idempotency_key,
                initiated_at=attempt.initiated_at,
                expires_at=attempt.expires_at,
            )
            db_session.add(transaction)
            db_session.flush()  # naît « en attente »
            transaction.status = attempt.status
            transaction.confirmed_at = attempt.confirmed_at
            transaction.provider_ref = attempt.provider_ref
            transaction.failure_reason = attempt.failure_reason
            db_session.flush()
            if attempt.status is TransactionStatus.SUCCEEDED:
                receipt_number += 1
                db_session.add(
                    Receipt(
                        transaction_id=transaction.id,
                        number=f"EP-{attempt.confirmed_at:%Y}-{receipt_number:06d}",
                        issued_at=attempt.confirmed_at,
                        verification_code=attempt.receipt_verification_code,
                    )
                )
                db_session.flush()

        if story.outcome is BillOutcome.PAID:
            bill.status, bill.paid_at = BillStatus.PAID, story.paid_at
        elif story.outcome is BillOutcome.OVERDUE:
            bill.status = BillStatus.OVERDUE
        db_session.flush()

    assert receipt_number == sum(s.outcome is BillOutcome.PAID for s in stories) > 0
