"""Routes de l'écran Compteurs du back-office (A4). Logique : `AdminMeters`."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.admin.meters import AdminMeters
from app.modules.admin.meters_schemas import (
    AdminMeterDetail,
    AdminMeterList,
    AnomalyHandled,
    AttachRequest,
    ControlRequest,
    DetachRequest,
    DismissRequest,
    MeterLink,
    TodayStatus,
)
from app.modules.admin.permissions import Permission, admin_route
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter(prefix="/meters")
NOT_FOUND = {404: {"model": ErrorResponse, "description": "Compteur, relevé ou foyer introuvable"}}
REFUSED = {409: {"model": ErrorResponse, "description": "Action impossible sur ce compteur"}}


@admin_route(
    router,
    "GET",
    "",
    Permission.STAFF,
    response_model=AdminMeterList,
    summary="Compteurs (A4) : état du jour, anomalies, compteurs inactifs",
    description="`today` : received, anomaly, missing (actif et rattaché sans relevé ce "
    "matin), inactive (suspendu, résilié ou détaché). `attached` : true / false. Recherche "
    "par N° de branchement, N° client, nom du compteur, du foyer ou du titulaire. Les "
    "compteurs du haut de l'écran ignorent les filtres. Heure de Brazzaville ; énergies en Wh.",
)
def list_meters(
    params: PageParams = Depends(page_params),
    q: str | None = Query(default=None, max_length=120),
    today: TodayStatus | None = Query(default=None),
    attached: bool | None = Query(default=None),
    db: Session = Depends(get_db),
) -> AdminMeterList:
    return AdminMeters(db).list(params, q=q, today_status=today, attached=attached)


@admin_route(
    router,
    "GET",
    "/{meter_id}",
    Permission.STAFF,
    response_model=AdminMeterDetail,
    summary="Détail d'un compteur (A4, panneau)",
    description="Index d'hier et d'aujourd'hui, explication, foyer, dernière facture, "
    "anomalies non classées, 14 derniers relevés.",
    responses=NOT_FOUND,
)
def meter_detail(meter_id: int, db: Session = Depends(get_db)) -> AdminMeterDetail:
    return AdminMeters(db).detail(meter_id)


@admin_route(
    router,
    "POST",
    "/{meter_id}/anomalies/{reading_id}/control",
    Permission.ADMIN,
    response_model=AnomalyHandled,
    summary="Demander un relevé de contrôle pour une anomalie",
    description="Note facultative. Le relevé n'est pas modifié (il reste exclu des "
    "factures) ; la demande est notée (auteur, date) et inscrite au journal.",
    responses=NOT_FOUND | REFUSED,
)
def request_control(
    meter_id: int,
    reading_id: int,
    data: ControlRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AnomalyHandled:
    return AdminMeters(db).request_control(actor, meter_id, reading_id, data.note, context)


@admin_route(
    router,
    "POST",
    "/{meter_id}/anomalies/{reading_id}/dismiss",
    Permission.ADMIN,
    response_model=AnomalyHandled,
    summary="Classer une anomalie sans suite (note obligatoire)",
    description="Possible aussi après une demande de contrôle. Le relevé reste gardé et "
    "exclu des factures. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def dismiss_anomaly(
    meter_id: int,
    reading_id: int,
    data: DismissRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> AnomalyHandled:
    return AdminMeters(db).dismiss(actor, meter_id, reading_id, data.note, context)


@admin_route(
    router,
    "POST",
    "/{meter_id}/detach",
    Permission.ADMIN,
    response_model=MeterLink,
    summary="Détacher un compteur de son foyer (motif obligatoire)",
    description="Relevés et factures restent attachés au compteur. Refusé si un paiement "
    "est en cours sur l'une de ses factures. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def detach_meter(
    meter_id: int,
    data: DetachRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> MeterLink:
    return AdminMeters(db).detach(actor, meter_id, data.reason, context)


@admin_route(
    router,
    "POST",
    "/{meter_id}/attach",
    Permission.ADMIN,
    response_model=MeterLink,
    summary="Rattacher un compteur détaché à un foyer (motif obligatoire)",
    description="5 compteurs au plus par foyer. Refusé si un paiement est en cours sur "
    "l'une de ses factures. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def attach_meter(
    meter_id: int,
    data: AttachRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> MeterLink:
    return AdminMeters(db).attach(actor, meter_id, data.household_id, data.reason, context)
