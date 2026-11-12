"""Tests des règles d'accès aux foyers et aux compteurs (B4.1)."""

import pytest

from app.modules.households.access import (
    HouseholdRole,
    accessible_households,
    household_access,
    meter_access,
)
from app.modules.households.errors import (
    HouseholdNotFoundError,
    HouseholdPermissionError,
    MeterNotFoundError,
)
from app.modules.households.models import MemberRole, MemberStatus
from tests.factories import make_household, make_member, make_meter, make_user


@pytest.fixture
def family(db_session):
    """Un foyer avec : propriétaire, payeur actif, lecteur actif, invité, ancien membre."""
    owner = make_user(db_session, full_name="Christelle")
    household = make_household(db_session, owner, name="Maison de maman")
    people = {"owner": owner}
    for key, role, status in (
        ("payer", MemberRole.PAYER, MemberStatus.ACTIVE),
        ("viewer", MemberRole.VIEWER, MemberStatus.ACTIVE),
        ("invited", MemberRole.PAYER, MemberStatus.INVITED),
        ("revoked", MemberRole.PAYER, MemberStatus.REVOKED),
    ):
        people[key] = make_user(db_session, full_name=key)
        make_member(db_session, household, people[key], role=role, status=status)
    people["stranger"] = make_user(db_session, full_name="Inconnu")
    return household, people


# --- Rôle dans le foyer -------------------------------------------------------------


@pytest.mark.parametrize(
    ("person", "role", "can_pay", "can_manage"),
    [
        ("owner", HouseholdRole.OWNER, True, True),
        ("payer", HouseholdRole.PAYER, True, False),
        ("viewer", HouseholdRole.VIEWER, False, False),
    ],
)
def test_rights_of_each_role(db_session, family, person, role, can_pay, can_manage):
    household, people = family
    access = household_access(db_session, people[person], household.id)
    assert access.role is role
    assert (access.can_pay, access.can_manage) == (can_pay, can_manage)


@pytest.mark.parametrize("person", ["invited", "revoked", "stranger"])
def test_no_access_looks_exactly_like_a_missing_household(db_session, family, person):
    household, people = family
    with pytest.raises(HouseholdNotFoundError) as no_access:
        household_access(db_session, people[person], household.id)
    with pytest.raises(HouseholdNotFoundError) as missing:
        household_access(db_session, people[person], 999_999)
    assert (no_access.value.code, no_access.value.message) == (
        missing.value.code,
        missing.value.message,
    )
    assert no_access.value.status_code == 404


@pytest.mark.parametrize("person", ["payer", "viewer"])
def test_members_cannot_manage(db_session, family, person):
    household, people = family
    with pytest.raises(HouseholdPermissionError):
        household_access(db_session, people[person], household.id).require_manage()


def test_owner_can_manage(db_session, family):
    household, people = family
    household_access(db_session, people["owner"], household.id).require_manage()


# --- Liste des foyers visibles ------------------------------------------------------


def visible(db_session, user):
    return {h.name for h in db_session.scalars(accessible_households(user))}


def test_each_person_sees_only_their_households(db_session, family):
    household, people = family
    own = make_household(db_session, people["payer"], name="Chez le payeur")
    make_household(db_session, people["stranger"], name="Chez l'inconnu")

    assert visible(db_session, people["owner"]) == {"Maison de maman"}
    assert visible(db_session, people["payer"]) == {"Maison de maman", own.name}
    assert visible(db_session, people["viewer"]) == {"Maison de maman"}
    assert visible(db_session, people["invited"]) == set()  # pas encore accepté
    assert visible(db_session, people["revoked"]) == set()
    assert visible(db_session, people["stranger"]) == {"Chez l'inconnu"}


# --- Compteurs ----------------------------------------------------------------------


def test_meter_access_follows_the_household(db_session, family):
    household, people = family
    meter = make_meter(db_session, household)
    found, access = meter_access(db_session, people["payer"], meter.id)
    assert found.id == meter.id and access.role is HouseholdRole.PAYER


@pytest.mark.parametrize("person", ["invited", "revoked", "stranger"])
def test_meter_of_another_household_is_not_found(db_session, family, person):
    household, people = family
    meter = make_meter(db_session, household)
    with pytest.raises(MeterNotFoundError):
        meter_access(db_session, people[person], meter.id)


def test_detached_or_missing_meter_is_not_found(db_session, family):
    _, people = family
    detached = make_meter(db_session, household=None)
    for meter_id in (detached.id, 999_999):
        with pytest.raises(MeterNotFoundError):
            meter_access(db_session, people["owner"], meter_id)
