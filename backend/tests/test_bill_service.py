"""Tests du service des factures : émission `generate_bill` (B6.1), retards (B6.2)."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.core.timezone import local_date, local_midnight_utc
from app.modules.bills.errors import (
    BillingError,
    BillingPeriodCancelledError,
    BillingPeriodNotClosedError,
    BillingReadingAnomalyError,
    BillingReadingMissingError,
    BillingReadingsMismatchError,
    BillSequenceExhaustedError,
    InvalidBillingPeriodError,
    NoTariffError,
)
from app.modules.bills.models import Bill, BillLine, BillLineKind, BillSource, BillStatus
from app.modules.bills.periods import billing_period, billing_periods, is_period_start
from app.modules.bills.service import generate_bill, mark_overdue_bills
from app.modules.consumption.models import ReadingSource
from app.modules.notifications.models import Notification, NotificationType
from app.simulators.bills import generate_bills
from app.simulators.persistence import insert_readings
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.factories import (
    Billing,
    make_bill,
    make_household,
    make_meter,
    make_reading,
    make_tariff,
)

JULY = date(2026, 7, 1)  # période juillet-août 2026 de la vraie facture E²C
ISSUE_DAY = date(2026, 9, 3)
SETTINGS = Billing()


def reading(session, meter, day, index_wh, consumption_wh, **overrides):
    """Relevé de minuit (heure du Congo) au début de `day`."""
    return make_reading(
        session,
        meter,
        read_at=local_midnight_utc(day),
        index_wh=index_wh,
        consumption_wh=consumption_wh,
        **overrides,
    )


def real_bill_meter(session, **meter_overrides):
    """Compteur dont les index reproduisent la vraie facture : 14 283 → 14 854 kWh (571 kWh)."""
    meter = make_meter(session, subscribed_power_va=3_000, **meter_overrides)
    reading(session, meter, JULY, 14_283_000, 9_000)
    reading(session, meter, date(2026, 9, 1), 14_854_000, 571_000)
    return meter


def generate(session, meter, start=JULY, today=ISSUE_DAY):
    return generate_bill(session, meter, start, today=today, settings=SETTINGS)


def bills_of(session, meter):
    return session.scalars(select(Bill).where(Bill.meter_id == meter.id).order_by(Bill.id)).all()


@pytest.fixture
def tariff(db_session):
    return make_tariff(db_session, valid_from=date(2025, 1, 1))


# --- La vraie facture ------------------------------------------------------------------


def test_reproduces_the_real_e2c_bill(db_session, tariff):
    meter = real_bill_meter(db_session)
    issued = generate(db_session, meter)
    bill = issued.bill

    assert issued.created
    assert bill.amount_total == 40_384
    assert (bill.amount_ht, bill.amount_tax, bill.amount_fees) == (33_124, 6_260, 1_000)
    assert (bill.previous_index_wh, bill.current_index_wh) == (14_283_000, 14_854_000)
    assert bill.consumption_wh == 571_000
    assert (bill.period_start, bill.period_end, bill.months_count) == (
        JULY,
        date(2026, 8, 31),
        2,
    )
    assert bill.billed_power_va == 3_000
    assert bill.tariff_id == tariff.id
    assert bill.status is BillStatus.UNPAID
    assert bill.source is BillSource.SIMULATED


def test_dates_and_reference_follow_the_real_bill(db_session, tariff):
    bill = generate(db_session, real_bill_meter(db_session)).bill
    assert bill.issued_at == datetime(2026, 9, 3, 7, 0, tzinfo=UTC)  # 8 h à Brazzaville
    assert bill.due_date == date(2026, 9, 18)
    assert bill.reference == "20260903000001"  # AAAAMMJJ + 6 chiffres


def test_lines_are_stored_and_add_up_to_the_total(db_session, tariff):
    bill = generate(db_session, real_bill_meter(db_session)).bill
    lines = db_session.scalars(
        select(BillLine).where(BillLine.bill_id == bill.id).order_by(BillLine.position)
    ).all()
    assert [line.kind for line in lines] == [
        BillLineKind.ENERGY,
        BillLineKind.FIXED_FEE,
        BillLineKind.AUDIOVISUAL_FEE,
        BillLineKind.VAT,
        BillLineKind.ADDITIONAL_TAX,
        BillLineKind.STAMP,
    ]
    assert [line.amount for line in lines] == [28_024, 5_100, 1_000, 5_962, 298, 0]
    assert sum(line.amount for line in lines) == bill.amount_total


def test_a_detached_meter_is_still_billed(db_session, tariff):
    """E²C facture le compteur, même s'il n'est rattaché à aucun foyer dans ElecPay."""
    meter = real_bill_meter(db_session)
    assert meter.household_id is None
    assert generate(db_session, meter).created


# --- Idempotence -------------------------------------------------------------------------


def test_calling_twice_returns_the_same_bill(db_session, tariff):
    meter = real_bill_meter(db_session)
    first = generate(db_session, meter)
    again = generate(db_session, meter, today=date(2026, 10, 1))
    assert not again.created
    assert again.bill.id == first.bill.id
    assert len(bills_of(db_session, meter)) == 1
    lines = db_session.scalar(
        select(func.count()).select_from(BillLine).where(BillLine.bill_id == first.bill.id)
    )
    assert lines == 6


def test_a_paid_bill_is_returned_untouched(db_session, tariff):
    meter = real_bill_meter(db_session)
    bill = generate(db_session, meter).bill
    bill.status, bill.paid_at = BillStatus.PAID, datetime(2026, 9, 10, tzinfo=UTC)
    db_session.flush()
    again = generate(db_session, meter)
    assert not again.created and again.bill.status is BillStatus.PAID


def test_a_cancelled_period_is_not_billed_again(db_session, tariff):
    meter = real_bill_meter(db_session)
    cancel(db_session, generate(db_session, meter).bill)
    with pytest.raises(BillingPeriodCancelledError) as error:
        generate(db_session, meter)
    assert error.value.details["meter_reference"] == meter.reference
    assert len(bills_of(db_session, meter)) == 1


def test_the_corrected_bill_of_a_cancelled_period_is_returned(db_session, tariff):
    """Après annulation, l'administration émet la facture corrigée : c'est elle qu'on renvoie."""
    meter = real_bill_meter(db_session)
    cancel(db_session, generate(db_session, meter).bill)
    corrected = make_bill(db_session, meter, tariff, reference="20260910000001")
    again = generate(db_session, meter)
    assert not again.created and again.bill.id == corrected.id


def cancel(session, bill):
    bill.status = BillStatus.CANCELLED
    bill.cancelled_at = datetime(2026, 9, 5, tzinfo=UTC)
    bill.cancelled_reason = "Facture émise par erreur"
    session.flush()


# --- Numéros de facture ------------------------------------------------------------------


def test_numbers_follow_each_other_on_the_same_issue_day(db_session, tariff):
    first = generate(db_session, real_bill_meter(db_session)).bill
    second = generate(db_session, real_bill_meter(db_session)).bill
    assert (first.reference, second.reference) == ("20260903000001", "20260903000002")


def test_numbers_continue_after_existing_ones(db_session, tariff):
    other = make_meter(db_session)
    make_bill(db_session, other, tariff, reference="20260903000041", period_start=date(2026, 5, 1))
    bill = generate(db_session, real_bill_meter(db_session)).bill
    assert bill.reference == "20260903000042"


def test_numbers_restart_each_issue_day(db_session, tariff):
    make_bill(db_session, make_meter(db_session), tariff, reference="20260902000007")
    assert generate(db_session, real_bill_meter(db_session)).bill.reference == "20260903000001"


def test_no_number_left_for_the_day(db_session, tariff):
    make_bill(db_session, make_meter(db_session), tariff, reference="20260903999999")
    with pytest.raises(BillSequenceExhaustedError):
        generate(db_session, real_bill_meter(db_session))


# --- Période -----------------------------------------------------------------------------


@pytest.mark.parametrize("start", [date(2026, 8, 1), date(2026, 7, 15), date(2026, 2, 1)])
def test_start_must_open_a_billing_period(db_session, tariff, start):
    with pytest.raises(InvalidBillingPeriodError) as error:
        generate(db_session, real_bill_meter(db_session), start=start)
    assert error.value.status_code == 422


def test_not_issued_before_the_issue_date(db_session, tariff):
    meter = real_bill_meter(db_session)
    with pytest.raises(BillingPeriodNotClosedError) as error:
        generate(db_session, meter, today=ISSUE_DAY - timedelta(days=1))
    assert error.value.details["issue_date"] == "2026-09-03"
    assert bills_of(db_session, meter) == []


def test_no_tariff_no_bill(db_session):
    make_tariff(db_session, valid_from=date(2026, 8, 1))  # entre en vigueur après le 01/07
    with pytest.raises(NoTariffError):
        generate(db_session, real_bill_meter(db_session))


def test_the_tariff_of_the_first_day_applies(db_session):
    old = make_tariff(db_session, valid_from=date(2025, 1, 1), valid_to=date(2026, 8, 1))
    make_tariff(db_session, valid_from=date(2026, 8, 1), price_per_kwh_milli=60_000)
    bill = generate(db_session, real_bill_meter(db_session)).bill
    assert bill.tariff_id == old.id and bill.amount_total == 40_384


# --- Relevés -----------------------------------------------------------------------------


@pytest.mark.parametrize("missing", [JULY, date(2026, 9, 1)])
def test_a_missing_billing_reading_is_refused(db_session, tariff, missing):
    meter = make_meter(db_session)
    for day, index in ((JULY, 14_283_000), (date(2026, 9, 1), 14_854_000)):
        if day != missing:
            reading(db_session, meter, day, index, 0)
    with pytest.raises(BillingReadingMissingError) as error:
        generate(db_session, meter)
    assert error.value.details["reading_date"] == missing.isoformat()
    assert "manquant" in error.value.message


def test_an_anomalous_billing_reading_is_refused(db_session, tariff):
    meter = make_meter(db_session)
    reading(
        db_session, meter, JULY, 14_283_000, 0, is_anomaly=True, anomaly_reason="Index illisible"
    )
    reading(db_session, meter, date(2026, 9, 1), 14_854_000, 571_000)
    with pytest.raises(BillingReadingAnomalyError):
        generate(db_session, meter)


def test_the_first_reading_of_the_day_is_the_billing_index(db_session, tariff):
    meter = real_bill_meter(db_session)
    make_reading(  # relevé de contrôle à midi le 01/09 : ne change pas le nouvel index
        db_session,
        meter,
        read_at=local_midnight_utc(date(2026, 9, 1)) + timedelta(hours=12),
        index_wh=14_860_000,
        consumption_wh=6_000,
    )
    assert generate(db_session, meter).bill.current_index_wh == 14_854_000


def test_daily_readings_must_match_the_indexes(db_session, tariff):
    meter = make_meter(db_session)
    reading(db_session, meter, JULY, 14_283_000, 0)
    reading(db_session, meter, date(2026, 8, 1), 14_500_000, 200_000)  # devrait être 217 000
    reading(db_session, meter, date(2026, 9, 1), 14_854_000, 354_000)
    with pytest.raises(BillingReadingsMismatchError) as error:
        generate(db_session, meter)
    assert error.value.details["readings_wh"] == 554_000
    assert error.value.details["index_wh"] == 571_000


def test_an_anomaly_inside_the_period_does_not_block_the_bill(db_session, tariff):
    """Un relevé en anomalie ne compte rien ; le suivant repart du dernier index valide."""
    meter = make_meter(db_session)
    reading(db_session, meter, JULY, 14_283_000, 0)
    reading(
        db_session, meter, date(2026, 8, 1), 14_100_000, 0, is_anomaly=True, anomaly_reason="Baisse"
    )
    reading(db_session, meter, date(2026, 9, 1), 14_854_000, 571_000)
    assert generate(db_session, meter).bill.consumption_wh == 571_000


@pytest.mark.parametrize(
    ("sources", "expected"),
    [
        ((ReadingSource.E2C, ReadingSource.E2C), BillSource.E2C),
        ((ReadingSource.E2C, ReadingSource.SIMULATED), BillSource.SIMULATED),
        ((ReadingSource.E2C, ReadingSource.MANUAL), BillSource.SIMULATED),
    ],
)
def test_a_bill_is_e2c_only_if_every_reading_is(db_session, tariff, sources, expected):
    meter = make_meter(db_session)
    reading(db_session, meter, JULY, 14_283_000, 0, source=ReadingSource.E2C)
    reading(db_session, meter, date(2026, 8, 1), 14_500_000, 217_000, source=sources[0])
    reading(db_session, meter, date(2026, 9, 1), 14_854_000, 354_000, source=sources[1])
    assert generate(db_session, meter).bill.source is expected


def test_errors_share_the_billing_family(db_session, tariff):
    with pytest.raises(BillingError) as error:
        generate(db_session, make_meter(db_session))  # aucun relevé
    assert error.value.status_code == 409
    assert error.value.code == "BILLING_READING_MISSING"


# --- Même résultat que le simulateur de B2 ------------------------------------------------


def test_same_bills_as_the_b2_simulator_over_18_months(db_session, tariff):
    """Avant de brancher le relevé quotidien et le seed (B6.2) : mêmes factures au franc près."""
    meter = make_meter(db_session, make_household(db_session), subscribed_power_va=6_000)
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY],
        date(2025, 5, 1),
        date(2026, 10, 31),
        start_index_wh=14_000_000,
        seed=7,
    )
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    today = date(2026, 11, 12)
    expected = generate_bills(
        readings,
        tariff,
        period_months=2,
        issue_delay_days=3,
        due_delay_days=15,
        as_of=today,
        billed_power_va=6_000,
    )
    last_day = local_date(readings[-1].read_at) - timedelta(days=1)
    periods = billing_periods(local_date(readings[0].read_at), last_day, 2)
    issued = [generate(db_session, meter, period.start, today).bill for period in periods]

    assert len(issued) == len(expected) == 9
    for bill, simulated in zip(issued, expected, strict=True):
        assert (bill.period_start, bill.period_end) == (
            simulated.period_start,
            simulated.period_end,
        )
        assert (bill.previous_index_wh, bill.current_index_wh) == (
            simulated.previous_index_wh,
            simulated.current_index_wh,
        )
        assert bill.amount_total == simulated.computation.amount_total
        assert (bill.issued_at, bill.due_date) == (simulated.issued_at, simulated.due_date)


# --- Passage en retard (B6.2) -------------------------------------------------------------

DUE = date(2026, 9, 30)  # échéance par défaut de `make_bill`


def overdue_notices(session, household):
    return session.scalars(
        select(Notification).where(
            Notification.user_id == household.owner_id,
            Notification.type == NotificationType.BILL_OVERDUE,
        )
    ).all()


def test_an_unpaid_bill_is_overdue_the_day_after_its_due_date(db_session, tariff):
    home = make_household(db_session)
    bill = make_bill(db_session, make_meter(db_session, home), tariff)

    assert mark_overdue_bills(db_session, today=DUE).bills == []  # le jour même : pas encore
    report = mark_overdue_bills(db_session, today=DUE + timedelta(days=1))

    assert report.bills == [bill] and report.notifications == 1
    assert bill.status is BillStatus.OVERDUE
    (notice,) = overdue_notices(db_session, home)
    assert notice.data_json == {"bill_id": bill.id}
    assert "40 384 FCFA" in notice.body and "30/09/2026" in notice.body


def test_overdue_is_marked_only_once(db_session, tariff):
    home = make_household(db_session)
    make_bill(db_session, make_meter(db_session, home), tariff)
    mark_overdue_bills(db_session, today=DUE + timedelta(days=1))
    again = mark_overdue_bills(db_session, today=DUE + timedelta(days=5))
    assert (again.bills, again.notifications) == ([], 0)
    assert len(overdue_notices(db_session, home)) == 1


@pytest.mark.parametrize(
    "changes",
    [
        {"status": BillStatus.PAID, "paid_at": datetime(2026, 9, 20, tzinfo=UTC)},
        {
            "status": BillStatus.CANCELLED,
            "cancelled_at": datetime(2026, 9, 20, tzinfo=UTC),
            "cancelled_reason": "Facture émise par erreur",
        },
        {"status": BillStatus.PENDING_PAYMENT},
    ],
    ids=["payee", "annulee", "paiement-en-cours"],
)
def test_only_unpaid_bills_become_overdue(db_session, tariff, changes):
    bill = make_bill(db_session, make_meter(db_session, make_household(db_session)), tariff)
    for name, value in changes.items():
        setattr(bill, name, value)
    db_session.flush()
    assert mark_overdue_bills(db_session, today=DUE + timedelta(days=10)).bills == []
    assert bill.status is changes["status"]


def test_a_detached_meter_bill_is_overdue_but_nobody_is_notified(db_session, tariff):
    bill = make_bill(db_session, make_meter(db_session), tariff)  # compteur sans foyer
    report = mark_overdue_bills(db_session, today=DUE + timedelta(days=1))
    assert report.bills == [bill] and report.notifications == 0


# --- Périodes (fonctions pures) -----------------------------------------------------------


@pytest.mark.parametrize(
    ("day", "months", "expected"),
    [
        (date(2026, 1, 1), 2, True),
        (date(2026, 7, 1), 2, True),
        (date(2026, 8, 1), 2, False),
        (date(2026, 7, 2), 2, False),
        (date(2026, 8, 1), 1, True),
        (date(2026, 4, 1), 3, True),
        (date(2026, 5, 1), 3, False),
    ],
)
def test_period_starts(day, months, expected):
    assert is_period_start(day, months) is expected


def test_period_from_its_start():
    period = billing_period(date(2026, 11, 1), 2)
    assert (period.end, period.months_count) == (date(2026, 12, 31), 2)


def test_period_from_a_wrong_start_is_refused():
    with pytest.raises(ValueError, match="pas un début de période"):
        billing_period(date(2026, 12, 1), 2)
