"""Erreurs des notifications."""

from fastapi import status

from app.core.errors import AppError


class NotificationNotFoundError(AppError):
    """Notification inexistante ou destinée à quelqu'un d'autre (même réponse)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "NOTIFICATION_NOT_FOUND"
    message = "Notification introuvable."
