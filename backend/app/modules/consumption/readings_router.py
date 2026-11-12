"""Route des relevés bruts d'un compteur (paginés). Aucune logique ici."""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import Page, PageParams, page_params
from app.db.session import get_db
from app.modules.auth.dependencies import current_user
from app.modules.consumption.schemas import ReadingPublic
from app.modules.consumption.service import ConsumptionService
from app.modules.users.models import User

router = APIRouter(tags=["Consommation"])


@router.get(
    "/meters/{meter_id}/readings",
    response_model=Page[ReadingPublic],
    summary="Relevés bruts du compteur (du plus récent au plus ancien)",
    description="Filtres `from` / `to` : journée consommée. Pagination : `page`, `size` (≤ 100).",
    responses={
        400: {"model": ErrorResponse, "description": "Plage de dates invalide"},
        404: {"model": ErrorResponse, "description": "Compteur introuvable"},
    },
)
def meter_readings(
    meter_id: int,
    params: PageParams = Depends(page_params),
    start: date | None = Query(default=None, alias="from"),
    end: date | None = Query(default=None, alias="to"),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Page[ReadingPublic]:
    return ConsumptionService(db, settings).readings(user, meter_id, params, start, end)
