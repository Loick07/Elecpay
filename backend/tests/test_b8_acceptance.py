"""Critères de l'étape B8 (backend/PLAN.md), testés de bout en bout à travers l'API.

- « Créé automatiquement à la confirmation du paiement » : un reçu par paiement réussi, jamais
  pour un échec, jamais deux (double webhook) ;
- « numéro séquentiel EP-2026-000123 » ;
- « mention mode démo tant que c'est simulé » : JSON, PDF et vérification publique ;
+ le parcours écrans 9 → 10 → vérification publique, et le reçu à jamais intouchable.
Chaque point est aussi testé en détail dans test_receipt_service.py et test_receipts_api.py.
"""

import io
import uuid
from datetime import date, timedelta

import pytest
from pypdf import PdfReader
from sqlalchemy import func, select, text

from app.core.timezone import local_date
from app.db.base import utcnow
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.integrations.payment_providers.factory import get_payment_provider
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.payments.models import PaymentTransaction
from app.modules.receipts.models import Receipt
from tests.db_helpers import expect_db_rejection
from tests.factories import make_bill, make_household, make_member, make_meter, make_user

WEBHOOK_URL = "/api/v1/webhooks/payments/simulated"


class Clock:
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
    meter = make_meter(db_session, home, reference="0412-8833")
    bills = [
        make_bill(db_session, meter, due_date=date(2099, 1, 1)),
        make_bill(
            db_session,
            meter,
            period_start=date(2026, 9, 1),
            period_end=date(2026, 10, 31),
            due_date=date(2099, 1, 1),
        ),
    ]
    return {"owner": owner, "delegate": delegate, "bills": bills}


def pay_and_wait(client, headers, bill, clock, phone="06 111 00 01", operator="mtn"):
    payment = client.post(
        "/api/v1/payments",
        json={"bill_id": bill.id, "operator": operator, "phone_number": phone},
        headers=headers | {"Idempotency-Key": uuid.uuid4().hex},
    ).json()
    clock.advance(11)
    return client.get(f"/api/v1/payments/{payment['id']}", headers=headers).json()


# --- Parcours : payer → reçu → vérification publique ------------------------------------------


def test_from_payment_to_public_verification(client, auth_headers, family, provider, clock):
    grace = auth_headers(family["delegate"])
    payment = pay_and_wait(
        client, grace, family["bills"][0], clock, phone="05 111 00 02", operator="airtel"
    )
    assert payment["status"] == "reussie"
    assert payment["receipt_number"] == f"EP-{local_date(utcnow()).year}-000001"

    # Écran 10 : le reçu, pour Grâce comme pour Arnaud.
    receipt = client.get(f"/api/v1/receipts/{payment['receipt_id']}", headers=grace).json()
    assert (receipt["amount"], receipt["payer_name"], receipt["phone_number"]) == (
        40_384,
        "Grâce Ngoma",
        "+242 05 *** ** 02",
    )
    arnaud = auth_headers(family["owner"])
    listed = client.get("/api/v1/receipts", headers=arnaud).json()
    assert [item["id"] for item in listed["items"]] == [payment["receipt_id"]]

    # « Télécharger » : le PDF porte le même code de vérification.
    pdf = client.get(f"/api/v1/receipts/{payment['receipt_id']}/pdf", headers=arnaud)
    text_ = "\n".join(page.extract_text() for page in PdfReader(io.BytesIO(pdf.content)).pages)
    assert receipt["verification_code"] in text_

    # Vérification publique, sans compte, avec le code tel qu'imprimé.
    public = client.get(f"/api/v1/receipts/verify/{receipt['verification_code']}")
    assert public.status_code == 200
    body = public.json()
    assert (body["valid"], body["number"], body["amount"]) == (True, receipt["number"], 40_384)
    assert body["meter_reference"] == "0412-••33"
    for private in ("Grâce", "Arnaud", "Maison Mpita", "+242"):
        assert private not in public.text


# --- Créé automatiquement, un seul, jamais pour un échec ---------------------------------------


def test_one_receipt_per_successful_payment_never_for_a_failure(
    client, auth_headers, db_session, family, provider, clock
):
    headers = auth_headers(family["owner"])
    failed = pay_and_wait(client, headers, family["bills"][0], clock, phone="06 000 00 02")
    assert (failed["status"], failed["receipt_id"]) == ("echouee", None)
    paid = pay_and_wait(client, headers, family["bills"][0], clock)
    assert paid["receipt_id"] is not None

    # Double webhook de confirmation : toujours un seul reçu.
    transaction = db_session.get(PaymentTransaction, paid["id"])
    headers_, body = provider.signed_webhook(
        ProviderUpdate(transaction.provider_ref, ProviderState.SUCCEEDED, utcnow(), amount=40_384)
    )
    assert client.post(WEBHOOK_URL, content=body, headers=headers_).json()["outcome"] == (
        "unchanged"
    )
    receipts = db_session.scalar(select(func.count()).select_from(Receipt))
    successes = db_session.scalar(
        select(func.count())
        .select_from(PaymentTransaction)
        .where(PaymentTransaction.status == "reussie")
    )
    assert receipts == successes == 1


def test_numbers_follow_each_other(client, auth_headers, family, provider, clock):
    headers = auth_headers(family["owner"])
    numbers = [
        pay_and_wait(client, headers, bill, clock)["receipt_number"] for bill in family["bills"]
    ]
    year = local_date(utcnow()).year
    assert numbers == [f"EP-{year}-000001", f"EP-{year}-000002"]


# --- Mode démo partout ------------------------------------------------------------------------


def test_demo_mode_is_shown_everywhere(client, auth_headers, family, provider, clock):
    headers = auth_headers(family["owner"])
    payment = pay_and_wait(client, headers, family["bills"][0], clock)
    receipt = client.get(f"/api/v1/receipts/{payment['receipt_id']}", headers=headers).json()
    assert receipt["source"] == "simulated"
    pdf = client.get(f"/api/v1/receipts/{payment['receipt_id']}/pdf", headers=headers)
    assert "MODE DÉMO" in PdfReader(io.BytesIO(pdf.content)).pages[0].extract_text()
    public = client.get(f"/api/v1/receipts/verify/{receipt['verification_code']}").json()
    assert public["demo"] is True and "mode démo" in public["message"]


# --- Un reçu ne change jamais ------------------------------------------------------------------


def test_a_receipt_can_never_be_changed_or_deleted(
    client, auth_headers, db_session, family, provider, clock
):
    payment = pay_and_wait(client, auth_headers(family["owner"]), family["bills"][0], clock)
    for statement in (
        "UPDATE receipts SET number = 'EP-2026-999999' WHERE id = :id",
        "UPDATE receipts SET verification_code = 'ZZZZZZZZZZZZ' WHERE id = :id",
        "DELETE FROM receipts WHERE id = :id",
    ):
        with expect_db_rejection(db_session, "receipt_immutable"):
            db_session.execute(text(statement), {"id": payment["receipt_id"]})
