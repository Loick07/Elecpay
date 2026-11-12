"""Tests des routes des foyers (B4.2), dont le test d'accès croisé exigé par le plan."""

import pytest
from sqlalchemy import select

from app.modules.audit.models import AuditLog
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.users.models import UserRole
from tests.factories import make_household, make_member, make_meter, make_user

HOUSEHOLDS = "/api/v1/households"


@pytest.fixture
def arnaud(db_session):
    return make_user(db_session, full_name="Arnaud Mavoungou", phone="+242060000101")


@pytest.fixture
def rodrigue(db_session):
    return make_user(db_session, full_name="Rodrigue Malonga", phone="+242060000107")


def code(response):
    return response.json()["error"]["code"]


# --- Création -----------------------------------------------------------------------


def test_create_a_household(client, auth_headers, arnaud):
    response = client.post(
        HOUSEHOLDS,
        json={"name": "  Maison   Mpita ", "city": "Pointe-Noire", "district": "Mpita"},
        headers=auth_headers(arnaud),
    )
    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "Maison Mpita"  # espaces nettoyés
    assert (body["my_role"], body["can_manage"], body["can_pay"]) == ("owner", True, True)
    assert body["owner"]["full_name"] == "Arnaud Mavoungou"
    assert body["owner"]["phone_masked"] == "+242 06 *** ** 01"  # jamais le numéro complet
    assert body["meters"] == [] and body["members"] == []
    assert body["address"] is None


def test_creation_is_audited(client, auth_headers, arnaud, db_session):
    client.post(
        HOUSEHOLDS, json={"name": "Boutique", "city": "Pointe-Noire"}, headers=auth_headers(arnaud)
    )
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "household.create")).one()
    assert log.actor_id == arnaud.id
    assert log.after_json["name"] == "Boutique"


@pytest.mark.parametrize(
    "data",
    [
        {"city": "Pointe-Noire"},  # nom manquant
        {"name": "   ", "city": "Pointe-Noire"},
        {"name": "x" * 81, "city": "Pointe-Noire"},
        {"name": "Maison", "city": "Pointe-Noire", "owner_id": 1},  # champ inattendu
    ],
)
def test_invalid_creation(client, auth_headers, arnaud, data):
    assert client.post(HOUSEHOLDS, json=data, headers=auth_headers(arnaud)).status_code == 422


def test_at_most_ten_households_per_account(client, auth_headers, arnaud, db_session):
    for i in range(10):
        make_household(db_session, arnaud, name=f"Foyer {i}")
    response = client.post(
        HOUSEHOLDS, json={"name": "Un de trop", "city": "Brazzaville"}, headers=auth_headers(arnaud)
    )
    assert response.status_code == 409
    assert code(response) == "HOUSEHOLD_LIMIT_REACHED"


@pytest.mark.parametrize("role", [UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN])
def test_team_accounts_do_not_create_households(client, auth_headers, db_session, role):
    staff = make_user(db_session, role=role)
    response = client.post(
        HOUSEHOLDS, json={"name": "Test", "city": "Brazzaville"}, headers=auth_headers(staff)
    )
    assert response.status_code == 403


def test_households_require_login(client):
    assert client.get(HOUSEHOLDS).status_code == 401
    assert client.post(HOUSEHOLDS, json={"name": "X", "city": "Y"}).status_code == 401


# --- Liste --------------------------------------------------------------------------


def test_my_households_with_my_role_in_each(client, auth_headers, arnaud, rodrigue, db_session):
    mine = make_household(db_session, arnaud, name="Maison Mpita")
    make_meter(db_session, mine)
    moms = make_household(db_session, rodrigue, name="Maison de maman")
    make_member(db_session, moms, arnaud, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    invited = make_household(db_session, rodrigue, name="Pas encore accepté")
    make_member(db_session, invited, arnaud, status=MemberStatus.INVITED)

    body = client.get(HOUSEHOLDS, headers=auth_headers(arnaud)).json()
    assert [(h["name"], h["my_role"]) for h in body] == [
        ("Maison Mpita", "owner"),
        ("Maison de maman", "payer"),
    ]
    assert body[0]["meters_count"] == 1
    assert body[1]["owner_name"] == "Rodrigue Malonga"
    assert body[1]["members_count"] == 1


def test_empty_list(client, auth_headers, arnaud):
    assert client.get(HOUSEHOLDS, headers=auth_headers(arnaud)).json() == []


# --- Accès croisé (exigé par le plan) -----------------------------------------------


def test_cross_access_is_impossible(client, auth_headers, arnaud, rodrigue, db_session):
    """Arnaud ne voit ni ne modifie jamais les foyers de Rodrigue — et n'apprend même pas
    qu'ils existent : même réponse que pour un foyer inexistant."""
    rodrigues = make_household(db_session, rodrigue, name="Maison Talangaï")
    headers = auth_headers(arnaud)

    assert client.get(HOUSEHOLDS, headers=headers).json() == []

    seen = client.get(f"{HOUSEHOLDS}/{rodrigues.id}", headers=headers)
    missing = client.get(f"{HOUSEHOLDS}/999999", headers=headers)
    assert seen.status_code == missing.status_code == 404
    assert seen.json() == missing.json()

    patched = client.patch(f"{HOUSEHOLDS}/{rodrigues.id}", json={"name": "Piraté"}, headers=headers)
    assert patched.status_code == 404  # pas 403 : on ne confirme rien
    db_session.refresh(rodrigues)
    assert rodrigues.name == "Maison Talangaï"


@pytest.mark.parametrize("status", [MemberStatus.INVITED, MemberStatus.REVOKED])
def test_pending_or_removed_members_have_no_access(
    client, auth_headers, arnaud, rodrigue, db_session, status
):
    household = make_household(db_session, rodrigue)
    make_member(db_session, household, arnaud, status=status)
    assert (
        client.get(f"{HOUSEHOLDS}/{household.id}", headers=auth_headers(arnaud)).status_code == 404
    )


# --- Détail -------------------------------------------------------------------------


def test_detail_shows_meters_and_members(client, auth_headers, arnaud, rodrigue, db_session):
    household = make_household(db_session, arnaud, name="Boutique Tié-Tié")
    make_meter(
        db_session, household, reference="0377-1209", label="Boutique", subscribed_power_va=9_000
    )
    make_member(db_session, household, rodrigue, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)

    body = client.get(f"{HOUSEHOLDS}/{household.id}", headers=auth_headers(arnaud)).json()
    (meter,) = body["meters"]
    assert (meter["reference"], meter["label"], meter["subscribed_power_va"]) == (
        "0377-1209",
        "Boutique",
        9_000,
    )
    (member,) = body["members"]
    assert member["person"]["full_name"] == "Rodrigue Malonga"
    assert member["person"]["phone_masked"] == "+242 06 *** ** 07"
    assert (member["role"], member["status"]) == ("payer", "active")


def test_delegated_payer_sees_but_cannot_manage(client, auth_headers, arnaud, rodrigue, db_session):
    household = make_household(db_session, rodrigue)
    make_member(db_session, household, arnaud, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    body = client.get(f"{HOUSEHOLDS}/{household.id}", headers=auth_headers(arnaud)).json()
    assert (body["my_role"], body["can_pay"], body["can_manage"]) == ("payer", True, False)


def test_only_the_owner_sees_pending_invitations(
    client, auth_headers, arnaud, rodrigue, db_session
):
    household = make_household(db_session, arnaud)
    viewer = make_user(db_session)
    make_member(db_session, household, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    make_member(db_session, household, rodrigue, status=MemberStatus.INVITED)

    as_owner = client.get(f"{HOUSEHOLDS}/{household.id}", headers=auth_headers(arnaud)).json()
    as_viewer = client.get(f"{HOUSEHOLDS}/{household.id}", headers=auth_headers(viewer)).json()
    assert {m["status"] for m in as_owner["members"]} == {"active", "invited"}
    assert {m["status"] for m in as_viewer["members"]} == {"active"}


# --- Modification -------------------------------------------------------------------


def test_owner_updates_the_household(client, auth_headers, arnaud, db_session):
    household = make_household(db_session, arnaud, name="Maison", district="Mpita", address="Rue 1")
    response = client.patch(
        f"{HOUSEHOLDS}/{household.id}",
        json={"name": "Maison Mpita", "address": None},
        headers=auth_headers(arnaud),
    )
    assert response.status_code == 200
    assert (response.json()["name"], response.json()["address"]) == ("Maison Mpita", None)
    assert response.json()["district"] == "Mpita"  # absent de la requête : inchangé
    log = db_session.scalars(select(AuditLog).where(AuditLog.action == "household.update")).one()
    assert log.before_json == {"name": "Maison", "address": "Rue 1"}
    assert log.after_json == {"name": "Maison Mpita", "address": None}


@pytest.mark.parametrize("role", [MemberRole.PAYER, MemberRole.VIEWER])
def test_members_cannot_update(client, auth_headers, arnaud, rodrigue, db_session, role):
    household = make_household(db_session, rodrigue, name="Maison de maman")
    make_member(db_session, household, arnaud, role=role, status=MemberStatus.ACTIVE)
    response = client.patch(
        f"{HOUSEHOLDS}/{household.id}", json={"name": "Changé"}, headers=auth_headers(arnaud)
    )
    assert response.status_code == 403
    assert code(response) == "HOUSEHOLD_FORBIDDEN"


@pytest.mark.parametrize("data", [{}, {"name": None}, {"city": None}, {"owner_id": 5}])
def test_invalid_updates(client, auth_headers, arnaud, db_session, data):
    household = make_household(db_session, arnaud)
    assert (
        client.patch(
            f"{HOUSEHOLDS}/{household.id}", json=data, headers=auth_headers(arnaud)
        ).status_code
        == 422
    )


def test_update_without_real_change_is_not_audited(client, auth_headers, arnaud, db_session):
    household = make_household(db_session, arnaud, name="Maison")
    client.patch(
        f"{HOUSEHOLDS}/{household.id}", json={"name": "Maison"}, headers=auth_headers(arnaud)
    )
    assert (
        db_session.scalars(select(AuditLog).where(AuditLog.action == "household.update")).first()
        is None
    )
