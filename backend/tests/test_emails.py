"""E-mails (B11.4) : vérification de l'adresse, récapitulatif de paiement mis en file au succès,
envoi avec le reçu PDF joint, nouvelles tentatives en cas de panne."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.db.base import utcnow
from app.integrations.email.factory import get_email_sender
from app.integrations.email.simulated import SimulatedEmailSender
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.audit.models import AuditLog
from app.modules.emails.models import EmailStatus, EmailVerificationCode, OutboxEmail
from app.modules.emails.receipts import MAX_ATTEMPTS, send_pending_emails
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.models import NotificationPreference
from app.modules.payments.confirmation import apply_provider_update
from tests.db_helpers import expect_db_rejection
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_transaction,
    make_user,
)

VERIFY = "/api/v1/me/email/verification"
NOW = datetime(2026, 11, 14, 9, 30, tzinfo=UTC)


@pytest.fixture
def sender(app) -> SimulatedEmailSender:
    outbox = SimulatedEmailSender()
    app.dependency_overrides[get_email_sender] = lambda: outbox
    return outbox


def verified(session, **overrides):
    return make_user(session, email_verified_at=utcnow(), **overrides)


# --- Vérification de l'adresse --------------------------------------------------------------


def test_verify_my_email(client, auth_headers, db_session, sender):
    user = make_user(db_session, email="grace.ngoma@example.com")
    headers = auth_headers(user)
    sent = client.post(VERIFY, headers=headers)
    assert sent.status_code == 200, sent.text
    body = sent.json()
    assert body["sent_to"] == "g***@example.com"
    (message,) = sender.outbox
    assert message.to == "grace.ngoma@example.com"
    assert body["demo_code"] in message.text  # mode démo : le code est aussi renvoyé

    wrong = client.post(f"{VERIFY}/confirm", json={"code": "000000"}, headers=headers)
    assert wrong.status_code == 400
    ok = client.post(f"{VERIFY}/confirm", json={"code": body["demo_code"]}, headers=headers)
    assert ok.status_code == 200, ok.text
    assert ok.json()["email_verified_at"] is not None
    assert client.post(VERIFY, headers=headers).status_code == 409  # déjà vérifiée
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "user.email_verified")).one()
    assert log.after_json == {"email": "g***@example.com"}  # jamais l'adresse en entier


def test_changing_the_email_requires_a_new_verification(client, auth_headers, db_session, sender):
    user = verified(db_session, email="ancienne@example.com")
    headers = auth_headers(user)
    assert client.get("/api/v1/me", headers=headers).json()["email_verified_at"] is not None
    changed = client.patch("/api/v1/me", json={"email": "nouvelle@example.com"}, headers=headers)
    assert changed.json()["email_verified_at"] is None
    assert client.post(VERIFY, headers=headers).json()["sent_to"] == "n***@example.com"


def test_a_code_only_verifies_the_address_it_was_sent_to(client, auth_headers, db_session, sender):
    user = make_user(db_session, email="premiere@example.com")
    headers = auth_headers(user)
    code = client.post(VERIFY, headers=headers).json()["demo_code"]
    client.patch("/api/v1/me", json={"email": "autre@example.com"}, headers=headers)
    refused = client.post(f"{VERIFY}/confirm", json={"code": code}, headers=headers)
    assert refused.status_code == 400


def test_five_wrong_codes_kill_the_code(client, auth_headers, db_session, sender):
    user = make_user(db_session, email="essais@example.com")
    headers = auth_headers(user)
    code = client.post(VERIFY, headers=headers).json()["demo_code"]
    for _ in range(5):
        client.post(f"{VERIFY}/confirm", json={"code": "000000"}, headers=headers)
    late = client.post(f"{VERIFY}/confirm", json={"code": code}, headers=headers)
    assert late.status_code == 400  # le bon code ne marche plus


def test_verification_errors(client, auth_headers, db_session, sender):
    no_email = auth_headers(make_user(db_session))
    assert client.post(VERIFY, headers=no_email).json()["error"]["code"] == "EMAIL_MISSING"
    broken = make_user(db_session, email="quelquun@echec.example")
    down = client.post(VERIFY, headers=auth_headers(broken))
    assert down.status_code == 503
    assert (
        db_session.scalars(
            select(EmailVerificationCode).where(EmailVerificationCode.user_id == broken.id)
        ).all()
        == []
    )  # rien d'enregistré si l'envoi échoue
    limited = auth_headers(make_user(db_session, email="rafale@example.com"))
    codes = [client.post(VERIFY, headers=limited).status_code for _ in range(4)]
    assert codes == [200, 200, 200, 429]


def test_the_database_refuses_a_verified_date_without_email(db_session):
    with expect_db_rejection(db_session, "ck_users_verified_email_exists"):
        make_user(db_session, email=None, email_verified_at=utcnow())


def test_email_receipts_switch(client, auth_headers, db_session):
    headers = auth_headers(make_user(db_session))
    prefs = client.get("/api/v1/me/notification-preferences", headers=headers).json()
    assert prefs["email_receipts"] is True  # activé par défaut
    changed = client.patch(
        "/api/v1/me/notification-preferences", json={"email_receipts": False}, headers=headers
    )
    assert changed.json()["email_receipts"] is False


# --- Récapitulatif de paiement --------------------------------------------------------------


@pytest.fixture
def family(db_session):
    owner = verified(db_session, full_name="Maman Ngoma", email="maman@example.com")
    payer = verified(db_session, full_name="Grâce Ngoma", email="grace@example.com")
    home = make_household(db_session, owner, name="Maison de maman")
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home, reference="0412-8833")
    bill = make_bill(db_session, meter, due_date=date(2099, 1, 1))
    return {"owner": owner, "payer": payer, "bill": bill}


def pay(session, bill, payer):
    transaction = make_transaction(session, bill, payer, phone_number="+242061110001")
    update = ProviderUpdate("SIM-B11-4", ProviderState.SUCCEEDED, NOW, amount=bill.amount_total)
    apply_provider_update(session, transaction.id, update, origin="test", now=NOW)
    return transaction


def queued(session):
    return session.scalars(select(OutboxEmail).order_by(OutboxEmail.id)).all()


def test_success_queues_the_payer_and_the_owner(db_session, family):
    pay(db_session, family["bill"], family["payer"])
    rows = queued(db_session)
    assert {row.to_email for row in rows} == {"maman@example.com", "grace@example.com"}
    assert {row.status for row in rows} == {
        EmailStatus.PENDING
    }  # rien n'est parti pendant le paiement


@pytest.mark.parametrize("reason", ["unverified", "no_email", "switched_off", "inactive"])
def test_nobody_unwanted_is_emailed(db_session, family, reason):
    payer = family["payer"]
    match reason:
        case "unverified":
            payer.email_verified_at = None
        case "no_email":
            payer.email_verified_at, payer.email = None, None
        case "switched_off":
            db_session.add(NotificationPreference(user_id=payer.id, email_receipts=False))
        case "inactive":
            payer.is_active = False
    db_session.flush()
    pay(db_session, family["bill"], payer)
    assert [row.to_email for row in queued(db_session)] == ["maman@example.com"]


def test_owner_paying_gets_a_single_email(db_session, family):
    pay(db_session, family["bill"], family["owner"])
    assert [row.to_email for row in queued(db_session)] == ["maman@example.com"]


def test_sending_with_the_receipt_attached(db_session, family, test_settings):
    pay(db_session, family["bill"], family["payer"])
    sender = SimulatedEmailSender()
    counts = send_pending_emails(db_session, sender, test_settings, now=NOW)
    assert counts["sent"] == 2
    messages = {message.to: message for message in sender.outbox}
    to_payer, to_owner = messages["grace@example.com"], messages["maman@example.com"]
    assert to_payer.subject == "[DÉMO] Paiement reçu : 40 384 FCFA, facture Juil.-Août 2026"
    assert "Votre paiement a bien été reçu" in to_payer.text
    assert "Grâce Ngoma a payé la facture de votre foyer « Maison de maman »" in to_owner.text
    for message in (to_payer, to_owner):
        assert "MODE DÉMO" in message.text
        assert "+242 06 *** ** 01" in message.text and "+242061110001" not in message.text
        (attachment,) = message.attachments
        assert attachment.content_type == "application/pdf"
        assert attachment.filename.startswith("recu-EP-")
        assert attachment.content.startswith(b"%PDF")
    assert {row.status for row in queued(db_session)} == {EmailStatus.SENT}
    assert send_pending_emails(db_session, SimulatedEmailSender(), test_settings, now=NOW) == {}


def test_a_failing_service_is_retried_then_given_up(db_session, family, test_settings):
    family["payer"].email = "grace@echec.example"  # le simulateur refuse cette adresse
    db_session.flush()
    pay(db_session, family["bill"], family["payer"])
    sender = SimulatedEmailSender()
    now = NOW
    send_pending_emails(db_session, sender, test_settings, now=now)
    failing = next(row for row in queued(db_session) if row.to_email.endswith("@echec.example"))
    assert (failing.status, failing.attempts) == (EmailStatus.PENDING, 1)
    assert failing.next_attempt_at == now + timedelta(minutes=1)
    assert "grace@echec.example" not in failing.last_error  # adresse masquée
    # Pas avant l'heure prévue…
    assert send_pending_emails(db_session, sender, test_settings, now=now)["retry"] == 0
    for _ in range(MAX_ATTEMPTS):
        now = failing.next_attempt_at
        send_pending_emails(db_session, sender, test_settings, now=now)
        db_session.refresh(failing)
        if failing.status is EmailStatus.FAILED:
            break
    assert (failing.status, failing.attempts) == (EmailStatus.FAILED, MAX_ATTEMPTS)
    assert [message.to for message in sender.outbox] == ["maman@example.com"]


def test_the_same_receipt_is_never_queued_twice(db_session, family):
    pay(db_session, family["bill"], family["payer"])
    first = queued(db_session)[0]
    with expect_db_rejection(db_session, "uq_email_outbox_kind_receipt_id_user_id"):
        db_session.add(
            OutboxEmail(
                user_id=first.user_id,
                to_email=first.to_email,
                kind=first.kind,
                receipt_id=first.receipt_id,
                status=EmailStatus.PENDING,
                next_attempt_at=NOW,
            )
        )
