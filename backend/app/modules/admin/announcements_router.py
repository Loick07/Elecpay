"""Routes de l'écran Notifications du back-office (A9). Logique : `AdminAnnouncements`."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.admin.announcements import AdminAnnouncements
from app.modules.admin.announcements_schemas import (
    AlertSettingsPublic,
    AlertSettingsUpdate,
    AnnouncementCreate,
    AnnouncementList,
    AnnouncementRow,
    AudiencePreview,
    DistrictLine,
)
from app.modules.admin.permissions import Permission, admin_route
from app.modules.announcements.models import Audience
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter()
REFUSED = {
    409: {"model": ErrorResponse, "description": "Action impossible sur cette annonce"},
    422: {"model": ErrorResponse, "description": "Cible ou programmation refusée"},
}


@admin_route(
    router,
    "GET",
    "/announcements",
    Permission.STAFF,
    response_model=AnnouncementList,
    summary="Annonces envoyées ou programmées, avec leur taux de lecture (A9)",
)
def list_announcements(
    params: PageParams = Depends(page_params), db: Session = Depends(get_db)
) -> AnnouncementList:
    return AdminAnnouncements(db).list(params)


@admin_route(
    router,
    "GET",
    "/announcements/audience",
    Permission.STAFF,
    response_model=AudiencePreview,
    summary="Nombre de destinataires d'une cible, si l'annonce partait maintenant",
    responses=REFUSED,
)
def preview_audience(
    audience: Audience = Query(),
    district: str | None = Query(default=None, max_length=80),
    user_id: int | None = Query(default=None, gt=0),
    db: Session = Depends(get_db),
) -> AudiencePreview:
    return AdminAnnouncements(db).preview(audience, district, user_id)


@admin_route(
    router,
    "GET",
    "/announcements/districts",
    Permission.STAFF,
    response_model=list[DistrictLine],
    summary="Quartiers connus (choix de la cible « un quartier »)",
)
def list_districts(db: Session = Depends(get_db)) -> list[DistrictLine]:
    return AdminAnnouncements(db).districts()


@admin_route(
    router,
    "POST",
    "/announcements",
    Permission.ADMIN,
    response_model=AnnouncementRow,
    status_code=201,
    summary="Envoyer ou programmer une annonce",
    description="Cibles : all (tous les clients), overdue (foyers ayant une facture en "
    "retard : titulaires et payeurs délégués), district (tous les membres des foyers du "
    "quartier), client. Sans `scheduled_at` : envoi immédiat (refusé s'il n'y a aucun "
    "destinataire). Avec : programmée (5 min à 90 jours), envoyée par la tâche "
    "`scripts.send_announcements` ; les destinataires sont alors calculés à l'envoi. Une "
    "notification « announcement » par personne, que l'abonné ne peut pas couper. Push : "
    "phase 2. Inscrit au journal.",
    responses=REFUSED,
)
def create_announcement(
    data: AnnouncementCreate,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AnnouncementRow:
    return AdminAnnouncements(db).create(actor, data, context)


@admin_route(
    router,
    "POST",
    "/announcements/{announcement_id}/cancel",
    Permission.ADMIN,
    response_model=AnnouncementRow,
    summary="Annuler une annonce programmée (pas encore envoyée)",
    responses=REFUSED | {404: {"model": ErrorResponse, "description": "Annonce introuvable"}},
)
def cancel_announcement(
    announcement_id: int,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AnnouncementRow:
    return AdminAnnouncements(db).cancel(actor, announcement_id, context)


@admin_route(
    router,
    "GET",
    "/alert-settings",
    Permission.STAFF,
    response_model=AlertSettingsPublic,
    summary="Alertes automatiques : lesquelles sont activées pour toute la plateforme (A9)",
)
def get_alert_settings(db: Session = Depends(get_db)) -> AlertSettingsPublic:
    return AdminAnnouncements(db).alert_settings()


@admin_route(
    router,
    "PUT",
    "/alert-settings",
    Permission.ADMIN,
    response_model=AlertSettingsPublic,
    summary="Activer ou couper une alerte automatique pour toute la plateforme",
    description="Rappels d'échéance, avis et rappels de retard, consommation inhabituelle. "
    "Couper une alerte n'arrête que les notifications : une facture échue passe quand même "
    "« en retard ». Les réglages de chaque abonné (écran 14) s'appliquent en plus. Inscrit "
    "au journal.",
)
def update_alert_settings(
    data: AlertSettingsUpdate,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AlertSettingsPublic:
    return AdminAnnouncements(db).update_alert_settings(actor, data, context)
