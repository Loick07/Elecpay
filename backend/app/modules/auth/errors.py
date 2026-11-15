"""Erreurs de l'authentification (codes stables, utilisés par l'app mobile et le back-office).

Règle anti-énumération : un numéro inconnu et un mauvais mot de passe donnent exactement
la même erreur (INVALID_CREDENTIALS). « Compte désactivé » n'est révélé qu'après un mot
de passe correct.
"""

from fastapi import status

from app.core.errors import AppError

BEARER_CHALLENGE = {"WWW-Authenticate": "Bearer"}


class InvalidCredentialsError(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "INVALID_CREDENTIALS"
    message = "Numéro ou mot de passe incorrect."


class AccountDisabledError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "ACCOUNT_DISABLED"
    message = "Ce compte est désactivé. Contactez l'assistance ElecPay."


class NotAuthenticatedError(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "NOT_AUTHENTICATED"
    message = "Authentification requise."

    def __init__(self, message: str | None = None, **kwargs) -> None:
        super().__init__(message, headers=BEARER_CHALLENGE, **kwargs)


class TokenExpiredError(NotAuthenticatedError):
    code = "TOKEN_EXPIRED"
    message = "Session expirée : reconnectez-vous ou rafraîchissez votre jeton."


class TokenInvalidError(NotAuthenticatedError):
    code = "TOKEN_INVALID"
    message = "Jeton invalide."


class RefreshTokenReusedError(NotAuthenticatedError):
    """Un jeton déjà utilisé a été présenté : vol probable, toute la famille est révoquée."""

    code = "REFRESH_TOKEN_REUSED"
    message = "Session révoquée par sécurité. Reconnectez-vous."


class InsufficientRoleError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "FORBIDDEN"
    message = "Vous n'avez pas les droits nécessaires pour cette action."


class CsrfError(AppError):
    """Requête du back-office qui modifie des données sans le bon jeton anti-CSRF."""

    status_code = status.HTTP_403_FORBIDDEN
    code = "CSRF_INVALID"
    message = "Requête refusée par sécurité (jeton CSRF absent ou invalide). Rechargez la page."


class PhoneAlreadyUsedError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "PHONE_ALREADY_USED"
    message = "Ce numéro est déjà utilisé par un compte."


class EmailAlreadyUsedError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "EMAIL_ALREADY_USED"
    message = "Cette adresse e-mail est déjà utilisée par un compte."


class WrongCurrentPasswordError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "WRONG_CURRENT_PASSWORD"
    message = "Mot de passe actuel incorrect."


class SamePasswordError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "SAME_PASSWORD"
    message = "Le nouveau mot de passe doit être différent de l'actuel."


class TwoFactorCodeInvalidError(AppError):
    """Code faux, déjà utilisé ou code de secours inconnu : une seule erreur, volontairement."""

    status_code = status.HTTP_401_UNAUTHORIZED
    code = "TWO_FACTOR_CODE_INVALID"
    message = "Code de vérification incorrect."


class TwoFactorChallengeInvalidError(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "TWO_FACTOR_CHALLENGE_INVALID"
    message = "Étape de connexion expirée : saisissez à nouveau votre mot de passe."


class TwoFactorSetupRequiredError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "TWO_FACTOR_SETUP_REQUIRED"
    message = (
        "Activez la double authentification pour accéder au back-office (Paramètres > Sécurité)."
    )


class TwoFactorStateError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "TWO_FACTOR_STATE"
    message = "Action impossible dans l'état actuel de la double authentification."


class TwoFactorRequiredForRoleError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "TWO_FACTOR_REQUIRED_FOR_ROLE"
    message = "La double authentification est obligatoire pour votre rôle."


class ResetCodeInvalidError(AppError):
    """Code faux, expiré, déjà utilisé ou trop d'essais : une seule erreur, volontairement."""

    status_code = status.HTTP_400_BAD_REQUEST
    code = "RESET_CODE_INVALID"
    message = "Code invalide ou expiré. Demandez un nouveau code."
