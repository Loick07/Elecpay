"""Tests des compteurs (B4.5) : ajout vérifié chez E²C, historique de démo, lecture, renommage."""

from datetime import date, timedelta

import pytest
from sqlalchemy import func, select

from app.core.rate_limit import RateLimiter
from app.core.timezone import local_midnight_utc
from app.modules.audit.models import AuditLog
from app.modules.bills.models import Bill, BillLine, BillStatus
from app.modules.consumption.models import MeterReading, ReadingSource
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.meters.service import MeterService
from app.modules.payments.models import PaymentTransaction
from app.simulators.daily import run_daily_tick
from app.simulators.history import meter_seed
from tests.factories import (
    Billing,
    make_household,
    make_member,
    make_meter,
    make_tariff,
    make_user,
)

TODAY = date(2026, 11, 12)
NEW_METER = {"reference": "0018 09 5408", "customer_number": "0758340H", "label": "Maison"}


@pytest.fixture
def owner(db_session):
    return make_user(db_session, full_name="Arnaud Mavoungou")


@pytest.fixture
def home(db_session, owner):
    make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))
    return make_household(db_session, owner, name="Maison Mpita")


@pytest.fixture(autouse=True)
def fixed_today(monkeypatch):
    """Date du jour fixe : l'historique importé est reproductible."""
    original = MeterService.__init__

    def init(self, session, today=None):
        original(self, session, today=lambda: TODAY)

    monkeypatch.setattr(MeterService, "__init__", init)


def meters_url(household):
    return f"/api/v1/households/{household.id}/meters"


def add(client, headers, household, data=NEW_METER):
    return client.post(meters_url(household), json=data, headers=headers)


def code(response):
    return response.json()["error"]["code"]


# --- Ajout --------------------------------------------------------------------------


def test_add_a_meter_verified_by_e2c(client, auth_headers, owner, home):
    response = add(client, auth_headers(owner), home)
    assert response.status_code == 201
    meter = response.json()["meter"]
    assert meter["reference"] == "0018 09 5408"  # format d'affichage de la facture
    assert meter["customer_number"] == "0758340H"
    assert meter["label"] == "Maison"
    assert meter["status"] == "active"
    assert meter["e2c_center"] and meter["subscribed_power_va"] and meter["contract_number"]
    assert (meter["my_role"], meter["can_manage"]) == ("owner", True)


def test_details_come_from_e2c_not_from_the_user(client, auth_headers, owner, home):
    data = NEW_METER | {"subscribed_power_va": 99_000}
    assert add(client, auth_headers(owner), home, data).status_code == 422  # champ refusé


def test_numbers_can_be_typed_freely(client, auth_headers, owner, home):
    data = {"reference": "0018-09-5408", "customer_number": "0758340h"}
    assert (
        add(client, auth_headers(owner), home, data).json()["meter"]["reference"] == "0018 09 5408"
    )


def test_demo_history_is_imported(client, auth_headers, owner, home, db_session):
    """Choix (a) : 18 mois de relevés et les factures, marqués « simulés »."""
    body = add(client, auth_headers(owner), home).json()
    meter_id = body["meter"]["id"]
    assert body["history"]["source"] == "simulated"

    readings = db_session.scalars(
        select(MeterReading).where(MeterReading.meter_id == meter_id).order_by(MeterReading.read_at)
    ).all()
    assert len(readings) == body["history"]["readings"] > 500
    assert all(r.source is ReadingSource.SIMULATED for r in readings)
    assert readings[-1].read_at == local_midnight_utc(TODAY)

    bills = db_session.scalars(
        select(Bill).where(Bill.meter_id == meter_id).order_by(Bill.period_start)
    ).all()
    assert len(bills) == body["history"]["bills"] == 9
    assert all(b.status is BillStatus.PAID for b in bills[:-1])
    assert bills[-1].status in (BillStatus.UNPAID, BillStatus.OVERDUE)
    for bill in bills:
        lines_total = db_session.scalar(
            select(func.sum(BillLine.amount)).where(BillLine.bill_id == bill.id)
        )
        assert lines_total == bill.amount_total


def test_past_payments_are_not_invented(client, auth_headers, owner, home, db_session):
    """Les anciennes factures ont été payées HORS ElecPay : aucune transaction inventée."""
    meter_id = add(client, auth_headers(owner), home).json()["meter"]["id"]
    transactions = db_session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .join(Bill, Bill.id == PaymentTransaction.bill_id)
        .where(Bill.meter_id == meter_id)
    )
    assert transactions == 0


def test_history_seed_depends_only_on_the_meter_number():
    """Même compteur → même historique, quelle que soit la base (l'id, lui, change)."""
    assert meter_seed(Meter(id=1, reference="0018 09 5408")) == meter_seed(
        Meter(id=999, reference="0018 09 5408")
    )
    assert meter_seed(Meter(reference="0018 09 5408")) != meter_seed(
        Meter(reference="0018 09 5409")
    )


def test_adding_is_audited(client, auth_headers, owner, home, db_session):
    add(client, auth_headers(owner), home)
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "meter.add")).one()
    assert log.after_json["reference"] == "0018 09 5408"
    assert log.after_json["history_source"] == "simulated"


# --- Refus --------------------------------------------------------------------------


def test_meter_unknown_at_e2c(client, auth_headers, owner, home):
    response = add(
        client,
        auth_headers(owner),
        home,
        {"reference": "0018 09 0000", "customer_number": "0758340H"},
    )
    assert response.status_code == 404
    assert code(response) == "E2C_METER_NOT_FOUND"
    assert "facture" in response.json()["error"]["message"]


def test_demo_meter_with_a_wrong_customer_number(client, auth_headers, owner, home):
    """On n'ajoute pas le compteur de la Boutique Tié-Tié sans sa facture."""
    response = add(
        client, auth_headers(owner), home, {"reference": "0377-1209", "customer_number": "1111111H"}
    )
    assert code(response) == "E2C_METER_NOT_FOUND"


def test_meter_already_linked_to_another_household(client, auth_headers, owner, home, db_session):
    other = make_household(db_session, make_user(db_session))
    make_meter(db_session, other, reference="0018 09 5408")
    response = add(client, auth_headers(owner), home)
    assert response.status_code == 409
    assert code(response) == "METER_ALREADY_LINKED"


def test_meter_already_in_my_household(client, auth_headers, owner, home):
    add(client, auth_headers(owner), home)
    assert code(add(client, auth_headers(owner), home)) == "METER_ALREADY_LINKED"


def test_detached_meter_can_be_attached_again_without_new_history(
    client, auth_headers, owner, home, db_session
):
    detached = make_meter(db_session, household=None, reference="0018 09 5408")
    response = add(client, auth_headers(owner), home)
    assert response.status_code == 201
    assert response.json()["meter"]["id"] == detached.id
    assert response.json()["history"] == {"readings": 0, "bills": 0, "source": "existing"}


def test_at_most_five_meters_per_household(client, auth_headers, owner, home, db_session):
    for i in range(5):
        make_meter(db_session, home, reference=f"0018 09 {i + 1:04d}")
    response = add(
        client,
        auth_headers(owner),
        home,
        {"reference": "0018 09 9999", "customer_number": "0758340H"},
    )
    assert response.status_code == 409
    assert code(response) == "METER_LIMIT_REACHED"


@pytest.mark.parametrize(
    "data",
    [
        {"reference": "0018 09", "customer_number": "0758340H"},
        {"reference": "0018 09 5408", "customer_number": "0758340"},
        {"reference": "0018 09 5408"},
        {"customer_number": "0758340H"},
        NEW_METER | {"label": "x" * 61},
    ],
)
def test_malformed_requests(client, auth_headers, owner, home, data):
    assert add(client, auth_headers(owner), home, data).status_code == 422


@pytest.mark.parametrize("role", [MemberRole.PAYER, MemberRole.VIEWER])
def test_only_the_owner_adds(client, auth_headers, home, db_session, role):
    member = make_user(db_session)
    make_member(db_session, home, member, role=role, status=MemberStatus.ACTIVE)
    response = add(client, auth_headers(member), home)
    assert response.status_code == 403
    assert code(response) == "HOUSEHOLD_FORBIDDEN"


def test_stranger_cannot_add_to_someone_elses_household(client, auth_headers, home, db_session):
    assert add(client, auth_headers(make_user(db_session)), home).status_code == 404


def test_adding_is_rate_limited(app, client, auth_headers, owner, home):
    app.state.rate_limiter = RateLimiter()
    for _ in range(10):
        add(
            client,
            auth_headers(owner),
            home,
            {"reference": "0018 09 0000", "customer_number": "0758340H"},
        )
    assert add(client, auth_headers(owner), home).status_code == 429


# --- Lecture et renommage -----------------------------------------------------------


def test_list_and_read_meters(client, auth_headers, owner, home, db_session):
    payer = make_user(db_session)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home, label="Maison", subscribed_power_va=6_000)

    listed = client.get(meters_url(home), headers=auth_headers(payer)).json()
    assert [m["label"] for m in listed] == ["Maison"]
    detail = client.get(f"/api/v1/meters/{meter.id}", headers=auth_headers(payer)).json()
    assert (detail["subscribed_power_va"], detail["my_role"], detail["can_manage"]) == (
        6_000,
        "payer",
        False,
    )


def test_meter_of_someone_else_is_not_found(client, auth_headers, home, db_session):
    meter = make_meter(db_session, home)
    stranger = make_user(db_session)
    for response in (
        client.get(f"/api/v1/meters/{meter.id}", headers=auth_headers(stranger)),
        client.patch(
            f"/api/v1/meters/{meter.id}", json={"label": "Piraté"}, headers=auth_headers(stranger)
        ),
        client.get(meters_url(home), headers=auth_headers(stranger)),
    ):
        assert response.status_code == 404


def test_owner_renames_a_meter(client, auth_headers, owner, home, db_session):
    meter = make_meter(db_session, home, label="Maison")
    response = client.patch(
        f"/api/v1/meters/{meter.id}", json={"label": "  Boutique  "}, headers=auth_headers(owner)
    )
    assert response.json()["label"] == "Boutique"
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "meter.rename")).one()
    assert (log.before_json, log.after_json) == ({"label": "Maison"}, {"label": "Boutique"})


def test_label_can_be_cleared(client, auth_headers, owner, home, db_session):
    meter = make_meter(db_session, home, label="Maison")
    response = client.patch(
        f"/api/v1/meters/{meter.id}", json={"label": None}, headers=auth_headers(owner)
    )
    assert response.json()["label"] is None


@pytest.mark.parametrize("data", [{}, {"reference": "0000 00 0000"}, {"subscribed_power_va": 1}])
def test_only_the_label_can_be_changed(client, auth_headers, owner, home, db_session, data):
    meter = make_meter(db_session, home)
    assert (
        client.patch(
            f"/api/v1/meters/{meter.id}", json=data, headers=auth_headers(owner)
        ).status_code
        == 422
    )


def test_payer_cannot_rename(client, auth_headers, home, db_session):
    payer = make_user(db_session)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home)
    response = client.patch(
        f"/api/v1/meters/{meter.id}", json={"label": "X"}, headers=auth_headers(payer)
    )
    assert code(response) == "HOUSEHOLD_FORBIDDEN"


# --- Le relevé quotidien prend le relais --------------------------------------------


def test_daily_tick_continues_the_imported_history(client, auth_headers, owner, home, db_session):
    meter_id = add(client, auth_headers(owner), home).json()["meter"]["id"]
    report = run_daily_tick(db_session, today=TODAY + timedelta(days=2), settings=Billing())
    assert report.counts["readings"] >= 2
    last = db_session.scalars(
        select(MeterReading)
        .where(MeterReading.meter_id == meter_id)
        .order_by(MeterReading.read_at.desc())
    ).first()
    assert last.read_at == local_midnight_utc(TODAY + timedelta(days=2))
