"""Tests du relevé quotidien (B2.6)."""

from dataclasses import replace
from datetime import UTC, date, datetime

import pytest
from sqlalchemy import func, select

from app.core.config import Settings
from app.core.timezone import local_date, local_midnight_utc
from app.modules.bills.calculator import compute_bill
from app.modules.bills.models import Bill, BillLine, BillStatus
from app.modules.consumption.models import MeterReading
from app.modules.meters.models import MeterStatus
from app.modules.notifications.models import Notification, NotificationType
from app.simulators import daily
from app.simulators.daily import run_daily_tick, tariff_at
from app.simulators.demo_dataset import profile_for
from app.simulators.persistence import insert_readings
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from scripts.daily_tick import refusal_reason
from tests.factories import (
    Billing,
    make_bill,
    make_household,
    make_meter,
    make_tariff,
    make_user,
)


def setup_meter(session, *, first=date(2026, 9, 1), last=date(2026, 10, 30), household=True):
    """Un compteur « famille » avec ses relevés de `first` à `last` inclus, et le tarif."""
    owner = make_user(session)
    home = make_household(session, owner) if household else None
    meter = make_meter(session, home, subscribed_power_va=6_000)
    make_tariff(session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY], first, last, start_index_wh=10_000_000, seed=5
    )
    insert_readings(session, meter.id, readings)
    session.flush()
    return owner, meter


def tick(session, today):
    return run_daily_tick(session, today=today, settings=Billing())


def readings_of(session, meter):
    return session.scalars(
        select(MeterReading).where(MeterReading.meter_id == meter.id).order_by(MeterReading.read_at)
    ).all()


def notifications_of(session, user, kind):
    return session.scalars(
        select(Notification).where(Notification.user_id == user.id, Notification.type == kind)
    ).all()


# --- Relevés ------------------------------------------------------------------------


def test_adds_missing_readings_up_to_this_morning(db_session):
    _, meter = setup_meter(db_session)  # dernier relevé : minuit le 31/10
    report = tick(db_session, date(2026, 11, 4))  # rattrape les journées du 31/10 au 03/11
    readings = readings_of(db_session, meter)
    assert report.counts["readings"] == 4
    assert readings[-1].read_at == local_midnight_utc(date(2026, 11, 4))


def test_is_idempotent(db_session):
    _, meter = setup_meter(db_session)
    tick(db_session, date(2026, 11, 4))
    count_before = len(readings_of(db_session, meter))
    report = tick(db_session, date(2026, 11, 4))
    assert report.counts["readings"] == 0
    assert report.counts["bills"] == 0
    assert len(readings_of(db_session, meter)) == count_before


def test_index_continues_without_gap(db_session):
    _, meter = setup_meter(db_session)
    tick(db_session, date(2026, 11, 20))
    last_valid = None
    for reading in readings_of(db_session, meter):
        if reading.is_anomaly:
            continue
        if last_valid is not None:
            assert reading.index_wh >= last_valid.index_wh
            assert reading.consumption_wh == reading.index_wh - last_valid.index_wh
        last_valid = reading


def test_restarts_from_the_last_valid_index_after_an_anomaly(db_session):
    _, meter = setup_meter(db_session, last=date(2026, 10, 29))
    valid = readings_of(db_session, meter)[-1]
    db_session.add(
        MeterReading(
            meter_id=meter.id,
            read_at=local_midnight_utc(date(2026, 10, 31)),
            index_wh=valid.index_wh - 20_000,  # index lu en baisse
            consumption_wh=0,
            source=valid.source,
            is_anomaly=True,
            anomaly_reason="Index lu en baisse",
        )
    )
    db_session.flush()
    tick(db_session, date(2026, 11, 2))  # ajoute les relevés du 01/11 et du 02/11
    by_day = {local_date(r.read_at): r for r in readings_of(db_session, meter)}
    first_after = by_day[date(2026, 11, 1)]  # le premier relevé après l'anomalie
    assert first_after.index_wh >= valid.index_wh
    # Il récupère toute la consommation depuis le dernier index VALIDE (30/10), pas depuis
    # l'index erroné du 31/10.
    assert first_after.consumption_wh == first_after.index_wh - valid.index_wh


def test_anomaly_on_the_new_day_is_notified_but_never_on_a_period_start(db_session, monkeypatch):
    always_anomalous = replace(PROFILES[ProfileName.FAMILY], anomaly_probability=1.0)
    monkeypatch.setitem(daily.PROFILES, ProfileName.FAMILY, always_anomalous)
    owner, meter = setup_meter(db_session)  # dernier relevé : minuit le 31/10

    report = tick(db_session, date(2026, 11, 3))  # relevés du 01/11, 02/11 et 03/11

    by_day = {local_date(r.read_at): r for r in readings_of(db_session, meter)}
    assert not by_day[date(2026, 11, 1)].is_anomaly  # 1er du mois : index de facturation
    assert by_day[date(2026, 11, 2)].is_anomaly and by_day[date(2026, 11, 3)].is_anomaly
    assert report.counts["anomalies"] == 2
    assert len(notifications_of(db_session, owner, NotificationType.CONSUMPTION_ANOMALY)) == 2
    assert report.counts["bills"] == 1  # la facture sept.-oct. reste calculable


def test_generator_option_allows_an_anomaly_on_the_last_day():
    profile = replace(PROFILES[ProfileName.FAMILY], anomaly_probability=1.0)
    day = date(2026, 11, 2)  # le relevé tombe le 03/11 (pas un début de mois)
    strict = generate_readings(profile, day, day, start_index_wh=1_000_000, seed=1)
    daily_mode = generate_readings(
        profile, day, day, start_index_wh=1_000_000, seed=1, anomaly_on_last_day=True
    )
    assert not strict[-1].is_anomaly
    assert daily_mode[-1].is_anomaly


def test_meter_without_readings_is_skipped(db_session):
    make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))
    meter = make_meter(db_session, make_household(db_session))
    report = tick(db_session, date(2026, 11, 4))
    assert any(meter.reference in message for message in report.skipped)


def test_terminated_meter_is_ignored(db_session):
    _, meter = setup_meter(db_session)
    meter.status = MeterStatus.TERMINATED
    db_session.flush()
    assert tick(db_session, date(2026, 11, 20)).counts["readings"] == 0


def test_detached_meter_gets_readings_but_nobody_is_notified(db_session):
    _, meter = setup_meter(db_session, household=False)
    report = tick(db_session, date(2026, 11, 3))
    assert report.counts["readings"] > 0 and report.counts["bills"] == 1
    assert report.counts["notifications"] == 0


# --- Factures -----------------------------------------------------------------------


def test_bill_is_issued_on_the_issue_date_not_before(db_session):
    """Période septembre-octobre : se termine le 31/10, émission le 03/11."""
    _, meter = setup_meter(db_session)
    assert tick(db_session, date(2026, 11, 2)).counts["bills"] == 0
    assert tick(db_session, date(2026, 11, 3)).counts["bills"] == 1


def test_issued_bill_is_computed_from_the_readings(db_session):
    owner, meter = setup_meter(db_session)
    tick(db_session, date(2026, 11, 3))
    bill = db_session.scalars(select(Bill).where(Bill.meter_id == meter.id)).one()
    by_day = {local_date(r.read_at): r for r in readings_of(db_session, meter)}
    assert (bill.period_start, bill.period_end) == (date(2026, 9, 1), date(2026, 10, 31))
    assert bill.previous_index_wh == by_day[date(2026, 9, 1)].index_wh
    assert bill.current_index_wh == by_day[date(2026, 11, 1)].index_wh
    assert (
        bill.amount_total
        == compute_bill(
            bill.consumption_wh, 2, tariff_at(db_session, bill.period_start)
        ).amount_total
    )
    assert bill.issued_at == datetime(2026, 11, 3, 7, 0, tzinfo=UTC)
    assert bill.due_date == date(2026, 11, 18)
    assert bill.billed_power_va == 6_000
    lines_total = db_session.scalar(
        select(func.sum(BillLine.amount)).where(BillLine.bill_id == bill.id)
    )
    assert lines_total == bill.amount_total
    assert notifications_of(db_session, owner, NotificationType.BILL_ISSUED)


def test_period_already_billed_is_never_billed_again_even_if_cancelled(db_session):
    _, meter = setup_meter(db_session)
    tariff = tariff_at(db_session, date(2026, 9, 1))
    cancelled = make_bill(
        db_session,
        meter,
        tariff,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=date(2026, 11, 18),
    )
    cancelled.status = BillStatus.CANCELLED
    cancelled.cancelled_at = datetime(2026, 11, 2, tzinfo=UTC)
    cancelled.cancelled_reason = "Facture émise par erreur"
    db_session.flush()
    assert tick(db_session, date(2026, 11, 3)).counts["bills"] == 0


def test_no_tariff_means_no_bill_and_a_clear_message(db_session):
    _, meter = setup_meter(db_session)
    tariff = tariff_at(db_session, date(2026, 9, 1))
    tariff.valid_from = date(2026, 12, 1)  # aucun tarif en vigueur en septembre
    db_session.flush()
    report = tick(db_session, date(2026, 11, 3))
    assert report.counts["bills"] == 0
    assert any("aucun tarif" in message for message in report.skipped)


# --- Retards ------------------------------------------------------------------------


def test_unpaid_bill_becomes_overdue_after_its_due_date_only_once(db_session):
    owner, meter = setup_meter(db_session)
    tick(db_session, date(2026, 11, 3))  # facture émise, échéance le 18/11
    bill = db_session.scalars(select(Bill).where(Bill.meter_id == meter.id)).one()

    tick(db_session, date(2026, 11, 18))
    assert bill.status is BillStatus.UNPAID  # le jour de l'échéance, pas encore en retard
    report = tick(db_session, date(2026, 11, 19))
    assert report.counts["overdue"] == 1
    assert bill.status is BillStatus.OVERDUE
    assert tick(db_session, date(2026, 11, 20)).counts["overdue"] == 0  # pas deux fois
    assert len(notifications_of(db_session, owner, NotificationType.BILL_OVERDUE)) == 1


def test_paid_bills_are_never_marked_overdue(db_session):
    _, meter = setup_meter(db_session)
    bill = make_bill(
        db_session,
        meter,
        tariff_at(db_session, date(2026, 9, 1)),
        status=BillStatus.PAID,
        paid_at=datetime(2026, 9, 10, tzinfo=UTC),
    )
    tick(db_session, date(2026, 12, 1))
    assert bill.status is BillStatus.PAID


# --- Divers -------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("reference", "power", "profile"),
    [
        ("0377-1209", 9_000, ProfileName.SHOP),  # compteur du jeu de démo
        ("INCONNU-1", 2_200, ProfileName.SMALL_HOUSEHOLD),
        ("INCONNU-2", 6_000, ProfileName.FAMILY),
        ("INCONNU-3", 12_000, ProfileName.SHOP),
        ("INCONNU-4", None, ProfileName.FAMILY),
    ],
)
def test_profile_of_a_meter(reference, power, profile):
    assert profile_for(reference, power) is profile


@pytest.mark.parametrize(
    ("changes", "refused"),
    [
        ({}, False),
        ({"app_env": "production"}, True),
        ({"demo_mode": False}, True),
    ],
)
def test_command_refuses_outside_simulated_demo(test_settings, changes, refused):
    settings: Settings = test_settings.model_copy(update=changes)
    assert (refusal_reason(settings) is not None) is refused
