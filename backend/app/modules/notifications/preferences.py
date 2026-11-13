"""Préférences d'alertes de l'utilisateur (B9.2, interrupteurs « Me prévenir » de l'écran 14)."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.notifications.models import NotificationPreference
from app.modules.notifications.schemas import NotificationPreferences, PreferencesUpdate
from app.modules.notifications.service import preferences_of
from app.modules.users.models import User


def get_preferences(session: Session, user: User) -> NotificationPreferences:
    return NotificationPreferences(**preferences_of(session, [user.id])[user.id])


def update_preferences(
    session: Session, user: User, changes: PreferencesUpdate
) -> NotificationPreferences:
    """Change seulement les interrupteurs envoyés (la ligne est créée au premier réglage)."""
    preference = session.scalars(
        select(NotificationPreference).where(NotificationPreference.user_id == user.id)
    ).first()
    if preference is None:
        current = preferences_of(session, [user.id])[user.id]
        preference = NotificationPreference(user_id=user.id, **current)
        session.add(preference)
    for switch, value in changes.model_dump(exclude_unset=True).items():
        setattr(preference, switch, value)
    session.commit()
    return get_preferences(session, user)
