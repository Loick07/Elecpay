"""Qui peut voir, payer ou gérer un foyer ? Un seul endroit pour le décider.

| Action                                    | Propriétaire | Payeur délégué | Lecteur |
|-------------------------------------------|:------------:|:--------------:|:-------:|
| Voir le foyer, ses compteurs, ses membres |      ✅      |       ✅       |   ✅    |
| Payer les factures                        |      ✅      |       ✅       |   ❌    |
| Modifier le foyer, gérer compteurs/membres|      ✅      |       ❌       |   ❌    |

Seuls le propriétaire (`households.owner_id`) et les membres ACTIFS ont accès :
une invitation non acceptée ou un membre retiré ne donnent rien.
"""

from dataclasses import dataclass
from enum import StrEnum

from sqlalchemy import Select, or_, select
from sqlalchemy.orm import Session

from app.modules.households.errors import (
    HouseholdNotFoundError,
    HouseholdPermissionError,
    MeterNotFoundError,
)
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.users.models import User


class HouseholdRole(StrEnum):
    """Le rôle d'un utilisateur DANS un foyer (à ne pas confondre avec le rôle du compte)."""

    OWNER = "owner"
    PAYER = "payer"  # payeur délégué
    VIEWER = "viewer"  # lecture seule


@dataclass(frozen=True, slots=True)
class HouseholdAccess:
    household: Household
    role: HouseholdRole

    @property
    def can_pay(self) -> bool:
        return self.role in (HouseholdRole.OWNER, HouseholdRole.PAYER)

    @property
    def can_manage(self) -> bool:
        return self.role is HouseholdRole.OWNER

    def require_manage(self) -> None:
        if not self.can_manage:
            raise HouseholdPermissionError()


def accessible_households(user: User) -> Select[tuple[Household]]:
    """Requête des foyers que `user` peut voir (propriétaire ou membre actif)."""
    active_membership = select(HouseholdMember.household_id).where(
        HouseholdMember.user_id == user.id, HouseholdMember.status == MemberStatus.ACTIVE
    )
    return select(Household).where(
        or_(Household.owner_id == user.id, Household.id.in_(active_membership))
    )


def household_access(session: Session, user: User, household_id: int) -> HouseholdAccess:
    """Le foyer et le rôle de `user` dedans. 404 si le foyer n'existe pas OU n'est pas à lui."""
    household = session.get(Household, household_id)
    if household is None:
        raise HouseholdNotFoundError()
    if household.owner_id == user.id:
        return HouseholdAccess(household, HouseholdRole.OWNER)
    member_role = session.scalars(
        select(HouseholdMember.role).where(
            HouseholdMember.household_id == household_id,
            HouseholdMember.user_id == user.id,
            HouseholdMember.status == MemberStatus.ACTIVE,
        )
    ).first()
    if member_role is None:
        raise HouseholdNotFoundError()  # même réponse que « n'existe pas »
    role = HouseholdRole.PAYER if member_role is MemberRole.PAYER else HouseholdRole.VIEWER
    return HouseholdAccess(household, role)


def meter_access(session: Session, user: User, meter_id: int) -> tuple[Meter, HouseholdAccess]:
    """Le compteur et l'accès au foyer qui le porte. 404 si le compteur n'existe pas, est
    détaché de tout foyer, ou appartient à un foyer auquel `user` n'a pas accès."""
    meter = session.get(Meter, meter_id)
    if meter is None or meter.household_id is None:
        raise MeterNotFoundError()
    try:
        access = household_access(session, user, meter.household_id)
    except HouseholdNotFoundError as error:
        raise MeterNotFoundError() from error
    return meter, access
