"""Routes des notifications. Aucune logique ici : tout est dans `NotificationQueries`."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.db.session import get_db
from app.modules.auth.dependencies import current_user
from app.modules.notifications.preferences import get_preferences, update_preferences
from app.modules.notifications.queries import NotificationQueries
from app.modules.notifications.schemas import (
    NotificationList,
    NotificationPreferences,
    NotificationPublic,
    PreferencesUpdate,
    ReadAllResult,
    UnreadCount,
)
from app.modules.users.models import User

router = APIRouter(prefix="/notifications", tags=["Notifications"])
preferences_router = APIRouter(prefix="/me/notification-preferences", tags=["Notifications"])


@preferences_router.get(
    "",
    response_model=NotificationPreferences,
    summary="Mes interrupteurs « Me prévenir » (écran 14)",
    description="Par défaut : échéances et paiements activés, consommation inhabituelle "
    "désactivée. Les autres messages sont toujours envoyés.",
)
def my_preferences(
    user: User = Depends(current_user), db: Session = Depends(get_db)
) -> NotificationPreferences:
    return get_preferences(db, user)


@preferences_router.patch(
    "",
    response_model=NotificationPreferences,
    summary="Changer un ou plusieurs interrupteurs",
    description="Seuls les interrupteurs envoyés changent. Une alerte désactivée n'est plus "
    "créée du tout (rien ne s'accumule en secret).",
)
def change_preferences(
    changes: PreferencesUpdate,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> NotificationPreferences:
    return update_preferences(db, user, changes)


@router.get(
    "",
    response_model=NotificationList,
    summary="Mes notifications (écran 13), de la plus récente à la plus ancienne",
    description="`group` : `today`, `this_week` (depuis lundi), `earlier` — heure de "
    "Brazzaville. `data` permet d'ouvrir le bon écran (facture, paiement, reçu…). "
    "`unread_count` : non lues, tous filtres confondus. Pagination : `page`, `size`.",
)
def list_notifications(
    params: PageParams = Depends(page_params),
    unread_only: bool = Query(default=False, description="Seulement les non lues"),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> NotificationList:
    return NotificationQueries(db).list(user, params, unread_only=unread_only)


@router.get(
    "/unread-count",
    response_model=UnreadCount,
    summary="Nombre de notifications non lues (badge de la cloche)",
)
def unread_count(user: User = Depends(current_user), db: Session = Depends(get_db)) -> UnreadCount:
    return UnreadCount(unread_count=NotificationQueries(db).unread_count(user))


@router.post(
    "/read-all",
    response_model=ReadAllResult,
    summary="Tout marquer comme lu",
)
def read_all(user: User = Depends(current_user), db: Session = Depends(get_db)) -> ReadAllResult:
    return NotificationQueries(db).mark_all_read(user)


@router.post(
    "/{notification_id}/read",
    response_model=NotificationPublic,
    summary="Marquer une notification comme lue (sans effet si elle l'est déjà)",
    responses={404: {"model": ErrorResponse, "description": "Notification introuvable"}},
)
def read_one(
    notification_id: int, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> NotificationPublic:
    return NotificationQueries(db).mark_read(user, notification_id)
