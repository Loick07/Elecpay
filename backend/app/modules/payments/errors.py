"""Erreurs des paiements (format commun : code stable + message en français)."""

from fastapi import status

from app.core.errors import AppError


class PaymentForbiddenError(AppError):
    """Lecteur du foyer : il voit la facture, mais ne peut pas la payer."""

    status_code = status.HTTP_403_FORBIDDEN
    code = "PAYMENT_FORBIDDEN"
    message = "Seuls le titulaire du foyer et ses payeurs délégués peuvent payer cette facture."


class BillAlreadyPaidError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "BILL_ALREADY_PAID"
    message = "Cette facture est déjà payée."


class BillNotPayableError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "BILL_NOT_PAYABLE"
    message = "Cette facture a été annulée : elle ne peut pas être payée."


class PaymentInProgressError(AppError):
    """Un paiement attend déjà la confirmation de l'opérateur (écran 9 : pas de 2e paiement)."""

    status_code = status.HTTP_409_CONFLICT
    code = "PAYMENT_IN_PROGRESS"
    message = "Un paiement de cette facture est déjà en cours : attendez sa confirmation."


class IdempotencyKeyReusedError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "IDEMPOTENCY_KEY_REUSED"
    message = "Cette clé d'idempotence a déjà servi pour une autre demande de paiement."


class PaymentNotFoundError(AppError):
    """Transaction inexistante ou d'un foyer auquel on n'a pas accès (même réponse)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "PAYMENT_NOT_FOUND"
    message = "Paiement introuvable."


class UnknownPaymentProviderError(AppError):
    """Webhook adressé à un prestataire qui n'est pas celui configuré."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "UNKNOWN_PAYMENT_PROVIDER"
    message = "Prestataire de paiement inconnu."


class OperatorMismatchError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "OPERATOR_MISMATCH"
    message = "Ce numéro ne correspond pas à l'opérateur choisi."


class NotMobileMoneyError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "PHONE_NOT_MOBILE_MONEY"
    message = "Ce numéro ne peut pas payer en Mobile Money (numéro fixe)."
