"""Erreurs de la facturation.

Les erreurs d'émission (`BillingError`) disent précisément pourquoi une facture ne peut pas
être émise ; le relevé quotidien les affiche, l'administration (B10) les renverra telles quelles.
"""

from fastapi import status

from app.core.errors import AppError


class BillNotFoundError(AppError):
    """Facture inexistante OU d'un foyer auquel on n'a pas accès (même réponse : rien n'est
    révélé)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "BILL_NOT_FOUND"
    message = "Facture introuvable."


class BillingError(AppError):
    """Une facture ne peut pas être émise pour ce compteur et cette période."""

    status_code = status.HTTP_409_CONFLICT
    code = "BILLING_ERROR"
    message = "La facture ne peut pas être émise."


class InvalidBillingPeriodError(BillingError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "BILLING_PERIOD_INVALID"
    message = "Cette date n'est pas le début d'une période de facturation."


class BillingPeriodNotClosedError(BillingError):
    code = "BILLING_PERIOD_NOT_CLOSED"
    message = "La période n'est pas terminée ou sa date d'émission n'est pas encore arrivée."


class BillingPeriodCancelledError(BillingError):
    """La facture de cette période a été annulée : la refacturer relève de l'administration."""

    code = "BILLING_PERIOD_CANCELLED"
    message = "La facture de cette période a été annulée : elle n'est pas réémise automatiquement."


class BillingNothingToReissueError(BillingError):
    code = "BILLING_NOTHING_TO_REISSUE"
    message = "Aucune facture annulée pour cette période : rien à réémettre."


class NoTariffError(BillingError):
    code = "NO_TARIFF"
    message = "Aucun tarif en vigueur au début de la période."


class BillingReadingMissingError(BillingError):
    code = "BILLING_READING_MISSING"
    message = "Relevé de facturation manquant."


class BillingReadingAnomalyError(BillingError):
    code = "BILLING_READING_ANOMALY"
    message = "Relevé de facturation en anomalie."


class BillingReadingsMismatchError(BillingError):
    code = "BILLING_READINGS_MISMATCH"
    message = "Les relevés journaliers ne correspondent pas aux index de facturation."


class BillSequenceExhaustedError(BillingError):
    code = "BILL_SEQUENCE_EXHAUSTED"
    message = "Plus aucun numéro de facture disponible."
