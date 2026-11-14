"""Tests du socle du back-office (B10.1) : permissions sur TOUTES les routes `/admin`, matrice,
journal des actions de l'équipe.

Le test « chaque route /admin » parcourt le contrat OpenAPI : toute route ajoutée par la suite
(B10.2 → B10.9) est vérifiée automatiquement, pour chaque rôle.
"""

import re

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.request_context import RequestContext
from app.core.security import hash_password
from app.main import create_app
from app.modules.admin.audit import record_admin_action
from app.modules.admin.permissions import OPENAPI_KEY, ROLES, Permission
from app.modules.audit.models import AuditLog
from app.modules.users.models import UserRole
from tests.factories import make_user

ADMIN_PREFIX = "/api/v1/admin"
ALL_ROLES = (UserRole.CLIENT, UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN)


def admin_operations():
    """(méthode, chemin, niveau) de chaque route du back-office, lus dans le contrat publié."""
    paths = create_app().openapi()["paths"]
    return [
        (method.upper(), path, operation.get(OPENAPI_KEY))
        for path, operations in paths.items()
        if path.startswith(ADMIN_PREFIX)
        for method, operation in operations.items()
    ]


OPERATIONS = admin_operations()


def concrete(path: str) -> str:
    """« /admin/users/{user_id} » → « /admin/users/1 »."""
    return re.sub(r"\{[^}]+\}", "1", path)


def call(client, method, path, headers=None):
    body = {} if method in {"POST", "PUT", "PATCH"} else None
    return client.request(method, concrete(path), json=body, headers=headers or {})


# --- Toutes les routes /admin -------------------------------------------------------------------


def test_the_back_office_has_routes():
    assert ("GET", f"{ADMIN_PREFIX}/permissions", "staff") in OPERATIONS


@pytest.mark.parametrize(("method", "path", "level"), OPERATIONS)
def test_every_admin_route_declares_its_level(method, path, level):
    assert level in {p.value for p in Permission}, f"{method} {path} sans {OPENAPI_KEY}"


@pytest.mark.parametrize(("method", "path", "level"), OPERATIONS)
def test_every_admin_route_requires_a_login(client, method, path, level):
    assert call(client, method, path).status_code == 401


@pytest.mark.parametrize("role", ALL_ROLES)
@pytest.mark.parametrize(("method", "path", "level"), OPERATIONS)
def test_every_admin_route_checks_the_role(
    client, auth_headers, db_session, method, path, level, role
):
    response = call(client, method, path, auth_headers(make_user(db_session, role=role)))
    if role in ROLES[Permission(level)]:
        assert response.status_code not in (401, 403), response.text
    else:
        assert response.status_code == 403, response.text
        assert response.json()["error"]["code"] == "FORBIDDEN"


def test_a_disabled_staff_member_is_refused(client, auth_headers, db_session):
    staff = make_user(db_session, role=UserRole.SUPER_ADMIN, is_active=False)
    response = client.get(f"{ADMIN_PREFIX}/permissions", headers=auth_headers(staff))
    assert (response.status_code, response.json()["error"]["code"]) == (403, "ACCOUNT_DISABLED")


def test_the_back_office_works_with_its_browser_cookies(app, db_session):
    """Le back-office Next.js se connecte par cookies httpOnly (B3), pas par en-tête."""
    make_user(
        db_session,
        phone="+242060000002",
        role=UserRole.SUPPORT,
        password_hash=hash_password("Demo2026!"),
    )
    with TestClient(app, base_url="https://testserver") as web:
        login = web.post(
            "/api/v1/auth/web/login", json={"phone": "+242060000002", "password": "Demo2026!"}
        )
        assert login.status_code == 200
        response = web.get(f"{ADMIN_PREFIX}/permissions")
    assert (response.status_code, response.json()["role"]) == (200, "support")


# --- Matrice des permissions (A11) ---------------------------------------------------------


@pytest.mark.parametrize(
    ("role", "levels", "allowed"),
    [
        (UserRole.SUPPORT, ["staff"], {"view"}),
        (
            UserRole.ADMIN,
            ["staff", "admin"],
            {
                "view",
                "view_audit_log",
                "toggle_account",
                "cancel_bill",
                "recheck_transaction",
                "send_announcement",
            },
        ),
        (
            UserRole.SUPER_ADMIN,
            ["staff", "admin", "super_admin"],
            {
                "view",
                "view_audit_log",
                "toggle_account",
                "cancel_bill",
                "recheck_transaction",
                "send_announcement",
                "edit_tariffs",
                "manage_team",
            },
        ),
    ],
)
def test_my_permissions_follow_the_validated_matrix(
    client, auth_headers, db_session, role, levels, allowed
):
    body = client.get(
        f"{ADMIN_PREFIX}/permissions", headers=auth_headers(make_user(db_session, role=role))
    ).json()
    assert (body["role"], body["levels"]) == (role.value, levels)
    assert {c["key"] for c in body["capabilities"] if c["allowed"]} == allowed


def test_nobody_can_ever_mark_a_payment_as_succeeded(client, auth_headers, db_session):
    staff = make_user(db_session, role=UserRole.SUPER_ADMIN)
    capabilities = client.get(f"{ADMIN_PREFIX}/permissions", headers=auth_headers(staff)).json()[
        "capabilities"
    ]
    (never,) = [c for c in capabilities if c["key"] == "force_payment_success"]
    assert (never["roles"], never["allowed"]) == ([], False)


def test_matrix_labels_are_those_of_the_mockup(client, auth_headers, db_session):
    staff = make_user(db_session, role=UserRole.ADMIN)
    labels = [
        c["label"]
        for c in client.get(f"{ADMIN_PREFIX}/permissions", headers=auth_headers(staff)).json()[
            "capabilities"
        ]
    ]
    assert labels == [
        "Consulter clients, factures, transactions",
        "Consulter le journal",
        "Désactiver / réactiver un compte",
        "Annuler une facture (motif)",
        "Relancer la vérification d'une transaction",
        "Envoyer une annonce",
        "Modifier les tarifs",
        "Attribuer des rôles, inviter un membre",
        "Marquer une transaction comme réussie",
    ]


# --- Journal des actions de l'équipe -------------------------------------------------------------

CONTEXT = RequestContext(ip="196.44.0.1", user_agent="Mozilla/5.0 (back-office ElecPay)")


def test_a_staff_action_is_written_with_its_author_and_context(db_session):
    staff = make_user(db_session, role=UserRole.ADMIN)
    record_admin_action(
        db_session,
        actor=staff,
        context=CONTEXT,
        action="bill.cancel",
        entity_type="bill",
        entity_id=42,
        before={"status": "unpaid"},
        after={"status": "cancelled", "cancelled_reason": "Facture émise en double"},
    )
    db_session.flush()
    log = db_session.scalars(select(AuditLog).where(AuditLog.actor_id == staff.id)).one()
    assert (log.action, log.entity_type, log.entity_id) == ("bill.cancel", "bill", 42)
    assert (log.ip, log.user_agent) == ("196.44.0.1", "Mozilla/5.0 (back-office ElecPay)")
    assert log.before_json == {"status": "unpaid"}


def test_only_staff_members_act_in_the_back_office(db_session):
    with pytest.raises(ValueError, match="équipe"):
        record_admin_action(
            db_session,
            actor=make_user(db_session),
            context=CONTEXT,
            action="bill.cancel",
            entity_type="bill",
            entity_id=1,
        )


def test_secrets_never_reach_the_journal(db_session):
    with pytest.raises(ValueError, match="secrète"):
        record_admin_action(
            db_session,
            actor=make_user(db_session, role=UserRole.SUPER_ADMIN),
            context=CONTEXT,
            action="user.reset_password",
            entity_type="user",
            entity_id=1,
            after={"code": "123456"},
        )
