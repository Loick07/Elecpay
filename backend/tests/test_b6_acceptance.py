"""Critères de l'étape B6 (backend/PLAN.md), testés de bout en bout.

- « Service generate_bill : unique endroit qui calcule une facture ; idempotent. »
- « Structure et calculs conformes à FACTURE_E2C.md (troncature par ligne). »
- « Passage automatique en overdue après échéance. »
- « Facture payée : aucune modification possible (test). »
+ les écrans client 6 et 7 (liste, détail, PDF), payeur délégué compris.
Chaque point est aussi testé en détail dans test_bill_*.py et test_bills_api.py.
"""

import re
from datetime import UTC, date, datetime
from pathlib import Path

import pytest
from sqlalchemy import select, text

from app.modules.bills.models import Bill, BillLine, BillLineKind, BillStatus
from app.modules.bills.queries import BillQueries
from app.modules.bills.service import generate_bill, mark_overdue_bills
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import Notification, NotificationType
from app.simulators.daily import run_daily_tick
from app.simulators.persistence import insert_readings
from app.simulators.readings import PROFILES, ProfileName, generate_readings
from tests.db_helpers import expect_db_rejection
from tests.factories import Billing, make_household, make_member, make_meter, make_tariff, make_user
from tests.test_bill_service import real_bill_meter

APP = Path(__file__).resolve().parents[1] / "app"
TODAY = date(2026, 11, 12)


@pytest.fixture(autouse=True)
def fixed_today(monkeypatch):
    original = BillQueries.__init__
    monkeypatch.setattr(
        BillQueries,
        "__init__",
        lambda self, session, today=None: original(self, session, lambda: TODAY),
    )


@pytest.fixture
def family(db_session):
    """Arnaud (propriétaire), Grâce (payeuse déléguée), Joël (lecteur) ; relevés de sept.-oct."""
    make_tariff(db_session, valid_from=date(2025, 1, 1))
    owner, payer, viewer = make_user(db_session), make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home, subscribed_power_va=6_000)
    readings = generate_readings(
        PROFILES[ProfileName.FAMILY],
        date(2026, 9, 1),
        date(2026, 10, 30),
        start_index_wh=10_000_000,
        seed=11,
    )
    insert_readings(db_session, meter.id, readings)
    db_session.flush()
    return {"owner": owner, "payer": payer, "viewer": viewer, "home": home, "meter": meter}


def tick(session, today):
    return run_daily_tick(session, today=today, settings=Billing())


def bills_of(session, meter):
    return session.scalars(select(Bill).where(Bill.meter_id == meter.id)).all()


# --- Une facture n'est créée qu'à un seul endroit ----------------------------------------


def test_bills_are_created_only_by_the_billing_service():
    """Garde-fou d'architecture : aucun autre fichier de app/ ne fabrique une facture."""
    creators = sorted(
        path.relative_to(APP).as_posix()
        for path in APP.rglob("*.py")
        # « Bill(… » (création), mais pas « class Bill(… » (sa définition)
        if re.search(
            r"(?<!class )(?<![\w.])Bill\(|insert\(Bill\)", path.read_text(encoding="utf-8")
        )
    )
    assert creators == ["modules/bills/service.py"]


def test_the_real_e2c_bill_is_reproduced(db_session):
    """FACTURE_E2C.md : 571 kWh → 40 384 FCFA, troncature au franc à chaque ligne."""
    make_tariff(db_session, valid_from=date(2025, 1, 1))
    bill = generate_bill(
        db_session,
        real_bill_meter(db_session),
        date(2026, 7, 1),
        today=date(2026, 9, 3),
        settings=Billing(),
    ).bill
    energy = db_session.scalars(
        select(BillLine).where(BillLine.bill_id == bill.id, BillLine.kind == BillLineKind.ENERGY)
    ).one()
    assert energy.amount == 28_024  # 28 024,68 → tronqué
    assert bill.amount_total == 40_384


# --- Cycle de vie complet, par le relevé quotidien ------------------------------------------


def test_from_issue_to_overdue_through_the_daily_tick(client, auth_headers, db_session, family):
    owner, meter = family["owner"], family["meter"]

    assert tick(db_session, date(2026, 11, 2)).counts["bills"] == 0  # pas avant le 03/11
    assert tick(db_session, date(2026, 11, 3)).counts["bills"] == 1
    assert tick(db_session, date(2026, 11, 3)).counts["bills"] == 0  # idempotent
    (bill,) = bills_of(db_session, meter)
    assert (bill.status, bill.due_date) == (BillStatus.UNPAID, date(2026, 11, 18))

    listed = client.get("/api/v1/bills", headers=auth_headers(owner)).json()
    assert [item["id"] for item in listed["items"]] == [bill.id]
    assert listed["outstanding"]["amount"] == bill.amount_total

    tick(db_session, date(2026, 11, 18))
    assert bill.status is BillStatus.UNPAID  # le jour de l'échéance : pas encore en retard
    assert tick(db_session, date(2026, 11, 19)).counts["overdue"] == 1
    assert bill.status is BillStatus.OVERDUE
    notices = db_session.scalars(
        select(Notification).where(
            Notification.user_id == owner.id, Notification.type == NotificationType.BILL_OVERDUE
        )
    ).all()
    assert len(notices) == 1


# --- Une facture payée ne change plus ------------------------------------------------------


def test_a_paid_bill_can_no_longer_change(client, auth_headers, db_session, family):
    tick(db_session, date(2026, 11, 3))
    (bill,) = bills_of(db_session, family["meter"])
    bill.status, bill.paid_at = BillStatus.PAID, datetime(2026, 11, 10, 9, 0, tzinfo=UTC)
    db_session.flush()
    total = bill.amount_total

    # La base refuse toute modification, même en SQL brut…
    for statement in (
        "UPDATE bills SET amount_total = amount_total + 1, amount_ht = amount_ht + 1 "
        "WHERE id = :id",
        "UPDATE bills SET status = 'unpaid', paid_at = NULL WHERE id = :id",
        "UPDATE bills SET status = 'cancelled', paid_at = NULL, cancelled_at = NOW(), "
        "cancelled_reason = 'Annulation après paiement' WHERE id = :id",
        "DELETE FROM bills WHERE id = :id",
        "UPDATE bill_lines SET amount = amount + 1 WHERE bill_id = :id",
        "DELETE FROM bill_lines WHERE bill_id = :id",
    ):
        with expect_db_rejection(db_session):
            db_session.execute(text(statement), {"id": bill.id})

    # … et les automates n'y touchent pas.
    assert (
        generate_bill(
            db_session, family["meter"], date(2026, 9, 1), today=TODAY, settings=Billing()
        ).created
        is False
    )
    assert mark_overdue_bills(db_session, today=date(2026, 12, 31)).bills == []
    db_session.refresh(bill)
    assert (bill.status, bill.amount_total) == (BillStatus.PAID, total)

    shown = client.get(f"/api/v1/bills/{bill.id}", headers=auth_headers(family["owner"])).json()
    assert (shown["status"], shown["can_pay"]) == ("paid", False)


# --- Écrans 6 et 7 : propriétaire, payeur délégué, lecteur, inconnu --------------------------


@pytest.mark.parametrize(
    ("person", "can_pay"), [("owner", True), ("payer", True), ("viewer", False)]
)
def test_household_members_follow_the_bill_screens(
    client, auth_headers, db_session, family, person, can_pay
):
    tick(db_session, date(2026, 11, 3))
    (bill,) = bills_of(db_session, family["meter"])
    headers = auth_headers(family[person])

    to_pay = client.get("/api/v1/bills", params={"status": "to_pay"}, headers=headers).json()
    assert [item["id"] for item in to_pay["items"]] == [bill.id]
    detail = client.get(f"/api/v1/bills/{bill.id}", headers=headers).json()
    assert (detail["my_role"], detail["can_pay"]) == (person, can_pay)
    assert sum(line["amount"] for line in detail["lines"]) == detail["amount_total"]
    pdf = client.get(f"/api/v1/bills/{bill.id}/pdf", headers=headers)
    assert (pdf.status_code, pdf.content[:5]) == (200, b"%PDF-")


def test_a_stranger_sees_nothing(client, auth_headers, db_session, family):
    tick(db_session, date(2026, 11, 3))
    (bill,) = bills_of(db_session, family["meter"])
    headers = auth_headers(make_user(db_session))
    assert client.get("/api/v1/bills", headers=headers).json()["total"] == 0
    for path in (f"/api/v1/bills/{bill.id}", f"/api/v1/bills/{bill.id}/pdf"):
        response = client.get(path, headers=headers)
        assert response.status_code == 404
        assert response.json()["error"]["code"] == "BILL_NOT_FOUND"
    by_meter = client.get("/api/v1/bills", params={"meter_id": family["meter"].id}, headers=headers)
    assert by_meter.status_code == 404
