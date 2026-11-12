"""Routes d'authentification.

La logique métier est dans les services (`AuthService`, `PasswordService`). Les routes
ajoutent seulement la limitation des tentatives, qui dépend de la requête (adresse IP).
"""

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.rate_limit import RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.sms.base import SmsSender
from app.integrations.sms.factory import get_sms_sender
from app.modules.auth import rate_limits as limits
from app.modules.auth.dependencies import current_user
from app.modules.auth.errors import InvalidCredentialsError
from app.modules.auth.passwords import RESET_CODE_TTL, PasswordService
from app.modules.auth.schemas import (
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LogoutAllResponse,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.modules.auth.service import AuthService
from app.modules.auth.sessions import IssuedTokens
from app.modules.users.models import User, UserRole
from app.modules.users.schemas import UserPublic

router = APIRouter(prefix="/auth", tags=["Authentification"])

TOO_MANY = {"model": ErrorResponse, "description": "Trop de tentatives (en-tête Retry-After)"}


def token_response(issued: IssuedTokens, settings: Settings) -> TokenResponse:
    return TokenResponse(
        access_token=issued.access_token,
        access_expires_at=issued.access_expires_at,
        expires_in=settings.access_token_minutes * 60,
        refresh_token=issued.refresh_token,
        refresh_expires_at=issued.refresh_expires_at,
        user=UserPublic.model_validate(issued.user),
    )


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Créer un compte client",
    responses={
        409: {"model": ErrorResponse, "description": "Numéro ou e-mail déjà utilisé"},
        429: TOO_MANY,
    },
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> TokenResponse:
    limiter.consume(limits.ip_key("register", context), limits.REGISTER_PER_IP)
    issued = AuthService(db, settings).register(data, context.user_agent)
    return token_response(issued, settings)


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Se connecter (téléphone + mot de passe)",
    responses={
        401: {"model": ErrorResponse, "description": "Numéro ou mot de passe incorrect"},
        403: {"model": ErrorResponse, "description": "Compte désactivé"},
        429: TOO_MANY,
    },
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> TokenResponse:
    issued = login_with_limits(data, db, settings, context, limiter)
    return token_response(issued, settings)


def login_with_limits(
    data: LoginRequest,
    db: Session,
    settings: Settings,
    context: RequestContext,
    limiter: RateLimiter,
    allowed_roles: frozenset[UserRole] | None = None,
) -> IssuedTokens:
    """Connexion avec les limites de tentatives (partagée par l'app mobile et le back-office :
    les mêmes compteurs s'appliquent, quel que soit le chemin)."""
    phone_key = limits.phone_key("login", data.phone)
    limiter.consume(limits.ip_key("login", context), limits.LOGIN_ATTEMPTS_PER_IP)
    # Le numéro est bloqué après 5 ÉCHECS, même si la 6e tentative a le bon mot de passe.
    limiter.check(phone_key, limits.LOGIN_FAILURES_PER_PHONE)
    try:
        issued = AuthService(db, settings).login(
            data.phone, data.password, context.user_agent, allowed_roles
        )
    except InvalidCredentialsError:
        limiter.record(phone_key, limits.LOGIN_FAILURES_PER_PHONE)
        raise
    limiter.reset(phone_key)  # une connexion réussie efface les échecs de ce numéro
    return issued


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Obtenir de nouveaux jetons (rotation du jeton de rafraîchissement)",
    responses={
        401: {
            "model": ErrorResponse,
            "description": "Jeton inconnu, expiré, ou déjà utilisé (REFRESH_TOKEN_REUSED : "
            "toutes les sessions de cette connexion sont fermées par sécurité)",
        },
        403: {"model": ErrorResponse, "description": "Compte désactivé"},
    },
)
def refresh(
    data: RefreshRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> TokenResponse:
    issued = AuthService(db, settings).refresh(data.refresh_token, context.user_agent)
    return token_response(issued, settings)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Se déconnecter de cet appareil",
    description="Révoque le jeton de rafraîchissement. Répond 204 même s'il est déjà invalide.",
)
def logout(
    data: RefreshRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Response:
    AuthService(db, settings).logout(data.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


FORGOT_MESSAGE = "Si ce numéro correspond à un compte, un code vient d'être envoyé par SMS."


@router.post(
    "/password/forgot",
    response_model=ForgotPasswordResponse,
    summary="Mot de passe oublié : recevoir un code par SMS",
    description="Répond toujours la même chose, que le numéro ait un compte ou non. "
    "En mode démo, le code est renvoyé dans `demo_code` (aucun SMS réel).",
    responses={429: TOO_MANY},
)
def forgot_password(
    data: ForgotPasswordRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> ForgotPasswordResponse:
    # Chaque code part par SMS (payant) : limite par IP ET par numéro visé.
    limiter.consume(limits.ip_key("forgot", context), limits.FORGOT_PER_IP)
    limiter.consume(limits.phone_key("forgot", data.phone), limits.FORGOT_PER_PHONE)
    code = PasswordService(db, settings, sms).request_reset(data.phone)
    return ForgotPasswordResponse(
        message=FORGOT_MESSAGE,
        expires_in=int(RESET_CODE_TTL.total_seconds()),
        demo_code=code if settings.demo_mode else None,
    )


@router.post(
    "/password/reset",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Choisir un nouveau mot de passe avec le code reçu",
    description="Déconnecte tous les appareils. Se reconnecter ensuite avec le nouveau mot.",
    responses={
        400: {"model": ErrorResponse, "description": "Code invalide ou expiré"},
        429: TOO_MANY,
    },
)
def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> Response:
    limiter.consume(limits.ip_key("reset", context), limits.RESET_ATTEMPTS_PER_IP)
    PasswordService(db, settings, sms).reset(data.phone, data.code, data.new_password, context)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/logout-all",
    response_model=LogoutAllResponse,
    summary="Déconnecter tous mes appareils",
    description="Le jeton d'accès en cours reste valable jusqu'à son expiration (15 min au plus).",
    responses={401: {"model": ErrorResponse, "description": "Non connecté"}},
)
def logout_all(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> LogoutAllResponse:
    revoked = AuthService(db, settings).logout_everywhere(user)
    return LogoutAllResponse(revoked_sessions=revoked)
