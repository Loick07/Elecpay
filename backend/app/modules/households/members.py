"""Membres d'un foyer : inviter, accepter, refuser, retirer, quitter. Ne connaît pas HTTP.

Cycle d'une adhésion : invited → active (acceptée) ; invited/active → revoked
(refusée, retirée ou quittée). La ligne n'est jamais supprimée : un ancien membre peut
être réinvité (la même ligne repasse à « invited »).
"""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.integrations.sms.base import SmsSender
from app.modules.audit.service import record
from app.modules.households.access import HouseholdRole, household_access
from app.modules.households.errors import (
    AlreadyMemberError,
    InvalidInviteeError,
    InvitationNotFoundError,
    InviteeNotFoundError,
    MemberLimitError,
    MemberNotFoundError,
    OwnerCannotLeaveError,
)
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.households.schemas import (
    HouseholdBrief,
    InvitationPublic,
    InviteRequest,
    MemberPublic,
)
from app.modules.households.service import member_public, person, visible_members
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import insert_notifications, notification_row
from app.modules.users.models import User, UserRole

MAX_MEMBERS = 10  # membres actifs + invitations en attente, propriétaire non compris
ROLE_LABELS = {MemberRole.PAYER: "payeur délégué", MemberRole.VIEWER: "lecteur"}


class MembershipService:
    def __init__(self, session: Session, sms: SmsSender) -> None:
        self.session = session
        self.sms = sms

    # --- Côté propriétaire ------------------------------------------------------------

    def invite(
        self,
        owner: User,
        household_id: int,
        data: InviteRequest,
        context: RequestContext | None = None,
    ) -> MemberPublic:
        access = household_access(self.session, owner, household_id)
        access.require_manage()
        household = access.household

        invitee = self.session.scalars(select(User).where(User.phone == data.phone)).first()
        if invitee is None or not invitee.is_active:
            raise InviteeNotFoundError()
        if invitee.id == household.owner_id:
            raise InvalidInviteeError("Vous êtes déjà propriétaire de ce foyer.")
        if invitee.role is not UserRole.CLIENT:
            raise InvalidInviteeError("Ce compte ne peut pas être invité dans un foyer.")

        existing = self.session.scalars(
            select(HouseholdMember)
            .where(
                HouseholdMember.household_id == household.id,
                HouseholdMember.user_id == invitee.id,
            )
            .with_for_update()
        ).first()
        if existing is not None and existing.status is not MemberStatus.REVOKED:
            raise AlreadyMemberError()
        if self._count_members(household.id) >= MAX_MEMBERS:
            raise MemberLimitError(f"Un foyer compte au plus {MAX_MEMBERS} membres.")

        if existing is None:
            member = HouseholdMember(
                household_id=household.id,
                user_id=invitee.id,
                role=data.role,
                status=MemberStatus.INVITED,
                invited_by=owner.id,
            )
            self.session.add(member)
        else:  # ancien membre : on réutilise sa ligne (jamais supprimée)
            member = existing
            member.role, member.status, member.invited_by = (
                data.role,
                MemberStatus.INVITED,
                owner.id,
            )
        self.session.flush()

        role_label = ROLE_LABELS[data.role]
        insert_notifications(
            self.session,
            [
                notification_row(
                    invitee.id,
                    NotificationType.INVITATION_RECEIVED,
                    "Invitation à un foyer",
                    f"{owner.full_name} vous invite comme {role_label} du foyer "
                    f"« {household.name} ». Ouvrez l'application pour accepter ou refuser.",
                    {"household_id": household.id, "invitation_id": member.id},
                    at=member.updated_at,
                )
            ],
        )
        self._audit("household.member_invite", owner, member, context, role=data.role)
        self.sms.send(
            invitee.phone,
            f"ElecPay : {owner.full_name} vous invite comme {role_label} du foyer "
            f"« {household.name} ». Ouvrez l'application pour répondre.",
        )
        self.session.commit()
        return member_public(member, invitee)

    def list_members(self, user: User, household_id: int) -> list[MemberPublic]:
        return visible_members(self.session, household_access(self.session, user, household_id))

    def remove(
        self, owner: User, household_id: int, member_id: int, context: RequestContext | None = None
    ) -> None:
        """Retire un membre ou annule une invitation en attente."""
        access = household_access(self.session, owner, household_id)
        access.require_manage()
        member = self.session.get(HouseholdMember, member_id)
        if (
            member is None
            or member.household_id != household_id
            or member.status is MemberStatus.REVOKED
        ):
            raise MemberNotFoundError()
        member.status = MemberStatus.REVOKED
        self._audit("household.member_remove", owner, member, context)
        self.session.commit()

    # --- Côté personne invitée / membre ---------------------------------------------

    def my_invitations(self, user: User) -> list[InvitationPublic]:
        rows = self.session.execute(
            select(HouseholdMember, Household)
            .join(Household, Household.id == HouseholdMember.household_id)
            .where(
                HouseholdMember.user_id == user.id,
                HouseholdMember.status == MemberStatus.INVITED,
            )
            .order_by(HouseholdMember.updated_at.desc())
        ).all()
        return [
            InvitationPublic(
                id=member.id,
                household=HouseholdBrief(id=household.id, name=household.name, city=household.city),
                role=member.role,
                invited_by=person(self.session.get(User, member.invited_by)),
                created_at=member.updated_at,  # date de la dernière invitation
            )
            for member, household in rows
        ]

    def accept(self, user: User, invitation_id: int, context: RequestContext | None = None) -> int:
        """Accepte une invitation. Renvoie l'identifiant du foyer rejoint."""
        member = self._my_pending_invitation(user, invitation_id)
        member.status = MemberStatus.ACTIVE
        self._audit("household.member_accept", user, member, context)
        self.session.commit()
        return member.household_id

    def decline(
        self, user: User, invitation_id: int, context: RequestContext | None = None
    ) -> None:
        member = self._my_pending_invitation(user, invitation_id)
        member.status = MemberStatus.REVOKED
        self._audit("household.member_decline", user, member, context)
        self.session.commit()

    def leave(self, user: User, household_id: int, context: RequestContext | None = None) -> None:
        access = household_access(self.session, user, household_id)
        if access.role is HouseholdRole.OWNER:
            raise OwnerCannotLeaveError()
        member = self.session.scalars(
            select(HouseholdMember).where(
                HouseholdMember.household_id == household_id,
                HouseholdMember.user_id == user.id,
            )
        ).one()
        member.status = MemberStatus.REVOKED
        self._audit("household.member_leave", user, member, context)
        self.session.commit()

    # --- Interne --------------------------------------------------------------------

    def _my_pending_invitation(self, user: User, invitation_id: int) -> HouseholdMember:
        member = self.session.get(HouseholdMember, invitation_id)
        if member is None or member.user_id != user.id or member.status is not MemberStatus.INVITED:
            raise InvitationNotFoundError()  # même réponse si elle est à quelqu'un d'autre
        return member

    def _count_members(self, household_id: int) -> int:
        return self.session.scalar(
            select(func.count())
            .select_from(HouseholdMember)
            .where(
                HouseholdMember.household_id == household_id,
                HouseholdMember.status.in_([MemberStatus.ACTIVE, MemberStatus.INVITED]),
            )
        )

    def _audit(
        self,
        action: str,
        actor: User,
        member: HouseholdMember,
        context: RequestContext | None,
        role: MemberRole | None = None,
    ) -> None:
        after = {"household_id": member.household_id, "user_id": member.user_id}
        after["status"] = member.status.value
        if role is not None:
            after["role"] = role.value
        record(
            self.session,
            action=action,
            entity_type="household_member",
            entity_id=member.id,
            actor_id=actor.id,
            context=context,
            after=after,
        )
