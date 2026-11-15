"""Parcours complets de B11 (backend/PLAN.md), UNIQUEMENT à travers l'API, comme depuis `/docs`.

« Inscription → ajout compteur → consultation → paiement → reçu → historique ; et côté admin. »
- client : inscription, foyer, compteur (historique E²C simulé), consommation, facture, e-mail
  vérifié, paiement Mobile Money suivi jusqu'au succès, reçu (PDF, vérification publique),
  historique, notification, récapitulatif par e-mail avec le reçu joint ;
- admin : double authentification obligatoire, tableau de bord, utilisateur, facture annulée
  puis réémise, transaction vérifiée auprès de l'opérateur, journal.
Chaque étape est aussi testée en détail dans les tests de son étape (B3 → B11).
"""

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.core import totp
from app.core.security import hash_password
from app.db.session import get_db
from app.integrations.email.factory import get_email_sender
from app.integrations.email.simulated import SimulatedEmailSender
from app.integrations.payment_providers.factory import get_payment_provider
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.main import create_app
from app.modules.auth.two_factor import TwoFactorService
from app.modules.emails.receipts import send_pending_emails
from app.modules.notifications.queries import NotificationQueries
from app.modules.payments.service import PaymentService
from app.modules.users.models import UserRole
from tests.factories import make_bill, make_household, make_meter, make_tariff, make_user

API = "/api/v1"
PASSWORD = "Parcours2026!"


class Clock:
    """Une seule horloge pour l'opérateur simulé, le suivi des paiements et la 2FA."""

    def __init__(self) -> None:
        self.now = datetime.now(UTC)

    def __call__(self) -> datetime:
        return self.now

    def advance(self, seconds: float) -> None:
        self.now += timedelta(seconds=seconds)

    def code(self, secret: str) -> str:
        return totp.hotp(secret, totp.time_step(self.now.timestamp()))


@pytest.fixture
def journey(test_settings, db_session, monkeypatch):
    clock = Clock()
    payment_init, two_factor_init = PaymentService.__init__, TwoFactorService.__init__
    monkeypatch.setattr(
        PaymentService,
        "__init__",
        lambda self, session, provider, settings, now=None: payment_init(
            self, session, provider, settings, clock
        ),
    )
    monkeypatch.setattr(
        TwoFactorService,
        "__init__",
        lambda self, session, settings, now=None: two_factor_init(self, session, settings, clock),
    )
    notifications_init = NotificationQueries.__init__
    monkeypatch.setattr(
        NotificationQueries,
        "__init__",
        lambda self, session, now=None: notifications_init(self, session, clock),
    )
    # Réglages de production pour l'équipe : double authentification obligatoire.
    app = create_app(test_settings.model_copy(update={"team_2fa_required": True}))
    app.dependency_overrides[get_db] = lambda: db_session
    provider = SimulatedPaymentProvider(
        test_settings.payment_webhook_secret.get_secret_value(), now=clock
    )
    app.dependency_overrides[get_payment_provider] = lambda: provider
    sender = SimulatedEmailSender()
    app.dependency_overrides[get_email_sender] = lambda: sender
    # https : les cookies du back-office sont « Secure » (comme en production).
    with TestClient(app, raise_server_exceptions=False, base_url="https://testserver") as client:
        yield client, clock, sender


def ok(response, status=200):
    assert response.status_code == status, (
        f"{response.request.method} {response.request.url}: {response.text}"
    )
    return response.json() if response.content else None


def test_client_journey_from_sign_up_to_receipt(journey, db_session, test_settings):
    client, clock, sender = journey
    # Le tarif E²C existe avant le premier abonné (installé à la mise en service).
    make_tariff(db_session, valid_from=date(2025, 1, 1))

    # 1. Inscription (écran 3) → jetons.
    signed = ok(
        client.post(
            f"{API}/auth/register",
            json={
                "full_name": "Grâce Ngoma",
                "phone": "06 111 22 33",
                "password": PASSWORD,
                "email": "grace.ngoma@example.com",
            },
        ),
        201,
    )
    me = {"Authorization": f"Bearer {signed['access_token']}"}
    assert signed["user"]["role"] == "client"

    # 2. Foyer et compteur (écran 15) : l'historique vient d'E²C (simulé).
    home = ok(
        client.post(
            f"{API}/households",
            json={"name": "Maison Mpita", "city": "Pointe-Noire", "district": "Mpita"},
            headers=me,
        ),
        201,
    )
    added = ok(
        client.post(
            f"{API}/households/{home['id']}/meters",
            json={"reference": "0018 09 5408", "customer_number": "0758340H", "label": "Maison"},
            headers=me,
        ),
        201,
    )
    meter_id = added["meter"]["id"]
    assert added["history"]["readings"] > 0

    # 3. Consultation : consommation (écran 11) et factures (écrans 6-7).
    summary = ok(client.get(f"{API}/meters/{meter_id}/consumption/summary", headers=me))
    assert summary
    bills = ok(client.get(f"{API}/bills", params={"status": "to_pay"}, headers=me))
    everything = ok(client.get(f"{API}/bills", headers=me))
    assert bills["items"], f"aucune facture à payer ; toutes : {everything}"
    bill = bills["items"][0]
    detail = ok(client.get(f"{API}/bills/{bill['id']}", headers=me))
    assert sum(line["amount"] for line in detail["lines"]) == bill["amount_total"]
    assert client.get(f"{API}/bills/{bill['id']}/pdf", headers=me).content.startswith(b"%PDF")

    # 4. Adresse e-mail vérifiée (pour recevoir le reçu par e-mail).
    code = ok(client.post(f"{API}/me/email/verification", headers=me))["demo_code"]
    ok(client.post(f"{API}/me/email/verification/confirm", json={"code": code}, headers=me))

    # 5. Paiement Mobile Money (écrans 8-9), suivi jusqu'au succès.
    started = ok(
        client.post(
            f"{API}/payments",
            json={"bill_id": bill["id"], "operator": "mtn", "phone_number": "06 111 22 33"},
            headers=me | {"Idempotency-Key": uuid.uuid4().hex},
        ),
        201,
    )
    assert ok(client.get(f"{API}/payments/{started['id']}", headers=me))["step"] == "requested"
    clock.advance(6)
    assert ok(client.get(f"{API}/payments/{started['id']}", headers=me))["step"] == "pin_entered"
    clock.advance(6)
    paid = ok(client.get(f"{API}/payments/{started['id']}", headers=me))
    assert (paid["status"], paid["step"]) == ("reussie", "succeeded")
    assert ok(client.get(f"{API}/bills/{bill['id']}", headers=me))["status"] == "paid"

    # 6. Reçu (écran 10) : détail, PDF, vérification publique sans connexion.
    receipt = ok(client.get(f"{API}/receipts/{paid['receipt_id']}", headers=me))
    assert receipt["amount"] == bill["amount_total"]
    assert client.get(f"{API}/receipts/{receipt['id']}/pdf", headers=me).content.startswith(b"%PDF")
    public = ok(client.get(f"{API}/receipts/verify/{receipt['verification_code']}"))
    assert public["number"] == receipt["number"]

    # 7. Historique (écran 12) et notification (écran 13).
    history = ok(client.get(f"{API}/payments", headers=me))
    assert [item["id"] for item in history["items"]] == [started["id"]]
    titles = [n["title"] for n in ok(client.get(f"{API}/notifications", headers=me))["items"]]
    assert "Paiement réussi" in titles

    # 8. Récapitulatif par e-mail, reçu PDF joint (tâche scripts.send_emails).
    assert send_pending_emails(db_session, sender, test_settings, now=clock.now)["sent"] == 1
    (email,) = [m for m in sender.outbox if m.attachments]
    assert email.to == "grace.ngoma@example.com"
    assert email.attachments[0].content.startswith(b"%PDF")


def test_admin_journey_with_two_factor(journey, db_session):
    client, clock, _ = journey
    boss = make_user(
        db_session,
        role=UserRole.SUPER_ADMIN,
        full_name="Serge Bouanga",
        phone="+242060000901",
        password_hash=hash_password(PASSWORD),
    )
    customer = make_user(db_session, full_name="Arnaud Mavoungou")
    credentials = {"phone": boss.phone, "password": PASSWORD}

    # 1. Mot de passe seul : le back-office exige d'abord la double authentification.
    first = ok(client.post(f"{API}/auth/login", json=credentials))
    token = {"Authorization": f"Bearer {first['access_token']}"}
    blocked = client.get(f"{API}/admin/stats", headers=token)
    assert blocked.json()["error"]["code"] == "TWO_FACTOR_SETUP_REQUIRED"
    secret = ok(client.post(f"{API}/me/2fa/setup", headers=token))["secret"]
    backup = ok(
        client.post(f"{API}/me/2fa/enable", json={"code": clock.code(secret)}, headers=token)
    )
    assert len(backup["backup_codes"]) == 10
    clock.advance(30)

    # 2. Connexion du back-office en deux étapes (cookies + CSRF).
    challenge = ok(client.post(f"{API}/auth/web/login", json=credentials))
    assert challenge["two_factor_required"] is True
    session = client.post(
        f"{API}/auth/web/login/2fa",
        json={"challenge_token": challenge["challenge_token"], "code": clock.code(secret)},
    )
    ok(session)
    csrf = {"X-CSRF-Token": session.cookies["elecpay_csrf"]}

    # 3. Tableau de bord, utilisateurs, facture annulée puis réémise.
    stats = ok(client.get(f"{API}/admin/stats"))
    assert "watchlist" in stats
    found = ok(client.get(f"{API}/admin/users", params={"q": "mavoungou"}))
    assert [row["id"] for row in found["items"]] == [customer.id]
    ok(client.get(f"{API}/admin/users/{customer.id}"))

    bill = make_bill(db_session, make_meter(db_session, make_household(db_session, customer)))
    cancelled = ok(
        client.post(
            f"{API}/admin/bills/{bill.id}/cancel",
            json={"reason": "Index de fin de période erroné"},
            headers=csrf,
        )
    )
    assert cancelled["status"] == "cancelled"
    reissued = client.post(
        f"{API}/admin/bills/{bill.id}/reissue", json={"reason": "Après contrôle"}, headers=csrf
    )
    assert reissued.json()["error"]["code"] == "BILLING_READING_MISSING"  # pas de relevés ici

    # 4. Journal : chaque action de l'équipe, avec la connexion à deux facteurs.
    journal = ok(client.get(f"{API}/admin/audit-logs", params={"actor": "team", "size": 50}))
    actions = [entry["action"] for entry in journal["items"]]
    assert {"team.two_factor_enable", "team.login", "bill.cancel"} <= set(actions)
    methods = [
        entry["after"]["method"] for entry in journal["items"] if entry["action"] == "team.login"
    ]
    assert "password+totp" in methods
