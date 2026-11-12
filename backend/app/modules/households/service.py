"""Service des foyers : lister, créer, consulter, modifier. Ne connaît pas HTTP."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.core.validation import mask_phone
from app.modules.audit.service import record
from app.modules.auth.errors import InsufficientRoleError
from app.modules.households.access import HouseholdAccess, accessible_households, household_access
from app.modules.households.errors import HouseholdLimitError
from app.modules.households.models import Household, HouseholdMember, MemberStatus
from app.modules.households.schemas import (
    HouseholdCreate,
    HouseholdDetail,
    HouseholdSummary,
    HouseholdUpdate,
    MemberPublic,
    MeterSummary,
    PersonPublic,
)
from app.modules.meters.models import Meter
from app.modules.users.models import User, UserRole

MAX_OWNED_HOUSEHOLDS = 10
EDITABLE_FIELDS = ("name", "city", "district", "address")


def person(user: User) -> PersonPublic:
    return PersonPublic(id=user.id, full_name=user.full_name, phone_masked=mask_phone(user.phone))


class HouseholdService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_for(self, user: User) -> list[HouseholdSummary]:
        households = self.session.scalars(accessible_households(user).order_by(Household.id)).all()
        return [self._summary(user, household) for household in households]

    def create(
        self, user: User, data: HouseholdCreate, context: RequestContext | None = None
    ) -> HouseholdDetail:
        if user.role is not UserRole.CLIENT:
            # L'équipe gère les foyers depuis le back-office (B10), pas comme une cliente.
            raise InsufficientRoleError("Les foyers se créent depuis un compte client.")
        owned = self.session.scalar(
            select(func.count()).select_from(Household).where(Household.owner_id == user.id)
        )
        if owned >= MAX_OWNED_HOUSEHOLDS:
            raise HouseholdLimitError(
                f"Un compte peut posséder au plus {MAX_OWNED_HOUSEHOLDS} foyers."
            )
        household = Household(owner_id=user.id, **data.model_dump())
        self.session.add(household)
        self.session.flush()
        record(
            self.session,
            action="household.create",
            entity_type="household",
            entity_id=household.id,
            actor_id=user.id,
            context=context,
            after=data.model_dump(),
        )
        self.session.commit()
        return self.detail(user, household.id)

    def detail(self, user: User, household_id: int) -> HouseholdDetail:
        access = household_access(self.session, user, household_id)
        return self._detail(access)

    def update(
        self,
        user: User,
        household_id: int,
        data: HouseholdUpdate,
        context: RequestContext | None = None,
    ) -> HouseholdDetail:
        access = household_access(self.session, user, household_id)
        access.require_manage()
        household = access.household
        changes = {
            field: getattr(data, field)
            for field in data.model_fields_set & set(EDITABLE_FIELDS)
            if getattr(data, field) != getattr(household, field)
        }
        if changes:
            before = {field: getattr(household, field) for field in changes}
            for field, value in changes.items():
                setattr(household, field, value)
            record(
                self.session,
                action="household.update",
                entity_type="household",
                entity_id=household.id,
                actor_id=user.id,
                context=context,
                before=before,
                after=changes,
            )
            self.session.commit()
        return self._detail(access)

    # --- Construction des réponses ---------------------------------------------------

    def _summary(self, user: User, household: Household) -> HouseholdSummary:
        access = household_access(self.session, user, household.id)
        owner = self.session.get(User, household.owner_id)
        return HouseholdSummary(
            id=household.id,
            name=household.name,
            city=household.city,
            district=household.district,
            my_role=access.role,
            owner_name=owner.full_name,
            meters_count=self.session.scalar(
                select(func.count()).select_from(Meter).where(Meter.household_id == household.id)
            ),
            members_count=self.session.scalar(
                select(func.count())
                .select_from(HouseholdMember)
                .where(
                    HouseholdMember.household_id == household.id,
                    HouseholdMember.status == MemberStatus.ACTIVE,
                )
            ),
        )

    def _detail(self, access: HouseholdAccess) -> HouseholdDetail:
        household = access.household
        meters = self.session.scalars(
            select(Meter).where(Meter.household_id == household.id).order_by(Meter.id)
        ).all()
        return HouseholdDetail(
            id=household.id,
            name=household.name,
            city=household.city,
            district=household.district,
            address=household.address,
            my_role=access.role,
            can_pay=access.can_pay,
            can_manage=access.can_manage,
            owner=person(self.session.get(User, household.owner_id)),
            meters=[MeterSummary.model_validate(meter) for meter in meters],
            members=visible_members(self.session, access),
            created_at=household.created_at,
        )


def visible_members(session: Session, access: HouseholdAccess) -> list[MemberPublic]:
    """Membres actifs ; le propriétaire voit en plus ses invitations en attente."""
    statuses = [MemberStatus.ACTIVE]
    if access.can_manage:
        statuses.append(MemberStatus.INVITED)
    rows = session.execute(
        select(HouseholdMember, User)
        .join(User, User.id == HouseholdMember.user_id)
        .where(
            HouseholdMember.household_id == access.household.id,
            HouseholdMember.status.in_(statuses),
        )
        .order_by(HouseholdMember.id)
    ).all()
    return [member_public(member, member_user) for member, member_user in rows]


def member_public(member: HouseholdMember, member_user: User) -> MemberPublic:
    return MemberPublic(
        id=member.id,
        person=person(member_user),
        role=member.role,
        status=member.status,
        created_at=member.created_at,
    )
