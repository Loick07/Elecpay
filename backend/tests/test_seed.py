"""Tests du remplissage de démonstration (B2.5) et des commandes reset_db / seed.

Le seed complet est lancé une fois pour tout le module, dans une transaction annulée à la fin.
"""

import time
from collections import Counter
from datetime import date

import pytest
from sqlalchemy import func, select, text

from app.core.money import format_fcfa
from app.core.security import verify_password
from app.core.timezone import local_date, local_midnight_utc
from app.modules.bills.models import Bill, BillLine, BillStatus
from app.modules.households.models import Household, HouseholdMember
from app.modules.meters.models import Meter
from app.modules.notifications.models import Notification
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.receipts.models import Receipt
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User, UserRole
from app.simulators.demo_dataset import CLIENTS, DEMO_PASSWORD
from app.simulators.seeder import SeedError, history_start, seed_demo
from scripts.reset_db import ResetRefusedError, reset_database
from scripts.seed import parse_args
from tests.conftest import transactional_session
from tests.factories import Billing

TODAY = date(2026, 11, 12)


@pytest.fixture(scope="module")
def seeded(test_engine):
    with transactional_session(test_engine) as session:
        started = time.perf_counter()
        report = seed_demo(session, today=TODAY, settings=Billing())
        report.seconds = time.perf_counter() - started
        yield session, report


def count(session, model, *where):
    return session.scalar(select(func.count()).select_from(model).where(*where))


# --- Critères « Terminé quand » du plan B2 ------------------------------------------


def test_seed_takes_less_than_a_minute(seeded):
    _, report = seeded
    assert report.seconds < 60


def test_every_bill_total_is_the_sum_of_its_lines(seeded):
    session, _ = seeded
    mismatches = session.execute(
        select(Bill.reference, Bill.amount_total, func.sum(BillLine.amount))
        .join(BillLine, BillLine.bill_id == Bill.id)
        .group_by(Bill.id)
        .having(Bill.amount_total != func.sum(BillLine.amount))
    ).all()
    assert mismatches == []
    assert count(session, Bill) > 100


def test_billed_consumption_is_the_sum_of_the_period_readings(seeded):
    session, _ = seeded
    for bill in session.scalars(select(Bill)):
        start = local_midnight_utc(bill.period_start)
        end = local_midnight_utc(date.fromordinal(bill.period_end.toordinal() + 1))
        readings_total = session.scalar(
            text(
                "SELECT COALESCE(SUM(consumption_wh), 0) FROM meter_readings"
                " WHERE meter_id = :m AND read_at > :start AND read_at <= :end"
            ),
            {
                "m": bill.meter_id,
                "start": start.replace(tzinfo=None),
                "end": end.replace(tzinfo=None),
            },
        )
        assert readings_total == bill.consumption_wh, bill.reference


# --- Contenu ------------------------------------------------------------------------


def test_team_and_clients(seeded):
    session, report = seeded
    roles = Counter(session.scalars(select(User.role)))
    assert roles == {
        UserRole.SUPER_ADMIN: 1,
        UserRole.ADMIN: 1,
        UserRole.SUPPORT: 1,
        UserRole.CLIENT: len(CLIENTS),
    }
    assert 8 <= len(CLIENTS) <= 12  # « une dizaine de clients »
    assert len(report.accounts) == roles.total()


def test_households_and_meters_per_client(seeded):
    session, _ = seeded
    per_owner = Counter(session.scalars(select(Household.owner_id)))
    assert all(1 <= n <= 3 for n in per_owner.values())
    per_household = Counter(session.scalars(select(Meter.household_id)))
    assert all(1 <= n <= 2 for n in per_household.values())
    assert count(session, HouseholdMember) >= 3


def test_every_demo_account_uses_the_demo_password(seeded):
    session, _ = seeded
    user = session.scalars(select(User).where(User.phone == "+242060000101")).one()
    assert user.full_name == "Arnaud Mavoungou"
    assert verify_password(DEMO_PASSWORD, user.password_hash)


def test_tariff_is_the_assumption_from_the_real_bill(seeded):
    session, _ = seeded
    tariff = session.scalars(select(Tariff)).one()
    assert (tariff.price_per_kwh_milli, tariff.is_assumption) == (49_080, True)
    assert tariff.valid_from == history_start(TODAY, 2) == date(2025, 5, 1)


def test_bill_numbers_follow_each_other_per_issue_day(seeded):
    """Factures émises par `generate_bill` (B6) : AAAAMMJJ du jour d'émission + 1, 2, 3…"""
    session, _ = seeded
    by_day: dict[str, list[int]] = {}
    for reference, issued_at in session.execute(
        select(Bill.reference, Bill.issued_at).order_by(Bill.reference)
    ):
        assert reference[:8] == f"{local_date(issued_at):%Y%m%d}"
        by_day.setdefault(reference[:8], []).append(int(reference[8:]))
    for sequences in by_day.values():
        assert sequences == list(range(1, len(sequences) + 1))


def test_bills_paid_unpaid_and_overdue(seeded):
    session, _ = seeded
    statuses = Counter(session.scalars(select(Bill.status)))
    assert statuses[BillStatus.PAID] > 0.8 * statuses.total()
    assert statuses[BillStatus.UNPAID] >= 1
    assert 1 <= statuses[BillStatus.OVERDUE] <= 4  # « une ou deux en retard »


def test_each_paid_bill_has_one_success_and_one_receipt(seeded):
    session, _ = seeded
    paid = count(session, Bill, Bill.status == BillStatus.PAID)
    succeeded = count(
        session, PaymentTransaction, PaymentTransaction.status == TransactionStatus.SUCCEEDED
    )
    assert paid == succeeded == count(session, Receipt)


def test_receipt_numbers_are_sequential_per_year(seeded):
    session, _ = seeded
    by_year: dict[str, list[int]] = {}
    for number in session.scalars(select(Receipt.number).order_by(Receipt.issued_at)):
        _, year, sequence = number.split("-")
        by_year.setdefault(year, []).append(int(sequence))
    for sequences in by_year.values():
        assert sequences == list(range(1, len(sequences) + 1))


def test_failures_and_delegated_payments_exist(seeded):
    session, _ = seeded
    statuses = Counter(session.scalars(select(PaymentTransaction.status)))
    assert statuses[TransactionStatus.FAILED] > 0 and statuses[TransactionStatus.EXPIRED] > 0
    delegated = session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .join(Bill, Bill.id == PaymentTransaction.bill_id)
        .join(Meter, Meter.id == Bill.meter_id)
        .join(Household, Household.id == Meter.household_id)
        .where(PaymentTransaction.payer_id != Household.owner_id)
    )
    assert delegated > 0


def test_notifications_are_created(seeded):
    session, _ = seeded
    arnaud = session.scalars(select(User).where(User.phone == "+242060000101")).one()
    assert count(session, Notification, Notification.user_id == arnaud.id) > 0
    assert count(session, Notification, Notification.read_at.is_(None)) > 0
    kinds = set(session.scalars(select(Notification.type)))
    assert len(kinds) >= 4


def test_seed_refuses_a_non_empty_database(seeded):
    session, _ = seeded
    with pytest.raises(SeedError, match="pas vide"):
        seed_demo(session, today=TODAY, settings=Billing())


# --- Petites fonctions et commandes -------------------------------------------------


@pytest.mark.parametrize(
    ("today", "months", "expected"),
    [
        (date(2026, 11, 12), 2, date(2025, 5, 1)),  # période en cours : nov.-déc. 2026
        (date(2026, 1, 3), 2, date(2024, 7, 1)),
        (date(2026, 11, 12), 3, date(2025, 4, 1)),
        (date(2026, 11, 12), 1, date(2025, 5, 1)),
    ],
)
def test_history_starts_on_a_billing_period(today, months, expected):
    assert history_start(today, months) == expected


def test_amounts_are_formatted_like_on_the_bill():
    assert format_fcfa(40_384) == "40 384 FCFA"
    assert format_fcfa(1_000_000) == "1 000 000 FCFA"


def test_reset_refuses_production(test_settings):
    production = test_settings.model_copy(update={"app_env": "production"})
    with pytest.raises(ResetRefusedError, match="production"):
        reset_database(production)


def test_seed_command_arguments():
    args = parse_args(["--today", "2026-11-12", "--seed", "7"])
    assert (args.today, args.seed) == (date(2026, 11, 12), 7)
