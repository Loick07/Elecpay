"""Tests des membres et des invitations (B4.3).

Scénario de la démo : Christelle invite son fils Davy (à Paris) comme payeur délégué
de « Maison de maman ».
"""

import pytest
from sqlalchemy import select

from app.core.rate_limit import RateLimiter
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.audit.models import AuditLog
from app.modules.households.models import HouseholdMember, MemberRole, MemberStatus
from app.modules.notifications.models import Notification, NotificationType
from app.modules.users.models import UserRole
from tests.factories import make_household, make_member, make_user

DAVY_PHONE = "+242060000104"


@pytest.fixture
def sms(app):
    sender = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sender
    return sender


@pytest.fixture
def christelle(db_session):
    return make_user(db_session, full_name="Christelle Bouanga", phone="+242060000103")


@pytest.fixture
def davy(db_session):
    return make_user(db_session, full_name="Davy Bouanga", phone=DAVY_PHONE)


@pytest.fixture
def home(db_session, christelle):
    return make_household(db_session, christelle, name="Maison de maman")


def members_url(household):
    return f"/api/v1/households/{household.id}/members"


def invite(client, headers, household, phone=DAVY_PHONE, role="payer"):
    return client.post(members_url(household), json={"phone": phone, "role": role}, headers=headers)


def code(response):
    return response.json()["error"]["code"]


def membership(db_session, household, user):
    return db_session.scalars(
        select(HouseholdMember).where(
            HouseholdMember.household_id == household.id, HouseholdMember.user_id == user.id
        )
    ).one()


# --- Invitation ---------------------------------------------------------------------


def test_invite_a_delegated_payer(client, auth_headers, sms, christelle, davy, home, db_session):
    response = invite(client, auth_headers(christelle), home, phone="06 000 01 04")
    assert response.status_code == 201
    body = response.json()
    assert (body["role"], body["status"]) == ("payer", "invited")
    assert body["person"]["full_name"] == "Davy Bouanga"

    notification = db_session.scalars(
        select(Notification).where(Notification.user_id == davy.id)
    ).one()
    assert notification.type is NotificationType.INVITATION_RECEIVED
    assert "Christelle Bouanga vous invite comme payeur délégué" in notification.body
    assert notification.data_json == {"household_id": home.id, "invitation_id": body["id"]}

    (message,) = sms.outbox
    assert message.phone == DAVY_PHONE and "Maison de maman" in message.message
    assert db_session.scalars(
        select(AuditLog).where(AuditLog.action == "household.member_invite")
    ).one()


def test_invited_person_has_no_access_yet(client, auth_headers, sms, christelle, davy, home):
    invite(client, auth_headers(christelle), home)
    response = client.get(f"/api/v1/households/{home.id}", headers=auth_headers(davy))
    assert response.status_code == 404


def test_number_without_account(client, auth_headers, sms, christelle, home):
    response = invite(client, auth_headers(christelle), home, phone="069999999")
    assert response.status_code == 404
    assert code(response) == "INVITEE_NOT_FOUND"
    assert "installer l'application" in response.json()["error"]["message"]
    assert sms.outbox == []


def test_disabled_account_looks_like_no_account(
    client, auth_headers, sms, christelle, davy, home, db_session
):
    davy.is_active = False
    db_session.flush()
    assert code(invite(client, auth_headers(christelle), home)) == "INVITEE_NOT_FOUND"


def test_cannot_invite_oneself(client, auth_headers, sms, christelle, home):
    response = invite(client, auth_headers(christelle), home, phone=christelle.phone)
    assert response.status_code == 400
    assert code(response) == "INVALID_INVITEE"


@pytest.mark.parametrize("role", [UserRole.SUPPORT, UserRole.ADMIN])
def test_team_accounts_cannot_be_invited(
    client, auth_headers, sms, christelle, home, db_session, role
):
    staff = make_user(db_session, phone="+242060000002", role=role)
    assert (
        code(invite(client, auth_headers(christelle), home, phone=staff.phone)) == "INVALID_INVITEE"
    )


@pytest.mark.parametrize("status", [MemberStatus.INVITED, MemberStatus.ACTIVE])
def test_cannot_invite_twice(client, auth_headers, sms, christelle, davy, home, db_session, status):
    make_member(db_session, home, davy, status=status)
    response = invite(client, auth_headers(christelle), home)
    assert response.status_code == 409
    assert code(response) == "ALREADY_MEMBER"


def test_a_removed_member_can_be_invited_again(
    client, auth_headers, sms, christelle, davy, home, db_session
):
    make_member(db_session, home, davy, role=MemberRole.VIEWER, status=MemberStatus.REVOKED)
    response = invite(client, auth_headers(christelle), home, role="payer")
    assert response.status_code == 201
    row = membership(db_session, home, davy)
    assert (row.status, row.role) == (MemberStatus.INVITED, MemberRole.PAYER)


def test_at_most_ten_members(client, auth_headers, sms, christelle, davy, home, db_session):
    for _ in range(10):
        make_member(db_session, home, make_user(db_session), status=MemberStatus.ACTIVE)
    response = invite(client, auth_headers(christelle), home)
    assert response.status_code == 409
    assert code(response) == "MEMBER_LIMIT_REACHED"


@pytest.mark.parametrize(
    "data",
    [
        {"phone": DAVY_PHONE},
        {"phone": DAVY_PHONE, "role": "owner"},
        {"phone": "123", "role": "payer"},
    ],
)
def test_invalid_invitations(client, auth_headers, sms, christelle, home, data):
    assert (
        client.post(members_url(home), json=data, headers=auth_headers(christelle)).status_code
        == 422
    )


def test_only_the_owner_invites(client, auth_headers, sms, christelle, davy, home, db_session):
    make_member(db_session, home, davy, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    other = make_user(db_session, phone="+242060000105")
    response = invite(client, auth_headers(davy), home, phone=other.phone)
    assert response.status_code == 403
    assert code(response) == "HOUSEHOLD_FORBIDDEN"


def test_stranger_cannot_invite_into_someone_elses_household(client, auth_headers, sms, davy, home):
    assert invite(client, auth_headers(davy), home, phone=davy.phone).status_code == 404


def test_invitations_are_rate_limited(app, client, auth_headers, sms, christelle, home, db_session):
    app.state.rate_limiter = RateLimiter()
    people = [make_user(db_session) for _ in range(21)]
    for person in people[:20]:
        response = invite(client, auth_headers(christelle), home, phone=person.phone)
        assert response.status_code in (201, 409)  # au-delà de 10 : limite de membres
    assert invite(client, auth_headers(christelle), home, phone=people[20].phone).status_code == 429


# --- Côté personne invitée ----------------------------------------------------------


def test_my_invitations(client, auth_headers, sms, christelle, davy, home):
    invite(client, auth_headers(christelle), home)
    body = client.get("/api/v1/invitations", headers=auth_headers(davy)).json()
    (invitation,) = body
    assert invitation["household"]["name"] == "Maison de maman"
    assert invitation["role"] == "payer"
    assert invitation["invited_by"]["full_name"] == "Christelle Bouanga"
    assert invitation["invited_by"]["phone_masked"] == "+242 06 *** ** 03"


def test_accept_gives_access_as_delegated_payer(client, auth_headers, sms, christelle, davy, home):
    invitation_id = invite(client, auth_headers(christelle), home).json()["id"]
    response = client.post(
        f"/api/v1/invitations/{invitation_id}/accept", headers=auth_headers(davy)
    )
    assert response.status_code == 200
    body = response.json()
    assert (body["name"], body["my_role"], body["can_pay"], body["can_manage"]) == (
        "Maison de maman",
        "payer",
        True,
        False,
    )
    assert client.get("/api/v1/invitations", headers=auth_headers(davy)).json() == []
    households = client.get("/api/v1/households", headers=auth_headers(davy)).json()
    assert [h["name"] for h in households] == ["Maison de maman"]


def test_decline(client, auth_headers, sms, christelle, davy, home, db_session):
    invitation_id = invite(client, auth_headers(christelle), home).json()["id"]
    response = client.post(
        f"/api/v1/invitations/{invitation_id}/decline", headers=auth_headers(davy)
    )
    assert response.status_code == 204
    assert membership(db_session, home, davy).status is MemberStatus.REVOKED
    assert (
        client.get(f"/api/v1/households/{home.id}", headers=auth_headers(davy)).status_code == 404
    )


def test_cannot_answer_someone_elses_invitation(
    client, auth_headers, sms, christelle, davy, home, db_session
):
    invitation_id = invite(client, auth_headers(christelle), home).json()["id"]
    intruder = make_user(db_session)
    for action in ("accept", "decline"):
        response = client.post(
            f"/api/v1/invitations/{invitation_id}/{action}", headers=auth_headers(intruder)
        )
        assert response.status_code == 404
        assert code(response) == "INVITATION_NOT_FOUND"
    assert membership(db_session, home, davy).status is MemberStatus.INVITED


def test_invitation_can_be_answered_only_once(client, auth_headers, sms, christelle, davy, home):
    invitation_id = invite(client, auth_headers(christelle), home).json()["id"]
    client.post(f"/api/v1/invitations/{invitation_id}/accept", headers=auth_headers(davy))
    again = client.post(f"/api/v1/invitations/{invitation_id}/decline", headers=auth_headers(davy))
    assert code(again) == "INVITATION_NOT_FOUND"


# --- Retrait et départ --------------------------------------------------------------


def test_owner_removes_a_member(client, auth_headers, sms, christelle, davy, home, db_session):
    member = make_member(db_session, home, davy, status=MemberStatus.ACTIVE)
    response = client.delete(f"{members_url(home)}/{member.id}", headers=auth_headers(christelle))
    assert response.status_code == 204
    assert membership(db_session, home, davy).status is MemberStatus.REVOKED
    assert (
        client.get(f"/api/v1/households/{home.id}", headers=auth_headers(davy)).status_code == 404
    )
    assert db_session.scalars(
        select(AuditLog).where(AuditLog.action == "household.member_remove")
    ).one()


def test_owner_cancels_a_pending_invitation(
    client, auth_headers, sms, christelle, davy, home, db_session
):
    invitation_id = invite(client, auth_headers(christelle), home).json()["id"]
    assert (
        client.delete(
            f"{members_url(home)}/{invitation_id}", headers=auth_headers(christelle)
        ).status_code
        == 204
    )
    assert client.get("/api/v1/invitations", headers=auth_headers(davy)).json() == []


def test_member_of_another_household_cannot_be_removed_from_here(
    client, auth_headers, sms, christelle, davy, home, db_session
):
    other_home = make_household(db_session, davy)
    stranger_member = make_member(
        db_session, other_home, make_user(db_session), status=MemberStatus.ACTIVE
    )
    response = client.delete(
        f"{members_url(home)}/{stranger_member.id}", headers=auth_headers(christelle)
    )
    assert response.status_code == 404
    assert code(response) == "MEMBER_NOT_FOUND"


def test_only_the_owner_removes(client, auth_headers, sms, christelle, davy, home, db_session):
    make_member(db_session, home, davy, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    viewer = make_member(
        db_session, home, make_user(db_session), role=MemberRole.VIEWER, status=MemberStatus.ACTIVE
    )
    response = client.delete(f"{members_url(home)}/{viewer.id}", headers=auth_headers(davy))
    assert code(response) == "HOUSEHOLD_FORBIDDEN"


def test_a_member_can_leave(client, auth_headers, sms, christelle, davy, home, db_session):
    make_member(db_session, home, davy, status=MemberStatus.ACTIVE)
    response = client.post(f"/api/v1/households/{home.id}/leave", headers=auth_headers(davy))
    assert response.status_code == 204
    assert membership(db_session, home, davy).status is MemberStatus.REVOKED


def test_owner_cannot_leave(client, auth_headers, sms, christelle, home):
    response = client.post(f"/api/v1/households/{home.id}/leave", headers=auth_headers(christelle))
    assert response.status_code == 400
    assert code(response) == "OWNER_CANNOT_LEAVE"


def test_members_list(client, auth_headers, sms, christelle, davy, home, db_session):
    make_member(db_session, home, davy, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, make_user(db_session), status=MemberStatus.INVITED)
    as_owner = client.get(members_url(home), headers=auth_headers(christelle)).json()
    as_member = client.get(members_url(home), headers=auth_headers(davy)).json()
    assert len(as_owner) == 2 and len(as_member) == 1
