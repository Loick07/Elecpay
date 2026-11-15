"""Finitions du back-office (B11.5) : factures non émises et e-mails abandonnés dans « À
surveiller », liste Utilisateurs en requêtes groupées, fréquence limitée des demandes d'état
au prestataire pendant le suivi d'un paiement."""

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import event

from app.db.base import utcnow
from app.integrations.payment_providers.factory import get_payment_provider
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.modules.admin.stats import AdminStatsService
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.emails.models import EmailKind, EmailStatus, OutboxEmail
from app.modules.payments.tracking import StatusCheckThrottle
from app.modules.users.models import UserRole
from tests.factories import make_bill, make_household, make_meter, make_transaction, make_user

NOW = datetime(2026, 11, 12, 13, 45, tzinfo=UTC)


@pytest.fixture
def fixed_now(monkeypatch):
    original = AdminStatsService.__init__
    monkeypatch.setattr(
        AdminStatsService,
        "__init__",
        lambda self, session, *, demo, now=None: original(
            self, session, demo=demo, now=lambda: NOW
        ),
    )


def watch(client, auth_headers, user, kind):
    body = client.get("/api/v1/admin/stats", headers=auth_headers(user)).json()
    return [item for item in body["watchlist"] if item["kind"] == kind]


def issue_failed(session, meter, period_start, at, message="Aucun tarif en vigueur."):
    session.add(
        AuditLog(
            actor_id=None,
            action="bill.issue_failed",
            entity_type="meter",
            entity_id=meter.id,
            after_json={"period_start": period_start, "error": "NO_TARIFF", "message": message},
            created_at=at,
        )
    )
    session.flush()


# --- À surveiller ---------------------------------------------------------------------------


def test_unissued_bills_until_they_are_issued(client, auth_headers, db_session, fixed_now):
    staff = make_user(db_session, role=UserRole.SUPPORT)
    meter = make_meter(db_session, make_household(db_session), reference="0412-8833")
    issue_failed(db_session, meter, "2026-09-01", NOW - timedelta(days=2))
    issue_failed(
        db_session, meter, "2026-09-01", NOW - timedelta(days=1)
    )  # même échec, un jour après
    other = make_meter(db_session, make_household(db_session))
    issue_failed(db_session, other, "2026-09-01", NOW - timedelta(days=9))  # trop ancien
    (item,) = watch(client, auth_headers, staff, "unissued_bills")
    assert item["title"] == "1 facture non émise"
    assert item["detail"] == "Compteur 0412-8833 : Aucun tarif en vigueur."
    assert (item["entity_type"], item["entity_id"]) == ("meter", meter.id)

    make_bill(  # le problème est réglé : la facture a fini par être émise
        db_session,
        meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=date(2026, 11, 18),
    )
    assert watch(client, auth_headers, staff, "unissued_bills") == []


def test_failed_emails(client, auth_headers, db_session, fixed_now):
    staff = make_user(db_session, role=UserRole.SUPPORT)
    user = make_user(db_session, email="grace@example.com")
    db_session.add(
        OutboxEmail(
            user_id=user.id,
            to_email="grace@example.com",
            kind=EmailKind.PAYMENT_RECEIPT,
            status=EmailStatus.FAILED,
            attempts=6,
            next_attempt_at=NOW,
            updated_at=NOW - timedelta(hours=1),
        )
    )
    db_session.flush()
    (item,) = watch(client, auth_headers, staff, "failed_emails")
    assert item["title"] == "1 e-mail de reçu non envoyé"
    assert "g***@example.com" in item["detail"] and "grace@" not in item["detail"]
    assert (item["entity_type"], item["entity_id"]) == ("user", user.id)


# --- Liste Utilisateurs : requêtes groupées -------------------------------------------------


def count_queries(db_session):
    statements = []

    def before(conn, cursor, statement, *args):
        statements.append(statement)

    engine = db_session.get_bind()
    event.listen(engine, "before_cursor_execute", before)
    return statements, lambda: event.remove(engine, "before_cursor_execute", before)


def test_user_list_does_not_query_per_row(client, auth_headers, db_session):
    admin = make_user(db_session, role=UserRole.ADMIN)
    headers = auth_headers(admin)

    def queries_for_page():
        statements, stop = count_queries(db_session)
        response = client.get("/api/v1/admin/users", params={"size": 50}, headers=headers)
        stop()
        assert response.status_code == 200
        return len(statements), len(response.json()["items"])

    for _ in range(3):
        owner = make_user(db_session)
        make_bill(db_session, make_meter(db_session, make_household(db_session, owner)))
    few_queries, few_rows = queries_for_page()
    for _ in range(12):
        owner = make_user(db_session)
        make_bill(db_session, make_meter(db_session, make_household(db_session, owner)))
    many_queries, many_rows = queries_for_page()
    assert many_rows >= few_rows + 12
    assert many_queries == few_queries  # même nombre de requêtes, quelle que soit la page


# --- Suivi d'un paiement : fréquence limitée vers le prestataire ----------------------------


def test_status_check_throttle_follows_the_service_clock():
    throttle = StatusCheckThrottle()
    assert throttle.allow(1, NOW) is True
    assert throttle.allow(1, NOW + timedelta(seconds=4)) is False
    assert throttle.allow(2, NOW + timedelta(seconds=4)) is True  # chaque transaction à part
    assert throttle.allow(1, NOW + timedelta(seconds=5)) is True


class CountingProvider(SimulatedPaymentProvider):
    def __init__(self) -> None:
        super().__init__("secret")
        self.checks = 0

    def check_status(self, provider_ref, request):
        self.checks += 1
        return super().check_status(provider_ref, request)


def test_tracking_asks_the_operator_at_most_every_5_seconds(app, client, auth_headers, db_session):
    provider = CountingProvider()
    app.dependency_overrides[get_payment_provider] = lambda: provider
    payer = make_user(db_session)
    bill = make_bill(
        db_session,
        make_meter(db_session, make_household(db_session, payer)),
        due_date=date(2099, 1, 1),
    )
    started = utcnow() - timedelta(seconds=2)
    transaction = make_transaction(
        db_session,
        bill,
        payer,
        phone_number="+242060000005",  # PIN saisi, jamais confirmé : reste en attente
        idempotency_key=uuid.uuid4().hex,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
        provider_ref="SIM-FREQUENCE",
    )
    bill.status = BillStatus.PENDING_PAYMENT
    db_session.flush()
    headers = auth_headers(payer)
    for _ in range(4):  # l'écran 9 interroge toutes les 2 à 3 s ; ici, en rafale
        assert client.get(f"/api/v1/payments/{transaction.id}", headers=headers).status_code == 200
    assert provider.checks == 1
