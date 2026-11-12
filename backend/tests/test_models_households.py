"""Contraintes des tables `households`, `household_members` et `meters` (B1.3)."""

from datetime import date

import pytest
from sqlalchemy import text

from app.modules.households.models import MemberRole, MemberStatus
from app.modules.meters.models import MeterStatus, MeterType
from tests.db_helpers import expect_db_rejection
from tests.factories import make_household, make_member, make_meter, make_user

# --- households ---------------------------------------------------------------------


def test_household_is_created_with_its_owner(db_session):
    owner = make_user(db_session)
    household = make_household(db_session, owner, name="Maison de maman", address="Av. de l'OUA")
    assert household.owner_id == owner.id
    assert household.city == "Pointe-Noire"


def test_household_district_for_targeted_announcements(db_session):
    household = make_household(db_session, district="Tié-Tié")
    db_session.expire(household)
    assert household.district == "Tié-Tié"


def test_household_requires_existing_owner(db_session):
    with expect_db_rejection(db_session, "fk_households_owner_id_users"):
        make_household(db_session, owner_id=999_999)


@pytest.mark.parametrize(
    ("column", "constraint"),
    [("name", "ck_households_name_not_blank"), ("city", "ck_households_city_not_blank")],
)
def test_household_name_and_city_cannot_be_blank(db_session, column, constraint):
    with expect_db_rejection(db_session, constraint):
        make_household(db_session, **{column: "  "})


def test_owner_with_household_cannot_be_deleted(db_session):
    household = make_household(db_session)
    with expect_db_rejection(db_session, "fk_households_owner_id_users"):
        db_session.execute(text("DELETE FROM users WHERE id = :id"), {"id": household.owner_id})


def test_a_user_can_own_several_households(db_session):
    owner = make_user(db_session)
    make_household(db_session, owner, name="Maison")
    make_household(db_session, owner, name="Boutique")


# --- household_members --------------------------------------------------------------


def test_member_defaults_to_invited(db_session):
    member = make_member(db_session, make_household(db_session))
    db_session.expire(member)
    assert member.status is MemberStatus.INVITED
    assert member.role is MemberRole.PAYER


def test_same_user_cannot_be_member_twice(db_session):
    household = make_household(db_session)
    user = make_user(db_session)
    make_member(db_session, household, user)
    with expect_db_rejection(db_session, "uq_household_members_household_id_user_id"):
        make_member(db_session, household, user, role=MemberRole.VIEWER)


def test_same_user_can_be_member_of_several_households(db_session):
    user = make_user(db_session)
    make_member(db_session, make_household(db_session), user)
    make_member(db_session, make_household(db_session), user, role=MemberRole.VIEWER)


def test_owner_is_not_a_member_role(db_session):
    household = make_household(db_session)
    member = make_member(db_session, household)
    with expect_db_rejection(db_session, "ck_household_members_role"):
        db_session.execute(
            text("UPDATE household_members SET role = 'owner' WHERE id = :id"), {"id": member.id}
        )


def test_unknown_member_status_is_refused(db_session):
    member = make_member(db_session, make_household(db_session))
    with expect_db_rejection(db_session, "ck_household_members_status"):
        db_session.execute(
            text("UPDATE household_members SET status = 'deleted' WHERE id = :id"),
            {"id": member.id},
        )


@pytest.mark.parametrize(
    ("column", "constraint"),
    [
        ("household_id", "fk_household_members_household_id_households"),
        ("user_id", "fk_household_members_user_id_users"),
        ("invited_by", "fk_household_members_invited_by_users"),
    ],
)
def test_member_references_must_exist(db_session, column, constraint):
    household = make_household(db_session)
    with expect_db_rejection(db_session, constraint):
        make_member(db_session, household, **{column: 999_999})


def test_household_with_members_cannot_be_deleted(db_session):
    household = make_household(db_session)
    make_member(db_session, household)
    with expect_db_rejection(db_session, "fk_household_members_household_id_households"):
        db_session.execute(text("DELETE FROM households WHERE id = :id"), {"id": household.id})


# --- meters -------------------------------------------------------------------------


def test_meter_defaults(db_session):
    meter = make_meter(db_session, make_household(db_session))
    db_session.expire(meter)
    assert meter.type is MeterType.POSTPAID
    assert meter.status is MeterStatus.ACTIVE
    assert meter.label is None


def test_meter_with_all_details(db_session):
    meter = make_meter(
        db_session,
        make_household(db_session),
        label="Boutique",
        contract_number="CT-2024-0042",
        subscribed_power_va=4400,  # 4,4 kVA
        installed_at=date(2021, 6, 15),
    )
    db_session.expire(meter)
    assert meter.subscribed_power_va == 4400
    assert meter.installed_at == date(2021, 6, 15)


def test_meter_can_be_detached_from_any_household(db_session):
    meter = make_meter(db_session, household=None)
    assert meter.household_id is None


def test_meter_reference_is_unique(db_session):
    make_meter(db_session, reference="E2C-PNR-00000001")
    with expect_db_rejection(db_session, "uq_meters_reference"):
        make_meter(db_session, reference="E2C-PNR-00000001")


def test_meter_reference_cannot_be_blank(db_session):
    with expect_db_rejection(db_session, "ck_meters_reference_not_blank"):
        make_meter(db_session, reference=" ")


@pytest.mark.parametrize("power", [0, -2200])
def test_subscribed_power_must_be_positive(db_session, power):
    with expect_db_rejection(db_session, "ck_meters_subscribed_power_positive"):
        make_meter(db_session, subscribed_power_va=power)


def test_prepaid_meter_type_does_not_exist_yet(db_session):
    meter = make_meter(db_session)
    with expect_db_rejection(db_session, "ck_meters_type"):
        db_session.execute(
            text("UPDATE meters SET type = 'prepaid' WHERE id = :id"), {"id": meter.id}
        )


def test_unknown_meter_status_is_refused(db_session):
    meter = make_meter(db_session)
    with expect_db_rejection(db_session, "ck_meters_status"):
        db_session.execute(
            text("UPDATE meters SET status = 'broken' WHERE id = :id"), {"id": meter.id}
        )


def test_meter_requires_existing_household(db_session):
    with expect_db_rejection(db_session, "fk_meters_household_id_households"):
        make_meter(db_session, household_id=999_999)


def test_household_with_meters_cannot_be_deleted(db_session):
    household = make_household(db_session)
    make_meter(db_session, household)
    with expect_db_rejection(db_session, "fk_meters_household_id_households"):
        db_session.execute(text("DELETE FROM households WHERE id = :id"), {"id": household.id})
