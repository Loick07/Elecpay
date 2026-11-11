"""Route de santé : l'API est-elle en vie, et la base répond-elle ?"""

from typing import Literal

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import database_is_reachable, get_db

router = APIRouter(tags=["Santé"])


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"]
    database: Literal["ok", "error"]
    demo_mode: bool


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="État de l'API et de la base de données",
    responses={503: {"model": HealthResponse, "description": "Base de données injoignable"}},
)
def health(
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> HealthResponse:
    database_ok = database_is_reachable(db)
    if not database_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return HealthResponse(
        status="ok" if database_ok else "degraded",
        database="ok" if database_ok else "error",
        demo_mode=settings.demo_mode,
    )
