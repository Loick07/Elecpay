"""Erreurs des reçus."""

from fastapi import status

from app.core.errors import AppError


class ReceiptNotFoundError(AppError):
    """Reçu inexistant ou d'un foyer auquel on n'a pas accès (même réponse)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "RECEIPT_NOT_FOUND"
    message = "Reçu introuvable."


class UnknownVerificationCodeError(AppError):
    """Vérification publique : aucun reçu ne porte ce code (ou code mal formé)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "RECEIPT_CODE_UNKNOWN"
    message = "Aucun reçu ElecPay ne correspond à ce code. Vérifiez la saisie."
