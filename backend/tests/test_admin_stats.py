"""Tests du tableau de bord du back-office (B10.2, A1) : GET /admin/stats."""

from datetime import UTC, date, datetime, timedelta

import pytest

from app.core.request_context import RequestContext
from app.core.timezone import local_midnight_utc
from app.modules.admin.audit import record_admin_action
from app.modules.admin.stats import AdminStatsService
from app.modules.audit.service import record
from app.modules.bills.models import BillStatus
from app.modules.consumption.models import AnomalyStatus
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.users.models import UserRole
from tests.factories import (
    make_bill,
    make_household,
    make_meter,
    make_reading,
    make_transaction,
    make_user,
)

# Jeudi 12 novembre 2026, 14 h 45 à Brazzaville (13 h 45 UTC), comme sur la maquette.
NOW = datetime(2026, 11, 12, 13, 45, tzinfo=UTC)
URL = "/api/v1/admin/stats"


@pytest.fixture(autouse=True)
def fixed_now(monkeypatch):
    original = AdminStatsService.__init__
    monkeypatch.setattr(
        AdminStatsService,
        "__init__",
        lambda self, session, *, demo, now=None: original(
            self, session, demo=demo, now=lambda: NOW
        ),
    )


@pytest.fixture
def staff(db_session):
    return make_user(db_session, role=UserRole.SUPPORT, full_name="Patrick Moukala")


def stats(client, auth_headers, staff):
    response = client.get(URL, headers=auth_headers(staff))
    assert response.status_code == 200, response.text
    return response.json()


def bill(session, *, total=40_384, status=BillStatus.UNPAID, due=date(2099, 1, 1), **extra):
    """Une facture sur son propre compteur (aucune contrainte entre les tests)."""
    meter = make_meter(session, make_household(session))
    return make_bill(
        session,
        meter,
        amount_ht=total - 1_000,
        amount_tax=0,
        amount_fees=1_000,
        amount_total=total,
        due_date=due,
        status=status,
        **extra,
    )


def payment(session, status, initiated, *, total=40_384, payer=None, pin=False, reason="Refus"):
    """Un paiement (sur sa propre facture) arrivé au statut voulu."""
    transaction = make_transaction(
        session,
        bill(session, total=total),
        payer or make_user(session),
        initiated_at=initiated,
        expires_at=initiated + timedelta(minutes=10),
        operator=MobileOperator.MTN,
    )
    if pin:
        transaction.pin_entered_at = initiated + timedelta(seconds=5)
    if status is TransactionStatus.SUCCEEDED:
        transaction.provider_ref = f"SIM-{transaction.id}"
        transaction.confirmed_at = initiated + timedelta(seconds=10)
    if status in (TransactionStatus.FAILED, TransactionStatus.EXPIRED):
        transaction.failure_reason = reason
    transaction.status = status
    session.flush()
    return transaction


def at(month, day, hour=10):
    return datetime(2026, month, day, hour, tzinfo=UTC)


# --- Indicateurs ------------------------------------------------------------------------------


def test_an_empty_platform(client, auth_headers, staff):
    body = stats(client, auth_headers, staff)
    assert body["month_label"] == "Novembre 2026"
    assert body["demo"] is True
    assert body["collected_this_month"] == {
        "amount": 0,
        "payments": 0,
        "previous_month_same_point": 0,
        "change_percent": None,
    }
    assert body["failure_rate_7_days"]["rate_percent"] is None
    assert body["latest_bills"] == {
        "period_start": None,
        "period_label": None,
        "issued": 0,
        "issued_on": None,
        "by_status": [],
    }
    assert (body["watchlist"], body["team_activity"]) == ([], [])
    assert len(body["collections_30_days"]["days"]) == 30


def test_collected_this_month_against_last_month_at_the_same_point(
    client, auth_headers, db_session, staff
):
    succeeded = TransactionStatus.SUCCEEDED
    payment(db_session, succeeded, at(11, 3), total=40_384)
    payment(db_session, succeeded, at(10, 5), total=30_000)  # avant le 12 octobre 14 h 45
    payment(db_session, succeeded, at(10, 20), total=20_000)  # après : ne compte pas
    payment(db_session, TransactionStatus.FAILED, at(11, 4))  # non abouti : rien d'encaissé
    collected = stats(client, auth_headers, staff)["collected_this_month"]
    assert collected == {
        "amount": 40_384,
        "payments": 1,
        "previous_month_same_point": 30_000,
        "change_percent": 34.6,
    }


def test_failure_rate_over_seven_days(client, auth_headers, db_session, staff):
    recent, older = NOW - timedelta(days=2), NOW - timedelta(days=9)
    payment(db_session, TransactionStatus.SUCCEEDED, recent)
    payment(db_session, TransactionStatus.FAILED, recent)
    payment(db_session, TransactionStatus.EXPIRED, recent)
    payment(db_session, TransactionStatus.PENDING, recent)  # pas terminé : ne compte pas
    payment(db_session, TransactionStatus.SUCCEEDED, older)
    payment(db_session, TransactionStatus.FAILED, older)
    assert stats(client, auth_headers, staff)["failure_rate_7_days"] == {
        "rate_percent": 66.7,
        "finished": 3,
        "not_completed": 2,
        "previous_rate_percent": 50.0,
        "change_points": 16.7,
    }


def test_unpaid_bills(client, auth_headers, db_session, staff):
    bill(db_session, total=10_000)
    bill(db_session, total=20_000, due=date(2026, 11, 1))  # échue : en retard à l'affichage
    bill(db_session, total=30_000, status=BillStatus.PENDING_PAYMENT)
    bill(db_session, total=99_000, status=BillStatus.PAID, paid_at=at(11, 1))
    assert stats(client, auth_headers, staff)["unpaid_bills"] == {
        "count": 3,
        "amount": 60_000,
        "overdue_count": 1,
    }


def test_pending_transactions(client, auth_headers, db_session, staff):
    payment(db_session, TransactionStatus.PENDING, NOW - timedelta(minutes=15), pin=True)
    payment(db_session, TransactionStatus.PENDING, NOW - timedelta(minutes=2))
    assert stats(client, auth_headers, staff)["pending_transactions"] == {
        "count": 2,
        "older_than_10_minutes": 1,
    }


def test_collections_day_by_day_over_thirty_days(client, auth_headers, db_session, staff):
    payment(db_session, TransactionStatus.SUCCEEDED, at(10, 20), total=20_000)
    payment(db_session, TransactionStatus.SUCCEEDED, at(11, 3), total=40_384)
    payment(db_session, TransactionStatus.SUCCEEDED, at(11, 3, 15), total=10_000)
    payment(db_session, TransactionStatus.SUCCEEDED, at(10, 1), total=99_000)  # trop ancien
    series = stats(client, auth_headers, staff)["collections_30_days"]
    days = {day["day"]: day for day in series["days"]}
    assert (series["days"][0]["day"], series["days"][-1]["day"]) == ("2026-10-14", "2026-11-12")
    assert days["2026-11-03"] == {"day": "2026-11-03", "amount": 50_384, "payments": 2}
    assert days["2026-10-20"]["amount"] == 20_000
    assert (series["total"], series["payments"]) == (70_384, 3)


def test_latest_billing_period_by_status(client, auth_headers, db_session, staff):
    september = {"period_start": date(2026, 9, 1), "period_end": date(2026, 10, 31)}
    issued = {"issued_at": datetime(2026, 11, 3, 7, tzinfo=UTC)}
    bill(db_session, status=BillStatus.PAID, paid_at=at(11, 5), **september, **issued)
    bill(db_session, status=BillStatus.PAID, paid_at=at(11, 6), **september, **issued)
    bill(db_session, due=date(2026, 11, 18), **september, **issued)
    bill(
        db_session,
        due=date(2026, 11, 18),
        status=BillStatus.PAID,
        paid_at=at(11, 7),
        **september,
        **issued,
    )
    bill(db_session)  # juillet-août : période précédente
    latest = stats(client, auth_headers, staff)["latest_bills"]
    assert (latest["period_label"], latest["issued"], latest["issued_on"]) == (
        "Sept.-Oct. 2026",
        4,
        "2026-11-03",
    )
    counts = {row["status"]: (row["count"], row["percent"]) for row in latest["by_status"]}
    assert counts == {
        "paid": (3, 75.0),
        "unpaid": (1, 25.0),
        "pending_payment": (0, 0.0),
        "overdue": (0, 0.0),
        "cancelled": (0, 0.0),
    }


# --- À surveiller -------------------------------------------------------------------------------


def watch(client, auth_headers, staff, kind):
    return [
        item for item in stats(client, auth_headers, staff)["watchlist"] if item["kind"] == kind
    ]


def test_a_payment_stuck_for_more_than_ten_minutes(client, auth_headers, db_session, staff):
    prisca = make_user(db_session, full_name="Prisca Loemba")
    stuck = payment(
        db_session,
        TransactionStatus.PENDING,
        NOW - timedelta(minutes=14),
        total=15_520,
        payer=prisca,
        pin=True,
    )
    (item,) = watch(client, auth_headers, staff, "stuck_payment")
    assert item["title"] == "Paiement en attente depuis 14 min"
    assert item["detail"] == (
        f"TX-{stuck.id:08d} · Prisca Loemba · 15 520 FCFA · MTN MoMo · "
        "PIN saisi, débit non confirmé"
    )
    assert (item["entity_type"], item["entity_id"]) == ("payment_transaction", stuck.id)


def test_repeated_failures_today(client, auth_headers, db_session, staff):
    junior = make_user(db_session, full_name="Junior Ibara")
    today = local_midnight_utc(date(2026, 11, 12)) + timedelta(hours=8)
    payment(db_session, TransactionStatus.FAILED, today, payer=junior, reason="Solde insuffisant")
    payment(
        db_session,
        TransactionStatus.FAILED,
        today + timedelta(hours=1),
        payer=junior,
        reason="Solde insuffisant",
    )
    payment(db_session, TransactionStatus.FAILED, today)  # quelqu'un d'autre, une seule fois
    (item,) = watch(client, auth_headers, staff, "repeated_failures")
    assert item["title"] == "2 paiements échoués aujourd'hui"
    assert item["detail"] == "Junior Ibara · MTN MoMo · solde insuffisant"
    assert (item["entity_type"], item["entity_id"]) == ("user", junior.id)


def test_reading_anomalies_and_missing_readings(client, auth_headers, db_session, staff):
    meter = make_meter(db_session, make_household(db_session), reference="0219-7741")
    make_reading(
        db_session,
        meter,
        read_at=NOW - timedelta(days=1),
        is_anomaly=True,
        anomaly_reason="Index en baisse",
        consumption_wh=0,
    )
    make_meter(db_session, make_household(db_session))  # aucun relevé ce matin
    (item,) = watch(client, auth_headers, staff, "reading_anomalies")
    assert item["title"] == "1 relevé anormal"
    assert item["detail"] == "Index en baisse sur le compteur 0219-7741 · 2 relevés manquants"
    assert (item["entity_type"], item["entity_id"]) == ("meter", meter.id)


def test_dismissed_anomalies_leave_the_watchlist(client, auth_headers, db_session, staff):
    meter = make_meter(db_session, make_household(db_session))
    make_reading(
        db_session,
        meter,
        read_at=NOW - timedelta(hours=14),  # relevé de ce matin : rien de manquant
        is_anomaly=True,
        anomaly_reason="Index en baisse",
        consumption_wh=0,
        anomaly_status=AnomalyStatus.DISMISSED,
        anomaly_handled_by=staff.id,
        anomaly_handled_at=NOW,
        anomaly_note="Erreur de lecture ponctuelle",
    )
    assert watch(client, auth_headers, staff, "reading_anomalies") == []


def test_bills_overdue_for_more_than_thirty_days(client, auth_headers, db_session, staff):
    bill(db_session, total=100_000, due=date(2026, 10, 1))
    bill(db_session, total=41_860, due=date(2026, 10, 10), status=BillStatus.OVERDUE)
    bill(db_session, total=99_000, due=date(2026, 11, 1))  # en retard, mais depuis 11 jours
    (item,) = watch(client, auth_headers, staff, "long_overdue")
    assert item["title"] == "2 factures en retard depuis plus de 30 jours"
    assert item["detail"].startswith("Total 141 860 FCFA")


# --- Activité de l'équipe ------------------------------------------------------------------------


def test_team_activity_only_shows_the_team(client, auth_headers, db_session, staff):
    admin = make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala")
    context = RequestContext(ip="196.44.0.1", user_agent="Mozilla/5.0")
    record_admin_action(
        db_session,
        actor=admin,
        context=context,
        action="bill.cancel",
        entity_type="bill",
        entity_id=7,
    )
    record(  # un abonné : pas dans « activité de l'équipe »
        db_session,
        action="household.create",
        entity_type="household",
        entity_id=1,
        actor_id=make_user(db_session).id,
    )
    db_session.flush()
    (activity,) = stats(client, auth_headers, staff)["team_activity"]
    assert (activity["actor_name"], activity["actor_role"]) == ("Christelle Mabiala", "admin")
    assert (activity["action"], activity["label"]) == ("bill.cancel", "a annulé une facture")
    assert (activity["entity_type"], activity["entity_id"]) == ("bill", 7)


def test_only_the_team_sees_the_dashboard(client, auth_headers, db_session):
    response = client.get(URL, headers=auth_headers(make_user(db_session)))
    assert response.status_code == 403
