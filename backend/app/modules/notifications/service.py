"""Création de notifications (utilisée par les services métier et par les simulateurs).

Les routes de lecture (liste, lu / non lu, badge) arrivent en B9.
"""

from collections.abc import Sequence
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import insert
from sqlalchemy.orm import Session

from app.modules.notifications.models import Notification, NotificationType


def notification_row(
    user_id: int,
    kind: NotificationType,
    title: str,
    body: str,
    data: dict[str, Any] | None,
    *,
    at: datetime,
    read: bool = False,
) -> dict[str, Any]:
    """Une notification prête pour une insertion groupée, datée au moment de l'événement."""
    return {
        "user_id": user_id,
        "type": kind,
        "title": title,
        "body": body,
        "data_json": data,
        "read_at": at + timedelta(hours=2) if read else None,
        "created_at": at,
        "updated_at": at,
    }


def insert_notifications(session: Session, rows: Sequence[dict[str, Any]]) -> int:
    """Insertion groupée (sans valider : part avec la transaction de l'action)."""
    if rows:
        session.execute(insert(Notification), list(rows))
    return len(rows)
