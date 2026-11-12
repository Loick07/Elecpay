"""Routes de la consommation. Aucune logique ici : tout est dans `ConsumptionService`."""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.db.session import get_db
from app.modules.auth.dependencies import current_user
from app.modules.consumption.aggregation import Granularity
from app.modules.consumption.schemas import (
    Comparison,
    ConsumptionSeries,
    ConsumptionSummary,
    DayDetail,
)
from app.modules.consumption.service import ConsumptionService
from app.modules.users.models import User

router = APIRouter(prefix="/meters/{meter_id}/consumption", tags=["Consommation"])


@router.get(
    "",
    response_model=ConsumptionSeries,
    summary="Consommation agrégée par période (kWh et coût estimé)",
    description="Valeurs relevées (jamais en temps réel) jusqu'à `measured_until`. "
    "Par défaut : l'année en cours en mois ; comparaison avec l'an dernier "
    "(ou avec la période précédente pour les vues jour et semaine).",
    responses={
        400: {"model": ErrorResponse, "description": "Plage de dates invalide ou trop longue"},
        404: {"model": ErrorResponse, "description": "Compteur introuvable"},
    },
)
def consumption_series(
    meter_id: int,
    granularity: Granularity = Granularity.MONTH,
    start: date | None = Query(default=None, alias="from", description="Premier jour (inclus)"),
    end: date | None = Query(default=None, alias="to", description="Dernier jour (inclus)"),
    compare: Comparison | None = None,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> ConsumptionSeries:
    return ConsumptionService(db, settings).series(user, meter_id, granularity, start, end, compare)


@router.get(
    "/summary",
    response_model=ConsumptionSummary,
    summary="Résumé : ce mois, le mois dernier, la variation, l'estimation de fin de mois",
    description="L'estimation de fin de mois est une ESTIMATION (consommation relevée + "
    "moyenne journalière × jours restants) ; `basis` dit sur quelles journées elle repose.",
    responses={404: {"model": ErrorResponse, "description": "Compteur introuvable"}},
)
def consumption_summary(
    meter_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> ConsumptionSummary:
    return ConsumptionService(db, settings).summary(user, meter_id)


@router.get(
    "/days/{day}",
    response_model=DayDetail,
    summary="Détail d'une journée : index, coût, moyenne du même jour, classement dans le mois",
    responses={
        404: {"model": ErrorResponse, "description": "Compteur introuvable ou journée non relevée"}
    },
)
def consumption_day(
    meter_id: int,
    day: date,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> DayDetail:
    return ConsumptionService(db, settings).day_detail(user, meter_id, day)
