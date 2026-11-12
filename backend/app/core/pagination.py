"""Pagination commune de l'API (format du plan) :

    GET …?page=1&size=20  →  {"items": [...], "total": 132, "page": 1, "size": 20}

Une page au-delà de la fin renvoie une liste vide (pas une erreur) : l'application s'arrête
quand `items` est vide ou quand page × size ≥ total.
"""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from fastapi import Query
from pydantic import BaseModel
from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100


class Page[T](BaseModel):
    items: list[T]
    total: int
    page: int
    size: int


@dataclass(frozen=True, slots=True)
class PageParams:
    page: int
    size: int

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


def page_params(
    page: int = Query(default=1, ge=1, description="Numéro de page (à partir de 1)"),
    size: int = Query(
        default=DEFAULT_PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE, description="Éléments par page"
    ),
) -> PageParams:
    """Dépendance FastAPI : `?page=&size=` validés (taille limitée à 100)."""
    return PageParams(page=page, size=size)


def paginate[T](
    session: Session,
    query: Select[Any],
    params: PageParams,
    to_item: Callable[[Any], T],
) -> Page[T]:
    """Exécute `query` (déjà triée) pour une page, et compte le total sans le tri."""
    total = session.scalar(select(func.count()).select_from(query.order_by(None).subquery()))
    rows = session.scalars(query.limit(params.size).offset(params.offset)).all()
    return Page[T](
        items=[to_item(row) for row in rows], total=total, page=params.page, size=params.size
    )
