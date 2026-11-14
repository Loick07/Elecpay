"""Critères de l'étape B10 (backend/PLAN.md), testés de bout en bout à travers l'API.

« Chaque action d'écriture admin → une ligne `audit_logs` (test). »
- chaque route d'écriture du back-office est appelée ici, et sa ligne de journal vérifiée
  (auteur = le membre de l'équipe, action attendue) ;
- la liste des routes d'écriture est comparée au contrat OpenAPI : une nouvelle route
  d'écriture sans ce test fait échouer la suite ;
- « jamais de passage manuel à `reussie` » : aucune route ne le permet ;
- rôles : chaque route `/admin` déclare son niveau (`x-permission`), contrôlé pour chaque rôle
  dans test_admin_permissions.py.
Chaque écran est aussi testé en détail dans test_admin_*.py.
"""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import select

from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentRequest
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.audit.models import AuditLog
from app.modules.bills.models import BillStatus
from app.modules.bills.service import generate_bill
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.payments.models import MobileOperator, TransactionStatus
from app.modules.users.models import UserRole
from tests.factories import (
    Billing,
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_reading,
    make_tariff,
    make_transaction,
    make_user,
)

ADMIN = "/api/v1/admin"
JULY = date(2026, 7, 1)
REASON = "Motif de vérification B10"

# Toutes les routes du back-office qui écrivent quelque chose (exports compris : une sortie
# de données personnelles est inscrite au journal), avec l'action attendue au journal.
WRITE_ROUTES = {
    "GET /api/v1/admin/users/export.csv": "admin.export",
    "POST /api/v1/admin/users/{user_id}/deactivate": "user.deactivate",
    "POST /api/v1/admin/users/{user_id}/reactivate": "user.reactivate",
    "POST /api/v1/admin/users/{user_id}/reset-code": "user.send_reset_code",
    "POST /api/v1/admin/meters/{meter_id}/anomalies/{reading_id}/control": "meter.anomaly_control",
    "POST /api/v1/admin/meters/{meter_id}/anomalies/{reading_id}/dismiss": "meter.anomaly_dismiss",
    "POST /api/v1/admin/meters/{meter_id}/detach": "meter.detach",
    "POST /api/v1/admin/meters/{meter_id}/attach": "meter.attach",
    "GET /api/v1/admin/bills/export.csv": "admin.export",
    "POST /api/v1/admin/bills/{bill_id}/cancel": "bill.cancel",
    "POST /api/v1/admin/bills/{bill_id}/reissue": "bill.reissue",
    "POST /api/v1/admin/transactions/{transaction_id}/recheck": "payment.recheck",
    "POST /api/v1/admin/transactions/{transaction_id}/disputes": "dispute.open",
    "POST /api/v1/admin/transactions/{transaction_id}/disputes/{dispute_id}/close": (
        "dispute.resolve"
    ),
    "POST /api/v1/admin/announcements": "announcement.create",
    "POST /api/v1/admin/announcements/{announcement_id}/cancel": "announcement.cancel",
    "PUT /api/v1/admin/alert-settings": "alerts.settings",
    "POST /api/v1/admin/team/invite": "team.invite",
    "PUT /api/v1/admin/team/{member_id}/role": "team.role",
    "POST /api/v1/admin/tariffs": "tariff.create",
}


def test_every_admin_write_route_is_covered_here(client):
    paths = client.get("/openapi.json").json()["paths"]
    writes = {
        f"{method.upper()} {path}"
        for path, operations in paths.items()
        if path.startswith(ADMIN)
        for method in operations
        if method != "get" or path.endswith(".csv")
    }
    assert writes == set(WRITE_ROUTES)


def test_no_route_ever_marks_a_payment_as_succeeded(client):
    paths = client.get("/openapi.json").json()["paths"]
    admin_paths = " ".join(path for path in paths if path.startswith(ADMIN)).lower()
    for word in ("succeed", "mark", "force", "confirm"):
        assert word not in admin_paths


@pytest.fixture
def world(db_session, app):
    sms = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sms
    boss = make_user(db_session, role=UserRole.SUPER_ADMIN, full_name="Serge Bouanga")
    admin = make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala")
    support = make_user(db_session, role=UserRole.SUPPORT, full_name="Patrick Moukala")
    arnaud = make_user(db_session, full_name="Arnaud Mavoungou", phone="+242061110001")
    grace = make_user(db_session, full_name="Grâce Ngoma", phone="+242051110002")
    home = make_household(db_session, arnaud, name="Maison Mpita", district="Mpita")
    make_member(db_session, home, grace, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_tariff(db_session, valid_from=date(2025, 1, 1))  # BT_DOMESTIQUE

    # Compteur aux relevés de la vraie facture E²C + une anomalie de relevé aujourd'hui.
    meter = make_meter(db_session, home, reference="0412-8833", subscribed_power_va=3_000)
    for day, index, used in ((JULY, 14_283_000, 0), (date(2026, 9, 1), 14_854_000, 571_000)):
        make_reading(
            db_session, meter, read_at=local_midnight_utc(day), index_wh=index, consumption_wh=used
        )
    anomaly = make_reading(
        db_session,
        meter,
        read_at=local_midnight_utc(local_date(utcnow())),
        index_wh=1_000,
        consumption_wh=0,
        is_anomaly=True,
        anomaly_reason="Index relevé inférieur au relevé précédent",
    )
    bill = generate_bill(db_session, meter, JULY, today=date(2026, 9, 3), settings=Billing()).bill

    # Un paiement en attente (sur sa propre facture) que l'opérateur a confirmé entre-temps.
    provider = SimulatedPaymentProvider("secret")
    other_bill = make_bill(db_session, make_meter(db_session, home), due_date=date(2099, 1, 1))
    started = utcnow() - timedelta(minutes=1)
    key = uuid.uuid4().hex
    request = PaymentRequest(key, "mtn", "+242061110001", other_bill.amount_total, started, "t")
    transaction = make_transaction(
        db_session,
        other_bill,
        arnaud,
        operator=MobileOperator.MTN,
        phone_number="+242061110001",
        idempotency_key=key,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
        provider_ref=provider.initiate(request),
    )
    other_bill.status = BillStatus.PENDING_PAYMENT
    db_session.flush()
    return {
        "boss": boss,
        "admin": admin,
        "support": support,
        "arnaud": arnaud,
        "grace": grace,
        "home": home,
        "meter": meter,
        "anomaly": anomaly,
        "bill": bill,
        "transaction": transaction,
        "sms": sms,
    }


def test_every_admin_write_leaves_its_line_in_the_journal(client, auth_headers, db_session, world):
    admin, boss = auth_headers(world["admin"]), auth_headers(world["boss"])
    done: list[tuple[str, int]] = []  # (action attendue, id de l'auteur)

    def call(method, path, user_headers, author, action, body=None, status=200):
        response = client.request(method, f"{ADMIN}{path}", json=body, headers=user_headers)
        assert response.status_code == status, f"{method} {path} : {response.text}"
        done.append((action, author.id))
        return response

    grace, meter, bill = world["grace"], world["meter"], world["bill"]
    reading, transaction = world["anomaly"], world["transaction"]

    # Utilisateurs (A2, A3)
    call("GET", "/users/export.csv", admin, world["admin"], "admin.export")
    call(
        "POST",
        f"/users/{grace.id}/deactivate",
        admin,
        world["admin"],
        "user.deactivate",
        {"reason": "Demande du titulaire"},
    )
    call("POST", f"/users/{grace.id}/reactivate", admin, world["admin"], "user.reactivate", {})
    call("POST", f"/users/{grace.id}/reset-code", admin, world["admin"], "user.send_reset_code")
    # Compteurs (A4)
    anomaly = f"/meters/{meter.id}/anomalies/{reading.id}"
    call("POST", f"{anomaly}/control", admin, world["admin"], "meter.anomaly_control", {})
    call(
        "POST",
        f"{anomaly}/dismiss",
        admin,
        world["admin"],
        "meter.anomaly_dismiss",
        {"note": "Erreur de lecture ponctuelle"},
    )
    call(
        "POST",
        f"/meters/{meter.id}/detach",
        admin,
        world["admin"],
        "meter.detach",
        {"reason": "Vérification B10"},
    )
    call(
        "POST",
        f"/meters/{meter.id}/attach",
        admin,
        world["admin"],
        "meter.attach",
        {"household_id": world["home"].id, "reason": "Remise en état"},
    )
    # Factures (A5, A6)
    call("GET", "/bills/export.csv", admin, world["admin"], "admin.export")
    call(
        "POST",
        f"/bills/{bill.id}/cancel",
        admin,
        world["admin"],
        "bill.cancel",
        {"reason": "Index de fin de période erroné"},
    )
    call(
        "POST",
        f"/bills/{bill.id}/reissue",
        admin,
        world["admin"],
        "bill.reissue",
        {"reason": "Réémission après contrôle"},
    )
    # Transactions et litiges (A7, A8)
    recheck = call(
        "POST", f"/transactions/{transaction.id}/recheck", admin, world["admin"], "payment.recheck"
    )
    assert recheck.json()["status_after"] == TransactionStatus.SUCCEEDED.value  # par l'opérateur
    dispute = call(
        "POST",
        f"/transactions/{transaction.id}/disputes",
        admin,
        world["admin"],
        "dispute.open",
        {"reason": "Le client dit avoir payé deux fois"},
        status=201,
    )
    call(
        "POST",
        f"/transactions/{transaction.id}/disputes/{dispute.json()['id']}/close",
        admin,
        world["admin"],
        "dispute.resolve",
        {"resolution": "no_debit", "note": "Un seul débit chez MTN"},
    )
    # Annonces et alertes (A9)
    call(
        "POST",
        "/announcements",
        admin,
        world["admin"],
        "announcement.create",
        {
            "title": "Coupure",
            "body": "Coupure jeudi de 8 h à 12 h à Mpita.",
            "audience": "district",
            "district": "Mpita",
        },
        status=201,
    )
    later = (utcnow() + timedelta(days=1)).isoformat()
    scheduled = call(
        "POST",
        "/announcements",
        admin,
        world["admin"],
        "announcement.create",
        {
            "title": "Rappel",
            "body": "Pensez à payer avant l'échéance.",
            "audience": "all",
            "scheduled_at": later,
        },
        status=201,
    )
    call(
        "POST",
        f"/announcements/{scheduled.json()['id']}/cancel",
        admin,
        world["admin"],
        "announcement.cancel",
    )
    call(
        "PUT",
        "/alert-settings",
        admin,
        world["admin"],
        "alerts.settings",
        {"due_soon": True, "overdue": True, "high_consumption": False},
    )
    # Paramètres (A11) : super admin
    invited = call(
        "POST",
        "/team/invite",
        boss,
        world["boss"],
        "team.invite",
        {"full_name": "Junior Ibara", "phone": "06 555 12 34", "role": "support"},
        status=201,
    )
    call(
        "PUT",
        f"/team/{invited.json()['member']['id']}/role",
        boss,
        world["boss"],
        "team.role",
        {"role": "admin", "reason": "Nouvelle mission confiée"},
    )
    call(
        "POST",
        "/tariffs",
        boss,
        world["boss"],
        "tariff.create",
        {
            "code": "BT_DOMESTIQUE",
            "label": "Basse tension domestique",
            "price_per_kwh_milli": 52_000,
            "fixed_fee_per_month": 2_550,
            "vat_rate_bp": 1_800,
            "additional_tax_rate_bp": 500,
            "audiovisual_fee": 1_000,
            "stamp_fee": 0,
            "valid_from": (local_date(utcnow()) + timedelta(days=30)).isoformat(),
            "is_assumption": False,
            "source_note": "Arrêté tarifaire (test)",
        },
        status=201,
    )

    journal = db_session.scalars(
        select(AuditLog).where(AuditLog.actor_id.in_([world["admin"].id, world["boss"].id]))
    ).all()
    for action, author in done:
        assert any(line.action == action and line.actor_id == author for line in journal), (
            f"pas de ligne « {action} » au journal"
        )
    assert len(journal) == len(done)  # une ligne par action, ni plus ni moins
    assert {action for action, _ in done} == set(WRITE_ROUTES.values())
    assert all(line.ip is not None for line in journal)  # métadonnées (A10)

    # Et l'écran A10 les montre, les plus récentes d'abord.
    shown = client.get(
        f"{ADMIN}/audit-logs", params={"actor": "team", "size": 50}, headers=admin
    ).json()
    assert shown["total"] == len(done)
    assert shown["items"][0]["action"] == "tariff.create"


def test_support_reads_everything_but_writes_nothing(client, auth_headers, world):
    support = auth_headers(world["support"])
    for path in (
        "/stats",
        "/users",
        "/meters",
        "/bills",
        "/transactions",
        "/announcements",
        "/tariffs",
    ):
        assert client.get(f"{ADMIN}{path}", headers=support).status_code == 200, path
    for path in ("/audit-logs", "/team", "/integrations"):
        assert client.get(f"{ADMIN}{path}", headers=support).status_code == 403, path
    bill = world["bill"]
    refused = client.post(
        f"{ADMIN}/bills/{bill.id}/cancel", json={"reason": REASON}, headers=support
    )
    assert refused.status_code == 403
