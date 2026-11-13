"""Critères de l'étape B7 (backend/PLAN.md), testés de bout en bout à travers l'API.

« Terminé quand : tests de double clic, double webhook, webhook mal signé, paiement d'une
facture déjà payée, échec puis nouvelle tentative. »
+ le parcours des écrans 8 → 9 → 12 (payer, suivre, historique), payeur délégué compris,
+ aucune voie, même en SQL, pour forcer un paiement réussi.
Chaque point est aussi testé en détail dans test_payment*.py et test_models_payments.py.
"""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import func, select, text

from app.db.base import utcnow
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.integrations.payment_providers.factory import get_payment_provider
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import Notification, NotificationType
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.tracking import expire_if_due
from tests.db_helpers import expect_db_rejection
from tests.factories import make_bill, make_household, make_member, make_meter, make_user

WEBHOOK_URL = "/api/v1/webhooks/payments/simulated"


class Clock:
    """Horloge du prestataire simulé, que le test avance à la main."""

    def __init__(self) -> None:
        self.now = utcnow()

    def __call__(self):
        return self.now

    def advance(self, seconds: float) -> None:
        self.now += timedelta(seconds=seconds)


@pytest.fixture
def clock():
    return Clock()


@pytest.fixture
def provider(app, test_settings, clock):
    """Le prestataire simulé de l'API, avec une horloge réglable."""
    simulated = SimulatedPaymentProvider(
        test_settings.payment_webhook_secret.get_secret_value(), now=clock
    )
    app.dependency_overrides[get_payment_provider] = lambda: simulated
    return simulated


@pytest.fixture
def family(db_session):
    owner = make_user(db_session, phone="+242061110001", full_name="Arnaud Mavoungou")
    delegate = make_user(db_session, phone="+242051110002", full_name="Grâce Ngoma")
    home = make_household(db_session, owner, name="Maison Mpita")
    make_member(db_session, home, delegate, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    bill = make_bill(db_session, make_meter(db_session, home), due_date=date(2099, 1, 1))
    return {"owner": owner, "delegate": delegate, "bill": bill}


def pay(client, headers, bill, phone, operator="mtn", key=None):
    return client.post(
        "/api/v1/payments",
        json={"bill_id": bill.id, "operator": operator, "phone_number": phone},
        headers=headers | {"Idempotency-Key": key or uuid.uuid4().hex},
    )


def track(client, headers, payment_id):
    return client.get(f"/api/v1/payments/{payment_id}", headers=headers).json()


def count_transactions(session, bill):
    return session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .where(PaymentTransaction.bill_id == bill.id)
    )


# --- Parcours complet : écrans 8 → 9 → 12 ----------------------------------------------------


def test_a_delegate_pays_for_a_relative_and_everyone_sees_it(
    client, auth_headers, db_session, family, provider, clock
):
    """Grâce paie la facture de la maison d'Arnaud depuis son téléphone Airtel."""
    grace = auth_headers(family["delegate"])
    started = pay(client, grace, family["bill"], "05 111 00 02", operator="airtel")
    assert started.status_code == 201
    payment = started.json()
    assert (payment["amount"], payment["step"]) == (40_384, "requested")

    assert track(client, grace, payment["id"])["step"] == "requested"
    clock.advance(6)
    assert track(client, grace, payment["id"])["step"] == "pin_entered"
    clock.advance(5)
    done = track(client, grace, payment["id"])
    assert (done["status"], done["step"]) == ("reussie", "succeeded")

    arnaud = auth_headers(family["owner"])
    bill = client.get(f"/api/v1/bills/{family['bill'].id}", headers=arnaud).json()
    assert (bill["status"], bill["can_pay"]) == ("paid", False)
    (line,) = client.get("/api/v1/payments", headers=arnaud).json()["items"]
    assert (line["id"], line["payer_name"], line["phone_number"]) == (
        payment["id"],
        "Grâce Ngoma",
        "+242 05 *** ** 02",
    )
    owner_notices = db_session.scalars(
        select(Notification.title).where(
            Notification.user_id == family["owner"].id,
            Notification.type == NotificationType.PAYMENT_SUCCEEDED,
        )
    ).all()
    assert owner_notices == ["Facture payée"]


# --- Les critères « Terminé quand » ------------------------------------------------------------


def test_double_click(client, auth_headers, db_session, family, provider):
    headers, key = auth_headers(family["owner"]), uuid.uuid4().hex
    first = pay(client, headers, family["bill"], "06 111 00 01", key=key)
    second = pay(client, headers, family["bill"], "06 111 00 01", key=key)
    assert (first.status_code, second.status_code) == (201, 200)
    assert first.json()["id"] == second.json()["id"]
    assert count_transactions(db_session, family["bill"]) == 1


def test_double_webhook(client, auth_headers, db_session, family, provider):
    payment = pay(client, auth_headers(family["owner"]), family["bill"], "06 111 00 01").json()
    transaction = db_session.get(PaymentTransaction, payment["id"])
    headers, body = provider.signed_webhook(
        ProviderUpdate(transaction.provider_ref, ProviderState.SUCCEEDED, utcnow(), amount=40_384)
    )
    outcomes = [
        client.post(WEBHOOK_URL, content=body, headers=headers).json()["outcome"] for _ in range(2)
    ]
    assert outcomes == ["succeeded", "unchanged"]
    successes = db_session.scalar(
        select(func.count())
        .select_from(Notification)
        .where(
            Notification.user_id == family["owner"].id,
            Notification.type == NotificationType.PAYMENT_SUCCEEDED,
        )
    )
    assert successes == 1


def test_badly_signed_webhook(client, auth_headers, db_session, family, provider):
    payment = pay(client, auth_headers(family["owner"]), family["bill"], "06 111 00 01").json()
    transaction = db_session.get(PaymentTransaction, payment["id"])
    forger = SimulatedPaymentProvider("pas-le-bon-secret-" + "f" * 30)
    headers, body = forger.signed_webhook(
        ProviderUpdate(transaction.provider_ref, ProviderState.SUCCEEDED, utcnow(), amount=40_384)
    )
    response = client.post(WEBHOOK_URL, content=body, headers=headers)
    assert response.status_code == 401
    db_session.refresh(transaction)
    assert transaction.status is TransactionStatus.PENDING


def test_paying_an_already_paid_bill(client, auth_headers, db_session, family, provider, clock):
    headers = auth_headers(family["owner"])
    payment = pay(client, headers, family["bill"], "06 111 00 01").json()
    clock.advance(11)
    track(client, headers, payment["id"])
    for who in ("owner", "delegate"):
        again = pay(client, auth_headers(family[who]), family["bill"], "06 111 00 01")
        assert (again.status_code, again.json()["error"]["code"]) == (409, "BILL_ALREADY_PAID")
    assert count_transactions(db_session, family["bill"]) == 1


def test_failure_then_new_attempt(client, auth_headers, db_session, family, provider, clock):
    headers = auth_headers(family["owner"])
    failed = pay(client, headers, family["bill"], "06 000 00 02").json()  # « solde insuffisant »
    clock.advance(11)
    result = track(client, headers, failed["id"])
    assert (result["status"], result["failure_reason"]) == ("echouee", "Solde insuffisant")
    assert client.get(f"/api/v1/bills/{family['bill'].id}", headers=headers).json()["can_pay"]

    retry = pay(client, headers, family["bill"], "06 111 00 01").json()  # nouvelle clé
    clock.advance(11)
    assert track(client, headers, retry["id"])["status"] == "reussie"
    statuses = db_session.scalars(
        select(PaymentTransaction.status)
        .where(PaymentTransaction.bill_id == family["bill"].id)
        .order_by(PaymentTransaction.id)
    ).all()
    assert statuses == [TransactionStatus.FAILED, TransactionStatus.SUCCEEDED]
    db_session.refresh(family["bill"])
    assert family["bill"].status is BillStatus.PAID


def test_expiry_then_new_attempt(client, auth_headers, db_session, family, provider):
    headers = auth_headers(family["owner"])
    stuck = pay(client, headers, family["bill"], "06 000 00 04").json()  # PIN jamais saisi
    transaction = db_session.get(PaymentTransaction, stuck["id"])
    # 10 minutes plus tard (les dates d'une transaction sont figées : on avance le temps).
    assert expire_if_due(db_session, transaction.id, now=transaction.expires_at)
    result = track(client, headers, stuck["id"])
    assert (result["status"], result["step"]) == ("expiree", "expired")
    assert pay(client, headers, family["bill"], "06 111 00 01").status_code == 201


# --- Aucune voie pour forcer un succès -------------------------------------------------------


def test_nobody_can_force_a_successful_payment(client, auth_headers, db_session, family, provider):
    payment = pay(client, auth_headers(family["owner"]), family["bill"], "06 000 00 02").json()
    transaction = db_session.get(PaymentTransaction, payment["id"])
    transaction.status, transaction.failure_reason = TransactionStatus.FAILED, "Solde insuffisant"
    db_session.flush()
    # Même un administrateur en SQL ne peut pas transformer l'échec en succès.
    with expect_db_rejection(db_session, "payment_closed_immutable"):
        db_session.execute(
            text(
                "UPDATE payment_transactions SET status = 'reussie', failure_reason = NULL,"
                " provider_ref = 'FORCE', confirmed_at = NOW(6) WHERE id = :id"
            ),
            {"id": transaction.id},
        )
    # Et l'API n'offre aucune route pour le faire (contrat OpenAPI publié).
    paths = client.app.openapi()["paths"]
    writable = {
        (path, method.upper())
        for path, operations in paths.items()
        for method in operations
        if "/payments" in path and method in {"post", "put", "patch", "delete"}
    }
    assert writable == {
        ("/api/v1/payments", "POST"),  # lancer un paiement (toujours « en attente »)
        ("/api/v1/webhooks/payments/{provider}", "POST"),  # signé par le prestataire
    }
    assert set(paths["/api/v1/payments/{payment_id}"]) == {"get"}
