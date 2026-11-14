"""Tests de l'écran Paramètres et rôles du back-office (B10.9, A11) : équipe, invitations,
rôles, tarifs datés, intégrations."""

from datetime import date, timedelta

import pytest
from sqlalchemy import select

from app.core.timezone import local_date
from app.db.base import utcnow
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.audit.models import AuditLog
from app.modules.bills.service import tariff_at
from app.modules.users.models import User, UserRole
from tests.factories import make_bill, make_tariff, make_user

ADMIN = "/api/v1/admin"
TOMORROW = local_date(utcnow()) + timedelta(days=1)


@pytest.fixture
def team(db_session):
    return {
        "boss": make_user(db_session, role=UserRole.SUPER_ADMIN, full_name="Serge Bouanga"),
        "admin": make_user(db_session, role=UserRole.ADMIN, full_name="Christelle Mabiala"),
        "support": make_user(db_session, role=UserRole.SUPPORT, full_name="Patrick Moukala"),
        "client": make_user(db_session, full_name="Arnaud Mavoungou", phone="+242061110001"),
    }


@pytest.fixture
def sms(app):
    sender = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sender
    return sender


def invite(client, auth_headers, user, **body):
    payload = {"full_name": "Junior Ibara", "phone": "06 555 12 34", "role": "support"} | body
    return client.post(f"{ADMIN}/team/invite", json=payload, headers=auth_headers(user))


def change_role(client, auth_headers, user, member, role, reason="Nouvelle mission confiée"):
    return client.put(
        f"{ADMIN}/team/{member.id}/role",
        json={"role": role, "reason": reason},
        headers=auth_headers(user),
    )


# --- Équipe ---------------------------------------------------------------------------------


def test_team_lists_staff_only(client, auth_headers, team):
    response = client.get(f"{ADMIN}/team", headers=auth_headers(team["admin"]))
    assert response.status_code == 200, response.text
    names = {member["full_name"] for member in response.json()}
    assert names == {"Serge Bouanga", "Christelle Mabiala", "Patrick Moukala"}
    assert {member["two_factor"] for member in response.json()} == {"not_available"}
    assert client.get(f"{ADMIN}/team", headers=auth_headers(team["support"])).status_code == 403


def test_invite_then_the_member_chooses_a_password(client, auth_headers, db_session, team, sms):
    response = invite(client, auth_headers, team["boss"])
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["sms_sent_to"] == "+242 06 *** ** 34"
    assert (body["member"]["role"], body["member"]["invitation_pending"]) == ("support", True)
    welcome, code_sms = sms.outbox
    assert "invité(e) dans l'équipe ElecPay (Support)" in welcome.message
    code = "".join(char for char in code_sms.message if char.isdigit())[:6]
    assert code not in response.text  # jamais montré à l'équipe
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "team.invite")).one()
    assert code not in str(log.after_json)

    reset = client.post(
        "/api/v1/auth/password/reset",
        json={"phone": "+242065551234", "code": code, "new_password": "Equipe2026!"},
    )
    assert reset.status_code in (200, 204), reset.text
    login = client.post(
        "/api/v1/auth/login", json={"phone": "+242065551234", "password": "Equipe2026!"}
    )
    assert login.status_code == 200, login.text
    assert login.json()["user"]["role"] == "support"


def test_invite_refuses_an_existing_account(client, auth_headers, team, sms):
    response = invite(client, auth_headers, team["boss"], phone="+242061110001")
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "TEAM_ACTION_REFUSED"
    assert sms.outbox == []


@pytest.mark.parametrize("role", ["client", "payer"])
def test_invite_only_team_roles(client, auth_headers, team, sms, role):
    assert invite(client, auth_headers, team["boss"], role=role).status_code == 422


def test_only_the_super_admin_invites(client, auth_headers, team, sms):
    assert invite(client, auth_headers, team["admin"]).status_code == 403


def test_change_a_role_takes_effect_now(client, auth_headers, db_session, team):
    support = team["support"]
    assert client.get(f"{ADMIN}/team", headers=auth_headers(support)).status_code == 403
    response = change_role(client, auth_headers, team["boss"], support, "admin")
    assert response.status_code == 200, response.text
    assert response.json()["role"] == "admin"
    assert client.get(f"{ADMIN}/team", headers=auth_headers(support)).status_code == 200
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "team.role")).one()
    assert (log.before_json, log.after_json["role"]) == ({"role": "support"}, "admin")


def test_role_guards(client, auth_headers, db_session, team):
    boss = team["boss"]
    own = change_role(client, auth_headers, boss, boss, "admin")
    assert own.status_code == 409
    assert change_role(client, auth_headers, boss, team["admin"], "admin").status_code == 409
    client_account = change_role(client, auth_headers, boss, team["client"], "support")
    assert client_account.status_code == 404  # un client n'est jamais promu
    assert (
        change_role(client, auth_headers, team["admin"], team["support"], "admin").status_code
        == 403
    )
    assert change_role(client, auth_headers, boss, team["support"], "admin", "x").status_code == 422


def test_always_one_active_super_admin(client, auth_headers, db_session, team):
    # Les autres super admins éventuels de la base de test sont écartés pour ce test.
    for other in db_session.scalars(
        select(User).where(User.role == UserRole.SUPER_ADMIN, User.id != team["boss"].id)
    ):
        other.is_active = False
    second = make_user(db_session, role=UserRole.SUPER_ADMIN)
    db_session.flush()
    first = change_role(client, auth_headers, second, team["boss"], "admin")
    assert first.status_code == 200, first.text
    last = change_role(client, auth_headers, team["boss"], second, "admin")
    assert last.status_code == 403  # Serge n'est plus super admin : effet immédiat
    db_session.refresh(second)
    assert second.role is UserRole.SUPER_ADMIN


# --- Tarifs ---------------------------------------------------------------------------------


def tariff_payload(**overrides):
    return {
        "code": "BT_DOMESTIQUE",
        "label": "Basse tension domestique",
        "price_per_kwh_milli": 52_000,
        "fixed_fee_per_month": 2_550,
        "vat_rate_bp": 1_800,
        "additional_tax_rate_bp": 500,
        "audiovisual_fee": 1_000,
        "stamp_fee": 0,
        "valid_from": (TOMORROW + timedelta(days=30)).isoformat(),
        "is_assumption": False,
        "source_note": "Arrêté tarifaire E²C (test)",
    } | overrides


@pytest.fixture
def current(db_session):
    return make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))


def test_new_tariff_version_closes_the_current_one(client, auth_headers, db_session, team, current):
    make_bill(db_session, tariff=current)
    response = client.post(
        f"{ADMIN}/tariffs", json=tariff_payload(), headers=auth_headers(team["boss"])
    )
    assert response.status_code == 201, response.text
    start = TOMORROW + timedelta(days=30)
    db_session.refresh(current)
    assert current.valid_to == start
    rows = {(row["code"], row["valid_from"]): row for row in response.json()}
    new = rows[("BT_DOMESTIQUE", start.isoformat())]
    assert (new["price_per_kwh_milli"], new["in_force"], new["bills"]) == (52_000, False, 0)
    old = rows[("BT_DOMESTIQUE", "2025-01-01")]
    assert (old["in_force"], old["bills"]) == (True, 1)
    assert tariff_at(db_session, start).price_per_kwh_milli == 52_000
    assert tariff_at(db_session, start - timedelta(days=1)).id == current.id
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "tariff.create")).one()
    assert log.before_json == {"previous_tariff_id": current.id, "previous_valid_to": None}


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        ({"valid_from": date(2026, 1, 1).isoformat()}, "au plus tôt demain"),
        ({"code": "BT_PRO"}, "Code de tarif inconnu"),
    ],
)
def test_tariff_refused(client, auth_headers, team, current, overrides, message):
    response = client.post(
        f"{ADMIN}/tariffs", json=tariff_payload(**overrides), headers=auth_headers(team["boss"])
    )
    assert response.status_code == 422
    assert message in response.json()["error"]["message"]


def test_tariff_must_follow_the_latest_version(client, auth_headers, team, current):
    later = tariff_payload(valid_from=(TOMORROW + timedelta(days=60)).isoformat())
    headers = auth_headers(team["boss"])
    assert client.post(f"{ADMIN}/tariffs", json=later, headers=headers).status_code == 201
    earlier = client.post(f"{ADMIN}/tariffs", json=tariff_payload(), headers=headers)
    assert earlier.status_code == 422


def test_tariffs_rights(client, auth_headers, team, current):
    assert client.get(f"{ADMIN}/tariffs", headers=auth_headers(team["support"])).status_code == 200
    refused = client.post(
        f"{ADMIN}/tariffs", json=tariff_payload(), headers=auth_headers(team["admin"])
    )
    assert refused.status_code == 403


def test_tariff_values_are_checked(client, auth_headers, team, current):
    headers = auth_headers(team["boss"])
    for bad in ({"vat_rate_bp": 10_001}, {"price_per_kwh_milli": 0}, {"source_note": ""}):
        assert (
            client.post(f"{ADMIN}/tariffs", json=tariff_payload(**bad), headers=headers).status_code
            == 422
        )


# --- Intégrations ---------------------------------------------------------------------------


def test_integrations_without_secrets(client, auth_headers, team, test_settings):
    response = client.get(f"{ADMIN}/integrations", headers=auth_headers(team["admin"]))
    assert response.status_code == 200, response.text
    body = response.json()
    modes = {line["key"]: line["mode"] for line in body["integrations"]}
    assert modes == {
        "mtn_momo": "simulated",
        "airtel_money": "simulated",
        "e2c": "simulated",
        "sms": "simulated",
        "push": "phase_2",
    }
    assert body["demo_mode"] is True
    secret = test_settings.payment_webhook_secret.get_secret_value()
    assert secret and secret not in response.text
    assert test_settings.jwt_secret.get_secret_value() not in response.text
    support = client.get(f"{ADMIN}/integrations", headers=auth_headers(team["support"]))
    assert support.status_code == 403
