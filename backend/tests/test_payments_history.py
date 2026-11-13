"""Tests de l'historique des paiements (B7.5) : GET /payments (écran client 12)."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import update

from app.modules.households.models import HouseholdMember, MemberRole, MemberStatus
from app.modules.payments.history import month_bounds
from app.modules.payments.models import MobileOperator, TransactionStatus
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_transaction,
    make_user,
)

URL = "/api/v1/payments"
OWNER_PHONE = "+242061110001"
DELEGATE_PHONE = "+242051110002"


def at(year, month, day, hour=10):
    return datetime(year, month, day, hour, tzinfo=UTC)


def attempt(session, bill, payer, phone, started, *, status, reason=None):
    """Une tentative terminée (ou en attente), datée."""
    transaction = make_transaction(
        session,
        bill,
        payer,
        phone_number=phone,
        operator=MobileOperator.AIRTEL if phone.startswith("+24205") else MobileOperator.MTN,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
    )
    if status is TransactionStatus.SUCCEEDED:
        transaction.status = status
        transaction.provider_ref = f"SIM-{transaction.id:08d}"
        transaction.confirmed_at = started + timedelta(seconds=10)
    elif status is not TransactionStatus.PENDING:
        transaction.status, transaction.failure_reason = status, reason
    session.flush()
    return transaction


@pytest.fixture
def world(db_session):
    """Arnaud : « Maison » (Grâce payeuse, Joël lecteur) et « Boutique » (seul)."""
    owner = make_user(db_session, phone=OWNER_PHONE, full_name="Arnaud Mavoungou")
    delegate = make_user(db_session, phone=DELEGATE_PHONE, full_name="Grâce Ngoma")
    viewer = make_user(db_session, full_name="Joël Mavoungou")
    home = make_household(db_session, owner, name="Maison")
    shop = make_household(db_session, owner, name="Boutique")
    make_member(db_session, home, delegate, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    home_meter = make_meter(db_session, home, reference="0412-8833")
    shop_meter = make_meter(db_session, shop, reference="0377-1209")
    july = make_bill(db_session, home_meter)  # juillet-août 2026
    sept = make_bill(
        db_session,
        home_meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=date(2026, 11, 18),
    )
    shop_bill = make_bill(db_session, shop_meter)
    done, failed, expired = (
        TransactionStatus.SUCCEEDED,
        TransactionStatus.FAILED,
        TransactionStatus.EXPIRED,
    )
    tx = {
        "paid": attempt(db_session, july, owner, OWNER_PHONE, at(2026, 9, 10), status=done),
        "failed": attempt(
            db_session,
            sept,
            delegate,
            DELEGATE_PHONE,
            at(2026, 11, 5),
            status=failed,
            reason="Solde insuffisant",
        ),
        "expired": attempt(
            db_session,
            sept,
            owner,
            OWNER_PHONE,
            at(2026, 11, 6),
            status=expired,
            reason="Délai de confirmation dépassé (code PIN non saisi)",
        ),
        "shop": attempt(
            db_session,
            shop_bill,
            owner,
            OWNER_PHONE,
            at(2026, 11, 7),
            status=TransactionStatus.PENDING,
        ),
    }
    stranger = make_user(db_session)
    stranger_home = make_household(db_session, stranger)
    stranger_bill = make_bill(db_session, make_meter(db_session, stranger_home))
    attempt(db_session, stranger_bill, stranger, "+242069999901", at(2026, 11, 8), status=done)
    return {
        "owner": owner,
        "delegate": delegate,
        "viewer": viewer,
        "home": home,
        "shop": shop,
        "sept": sept,
        "stranger_bill": stranger_bill,
        "stranger_home": stranger_home,
        "stranger": stranger,
        "tx": tx,
    }


def get(client, headers, **params):
    return client.get(URL, params=params, headers=headers)


def ids(response):
    return [item["id"] for item in response.json()["items"]]


def tx_ids(world, *names):
    return [world["tx"][name].id for name in names]


# --- Contenu -------------------------------------------------------------------------------


def test_owner_sees_every_payment_of_their_households_most_recent_first(
    client, auth_headers, world
):
    response = get(client, auth_headers(world["owner"]))
    assert response.status_code == 200
    assert ids(response) == tx_ids(world, "shop", "expired", "failed", "paid")
    assert response.json()["total"] == 4


def test_a_payment_line_has_what_the_screen_shows(client, auth_headers, world):
    items = get(client, auth_headers(world["owner"])).json()["items"]
    failed = next(item for item in items if item["id"] == world["tx"]["failed"].id)
    assert (failed["status"], failed["step"], failed["failure_reason"]) == (
        "echouee",
        "failed",
        "Solde insuffisant",
    )
    assert (failed["payer_name"], failed["is_mine"]) == ("Grâce Ngoma", False)
    assert failed["phone_number"] == "+242 05 *** ** 02"  # pas le mien : masqué
    assert (failed["operator"], failed["operator_label"]) == ("airtel", "Airtel Money")
    assert (failed["bill_period_label"], failed["household_name"]) == ("Sept.-Oct. 2026", "Maison")
    assert (failed["meter_reference"], failed["amount"]) == ("0412-8833", 40_384)
    assert failed["source"] == "simulated"
    paid = next(item for item in items if item["id"] == world["tx"]["paid"].id)
    assert (paid["payer_name"], paid["is_mine"], paid["phone_number"]) == (
        "Arnaud Mavoungou",
        True,
        OWNER_PHONE,
    )
    assert paid["confirmed_at"] is not None


# --- Qui voit quoi --------------------------------------------------------------------------


@pytest.mark.parametrize("person", ["delegate", "viewer"])
def test_members_see_the_payments_of_the_shared_household_only(client, auth_headers, world, person):
    response = get(client, auth_headers(world[person]))
    assert ids(response) == tx_ids(world, "expired", "failed", "paid")  # pas la Boutique


def test_a_former_member_still_sees_their_own_payments(client, auth_headers, db_session, world):
    db_session.execute(  # Grâce est retirée du foyer « Maison »
        update(HouseholdMember)
        .where(
            HouseholdMember.household_id == world["home"].id,
            HouseholdMember.user_id == world["delegate"].id,
        )
        .values(status=MemberStatus.REVOKED)
    )
    db_session.flush()
    response = get(client, auth_headers(world["delegate"]))
    assert ids(response) == tx_ids(world, "failed")  # le sien, plus ceux des autres


def test_a_stranger_sees_only_their_own(client, auth_headers, world):
    response = get(client, auth_headers(world["stranger"]))
    assert response.json()["total"] == 1
    assert world["tx"]["paid"].id not in ids(response)


# --- Filtres ----------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("params", "expected"),
    [
        ({"status": "echouee"}, ["failed"]),
        ({"status": "reussie"}, ["paid"]),
        ({"status": "en_attente"}, ["shop"]),
        ({"month": "2026-11"}, ["shop", "expired", "failed"]),
        ({"month": "2026-09"}, ["paid"]),
        ({"month": "2026-10"}, []),
        ({"status": "expiree", "month": "2026-11"}, ["expired"]),
    ],
)
def test_filters(client, auth_headers, world, params, expected):
    assert ids(get(client, auth_headers(world["owner"]), **params)) == tx_ids(world, *expected)


def test_household_filter(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    assert ids(get(client, headers, household_id=world["shop"].id)) == tx_ids(world, "shop")
    assert ids(get(client, headers, household_id=world["home"].id)) == tx_ids(
        world, "expired", "failed", "paid"
    )


def test_bill_filter(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]), bill_id=world["sept"].id)
    assert ids(response) == tx_ids(world, "expired", "failed")


def test_someone_elses_household_or_bill_is_not_found(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    by_household = get(client, headers, household_id=world["stranger_home"].id)
    assert (by_household.status_code, by_household.json()["error"]["code"]) == (
        404,
        "HOUSEHOLD_NOT_FOUND",
    )
    by_bill = get(client, headers, bill_id=world["stranger_bill"].id)
    assert (by_bill.status_code, by_bill.json()["error"]["code"]) == (404, "BILL_NOT_FOUND")
    unknown = get(client, headers, bill_id=999_999_999)
    assert unknown.json() == by_bill.json()


@pytest.mark.parametrize(
    "params",
    [
        {"month": "2026-13"},
        {"month": "2026-1"},
        {"month": "octobre"},
        {"status": "payee"},
        {"size": 101},
    ],
)
def test_invalid_filters_are_refused(client, auth_headers, world, params):
    response = get(client, auth_headers(world["owner"]), **params)
    assert (response.status_code, response.json()["error"]["code"]) == (422, "VALIDATION_ERROR")


def test_months_follow_brazzaville_time():
    """31 octobre 23 h 30 à Brazzaville = 22 h 30 UTC : encore octobre."""
    start, end = month_bounds("2026-11")
    assert start == datetime(2026, 10, 31, 23, 0, tzinfo=UTC)  # 1er novembre 0 h (UTC+1)
    assert end == datetime(2026, 11, 30, 23, 0, tzinfo=UTC)


def test_a_payment_just_after_local_midnight_belongs_to_the_new_month(
    client, auth_headers, db_session, world
):
    bill = make_bill(
        db_session,
        make_meter(db_session, world["shop"]),
        due_date=date(2099, 1, 1),
    )
    late = attempt(
        db_session,
        bill,
        world["owner"],
        OWNER_PHONE,
        datetime(2026, 9, 30, 23, 30, tzinfo=UTC),  # 1er octobre, 0 h 30 à Brazzaville
        status=TransactionStatus.SUCCEEDED,
    )
    assert ids(get(client, auth_headers(world["owner"]), month="2026-10")) == [late.id]


# --- Pagination et connexion -------------------------------------------------------------------


def test_pagination(client, auth_headers, world):
    second = get(client, auth_headers(world["owner"]), page=2, size=2)
    assert ids(second) == tx_ids(world, "failed", "paid")
    assert (second.json()["total"], second.json()["page"]) == (4, 2)


def test_login_is_required(client, world):
    assert client.get(URL).status_code == 401
