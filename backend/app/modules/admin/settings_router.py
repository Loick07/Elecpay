"""Routes de l'écran Paramètres et rôles du back-office (A11). Logique : `AdminSettings`.

La matrice des permissions (onglet « Permissions ») : `GET /admin/permissions`.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.sms.base import SmsSender
from app.integrations.sms.factory import get_sms_sender
from app.modules.admin.permissions import Permission, admin_route
from app.modules.admin.settings import AdminSettings
from app.modules.admin.settings_schemas import (
    IntegrationsStatus,
    RoleChange,
    TariffCreate,
    TariffRow,
    TeamInvite,
    TeamInvited,
    TeamMember,
)
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter()
REFUSED = {409: {"model": ErrorResponse, "description": "Action refusée"}}


@admin_route(
    router,
    "GET",
    "/team",
    Permission.ADMIN,
    response_model=list[TeamMember],
    summary="Équipe (A11) : membres, rôle, dernière connexion, invitation en attente",
    description="Double authentification : prévue en B11 (`two_factor` = not_available).",
)
def list_team(db: Session = Depends(get_db)) -> list[TeamMember]:
    return AdminSettings(db).team()


@admin_route(
    router,
    "POST",
    "/team/invite",
    Permission.SUPER_ADMIN,
    response_model=TeamInvited,
    status_code=201,
    summary="Inviter un membre de l'équipe (support, admin ou super admin)",
    description="Crée le compte et envoie par SMS un code pour choisir le mot de passe ; le "
    "code n'est jamais montré à l'équipe. Refusé si le numéro ou l'e-mail a déjà un compte "
    "(un client n'est jamais promu). Inscrit au journal.",
    responses=REFUSED,
)
def invite_member(
    data: TeamInvite,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
    settings: Settings = Depends(get_settings),
    sms: SmsSender = Depends(get_sms_sender),
) -> TeamInvited:
    return AdminSettings(db).invite(actor, data, context, settings, sms)


@admin_route(
    router,
    "PUT",
    "/team/{member_id}/role",
    Permission.SUPER_ADMIN,
    response_model=TeamMember,
    summary="Changer le rôle d'un membre de l'équipe (motif obligatoire)",
    description="Effet immédiat (le rôle est relu à chaque requête). Personne ne change son "
    "propre rôle ; il reste toujours au moins un super admin actif. Inscrit au journal.",
    responses=REFUSED | {404: {"model": ErrorResponse, "description": "Membre introuvable"}},
)
def change_role(
    member_id: int,
    data: RoleChange,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> TeamMember:
    return AdminSettings(db).change_role(actor, member_id, data, context)


@admin_route(
    router,
    "GET",
    "/tariffs",
    Permission.STAFF,
    response_model=list[TariffRow],
    summary="Tarifs datés (A11), avec le nombre de factures émises par version",
)
def list_tariffs(db: Session = Depends(get_db)) -> list[TariffRow]:
    return AdminSettings(db).tariffs()


@admin_route(
    router,
    "POST",
    "/tariffs",
    Permission.SUPER_ADMIN,
    response_model=list[TariffRow],
    status_code=201,
    summary="Créer une nouvelle version datée d'un tarif",
    description="À partir de demain au plus tôt, après la dernière version du même code ; la "
    "version en cours s'arrête à cette date. Les factures émises ne changent jamais ; une "
    "facture prend le tarif en vigueur au premier jour de sa période. Renvoie tous les "
    "tarifs. Inscrit au journal.",
    responses={422: {"model": ErrorResponse, "description": "Tarif refusé"}},
)
def create_tariff(
    data: TariffCreate,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> list[TariffRow]:
    return AdminSettings(db).create_tariff(actor, data, context)


@admin_route(
    router,
    "GET",
    "/integrations",
    Permission.ADMIN,
    response_model=IntegrationsStatus,
    summary="Intégrations (A11) : simulateurs ou services branchés, mode démo",
    description="Aucun secret n'est renvoyé (seulement s'il est configuré ou non).",
)
def integrations(settings: Settings = Depends(get_settings)) -> IntegrationsStatus:
    return AdminSettings.integrations(settings)
