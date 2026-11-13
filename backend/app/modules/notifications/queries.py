"""Lecture des notifications par leur destinataire (B9.1, écran client 13).

- Chacun ne voit que SES notifications ; celle d'un autre répond comme une inexistante (404).
- Une notification n'apparaît qu'à partir de sa date (`created_at`) : certaines sont datées de
  l'événement qu'elles annoncent (rappel de retard à 9 h, rattrapage du relevé quotidien…).
- Tri par date de l'événement (`created_at`), jamais par `id` : l'ordre d'écriture ne suit pas
  toujours l'ordre des événements (seed, rattrapage).
- Groupes en heure de Brazzaville : aujourd'hui, cette semaine (depuis lundi), plus tôt.
- Marquer comme lu est idempotent : la première date de lecture est gardée.
"""

from collections.abc import Callable
from datetime import datetime, timedelta

from sqlalchemy import ColumnElement, func, select, update
from sqlalchemy.orm import Session

from app.core.pagination import PageParams, paginate
from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.modules.notifications.errors import NotificationNotFoundError
from app.modules.notifications.models import Notification
from app.modules.notifications.schemas import (
    NotificationGroup,
    NotificationList,
    NotificationPublic,
    ReadAllResult,
)
from app.modules.users.models import User


def group_of(created_at: datetime, now: datetime) -> NotificationGroup:
    today = local_date(now)
    if created_at >= local_midnight_utc(today):
        return NotificationGroup.TODAY
    monday = today - timedelta(days=today.weekday())
    if created_at >= local_midnight_utc(monday):
        return NotificationGroup.THIS_WEEK
    return NotificationGroup.EARLIER


def to_public(notification: Notification, now: datetime) -> NotificationPublic:
    return NotificationPublic(
        id=notification.id,
        type=notification.type,
        title=notification.title,
        body=notification.body,
        data=notification.data_json,
        created_at=notification.created_at,
        read_at=notification.read_at,
        is_read=notification.read_at is not None,
        group=group_of(notification.created_at, now),
    )


class NotificationQueries:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    def list(
        self, user: User, params: PageParams, *, unread_only: bool = False
    ) -> NotificationList:
        now = self.now()
        conditions = self._visible(user, now)
        if unread_only:
            conditions.append(Notification.read_at.is_(None))
        query = (
            select(Notification)
            .where(*conditions)
            .order_by(Notification.created_at.desc(), Notification.id.desc())
        )
        page = paginate(self.session, query, params, lambda row: to_public(row, now))
        return NotificationList(**page.model_dump(), unread_count=self._unread(user, now))

    def unread_count(self, user: User) -> int:
        return self._unread(user, self.now())

    def mark_read(self, user: User, notification_id: int) -> NotificationPublic:
        now = self.now()
        notification = self.session.scalars(
            select(Notification).where(
                Notification.id == notification_id, *self._visible(user, now)
            )
        ).first()
        if notification is None:
            raise NotificationNotFoundError()
        if notification.read_at is None:
            notification.read_at = now
            self.session.commit()
        return to_public(notification, now)

    def mark_all_read(self, user: User) -> ReadAllResult:
        now = self.now()
        result = self.session.execute(
            update(Notification)
            .where(*self._visible(user, now), Notification.read_at.is_(None))
            .values(read_at=now, updated_at=now)
        )
        self.session.commit()
        return ReadAllResult(marked=result.rowcount, unread_count=self._unread(user, now))

    # --- Outils --------------------------------------------------------------------------------

    @staticmethod
    def _visible(user: User, now: datetime) -> list[ColumnElement[bool]]:
        return [Notification.user_id == user.id, Notification.created_at <= now]

    def _unread(self, user: User, now: datetime) -> int:
        return self.session.scalar(
            select(func.count())
            .select_from(Notification)
            .where(*self._visible(user, now), Notification.read_at.is_(None))
        )
