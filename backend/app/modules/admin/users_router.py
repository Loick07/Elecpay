"""Routes des écrans Utilisateurs du back-office (A2, A3). Logique : `AdminUsers`."""

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.sms.base import SmsSender
from app.integrations.sms.factory import get_sms_sender
from app.modules.admin.permissions import Permission, admin_route
from app.modules.admin.users import AdminUsers
from app.modules.admin.users_schemas import (
    AccountChange,
    AccountStatus,
    AdminUserDetail,
    AdminUserList,
    DeactivateRequest,
    ReactivateRequest,
    ResetCodeSent,
    UserKind,
)
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter(prefix="/users")
NOT_FOUND = {404: {"model": ErrorResponse, "description": "Utilisateur introuvable"}}
REFUSED = {409: {"model": ErrorResponse, "description": "Action impossible sur ce compte"}}


def filters(
    q: str | None = Query(default=None, max_length=120, description="Nom ou numéro"),
    kind: UserKind | None = Query(default=None, description="client, delegated_payer, team"),
    account_status: AccountStatus | None = Query(default=None, alias="status"),
) -> dict:
    return {"q": q, "kind": kind, "account_status": account_status}


@admin_route(
    router,
    "GET",
    "",
    Permission.STAFF,
    response_model=AdminUserList,
    summary="Utilisateurs (A2) : recherche, filtres, impayés, dernière connexion",
    description="Recherche par nom ou par numéro (au moins 3 chiffres). `kind` : client, "
    "delegated_payer (payeur actif dans au moins un foyer), team. Numéros masqués pour le "
    "support. Les plus récents d'abord. Pagination : `page`, `size`.",
)
def list_users(
    params: PageParams = Depends(page_params),
    chosen: dict = Depends(filters),
    viewer: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> AdminUserList:
    return AdminUsers(db).list(viewer, params, **chosen)


@admin_route(
    router,
    "GET",
    "/export.csv",
    Permission.ADMIN,
    response_class=Response,
    summary="Exporter les utilisateurs en CSV (mêmes filtres que la liste)",
    description="UTF-8, séparateur « ; » (Excel en français). 10 000 lignes au plus "
    "(`422 EXPORT_TOO_LARGE` sinon). Sortie de données personnelles : inscrite au journal.",
    responses={200: {"content": {"text/csv": {}}, "description": "Le fichier CSV"}},
)
def export_users(
    chosen: dict = Depends(filters),
    viewer: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> Response:
    content = AdminUsers(db).export_csv(viewer, context, **chosen)
    return Response(
        content="﻿" + content,  # BOM : Excel lit correctement les accents
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": 'attachment; filename="utilisateurs-elecpay.csv"',
            "Cache-Control": "private, no-store",
        },
    )


@admin_route(
    router,
    "GET",
    "/{user_id}",
    Permission.STAFF,
    response_model=AdminUserDetail,
    summary="Détail d'un utilisateur (A3)",
    description="Identité, foyers et compteurs, transactions récentes, résumé financier, "
    "sessions ouvertes, journal du compte, motif de la dernière désactivation.",
    responses=NOT_FOUND,
)
def user_detail(
    user_id: int, viewer: User = Depends(current_user), db: Session = Depends(get_db)
) -> AdminUserDetail:
    return AdminUsers(db).detail(viewer, user_id)


@admin_route(
    router,
    "POST",
    "/{user_id}/deactivate",
    Permission.ADMIN,
    response_model=AccountChange,
    summary="Désactiver un compte (motif obligatoire ; ferme toutes ses sessions)",
    description="Factures et historique conservés ; réactivable. Personne ne se désactive "
    "soi-même ; seul un super admin agit sur un compte de l'équipe. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def deactivate(
    user_id: int,
    data: DeactivateRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> AccountChange:
    return AdminUsers(db).deactivate(actor, user_id, data.reason, context, settings)


@admin_route(
    router,
    "POST",
    "/{user_id}/reactivate",
    Permission.ADMIN,
    response_model=AccountChange,
    summary="Réactiver un compte",
    responses=NOT_FOUND | REFUSED,
)
def reactivate(
    user_id: int,
    data: ReactivateRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AccountChange:
    return AdminUsers(db).reactivate(actor, user_id, data.reason, context)


@admin_route(
    router,
    "POST",
    "/{user_id}/reset-code",
    Permission.ADMIN,
    response_model=ResetCodeSent,
    summary="Envoyer à l'utilisateur un code de réinitialisation du mot de passe (SMS)",
    description="Le code part par SMS au titulaire du compte ; il n'est jamais montré à "
    "l'équipe ni écrit au journal (seul l'envoi y figure).",
    responses=NOT_FOUND | REFUSED,
)
def send_reset_code(
    user_id: int,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
    sms: SmsSender = Depends(get_sms_sender),
) -> ResetCodeSent:
    return AdminUsers(db).send_reset_code(actor, user_id, context, settings, sms)
