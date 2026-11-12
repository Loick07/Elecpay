"""Routes des compteurs. Aucune logique ici : tout est dans `MeterService`."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.rate_limit import Limit, RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.billing_sources.base import BillingSource
from app.integrations.billing_sources.factory import get_billing_source
from app.integrations.consumption_sources.base import ConsumptionSource
from app.integrations.consumption_sources.factory import get_consumption_source
from app.modules.auth.dependencies import current_user
from app.modules.meters.schemas import MeterAddRequest, MeterAddResponse, MeterDetail, MeterUpdate
from app.modules.meters.service import MeterService
from app.modules.users.models import User

router = APIRouter(tags=["Compteurs"])

# Chaque ajout interroge E²C : on évite qu'on essaie des références à la chaîne.
METER_ADDS_PER_USER = Limit(10, 3600)
NOT_FOUND = {404: {"model": ErrorResponse, "description": "Foyer ou compteur introuvable"}}
OWNER_ONLY = {403: {"model": ErrorResponse, "description": "Réservé au propriétaire du foyer"}}


@router.get(
    "/households/{household_id}/meters",
    response_model=list[MeterDetail],
    summary="Compteurs d'un foyer",
    responses=NOT_FOUND,
)
def list_meters(
    household_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> list[MeterDetail]:
    return MeterService(db).list_for_household(user, household_id)


@router.post(
    "/households/{household_id}/meters",
    response_model=MeterAddResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter un compteur (N° branchement + N° client, vérifiés chez E²C)",
    description="En mode démo, 18 mois d'historique simulé sont importés "
    '(`history.source = "simulated"`).',
    responses=NOT_FOUND
    | OWNER_ONLY
    | {
        409: {"model": ErrorResponse, "description": "Déjà rattaché, ou limite atteinte"},
        429: {"model": ErrorResponse, "description": "Trop d'ajouts en peu de temps"},
    },
)
def add_meter(
    household_id: int,
    data: MeterAddRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    billing: BillingSource = Depends(get_billing_source),
    consumption: ConsumptionSource = Depends(get_consumption_source),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> MeterAddResponse:
    limiter.consume(f"meter-add:user:{user.id}", METER_ADDS_PER_USER)
    return MeterService(db).add(user, household_id, data, billing, consumption, context)


@router.get(
    "/meters/{meter_id}",
    response_model=MeterDetail,
    summary="Détail d'un compteur",
    responses=NOT_FOUND,
)
def read_meter(
    meter_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> MeterDetail:
    return MeterService(db).detail(user, meter_id)


@router.patch(
    "/meters/{meter_id}",
    response_model=MeterDetail,
    summary="Renommer un compteur (propriétaire)",
    responses=NOT_FOUND | OWNER_ONLY,
)
def rename_meter(
    meter_id: int,
    data: MeterUpdate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> MeterDetail:
    return MeterService(db).rename(user, meter_id, data, context)
