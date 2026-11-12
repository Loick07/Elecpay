"""Contraintes et garde-fous des tables `bills` et `bill_lines` (B1.5)."""

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.exc import StatementError

from app.modules.bills.models import BillLine, BillLineKind, BillStatus
from tests.db_helpers import expect_db_rejection
from tests.factories import (
    e2c_bill_lines,
    make_bill,
    make_bill_with_lines,
    make_meter,
    make_tariff,
)

NOW = datetime(2026, 9, 11, 10, 0, tzinfo=UTC)


def set_columns(session, bill, **values):
    """UPDATE en SQL brut : contourne Python pour tester la base elle-même."""
    assignments = ", ".join(f"{column} = :{column}" for column in values)
    session.execute(
        text(f"UPDATE bills SET {assignments} WHERE id = :id"), values | {"id": bill.id}
    )


# --- La vraie facture E²C -----------------------------------------------------------


def test_real_e2c_bill_is_stored_with_its_six_lines(db_session):
    bill = make_bill_with_lines(db_session)
    lines_total = db_session.scalar(
        select(func.sum(BillLine.amount)).where(BillLine.bill_id == bill.id)
    )
    assert lines_total == bill.amount_total == 40_384


def test_e2c_formulas_in_integers_reproduce_the_real_bill():
    """La règle de calcul (troncature, entiers) donne exactement les montants E²C."""
    energy = 571_000 * 49_080 // 1_000_000  # Wh × millièmes de FCFA/kWh
    fixed_fee = 2_000 * 2_550_000 // 1_000_000  # 2 mois × 2 550 FCFA
    ht = energy + fixed_fee
    vat = ht * 1_800 // 10_000
    additional = vat * 500 // 10_000
    assert (energy, fixed_fee, ht, vat, additional) == (28_024, 5_100, 33_124, 5_962, 298)
    assert ht + 1_000 + vat + additional + 0 == 40_384


def test_bill_defaults_and_computed_column(db_session):
    bill = make_bill(db_session)
    db_session.expire(bill)
    assert bill.status is BillStatus.UNPAID
    assert bill.active_period_start == date(2026, 7, 1)
    assert bill.paid_at is None


# --- Unicité ------------------------------------------------------------------------


def test_reference_is_unique(db_session):
    first = make_bill(db_session)
    with expect_db_rejection(db_session, "uq_bills_reference"):
        make_bill(db_session, reference=first.reference)


def test_one_active_bill_per_meter_and_period(db_session):
    meter = make_meter(db_session)
    make_bill(db_session, meter)
    with expect_db_rejection(db_session, "uq_bills_meter_id_active_period_start"):
        make_bill(db_session, meter)


def test_cancellation_reason_of_exactly_ten_characters_is_accepted(db_session):
    make_bill(
        db_session, status=BillStatus.CANCELLED, cancelled_at=NOW, cancelled_reason="Erreur 123"
    )


def test_cancelled_bill_frees_the_period_for_a_corrected_one(db_session):
    meter = make_meter(db_session)
    wrong = make_bill(db_session, meter)
    wrong.status = BillStatus.CANCELLED
    wrong.cancelled_at = NOW
    wrong.cancelled_reason = "Index mal relevé"
    db_session.flush()
    db_session.expire(wrong)
    assert wrong.active_period_start is None
    make_bill(db_session, meter)  # la facture corrigée


# --- Cohérence des valeurs (CHECK) --------------------------------------------------


@pytest.mark.parametrize(
    ("values", "constraint"),
    [
        ({"period_end": date(2026, 6, 30)}, "ck_bills_period_order"),
        ({"months_count": 0}, "ck_bills_months_count_range"),
        ({"months_count": 13}, "ck_bills_months_count_range"),
        ({"due_date": date(2026, 8, 30)}, "ck_bills_due_after_period"),
        (
            # consommation cohérente avec les index, pour isoler la règle « index qui baisse »
            {"current_index_wh": 14_000_000, "consumption_wh": -283_000},
            "ck_bills_index_not_decreasing",
        ),
        ({"consumption_wh": 570_000}, "ck_bills_consumption_matches_index"),
        ({"amount_total": 40_385}, "ck_bills_total_is_sum"),
        ({"amount_tax": -1, "amount_total": 40_383}, "ck_bills_amount_tax_non_negative"),
        ({"billed_power_va": 0}, "ck_bills_billed_power_positive"),
        ({"status": BillStatus.PAID}, "ck_bills_paid_has_date"),
        ({"paid_at": NOW}, "ck_bills_paid_has_date"),
        ({"status": BillStatus.CANCELLED, "cancelled_at": NOW}, "ck_bills_cancelled_has_reason"),
        (
            {"status": BillStatus.CANCELLED, "cancelled_at": NOW, "cancelled_reason": "  "},
            "ck_bills_cancelled_has_reason",
        ),
        (  # motif trop court : 9 caractères (≥ 10 exigés, écran A6)
            {"status": BillStatus.CANCELLED, "cancelled_at": NOW, "cancelled_reason": "Erreur 12"},
            "ck_bills_cancelled_has_reason",
        ),
        (  # espaces autour ignorés : « Doublon » ne fait que 7 caractères
            {
                "status": BillStatus.CANCELLED,
                "cancelled_at": NOW,
                "cancelled_reason": "  Doublon   ",
            },
            "ck_bills_cancelled_has_reason",
        ),
        ({"cancelled_reason": "motif sans annulation"}, "ck_bills_cancelled_has_reason"),
    ],
)
def test_inconsistent_bill_is_refused(db_session, values, constraint):
    with expect_db_rejection(db_session, constraint):
        make_bill(db_session, **values)


def test_float_amount_is_refused(db_session):
    with pytest.raises(StatementError, match="Entier attendu"):
        make_bill(db_session, amount_total=40_384.0)
    db_session.rollback()


def test_unknown_status_is_refused(db_session):
    bill = make_bill(db_session)
    with expect_db_rejection(db_session, "ck_bills_status"):
        set_columns(db_session, bill, status="refunded")


# --- Cycle de vie autorisé ----------------------------------------------------------


def test_normal_payment_lifecycle(db_session):
    bill = make_bill(db_session)
    bill.status = BillStatus.PENDING_PAYMENT
    db_session.flush()
    bill.status = BillStatus.PAID
    bill.paid_at = NOW
    db_session.flush()
    db_session.expire(bill)
    assert bill.status is BillStatus.PAID


def test_unpaid_bill_can_become_overdue(db_session):
    bill = make_bill(db_session)
    bill.status = BillStatus.OVERDUE
    db_session.flush()


# --- Garde-fous (triggers) : jamais supprimée, contenu figé -------------------------


def test_bill_can_never_be_deleted(db_session):
    bill = make_bill(db_session)
    with expect_db_rejection(db_session, "bill_delete_forbidden"):
        db_session.execute(text("DELETE FROM bills WHERE id = :id"), {"id": bill.id})


@pytest.mark.parametrize(
    "values",
    [
        {"due_date": date(2026, 10, 31)},
        {"reference": "AUTRE-REFERENCE"},
        {"amount_ht": 33_000, "amount_total": 40_260},  # total cohérent, mais montant modifié
        {"period_start": date(2026, 6, 1)},
    ],
)
def test_bill_content_never_changes_even_when_unpaid(db_session, values):
    bill = make_bill(db_session)
    with expect_db_rejection(db_session, "bill_content_immutable"):
        set_columns(db_session, bill, **values)


@pytest.mark.parametrize("closed_status", [BillStatus.PAID, BillStatus.CANCELLED])
def test_paid_or_cancelled_bill_is_frozen(db_session, closed_status):
    extra = (
        {"paid_at": NOW}
        if closed_status is BillStatus.PAID
        else {"cancelled_at": NOW, "cancelled_reason": "Facture émise en double"}
    )
    bill = make_bill(db_session, status=closed_status, **extra)
    with expect_db_rejection(db_session, "bill_closed_immutable"):
        set_columns(
            db_session,
            bill,
            status="unpaid",
            paid_at=None,
            cancelled_at=None,
            cancelled_reason=None,
        )


def test_paid_bill_cannot_be_cancelled(db_session):
    bill = make_bill(db_session, status=BillStatus.PAID, paid_at=NOW)
    with expect_db_rejection(db_session, "bill_closed_immutable"):
        set_columns(
            db_session,
            bill,
            status="cancelled",
            paid_at=None,
            cancelled_at=NOW,
            cancelled_reason="x",
        )


def test_meter_or_tariff_with_bills_cannot_be_deleted(db_session):
    meter = make_meter(db_session)
    tariff = make_tariff(db_session, code="BT_SUPPR")
    make_bill(db_session, meter, tariff)
    with expect_db_rejection(db_session, "fk_bills_meter_id_meters"):
        db_session.execute(text("DELETE FROM meters WHERE id = :id"), {"id": meter.id})
    with expect_db_rejection(db_session, "fk_bills_tariff_id_tariffs"):
        db_session.execute(text("DELETE FROM tariffs WHERE id = :id"), {"id": tariff.id})


# --- Lignes de facture --------------------------------------------------------------


def test_line_kinds_are_the_e2c_ones(db_session):
    bill = make_bill_with_lines(db_session)
    kinds = db_session.scalars(
        select(BillLine.kind).where(BillLine.bill_id == bill.id).order_by(BillLine.position)
    ).all()
    assert kinds == [
        BillLineKind.ENERGY,
        BillLineKind.FIXED_FEE,
        BillLineKind.AUDIOVISUAL_FEE,
        BillLineKind.VAT,
        BillLineKind.ADDITIONAL_TAX,
        BillLineKind.STAMP,
    ]


def test_line_position_is_unique_per_bill(db_session):
    bill = make_bill_with_lines(db_session)
    duplicate = e2c_bill_lines(bill)[0]
    with expect_db_rejection(db_session, "uq_bill_lines_bill_id_position"):
        db_session.add(duplicate)


@pytest.mark.parametrize(
    ("values", "constraint"),
    [
        ({"label": " "}, "ck_bill_lines_label_not_blank"),
        ({"position": 0}, "ck_bill_lines_position_positive"),
        ({"amount": -1}, "ck_bill_lines_amount_non_negative"),
        ({"quantity_milli": 1_000}, "ck_bill_lines_quantity_price_unit_together"),
        (
            {"quantity_milli": 1_000, "unit_price_milli": 5},
            "ck_bill_lines_quantity_price_unit_together",
        ),
        ({"rate_bp": 1_800}, "ck_bill_lines_rate_and_base_together"),
        ({"rate_bp": 10_001, "base_amount": 1}, "ck_bill_lines_rate_bp_range"),
    ],
)
def test_inconsistent_line_is_refused(db_session, values, constraint):
    bill = make_bill(db_session)
    line = {
        "bill_id": bill.id,
        "position": 1,
        "kind": BillLineKind.OTHER,
        "label": "Divers",
        "amount": 0,
    }
    with expect_db_rejection(db_session, constraint):
        db_session.add(BillLine(**(line | values)))


def test_line_requires_existing_bill(db_session):
    with expect_db_rejection(db_session, "fk_bill_lines_bill_id_bills"):
        db_session.add(
            BillLine(bill_id=999_999, position=1, kind=BillLineKind.OTHER, label="x", amount=0)
        )


def test_line_cannot_be_added_to_a_paid_bill(db_session):
    bill = make_bill(db_session, status=BillStatus.PAID, paid_at=NOW)
    with expect_db_rejection(db_session, "bill_closed_immutable"):
        db_session.add(
            BillLine(bill_id=bill.id, position=1, kind=BillLineKind.OTHER, label="x", amount=0)
        )


def test_line_can_never_be_modified(db_session):
    bill = make_bill_with_lines(db_session)
    with expect_db_rejection(db_session, "bill_line_immutable"):
        db_session.execute(
            text("UPDATE bill_lines SET amount = 0 WHERE bill_id = :id AND position = 1"),
            {"id": bill.id},
        )


def test_line_can_never_be_deleted(db_session):
    bill = make_bill_with_lines(db_session)
    with expect_db_rejection(db_session, "bill_line_immutable"):
        db_session.execute(text("DELETE FROM bill_lines WHERE bill_id = :id"), {"id": bill.id})
