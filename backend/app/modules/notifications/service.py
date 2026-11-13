"""Création de notifications (utilisée par les services métier et par les simulateurs).

`insert_notifications` est le passage obligé de toute notification : c'est là que s'appliquent
les préférences « Me prévenir » de l'écran 14 (B9.2). Une alerte désactivée n'est pas créée.
Seules trois familles se coupent (décision du 13/11/2026) ; les autres messages sont toujours
envoyés.
"""

from collections.abc import Sequence
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import insert, select
from sqlalchemy.orm import Session

from app.modules.notifications.models import (
    Notification,
    NotificationPreference,
    NotificationType,
)

# Interrupteur de l'écran 14 → types de notification qu'il commande.
SWITCHES: dict[str, frozenset[NotificationType]] = {
    "due_soon": frozenset({NotificationType.BILL_DUE_SOON}),
    "payments": frozenset({NotificationType.PAYMENT_SUCCEEDED, NotificationType.PAYMENT_FAILED}),
    "high_consumption": frozenset({NotificationType.HIGH_CONSUMPTION}),
}
DEFAULTS: dict[str, bool] = {"due_soon": True, "payments": True, "high_consumption": False}
SWITCH_OF = {kind: switch for switch, kinds in SWITCHES.items() for kind in kinds}


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
    """Insertion groupée (sans valider : part avec la transaction de l'action).

    Les lignes que leur destinataire a désactivées (écran 14) sont écartées. Renvoie le nombre
    de notifications réellement créées.
    """
    wanted = _wanted(session, rows)
    if wanted:
        session.execute(insert(Notification), wanted)
    return len(wanted)


def preferences_of(session: Session, user_ids: Sequence[int]) -> dict[int, dict[str, bool]]:
    """Interrupteurs de chaque utilisateur (valeurs par défaut s'il n'a rien réglé)."""
    found = {
        preference.user_id: {switch: getattr(preference, switch) for switch in DEFAULTS}
        for preference in session.scalars(
            select(NotificationPreference).where(NotificationPreference.user_id.in_(user_ids))
        )
    }
    return {user_id: found.get(user_id, dict(DEFAULTS)) for user_id in user_ids}


def _wanted(session: Session, rows: Sequence[dict[str, Any]]) -> list[dict[str, Any]]:
    switchable = [row for row in rows if row["type"] in SWITCH_OF]
    if not switchable:
        return list(rows)
    preferences = preferences_of(session, sorted({row["user_id"] for row in switchable}))
    return [
        row
        for row in rows
        if row["type"] not in SWITCH_OF or preferences[row["user_id"]][SWITCH_OF[row["type"]]]
    ]
