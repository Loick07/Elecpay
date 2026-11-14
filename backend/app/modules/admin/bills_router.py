"""Routes des écrans Factures du back-office (A5, A6). Logique : `AdminBills`."""

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.admin.bills import AdminBills
from app.modules.admin.bills_schemas import (
    AdminBillDetail,
    AdminBillFilter,
    AdminBillList,
    BillCancelled,
    BillReissued,
    CancelRequest,
    ReissueRequest,
)
from app.modules.admin.permissions import Permission, admin_route
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter(prefix="/bills")
NOT_FOUND = {404: {"model": ErrorResponse, "description": "Facture introuvable"}}
REFUSED = {409: {"model": ErrorResponse, "description": "Action impossible sur cette facture"}}
MONTH = r"^\d{4}-(0[1-9]|1[0-2])$"


def filters(
    q: str | None = Query(
        default=None, max_length=120, description="N° de facture, compteur, N° client, foyer, nom"
    ),
    bill_status: AdminBillFilter | None = Query(default=None, alias="status"),
    month: str | None = Query(default=None, pattern=MONTH, description="Mois d'émission AAAA-MM"),
    meter_id: int | None = Query(default=None, gt=0),
) -> dict:
    return {"q": q, "bill_status": bill_status, "month": month, "meter_id": meter_id}


@admin_route(
    router,
    "GET",
    "",
    Permission.STAFF,
    response_model=AdminBillList,
    summary="Factures (A5) : totaux du mois, filtres, recherche",
    description="`status` : unpaid (échéance pas encore dépassée), overdue, pending_payment, "
    "paid, cancelled. `month` (AAAA-MM) filtre sur le mois d'émission ; les totaux portent "
    "sur ce mois, ou sur le mois en cours sans filtre. Les plus récentes d'abord.",
)
def list_bills(
    params: PageParams = Depends(page_params),
    chosen: dict = Depends(filters),
    db: Session = Depends(get_db),
) -> AdminBillList:
    return AdminBills(db).list(params, **chosen)


@admin_route(
    router,
    "GET",
    "/export.csv",
    Permission.ADMIN,
    response_class=Response,
    summary="Exporter les factures en CSV (mêmes filtres que la liste)",
    description="UTF-8, séparateur « ; ». 10 000 lignes au plus (`422 EXPORT_TOO_LARGE` "
    "sinon). Inscrit au journal.",
    responses={200: {"content": {"text/csv": {}}, "description": "Le fichier CSV"}},
)
def export_bills(
    chosen: dict = Depends(filters),
    viewer: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> Response:
    content = AdminBills(db).export_csv(viewer, context, **chosen)
    return Response(
        content="﻿" + content,  # BOM : Excel lit correctement les accents
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": 'attachment; filename="factures-elecpay.csv"',
            "Cache-Control": "private, no-store",
        },
    )


@admin_route(
    router,
    "GET",
    "/{bill_id}",
    Permission.STAFF,
    response_model=AdminBillDetail,
    summary="Détail d'une facture (A6)",
    description="Lignes, période, index, tarif appliqué, source des relevés, payeurs "
    "autorisés, transactions liées (numéros masqués), historique, facture remplacée ou "
    "de remplacement. Montants jamais modifiables.",
    responses=NOT_FOUND,
)
def bill_detail(
    bill_id: int, viewer: User = Depends(current_user), db: Session = Depends(get_db)
) -> AdminBillDetail:
    return AdminBills(db).detail(viewer, bill_id)


@admin_route(
    router,
    "POST",
    "/{bill_id}/cancel",
    Permission.ADMIN,
    response_model=BillCancelled,
    summary="Annuler une facture (motif d'au moins 10 caractères)",
    description="Jamais de suppression. Refusé si la facture est payée, déjà annulée ou si "
    "un paiement est en cours. La période peut ensuite être réémise. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def cancel_bill(
    bill_id: int,
    data: CancelRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> BillCancelled:
    return AdminBills(db).cancel(actor, bill_id, data.reason, context)


@admin_route(
    router,
    "POST",
    "/{bill_id}/reissue",
    Permission.ADMIN,
    response_model=BillReissued,
    summary="Réémettre la période d'une facture annulée",
    description="Nouvelle facture calculée avec les relevés de facturation actuels et le tarif "
    "du début de période ; nouveau numéro, émise aujourd'hui, échéance dans 15 jours. Le "
    "titulaire et les payeurs délégués sont prévenus. Erreurs de facturation renvoyées "
    "telles quelles (relevé manquant, en anomalie…). Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def reissue_bill(
    bill_id: int,
    data: ReissueRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
    settings: Settings = Depends(get_settings),
) -> BillReissued:
    return AdminBills(db).reissue(actor, bill_id, data.reason, context, settings)
