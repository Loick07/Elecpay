"""Routes du journal d'activité (A10) : lecture seule, admin et super admin."""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.db.session import get_db
from app.modules.admin.journal import AdminJournal
from app.modules.admin.journal_schemas import ActorKind, DomainCount, JournalPage
from app.modules.admin.permissions import Permission, admin_route

router = APIRouter(prefix="/audit-logs")


@admin_route(
    router,
    "GET",
    "",
    Permission.ADMIN,
    response_model=JournalPage,
    summary="Journal d'activité (A10) : toutes les actions sensibles, les plus récentes d'abord",
    description="Filtres : `domain` (premier mot de l'action : bill, payment, user…), "
    "`action` exacte, `actor` (team, client, system), `actor_id`, `entity_type` + "
    "`entity_id`, `from` / `to` (dates incluses, heure de Brazzaville). Chaque ligne : "
    "avant / après, IP, navigateur. Ni modifiable ni supprimable (aucune route, et la base "
    "l'interdit).",
    responses={422: {"model": ErrorResponse, "description": "Filtres invalides"}},
)
def list_journal(
    params: PageParams = Depends(page_params),
    domain: str | None = Query(default=None, max_length=32, pattern=r"^[a-z_]+$"),
    action: str | None = Query(default=None, max_length=64, pattern=r"^[a-z_]+[.][a-z_]+$"),
    actor: ActorKind | None = Query(default=None),
    actor_id: int | None = Query(default=None, gt=0),
    entity_type: str | None = Query(default=None, max_length=64),
    entity_id: int | None = Query(default=None, gt=0),
    date_from: date | None = Query(default=None, alias="from"),
    date_to: date | None = Query(default=None, alias="to"),
    db: Session = Depends(get_db),
) -> JournalPage:
    return AdminJournal(db).list(
        params,
        domain=domain,
        action=action,
        actor_kind=actor,
        actor_id=actor_id,
        entity_type=entity_type,
        entity_id=entity_id,
        date_from=date_from,
        date_to=date_to,
    )


@admin_route(
    router,
    "GET",
    "/domains",
    Permission.ADMIN,
    response_model=list[DomainCount],
    summary="Types d'actions présents dans le journal (filtres de l'écran A10)",
)
def list_domains(db: Session = Depends(get_db)) -> list[DomainCount]:
    return AdminJournal(db).domains()
