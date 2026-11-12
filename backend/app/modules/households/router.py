"""Routes des foyers, de leurs membres et des invitations reçues.

Aucune logique métier ici : tout est dans `HouseholdService` et `MembershipService`.
"""

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.rate_limit import Limit, RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.sms.base import SmsSender
from app.integrations.sms.factory import get_sms_sender
from app.modules.auth.dependencies import current_user
from app.modules.households.members import MembershipService
from app.modules.households.schemas import (
    HouseholdCreate,
    HouseholdDetail,
    HouseholdSummary,
    HouseholdUpdate,
    InvitationPublic,
    InviteRequest,
    MemberPublic,
)
from app.modules.households.service import HouseholdService
from app.modules.users.models import User

router = APIRouter(prefix="/households", tags=["Foyers"])

NOT_FOUND = {
    "model": ErrorResponse,
    "description": "Foyer introuvable (ou auquel vous n'avez pas accès : même réponse)",
}
COMMON = {401: {"model": ErrorResponse, "description": "Non connecté"}, 404: NOT_FOUND}


@router.get(
    "",
    response_model=list[HouseholdSummary],
    summary="Mes foyers (possédés et ceux dont je suis membre)",
    responses={401: COMMON[401]},
)
def list_households(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> list[HouseholdSummary]:
    return HouseholdService(db).list_for(user)


@router.post(
    "",
    response_model=HouseholdDetail,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un foyer",
    responses={
        401: COMMON[401],
        403: {"model": ErrorResponse, "description": "Réservé aux comptes clients"},
        409: {"model": ErrorResponse, "description": "Nombre maximal de foyers atteint"},
    },
)
def create_household(
    data: HouseholdCreate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> HouseholdDetail:
    return HouseholdService(db).create(user, data, context)


@router.get(
    "/{household_id}",
    response_model=HouseholdDetail,
    summary="Détail d'un foyer : compteurs, membres, mon rôle",
    responses=COMMON,
)
def read_household(
    household_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> HouseholdDetail:
    return HouseholdService(db).detail(user, household_id)


@router.patch(
    "/{household_id}",
    response_model=HouseholdDetail,
    summary="Modifier un foyer (propriétaire)",
    responses=COMMON
    | {403: {"model": ErrorResponse, "description": "Réservé au propriétaire du foyer"}},
)
def update_household(
    household_id: int,
    data: HouseholdUpdate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> HouseholdDetail:
    return HouseholdService(db).update(user, household_id, data, context)


# --- Membres --------------------------------------------------------------------------

# Chaque invitation envoie un SMS (payant) : limite par compte qui invite.
INVITES_PER_USER = Limit(20, 24 * 3600)
OWNER_ONLY = {403: {"model": ErrorResponse, "description": "Réservé au propriétaire du foyer"}}


@router.get(
    "/{household_id}/members",
    response_model=list[MemberPublic],
    summary="Membres du foyer (le propriétaire voit aussi les invitations en attente)",
    responses=COMMON,
)
def list_members(
    household_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
) -> list[MemberPublic]:
    return MembershipService(db, sms).list_members(user, household_id)


@router.post(
    "/{household_id}/members",
    response_model=MemberPublic,
    status_code=status.HTTP_201_CREATED,
    summary="Inviter quelqu'un par son numéro (payeur délégué ou lecteur)",
    description="La personne doit déjà avoir un compte ElecPay. Elle reçoit une notification "
    "et un SMS, puis accepte ou refuse avec `/invitations/{id}/accept|decline`.",
    responses=COMMON
    | OWNER_ONLY
    | {
        400: {"model": ErrorResponse, "description": "Personne qui ne peut pas être invitée"},
        409: {"model": ErrorResponse, "description": "Déjà membre, ou limite de membres atteinte"},
        429: {"model": ErrorResponse, "description": "Trop d'invitations envoyées aujourd'hui"},
    },
)
def invite_member(
    household_id: int,
    data: InviteRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> MemberPublic:
    limiter.consume(f"invite:user:{user.id}", INVITES_PER_USER)
    return MembershipService(db, sms).invite(user, household_id, data, context)


@router.delete(
    "/{household_id}/members/{member_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Retirer un membre ou annuler une invitation (propriétaire)",
    responses=COMMON | OWNER_ONLY,
)
def remove_member(
    household_id: int,
    member_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
) -> Response:
    MembershipService(db, sms).remove(user, household_id, member_id, context)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/{household_id}/leave",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Quitter un foyer (membre)",
    responses=COMMON
    | {400: {"model": ErrorResponse, "description": "Le propriétaire ne quitte pas son foyer"}},
)
def leave_household(
    household_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
) -> Response:
    MembershipService(db, sms).leave(user, household_id, context)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- Invitations reçues ---------------------------------------------------------------

invitations_router = APIRouter(prefix="/invitations", tags=["Foyers"])
INVITATION_NOT_FOUND = {
    404: {"model": ErrorResponse, "description": "Invitation introuvable ou déjà traitée"}
}


@invitations_router.get(
    "", response_model=list[InvitationPublic], summary="Mes invitations en attente"
)
def my_invitations(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
) -> list[InvitationPublic]:
    return MembershipService(db, sms).my_invitations(user)


@invitations_router.post(
    "/{invitation_id}/accept",
    response_model=HouseholdDetail,
    summary="Accepter une invitation (renvoie le foyer rejoint)",
    responses=INVITATION_NOT_FOUND,
)
def accept_invitation(
    invitation_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
) -> HouseholdDetail:
    household_id = MembershipService(db, sms).accept(user, invitation_id, context)
    return HouseholdService(db).detail(user, household_id)


@invitations_router.post(
    "/{invitation_id}/decline",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Refuser une invitation",
    responses=INVITATION_NOT_FOUND,
)
def decline_invitation(
    invitation_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
) -> Response:
    MembershipService(db, sms).decline(user, invitation_id, context)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
