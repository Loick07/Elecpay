"""Tests de la liste des factures (B6.3) : GET /bills."""

from datetime import UTC, date, datetime, timedelta

import pytest

from app.core.calendar import add_months
from app.modules.bills.models import BillStatus
from app.modules.bills.queries import BillQueries, bill_period_label
from app.modules.households.models import MemberRole, MemberStatus
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_tariff,
    make_user,
)

TODAY = date(2026, 11, 12)
URL = "/api/v1/bills"


@pytest.fixture(autouse=True)
def fixed_today(monkeypatch):
    original = BillQueries.__init__
    monkeypatch.setattr(
        BillQueries,
        "__init__",
        lambda self, session, today=None: original(self, session, lambda: TODAY),
    )


def make_period_bill(session, meter, tariff, start, *, status=BillStatus.UNPAID, due, total):
    """Facture bimestrielle commençant le `start` (montants cohérents : HT = total − 1 000)."""
    end = add_months(start, 2) - timedelta(days=1)
    extra = {}
    if status is BillStatus.PAID:
        extra["paid_at"] = datetime(due.year, due.month, 1, tzinfo=UTC)
    if status is BillStatus.CANCELLED:
        extra["cancelled_at"] = datetime(due.year, due.month, 1, tzinfo=UTC)
        extra["cancelled_reason"] = "Facture émise par erreur"
    return make_bill(
        session,
        meter,
        tariff,
        period_start=start,
        period_end=end,
        due_date=due,
        status=status,
        amount_ht=total - 1_000,
        amount_tax=0,
        amount_fees=1_000,
        amount_total=total,
        **extra,
    )


@pytest.fixture
def world(db_session):
    """Deux foyers d'Arnaud : « Maison » (lecteur : Joël) et « Boutique » (payeuse : Grâce)."""
    tariff = make_tariff(db_session, valid_from=date(2025, 1, 1))
    owner, payer, viewer = make_user(db_session), make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner, name="Maison")
    shop = make_household(db_session, owner, name="Boutique")
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    make_member(db_session, shop, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    home_meter = make_meter(db_session, home, label="Maison", reference="0412-8833")
    shop_meter = make_meter(db_session, shop, label="Boutique", reference="0377-1209")

    def bill(meter, start, status, due, total):
        return make_period_bill(
            db_session, meter, tariff, start, status=status, due=due, total=total
        )

    paid, unpaid, overdue = BillStatus.PAID, BillStatus.UNPAID, BillStatus.OVERDUE
    pending, cancelled = BillStatus.PENDING_PAYMENT, BillStatus.CANCELLED
    bills = {
        "jan": bill(home_meter, date(2026, 1, 1), paid, date(2026, 3, 18), 30_000),
        "mar": bill(home_meter, date(2026, 3, 1), paid, date(2026, 5, 18), 31_000),
        # impayée, échéance dépassée, relevé quotidien pas encore passé : affichée en retard
        "may": bill(home_meter, date(2026, 5, 1), unpaid, date(2026, 7, 18), 32_000),
        "jul": bill(home_meter, date(2026, 7, 1), overdue, date(2026, 9, 18), 33_000),
        "sep": bill(home_meter, date(2026, 9, 1), unpaid, date(2026, 11, 18), 34_000),
        "shop_sep": bill(shop_meter, date(2026, 9, 1), pending, date(2026, 11, 18), 50_000),
        "shop_old": bill(shop_meter, date(2025, 7, 1), cancelled, date(2025, 9, 18), 45_000),
    }
    # Le foyer d'un inconnu : jamais visible.
    stranger_meter = make_meter(db_session, make_household(db_session))
    bill(stranger_meter, date(2026, 9, 1), unpaid, date(2026, 11, 18), 99_000)
    return {
        "owner": owner,
        "payer": payer,
        "viewer": viewer,
        "home": home,
        "shop": shop,
        "home_meter": home_meter,
        "shop_meter": shop_meter,
        "bills": bills,
        "stranger_meter": stranger_meter,
    }


def get(client, headers, **params):
    return client.get(URL, params=params, headers=headers)


def ids(response):
    return [item["id"] for item in response.json()["items"]]


def bill_ids(world, *names):
    return [world["bills"][name].id for name in names]


# --- Liste par défaut -------------------------------------------------------------------


def test_lists_all_my_bills_most_recent_first_without_cancelled(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]))
    assert response.status_code == 200
    body = response.json()
    # Même période : la plus récemment émise d'abord.
    assert ids(response) == bill_ids(world, "shop_sep", "sep", "jul", "may", "mar", "jan")
    assert (body["total"], body["page"], body["size"]) == (6, 1, 20)


def test_a_bill_summary_has_what_the_screen_shows(client, auth_headers, world):
    items = get(client, auth_headers(world["owner"])).json()["items"]
    sep = next(item for item in items if item["id"] == world["bills"]["sep"].id)
    assert sep["period_label"] == "Sept.-Oct. 2026"
    assert (sep["period_start"], sep["period_end"]) == ("2026-09-01", "2026-10-31")
    assert sep["amount_total"] == 34_000
    assert (sep["consumption_wh"], sep["consumption_kwh"]) == (571_000, 571.0)
    assert sep["due_date"] == "2026-11-18"
    assert (sep["status"], sep["days_overdue"], sep["can_pay"]) == ("unpaid", 0, True)
    assert (sep["meter_reference"], sep["meter_label"]) == ("0412-8833", "Maison")
    assert (sep["household_id"], sep["household_name"]) == (world["home"].id, "Maison")
    assert (sep["my_role"], sep["source"]) == ("owner", "simulated")
    assert sep["reference"] == world["bills"]["sep"].reference


def test_an_unpaid_bill_past_its_due_date_is_shown_overdue(client, auth_headers, world):
    """Décision B6 : le retard s'affiche sans attendre le relevé quotidien."""
    items = get(client, auth_headers(world["owner"])).json()["items"]
    may = next(item for item in items if item["id"] == world["bills"]["may"].id)
    assert (may["status"], may["days_overdue"], may["can_pay"]) == ("overdue", 117, True)
    assert world["bills"]["may"].status is BillStatus.UNPAID  # la base n'est pas modifiée


def test_paid_and_pending_bills_cannot_be_paid_again(client, auth_headers, world):
    items = {item["id"]: item for item in get(client, auth_headers(world["owner"])).json()["items"]}
    assert items[world["bills"]["jan"].id]["can_pay"] is False
    assert items[world["bills"]["jan"].id]["paid_at"] is not None
    assert items[world["bills"]["shop_sep"].id]["status"] == "pending_payment"
    assert items[world["bills"]["shop_sep"].id]["can_pay"] is False


# --- Filtres de statut ------------------------------------------------------------------


@pytest.mark.parametrize(
    ("status", "expected"),
    [
        ("to_pay", ["shop_sep", "sep", "jul", "may"]),
        ("overdue", ["jul", "may"]),
        ("paid", ["mar", "jan"]),
        ("pending_payment", ["shop_sep"]),
        ("cancelled", ["shop_old"]),
    ],
)
def test_status_filters(client, auth_headers, world, status, expected):
    response = get(client, auth_headers(world["owner"]), status=status)
    assert ids(response) == bill_ids(world, *expected)
    assert response.json()["total"] == len(expected)


def test_unknown_status_is_refused(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]), status="unpaid")
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


# --- Reste à payer ----------------------------------------------------------------------


def test_outstanding_covers_all_my_households(client, auth_headers, world):
    outstanding = get(client, auth_headers(world["owner"])).json()["outstanding"]
    assert outstanding == {
        "amount": 34_000 + 50_000 + 33_000 + 32_000,
        "count": 4,
        "overdue_amount": 33_000 + 32_000,
        "overdue_count": 2,
    }


def test_outstanding_ignores_status_and_year_filters(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    reference = get(client, headers).json()["outstanding"]
    assert get(client, headers, status="paid").json()["outstanding"] == reference
    assert get(client, headers, year=2025).json()["outstanding"] == reference


def test_outstanding_follows_the_household_filter(client, auth_headers, world):
    body = get(client, auth_headers(world["owner"]), household_id=world["shop"].id).json()
    assert body["outstanding"] == {
        "amount": 50_000,
        "count": 1,
        "overdue_amount": 0,
        "overdue_count": 0,
    }


# --- Filtres de foyer, compteur, année ----------------------------------------------------


def test_household_filter(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]), household_id=world["shop"].id)
    assert ids(response) == bill_ids(world, "shop_sep")


def test_meter_filter(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]), meter_id=world["home_meter"].id)
    assert ids(response) == bill_ids(world, "sep", "jul", "may", "mar", "jan")


def test_year_filter_uses_the_start_of_the_period(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    assert ids(get(client, headers, year=2025)) == []  # la seule de 2025 est annulée
    assert ids(get(client, headers, year=2025, status="cancelled")) == bill_ids(world, "shop_old")
    assert get(client, headers, year=2026).json()["total"] == 6


@pytest.mark.parametrize("year", [1999, 2101])
def test_year_out_of_range_is_refused(client, auth_headers, world, year):
    assert get(client, auth_headers(world["owner"]), year=year).status_code == 422


def test_filters_combine(client, auth_headers, world):
    response = get(
        client,
        auth_headers(world["owner"]),
        meter_id=world["home_meter"].id,
        status="overdue",
        year=2026,
    )
    assert ids(response) == bill_ids(world, "jul", "may")


# --- Accès --------------------------------------------------------------------------------


def test_someone_elses_meter_or_household_is_not_found(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    by_meter = get(client, headers, meter_id=world["stranger_meter"].id)
    assert by_meter.status_code == 404
    assert by_meter.json()["error"]["code"] == "METER_NOT_FOUND"
    by_household = get(client, headers, household_id=world["stranger_meter"].household_id)
    assert by_household.status_code == 404
    assert by_household.json()["error"]["code"] == "HOUSEHOLD_NOT_FOUND"


def test_unknown_meter_answers_like_someone_elses(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]), meter_id=999_999_999)
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "METER_NOT_FOUND"


def test_a_delegated_payer_sees_and_can_pay_only_the_shared_household(client, auth_headers, world):
    body = get(client, auth_headers(world["payer"]), status="to_pay").json()
    assert [item["id"] for item in body["items"]] == bill_ids(world, "shop_sep")
    assert body["items"][0]["my_role"] == "payer"
    assert body["outstanding"]["amount"] == 50_000
    home_only = get(client, auth_headers(world["payer"]), household_id=world["home"].id)
    assert home_only.status_code == 404


def test_a_viewer_sees_but_cannot_pay(client, auth_headers, world):
    items = get(client, auth_headers(world["viewer"]), status="to_pay").json()["items"]
    assert [item["id"] for item in items] == bill_ids(world, "sep", "jul", "may")
    assert all(item["my_role"] == "viewer" and item["can_pay"] is False for item in items)


@pytest.mark.parametrize("status", [MemberStatus.INVITED, MemberStatus.REVOKED])
def test_a_pending_or_revoked_member_sees_nothing(client, auth_headers, db_session, world, status):
    someone = make_user(db_session)
    make_member(db_session, world["home"], someone, role=MemberRole.PAYER, status=status)
    body = get(client, auth_headers(someone)).json()
    assert (body["items"], body["total"]) == ([], 0)
    assert body["outstanding"] == {"amount": 0, "count": 0, "overdue_amount": 0, "overdue_count": 0}


def test_bills_of_a_detached_meter_are_hidden(client, auth_headers, db_session, world):
    world["shop_meter"].household_id = None  # détaché par l'administration
    db_session.flush()
    response = get(client, auth_headers(world["owner"]))
    assert world["bills"]["shop_sep"].id not in ids(response)
    assert response.json()["outstanding"]["amount"] == 34_000 + 33_000 + 32_000


def test_login_is_required(client, world):
    response = client.get(URL)
    assert response.status_code == 401


# --- Pagination ---------------------------------------------------------------------------


def test_pagination(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    second = get(client, headers, page=2, size=2)
    assert ids(second) == bill_ids(world, "jul", "may")
    assert second.json()["total"] == 6
    assert ids(get(client, headers, page=4, size=2)) == []


@pytest.mark.parametrize("params", [{"size": 0}, {"size": 101}, {"page": 0}])
def test_invalid_pagination_is_refused(client, auth_headers, world, params):
    assert get(client, auth_headers(world["owner"]), **params).status_code == 422


# --- Libellés ------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("start", "end", "label"),
    [
        (date(2026, 7, 1), date(2026, 8, 31), "Juil.-Août 2026"),
        (date(2026, 11, 1), date(2026, 12, 31), "Nov.-Déc. 2026"),
        (date(2026, 10, 1), date(2026, 10, 31), "Oct. 2026"),
        (date(2026, 1, 1), date(2026, 3, 31), "Janv.-Mars 2026"),
    ],
)
def test_period_labels_like_e2c(start, end, label):
    assert bill_period_label(start, end) == label
