"""Tests des écrans Utilisateurs du back-office (B10.3, A2 et A3)."""

import csv
import io
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.db.base import utcnow
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.admin import users as users_module
from app.modules.audit.models import AuditLog
from app.modules.auth.models import RefreshToken
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.users.models import UserRole
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_refresh_token,
    make_transaction,
    make_user,
)

URL = "/api/v1/admin/users"
THIS_YEAR = utcnow().year


def paid_by(session, bill, payer, operator=MobileOperator.MTN, status=TransactionStatus.SUCCEEDED):
    started = datetime(THIS_YEAR, 1, 15, 9, tzinfo=UTC)
    transaction = make_transaction(
        session,
        bill,
        payer,
        operator=operator,
        phone_number="+242051110002" if operator is MobileOperator.AIRTEL else "+242061110001",
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
    )
    if status is TransactionStatus.SUCCEEDED:
        transaction.provider_ref = f"SIM-{transaction.id}"
        transaction.confirmed_at = started + timedelta(seconds=10)
    else:
        transaction.failure_reason = "Solde insuffisant"
    transaction.status = status
    session.flush()
    if status is TransactionStatus.SUCCEEDED:  # comme en vrai : la facture est payée avec
        bill.status, bill.paid_at = BillStatus.PAID, transaction.confirmed_at
        session.flush()
    return transaction


@pytest.fixture
def world(db_session):
    arnaud = make_user(db_session, full_name="Arnaud Mavoungou", phone="+242061110001")
    grace = make_user(db_session, full_name="Grâce Ngoma", phone="+242051110002")
    support = make_user(db_session, role=UserRole.SUPPORT, full_name="Patrick Moukala")
    admin = make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala")
    boss = make_user(db_session, role=UserRole.SUPER_ADMIN, full_name="Serge Bouanga")
    home = make_household(db_session, arnaud, name="Maison Mpita")
    shop = make_household(db_session, arnaud, name="Boutique Tié-Tié")
    make_member(db_session, shop, grace, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    home_meter = make_meter(db_session, home, reference="0412-8833", subscribed_power_va=6_000)
    shop_meter = make_meter(db_session, shop, reference="0377-1209")
    paid_bill = make_bill(db_session, home_meter)
    shop_bill = make_bill(db_session, shop_meter)
    make_bill(  # à payer, échue depuis longtemps : en retard
        db_session,
        home_meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=date(2026, 11, 1),
        amount_ht=9_000,
        amount_tax=0,
        amount_fees=870,
        amount_total=9_870,
    )
    paid_by(db_session, paid_bill, arnaud)
    paid_by(db_session, shop_bill, grace, operator=MobileOperator.AIRTEL)
    paid_by(
        db_session,
        make_bill(db_session, make_meter(db_session, home)),
        arnaud,
        status=TransactionStatus.FAILED,
    )
    return {
        "arnaud": arnaud,
        "grace": grace,
        "support": support,
        "admin": admin,
        "boss": boss,
        "home": home,
        "shop": shop,
    }


def get(client, headers, path="", **params):
    return client.get(URL + path, params=params, headers=headers)


def names(response):
    return [item["full_name"] for item in response.json()["items"]]


# --- Liste (A2) -----------------------------------------------------------------------------


def test_everyone_is_listed_with_the_account_counts(client, auth_headers, world):
    body = get(client, auth_headers(world["admin"])).json()
    assert set(names_of(body)) >= {"Arnaud Mavoungou", "Grâce Ngoma", "Patrick Moukala"}
    assert body["accounts"] == body["total"]
    assert body["active_accounts"] == body["accounts"]


def names_of(body):
    return [item["full_name"] for item in body["items"]]


@pytest.mark.parametrize(
    ("q", "expected"),
    [("ngoma", ["Grâce Ngoma"]), ("05 111", ["Grâce Ngoma"]), ("1110001", ["Arnaud Mavoungou"])],
)
def test_search_by_name_or_number(client, auth_headers, world, q, expected):
    assert names(get(client, auth_headers(world["support"]), q=q)) == expected


def test_too_few_digits_do_not_search_numbers(client, auth_headers, world):
    assert names(get(client, auth_headers(world["admin"]), q="06")) == []


@pytest.mark.parametrize(
    ("kind", "expected"),
    [
        ("delegated_payer", {"Grâce Ngoma"}),
        ("team", {"Patrick Moukala", "Christelle Mabiala", "Serge Bouanga"}),
    ],
)
def test_kind_filters(client, auth_headers, world, kind, expected):
    assert set(names(get(client, auth_headers(world["admin"]), kind=kind))) == expected


def test_client_filter_leaves_the_team_out(client, auth_headers, world):
    listed = set(names(get(client, auth_headers(world["admin"]), kind="client")))
    assert {"Arnaud Mavoungou", "Grâce Ngoma"} <= listed
    assert not listed & {"Patrick Moukala", "Christelle Mabiala", "Serge Bouanga"}


def test_a_row_has_what_the_screen_shows(client, auth_headers, world):
    rows = {
        item["full_name"]: item
        for item in get(client, auth_headers(world["admin"]), kind="client").json()["items"]
    }
    arnaud, grace = rows["Arnaud Mavoungou"], rows["Grâce Ngoma"]
    assert (arnaud["households"], arnaud["is_delegated_payer"]) == (2, False)
    # La facture échue le 01/11 et celle du paiement échoué (échue le 30/09) : 2 en retard.
    assert arnaud["unpaid"]["count"] == 2
    assert arnaud["unpaid"]["overdue_count"] == 2
    assert arnaud["unpaid"]["oldest_overdue_days"] >= 1
    assert (grace["households"], grace["is_delegated_payer"]) == (1, True)
    assert grace["unpaid"] == {
        "count": 0,
        "amount": 0,
        "overdue_count": 0,
        "pending_payment_count": 0,
        "oldest_overdue_days": None,
    }
    assert arnaud["phone"] == "+242061110001"  # admin : numéro en entier


def test_support_sees_masked_numbers_but_can_search_them(client, auth_headers, world):
    (row,) = get(client, auth_headers(world["support"]), q="1110002").json()["items"]
    assert row["phone"] == "+242 05 *** ** 02"


def test_disabled_filter(client, auth_headers, db_session, world):
    world["grace"].is_active = False
    db_session.flush()
    assert names(get(client, auth_headers(world["admin"]), status="disabled")) == ["Grâce Ngoma"]


def test_pagination(client, auth_headers, world):
    body = get(client, auth_headers(world["admin"]), page=1, size=2).json()
    assert (len(body["items"]), body["size"]) == (2, 2)
    assert body["total"] >= 5


# --- Export CSV -----------------------------------------------------------------------------


def test_export_csv_is_written_to_the_journal(client, auth_headers, db_session, world):
    response = client.get(
        f"{URL}/export.csv", params={"kind": "client"}, headers=auth_headers(world["admin"])
    )
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/csv")
    assert response.headers["content-disposition"] == (
        'attachment; filename="utilisateurs-elecpay.csv"'
    )
    text = response.content.decode("utf-8")
    assert text.startswith("﻿")  # BOM : accents corrects dans Excel
    rows = list(csv.reader(io.StringIO(text.lstrip("﻿")), delimiter=";"))
    assert rows[0][:3] == ["id", "nom", "téléphone"]
    by_name = {row[1]: row for row in rows[1:]}
    assert by_name["Grâce Ngoma"][4] == "oui"
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "admin.export")).one()
    assert log.actor_id == world["admin"].id
    assert log.after_json["rows"] == len(rows) - 1
    assert log.after_json["kind"] == "client"


def test_export_refuses_too_many_rows(client, auth_headers, world, monkeypatch):
    monkeypatch.setattr(users_module, "EXPORT_LIMIT", 1)
    response = client.get(f"{URL}/export.csv", headers=auth_headers(world["admin"]))
    assert (response.status_code, response.json()["error"]["code"]) == (422, "EXPORT_TOO_LARGE")


# --- Détail (A3) ----------------------------------------------------------------------------


def test_detail_of_a_customer(client, auth_headers, db_session, world):
    arnaud = world["arnaud"]
    make_refresh_token(db_session, arnaud, user_agent="ElecPay Android")
    make_refresh_token(db_session, arnaud, revoked_at=utcnow())  # fermée
    make_refresh_token(
        db_session,
        arnaud,
        created_at=utcnow() - timedelta(days=40),
        expires_at=utcnow() - timedelta(days=10),
    )  # expirée
    body = get(client, auth_headers(world["admin"]), f"/{arnaud.id}").json()

    assert (body["full_name"], body["phone"], body["is_active"]) == (
        "Arnaud Mavoungou",
        "+242061110001",
        True,
    )
    households = {line["name"]: line for line in body["households"]}
    assert households["Maison Mpita"]["role"] == "owner"
    assert households["Maison Mpita"]["meters"][0]["reference"] == "0412-8833"
    assert households["Boutique Tié-Tié"]["delegated_payers"] == ["Grâce Ngoma"]

    payers = {line["payer_name"] for line in body["recent_transactions"]}
    assert payers == {"Arnaud Mavoungou", "Grâce Ngoma"}  # Grâce a payé pour sa boutique

    summary = body["summary"]
    assert summary["paid_this_year"] == 40_384  # ses propres paiements réussis
    assert (summary["attempts"], summary["not_completed"]) == (2, 1)
    assert summary["preferred_operator"] == "mtn"
    assert summary["left_to_pay"] == 9_870 + 40_384

    assert [s["user_agent"] for s in body["open_sessions"]] == ["ElecPay Android"]
    assert body["deactivation"] is None


def test_support_sees_a_masked_number_in_the_detail(client, auth_headers, world):
    body = get(client, auth_headers(world["support"]), f"/{world['arnaud'].id}").json()
    assert body["phone"] == "+242 06 *** ** 01"


def test_unknown_user(client, auth_headers, world):
    response = get(client, auth_headers(world["admin"]), "/999999999")
    assert (response.status_code, response.json()["error"]["code"]) == (404, "USER_NOT_FOUND")


# --- Désactiver / réactiver -----------------------------------------------------------------


def deactivate(client, headers, user, reason="Demande du titulaire"):
    return client.post(f"{URL}/{user.id}/deactivate", json={"reason": reason}, headers=headers)


def test_deactivation_closes_every_session_and_is_journaled(
    client, auth_headers, db_session, world
):
    arnaud = world["arnaud"]
    make_refresh_token(db_session, arnaud)
    make_refresh_token(db_session, arnaud)
    headers_of_arnaud = auth_headers(arnaud)

    response = deactivate(client, auth_headers(world["admin"]), arnaud)
    assert response.json() == {"id": arnaud.id, "is_active": False, "sessions_closed": 2}
    open_tokens = db_session.scalars(
        select(RefreshToken).where(
            RefreshToken.user_id == arnaud.id, RefreshToken.revoked_at.is_(None)
        )
    ).all()
    assert open_tokens == []
    # Son jeton d'accès encore valide ne sert plus à rien.
    refused = client.get("/api/v1/me", headers=headers_of_arnaud)
    assert (refused.status_code, refused.json()["error"]["code"]) == (403, "ACCOUNT_DISABLED")

    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "user.deactivate")).one()
    assert (log.actor_id, log.entity_id) == (world["admin"].id, arnaud.id)
    assert log.after_json == {
        "is_active": False,
        "reason": "Demande du titulaire",
        "sessions_closed": 2,
    }

    detail = get(client, auth_headers(world["support"]), f"/{arnaud.id}").json()
    assert detail["deactivation"]["reason"] == "Demande du titulaire"
    assert detail["deactivation"]["by"] == "Christelle Mabiala"
    assert detail["journal"][0]["label"] == "a désactivé un compte"


@pytest.mark.parametrize("reason", ["", "  ", "non"])
def test_a_reason_is_required(client, auth_headers, world, reason):
    response = deactivate(client, auth_headers(world["admin"]), world["arnaud"], reason)
    assert response.status_code == 422


def test_refused_deactivations(client, auth_headers, db_session, world):
    admin = auth_headers(world["admin"])
    assert deactivate(client, admin, world["admin"]).status_code == 409  # soi-même
    refused = deactivate(client, admin, world["support"])  # l'équipe : super admin seulement
    assert (refused.status_code, refused.json()["error"]["code"]) == (409, "ACCOUNT_ACTION_REFUSED")
    assert deactivate(client, auth_headers(world["boss"]), world["support"]).status_code == 200
    again = deactivate(client, auth_headers(world["boss"]), world["support"])
    assert "déjà désactivé" in again.json()["error"]["message"]


def test_reactivation(client, auth_headers, db_session, world):
    admin = auth_headers(world["admin"])
    deactivate(client, admin, world["arnaud"])
    response = client.post(f"{URL}/{world['arnaud'].id}/reactivate", json={}, headers=admin)
    assert response.json() == {"id": world["arnaud"].id, "is_active": True, "sessions_closed": 0}
    assert client.get("/api/v1/me", headers=auth_headers(world["arnaud"])).status_code == 200
    again = client.post(f"{URL}/{world['arnaud'].id}/reactivate", json={}, headers=admin)
    assert again.status_code == 409
    actions = db_session.scalars(
        select(AuditLog.action)
        .where(AuditLog.entity_id == world["arnaud"].id)
        .order_by(AuditLog.id)
    ).all()
    assert actions[-2:] == ["user.deactivate", "user.reactivate"]


# --- Code de réinitialisation ---------------------------------------------------------------


def test_reset_code_goes_to_the_user_never_to_the_team(
    app, client, auth_headers, db_session, world
):
    sms = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sms
    response = client.post(
        f"{URL}/{world['arnaud'].id}/reset-code", headers=auth_headers(world["admin"])
    )
    assert response.json() == {"sent": True, "phone": "+242 06 *** ** 01"}
    (message,) = sms.outbox
    assert message.phone == "+242061110001"
    code = "".join(char for char in message.message if char.isdigit())[:6]
    assert code not in response.text
    log = db_session.scalars(
        select(AuditLog).where(AuditLog.action == "user.send_reset_code")
    ).one()
    assert log.after_json == {"sent_to": "+242 06 *** ** 01"}
    assert code not in str(log.after_json)


def test_no_reset_code_for_a_disabled_account(client, auth_headers, world):
    admin = auth_headers(world["admin"])
    deactivate(client, admin, world["arnaud"])
    response = client.post(f"{URL}/{world['arnaud'].id}/reset-code", headers=admin)
    assert response.status_code == 409
