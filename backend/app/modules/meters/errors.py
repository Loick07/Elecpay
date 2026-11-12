"""Erreurs de l'ajout et de la gestion des compteurs."""

from fastapi import status

from app.core.errors import AppError


class E2CMeterNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "E2C_METER_NOT_FOUND"
    message = (
        "Compteur introuvable chez E²C : vérifiez le N° de branchement et le N° client "
        "sur votre facture."
    )


class MeterAlreadyLinkedError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "METER_ALREADY_LINKED"
    message = (
        "Ce compteur est déjà rattaché à un foyer. S'il s'agit d'une erreur, "
        "contactez l'assistance ElecPay."
    )


class MeterLimitError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "METER_LIMIT_REACHED"
    message = "Nombre maximal de compteurs atteint pour ce foyer."
