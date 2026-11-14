"""Tests des écrans Factures du back-office (B10.5, A5 et A6) : liste, détail, annulation,
réémission, export."""

import csv
import io
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import func, select

from app.core.timezone import local_midnight_utc
from app.modules.admin.bills import AdminBills
from app.modules.audit.models import AuditLog
from app.modules.bills.errors import BillingNothingToReissueError, BillingPeriodCancelledError
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.service import generate_bill
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import Notification
from app.modules.payments.models import TransactionStatus
from app.modules.users.models import UserRole
from tests.factories import (
    Billing,
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_reading,
    make_tariff,
    make_transaction,
    make_user,
)

# Jeudi 12 novembre 2026, 14 h 45 à Brazzaville (13 h 45 UTC).
NOW = datetime(2026, 11, 12, 13, 45, tzinfo=UTC)
JULY = date(2026, 7, 1)
URL = "/api/v1/admin/bills"
NOVEMBER_ISSUE = datetime(2026, 11, 3, 7, 0, tzinfo=UTC)  # 3 novembre, 8 h à Brazzaville
REASON = "Index de fin de période erroné"


@pytest.fixture(autouse=True)
def fixed_now(monkeypatch):
    original = AdminBills.__init__
    monkeypatch.setattr(
        AdminBills,
        "__init__",
        lambda self, session, now=None: original(self, session, lambda: NOW),
    )


def november_bill(session, household, **overrides):
    """Facture septembre-octobre émise le 3 novembre, sur son propre compteur."""
    return make_bill(
        session,
        make_meter(session, household),
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        issued_at=NOVEMBER_ISSUE,
        due_date=date(2026, 11, 18),
        **overrides,
    )


@pytest.fixture
def world(db_session):
    arnaud = make_user(db_session, full_name="Arnaud Mavoungou", phone="+242061110001")
    grace = make_user(db_session, full_name="Grâce Ngoma", phone="+242051110002")
    home = make_household(db_session, arnaud, name="Maison Mpita")
    make_member(db_session, home, grace, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_tariff(db_session, valid_from=date(2025, 1, 1))
    # Compteur dont les relevés reproduisent la vraie facture E²C (571 kWh, 40 384 FCFA).
    meter = make_meter(db_session, home, reference="0412-8833", subscribed_power_va=3_000)
    make_reading(
        db_session, meter, read_at=local_midnight_utc(JULY), index_wh=14_283_000, consumption_wh=0
    )
    make_reading(
        db_session,
        meter,
        read_at=local_midnight_utc(date(2026, 9, 1)),
        index_wh=14_854_000,
        consumption_wh=571_000,
    )
    july = generate_bill(db_session, meter, JULY, today=date(2026, 9, 3), settings=Billing()).bill
    paid = november_bill(
        db_session, home, status=BillStatus.PAID, paid_at=NOVEMBER_ISSUE + timedelta(days=2)
    )
    unpaid = november_bill(db_session, home)
    pending = november_bill(db_session, home, status=BillStatus.PENDING_PAYMENT)
    failed = make_transaction(db_session, july, grace, phone_number="+242051110002")
    failed.status, failed.failure_reason = TransactionStatus.FAILED, "Solde insuffisant"
    db_session.flush()
    return {
        "arnaud": arnaud,
        "grace": grace,
        "home": home,
        "meter": meter,
        "july": july,
        "paid": paid,
        "unpaid": unpaid,
        "pending": pending,
        "support": make_user(db_session, role=UserRole.SUPPORT),
        "admin": make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala"),
    }


def listing(client, auth_headers, user, **params):
    response = client.get(URL, params=params, headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def ids(body):
    return [item["id"] for item in body["items"]]


def detail(client, auth_headers, user, bill):
    response = client.get(f"{URL}/{bill.id}", headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def post(client, auth_headers, user, bill, action, body):
    return client.post(f"{URL}/{bill.id}/{action}", json=body, headers=auth_headers(user))


# --- Liste (A5) -----------------------------------------------------------------------------


def test_list_with_the_totals_of_the_month(client, auth_headers, world):
    body = listing(client, auth_headers, world["support"])
    assert body["total"] == 4
    assert body["totals"] == {
        "month": "2026-11",
        "issued": 3,
        "billed": 3 * 40_384,
        "collected": 40_384,
        "remaining": 2 * 40_384,
        "overdue": 0,
        "cancelled": 0,
    }
    july = next(item for item in body["items"] if item["id"] == world["july"].id)
    assert july["status"] == "overdue"
    assert july["days_overdue"] == (date(2026, 11, 12) - july_due(world)).days
    assert (july["household_name"], july["owner_name"]) == ("Maison Mpita", "Arnaud Mavoungou")
    assert july["period_label"] == "Juil.-Août 2026"


def july_due(world):
    return world["july"].due_date


@pytest.mark.parametrize(
    ("params", "expected"),
    [
        ({"status": "overdue"}, ["july"]),
        ({"status": "unpaid"}, ["unpaid"]),
        ({"status": "paid"}, ["paid"]),
        ({"status": "pending_payment"}, ["pending"]),
        ({"status": "cancelled"}, []),
        ({"month": "2026-09"}, ["july"]),
        ({"q": "0412-8833"}, ["july"]),
        ({"q": "mavoungou", "status": "overdue"}, ["july"]),
    ],
)
def test_filters_and_search(client, auth_headers, world, params, expected):
    found = ids(listing(client, auth_headers, world["support"], **params))
    assert sorted(found) == sorted(world[name].id for name in expected)


def test_totals_follow_the_chosen_month(client, auth_headers, world):
    totals = listing(client, auth_headers, world["support"], month="2026-09")["totals"]
    assert (totals["issued"], totals["billed"], totals["overdue"]) == (1, 40_384, 1)


def test_bad_month_and_clients(client, auth_headers, world):
    bad = client.get(URL, params={"month": "2026-13"}, headers=auth_headers(world["admin"]))
    assert bad.status_code == 422
    assert client.get(URL, headers=auth_headers(world["arnaud"])).status_code == 403


# --- Détail (A6) ----------------------------------------------------------------------------


def test_detail_of_a_bill(client, auth_headers, world):
    body = detail(client, auth_headers, world["support"], world["july"])
    assert body["amount_total"] == 40_384
    assert (body["previous_index_wh"], body["current_index_wh"]) == (14_283_000, 14_854_000)
    assert [line["kind"] for line in body["lines"]][0] == "energy"
    assert sum(line["amount"] for line in body["lines"]) == 40_384
    assert body["tariff"]["price_per_kwh_milli"] == 49_080
    readings = body["readings"]
    assert readings["bill_source"] == "simulated"
    assert readings["previous"]["index_wh"] == 14_283_000
    assert readings["current"]["index_wh"] == 14_854_000
    assert (readings["daily_readings"], readings["anomalies"]) == (1, 0)
    payers = [(p["full_name"], p["role"], p["phone"]) for p in body["authorized_payers"]]
    assert payers == [
        ("Arnaud Mavoungou", "owner", "+242 06 *** ** 01"),
        ("Grâce Ngoma", "payer", "+242 05 *** ** 02"),
    ]
    (transaction,) = body["transactions"]
    assert transaction["status"] == TransactionStatus.FAILED.value
    assert transaction["payer_name"] == "Grâce Ngoma"
    assert "*" in transaction["phone_number"]
    assert body["history"][0]["action"] == "bill.issued"
    assert (body["can_cancel"], body["can_reissue"]) == (True, False)
    assert (body["replaces"], body["replaced_by"]) == (None, None)


def test_admins_see_full_numbers_but_never_in_transactions(client, auth_headers, world):
    body = detail(client, auth_headers, world["admin"], world["july"])
    assert body["authorized_payers"][0]["phone"] == "+242061110001"
    assert "*" in body["transactions"][0]["phone_number"]


def test_cancel_is_not_offered_on_paid_or_pending_bills(client, auth_headers, world):
    for name in ("paid", "pending"):
        assert detail(client, auth_headers, world["support"], world[name])["can_cancel"] is False


def test_unknown_bill(client, auth_headers, world):
    response = client.get(f"{URL}/999999", headers=auth_headers(world["support"]))
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "BILL_NOT_FOUND"


# --- Annulation -----------------------------------------------------------------------------


def test_cancel_with_a_reason(client, auth_headers, world, db_session):
    bill = world["july"]
    assert post(client, auth_headers, world["admin"], bill, "cancel", {}).status_code == 422
    short = post(client, auth_headers, world["admin"], bill, "cancel", {"reason": "Erreur"})
    assert short.status_code == 422
    response = post(client, auth_headers, world["admin"], bill, "cancel", {"reason": REASON})
    assert response.status_code == 200, response.text
    assert response.json()["status"] == "cancelled"
    db_session.refresh(bill)
    assert (bill.status, bill.cancelled_reason, bill.amount_total) == (
        BillStatus.CANCELLED,
        REASON,
        40_384,
    )
    body = detail(client, auth_headers, world["support"], bill)
    assert body["status"] == "cancelled"
    assert body["cancelled_by"] == "Christelle Mabiala"
    assert (body["can_cancel"], body["can_reissue"]) == (False, True)
    assert body["history"][-1]["action"] == "bill.cancel"
    assert body["history"][-1]["detail"] == REASON
    again = post(client, auth_headers, world["admin"], bill, "cancel", {"reason": REASON})
    assert again.status_code == 409


@pytest.mark.parametrize(
    ("name", "message"),
    [("paid", "payée ne peut pas"), ("pending", "paiement est en cours")],
)
def test_cancel_is_refused(client, auth_headers, world, name, message):
    response = post(client, auth_headers, world["admin"], world[name], "cancel", {"reason": REASON})
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "BILL_ACTION_REFUSED"
    assert message in response.json()["error"]["message"]


def test_support_cannot_cancel(client, auth_headers, world):
    response = post(
        client, auth_headers, world["support"], world["july"], "cancel", {"reason": REASON}
    )
    assert response.status_code == 403


# --- Réémission -----------------------------------------------------------------------------


def test_reissue_a_cancelled_period(client, auth_headers, world, db_session):
    cancelled = world["july"]
    post(client, auth_headers, world["admin"], cancelled, "cancel", {"reason": REASON})
    response = post(
        client, auth_headers, world["admin"], cancelled, "reissue", {"reason": "Après contrôle"}
    )
    assert response.status_code == 200, response.text
    body = response.json()
    new = body["bill"]
    assert body["cancelled_bill_id"] == cancelled.id
    assert body["notifications"] == 2  # titulaire + payeuse déléguée
    assert new["reference"].startswith("20261112")
    assert new["issued_at"] == "2026-11-12T13:45:00Z"
    assert new["due_date"] == "2026-11-27"  # 15 jours pour payer
    assert (new["status"], new["amount_total"], new["period_label"]) == (
        "unpaid",
        40_384,
        "Juil.-Août 2026",
    )
    replacement = db_session.get(Bill, new["id"])
    assert replacement.period_start == cancelled.period_start
    notice = db_session.scalars(
        select(Notification).where(Notification.user_id == world["grace"].id)
    ).one()
    assert notice.title == "Facture corrigée"
    assert cancelled.reference in notice.body

    old = detail(client, auth_headers, world["support"], cancelled)
    assert old["replaced_by"]["id"] == new["id"]
    assert old["can_reissue"] is False
    fresh = detail(client, auth_headers, world["support"], replacement)
    assert fresh["replaces"]["id"] == cancelled.id
    assert fresh["history"][-1]["action"] == "bill.reissue"
    actions = db_session.scalars(
        select(AuditLog.action).where(AuditLog.action.in_(["bill.cancel", "bill.reissue"]))
    ).all()
    assert sorted(actions) == ["bill.cancel", "bill.reissue"]

    twice = post(
        client, auth_headers, world["admin"], cancelled, "reissue", {"reason": "Encore une fois"}
    )
    assert twice.status_code == 409


def test_only_a_cancelled_bill_can_be_reissued(client, auth_headers, world):
    response = post(
        client, auth_headers, world["admin"], world["july"], "reissue", {"reason": "Pour voir x"}
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "BILL_ACTION_REFUSED"


def test_reissue_reports_billing_errors(client, auth_headers, world, db_session):
    # Facture annulée sur un compteur sans relevés : impossible de la recalculer.
    bill = make_bill(
        db_session,
        make_meter(db_session, world["home"]),
        status=BillStatus.CANCELLED,
        cancelled_at=NOW,
        cancelled_reason=REASON,
    )
    response = post(
        client, auth_headers, world["admin"], bill, "reissue", {"reason": "Après contrôle"}
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "BILLING_READING_MISSING"
    count = db_session.scalar(
        select(func.count()).select_from(Bill).where(Bill.meter_id == bill.meter_id)
    )
    assert count == 1  # rien n'a été créé


def test_generate_bill_reissue_rules(db_session, world):
    meter = world["meter"]
    with pytest.raises(BillingNothingToReissueError):
        generate_bill(
            db_session,
            make_meter(db_session),
            JULY,
            today=date(2026, 11, 12),
            settings=Billing(),
            reissue_at=NOW,
        )
    world["july"].status = BillStatus.CANCELLED
    world["july"].cancelled_at = NOW
    world["july"].cancelled_reason = REASON
    db_session.flush()
    with pytest.raises(BillingPeriodCancelledError):  # jamais automatiquement
        generate_bill(db_session, meter, JULY, today=date(2026, 11, 12), settings=Billing())


# --- Export ---------------------------------------------------------------------------------


def test_export_csv(client, auth_headers, world, db_session):
    response = client.get(
        f"{URL}/export.csv", params={"month": "2026-11"}, headers=auth_headers(world["admin"])
    )
    assert response.status_code == 200, response.text
    rows = list(csv.reader(io.StringIO(response.text.lstrip("﻿")), delimiter=";"))
    assert rows[0][0] == "référence"
    assert len(rows) == 4
    assert {row[9] for row in rows[1:]} == {"paid", "unpaid", "pending_payment"}
    assert rows[1][7] == "03/11/2026"
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "admin.export")).one()
    assert log.after_json["export"] == "bills"
    support = client.get(f"{URL}/export.csv", headers=auth_headers(world["support"]))
    assert support.status_code == 403
