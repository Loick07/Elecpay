"""Tests du journal d'activité du back-office (B10.8, A10) : lecture seule, admin+."""

from datetime import UTC, datetime

import pytest
from sqlalchemy import delete, update

from app.modules.audit.models import AuditLog
from app.modules.users.models import UserRole
from tests.db_helpers import expect_db_rejection
from tests.factories import make_user

URL = "/api/v1/admin/audit-logs"


def log(session, action, *, actor=None, entity_type="bill", entity_id=1, at, **extra):
    entry = AuditLog(
        actor_id=actor.id if actor else None,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        created_at=at,
        **extra,
    )
    session.add(entry)
    session.flush()
    return entry


@pytest.fixture
def world(db_session):
    admin = make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala")
    client = make_user(db_session, full_name="Arnaud Mavoungou")
    entries = {
        "cancel": log(
            db_session,
            "bill.cancel",
            actor=admin,
            entity_id=42,
            at=datetime(2026, 11, 10, 9, tzinfo=UTC),
            before_json={"status": "unpaid"},
            after_json={"status": "cancelled", "reason": "Index de fin erroné"},
            ip="196.200.1.10",
            user_agent="Mozilla/5.0",
        ),
        "pay": log(
            db_session,
            "payment.initiate",
            actor=client,
            entity_type="payment_transaction",
            entity_id=7,
            at=datetime(2026, 11, 11, 9, tzinfo=UTC),
        ),
        "webhook": log(
            db_session,
            "payment.succeeded",
            entity_type="payment_transaction",
            entity_id=7,
            at=datetime(2026, 11, 12, 9, tzinfo=UTC),
        ),
    }
    return {
        "admin": admin,
        "client": client,
        "support": make_user(db_session, role=UserRole.SUPPORT),
        "boss": make_user(db_session, role=UserRole.SUPER_ADMIN),
        **entries,
    }


def journal(client, auth_headers, user, **params):
    response = client.get(URL, params=params, headers=auth_headers(user))
    assert response.status_code == 200, response.text
    return response.json()


def ids(body):
    return [item["id"] for item in body["items"]]


def test_everything_newest_first_with_details(client, auth_headers, world):
    body = journal(client, auth_headers, world["admin"])
    assert ids(body)[:3] == [world["webhook"].id, world["pay"].id, world["cancel"].id]
    cancel = next(item for item in body["items"] if item["id"] == world["cancel"].id)
    assert cancel["label"] == "a annulé une facture"
    assert (cancel["domain"], cancel["domain_label"]) == ("bill", "Factures")
    assert cancel["actor"] == {
        "id": world["admin"].id,
        "full_name": "Christelle Mabiala",
        "role": "admin",
    }
    assert cancel["before"] == {"status": "unpaid"}
    assert cancel["after"]["reason"] == "Index de fin erroné"
    assert (cancel["ip"], cancel["user_agent"]) == ("196.200.1.10", "Mozilla/5.0")
    webhook = next(item for item in body["items"] if item["id"] == world["webhook"].id)
    assert webhook["actor"] is None  # l'opérateur, pas une personne


@pytest.mark.parametrize(
    ("params", "expected"),
    [
        ({"domain": "payment"}, ["webhook", "pay"]),
        ({"action": "bill.cancel"}, ["cancel"]),
        ({"actor": "team"}, ["cancel"]),
        ({"actor": "client"}, ["pay"]),
        ({"actor": "system"}, ["webhook"]),
        ({"entity_type": "payment_transaction", "entity_id": 7}, ["webhook", "pay"]),
        ({"from": "2026-11-11", "to": "2026-11-11"}, ["pay"]),
    ],
)
def test_filters(client, auth_headers, world, params, expected):
    found = ids(journal(client, auth_headers, world["admin"], **params))
    assert found == [world[name].id for name in expected]


def test_actor_filter(client, auth_headers, world):
    found = ids(journal(client, auth_headers, world["boss"], actor_id=world["client"].id))
    assert found == [world["pay"].id]


def test_bad_filters(client, auth_headers, world):
    headers = auth_headers(world["admin"])
    assert (
        client.get(
            URL, params={"from": "2026-11-12", "to": "2026-11-01"}, headers=headers
        ).status_code
        == 422
    )
    assert client.get(URL, params={"action": "DROP TABLE"}, headers=headers).status_code == 422


def test_domains(client, auth_headers, world):
    response = client.get(f"{URL}/domains", headers=auth_headers(world["admin"]))
    counts = {line["domain"]: (line["label"], line["count"]) for line in response.json()}
    assert counts["bill"] == ("Factures", 1)
    assert counts["payment"] == ("Paiements", 2)


@pytest.mark.parametrize("role", [UserRole.SUPPORT, UserRole.CLIENT])
def test_admins_only(client, auth_headers, db_session, role):
    user = make_user(db_session, role=role)
    assert client.get(URL, headers=auth_headers(user)).status_code == 403
    assert client.get(f"{URL}/domains", headers=auth_headers(user)).status_code == 403


def test_no_route_can_change_the_journal(client):
    paths = client.get("/openapi.json").json()["paths"]
    methods = {
        method
        for path, operations in paths.items()
        if path.startswith("/api/v1/admin/audit-logs")
        for method in operations
    }
    assert methods == {"get"}


def test_the_database_refuses_to_change_the_journal(db_session, world):
    with expect_db_rejection(db_session):
        db_session.execute(
            update(AuditLog).where(AuditLog.id == world["cancel"].id).values(action="bill.paid")
        )
    with expect_db_rejection(db_session):
        db_session.execute(delete(AuditLog).where(AuditLog.id == world["cancel"].id))
