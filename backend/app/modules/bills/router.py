"""Routes des factures de l'abonné. Aucune logique ici : tout est dans `BillQueries`."""

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.db.session import get_db
from app.modules.auth.dependencies import current_user
from app.modules.bills.queries import BillQueries
from app.modules.bills.schemas import BillDetail, BillFilter, BillList
from app.modules.users.models import User

router = APIRouter(prefix="/bills", tags=["Factures"])


@router.get(
    "",
    response_model=BillList,
    summary="Mes factures (tous mes foyers), de la plus récente à la plus ancienne",
    description="Sans `status` : toutes les factures sauf les annulées. "
    "`to_pay` = impayées, en retard et en cours de paiement. "
    "Une facture impayée dont l'échéance est dépassée est renvoyée `overdue`. "
    "`outstanding` (reste à payer) tient compte de `household_id` et `meter_id`, "
    "pas de `status` ni de `year`. Pagination : `page`, `size` (≤ 100).",
    responses={404: {"model": ErrorResponse, "description": "Foyer ou compteur introuvable"}},
)
def list_bills(
    params: PageParams = Depends(page_params),
    status: BillFilter | None = Query(default=None, description="Filtre de l'écran"),
    meter_id: int | None = Query(default=None, ge=1),
    household_id: int | None = Query(default=None, ge=1),
    year: int | None = Query(
        default=None, ge=2000, le=2100, description="Année du début de la période"
    ),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> BillList:
    return BillQueries(db).list(
        user, params, status=status, meter_id=meter_id, household_id=household_id, year=year
    )


@router.get(
    "/{bill_id}",
    response_model=BillDetail,
    summary="Détail d'une facture : lignes, index, tarif, comparaison avec la précédente",
    description="Les lignes reprennent la facture E²C (troncature au FCFA à chaque ligne). "
    "Une facture annulée reste consultable avec son motif.",
    responses={404: {"model": ErrorResponse, "description": "Facture introuvable"}},
)
def bill_detail(
    bill_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> BillDetail:
    return BillQueries(db).detail(user, bill_id)


@router.get(
    "/{bill_id}/pdf",
    response_class=Response,
    summary="Facture en PDF (copie d'information, mention « mode démo » si simulée)",
    description="Mêmes accès que le détail. Le PDF est généré à la demande "
    "(`Content-Disposition: attachment`). Il n'est jamais présenté comme la facture "
    "officielle E²C.",
    responses={
        200: {"content": {"application/pdf": {}}, "description": "Le fichier PDF"},
        404: {"model": ErrorResponse, "description": "Facture introuvable"},
    },
)
def bill_pdf(
    bill_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Response:
    filename, content = BillQueries(db).pdf(user, bill_id, demo_mode=settings.demo_mode)
    return Response(
        content=content,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Cache-Control": "private, no-store",  # document personnel
        },
    )
