"""Authentification du back-office (mode navigateur) : jetons dans des cookies httpOnly.

Réservé à l'équipe (support, admin, super admin). Les clients utilisent l'application mobile.
Mêmes limites de tentatives que la connexion mobile (compteurs partagés).
"""

from fastapi import APIRouter, Depends, Request, Response, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.rate_limit import RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.auth.cookies import (
    REFRESH_COOKIE,
    clear_session_cookies,
    set_session_cookies,
    verify_csrf,
)
from app.modules.auth.errors import NotAuthenticatedError
from app.modules.auth.router import TOO_MANY, login_with_limits
from app.modules.auth.schemas import LoginRequest, WebSessionResponse
from app.modules.auth.service import AuthService
from app.modules.auth.sessions import IssuedTokens
from app.modules.users.models import UserRole
from app.modules.users.schemas import UserPublic

router = APIRouter(prefix="/auth/web", tags=["Authentification back-office"])

TEAM_ROLES = frozenset({UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN})


def web_session(issued: IssuedTokens, response: Response, settings: Settings) -> WebSessionResponse:
    set_session_cookies(response, issued, settings)
    return WebSessionResponse(
        access_expires_at=issued.access_expires_at,
        refresh_expires_at=issued.refresh_expires_at,
        user=UserPublic.model_validate(issued.user),
    )


@router.post(
    "/login",
    response_model=WebSessionResponse,
    summary="Connexion au back-office (cookies httpOnly)",
    description="Dépose les cookies `elecpay_access`, `elecpay_refresh` (httpOnly) et "
    "`elecpay_csrf` (à recopier dans l'en-tête `X-CSRF-Token` des requêtes qui modifient).",
    responses={
        401: {"model": ErrorResponse, "description": "Numéro ou mot de passe incorrect"},
        403: {"model": ErrorResponse, "description": "Compte désactivé, ou réservé à l'équipe"},
        429: TOO_MANY,
    },
)
def web_login(
    data: LoginRequest,
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> WebSessionResponse:
    issued = login_with_limits(data, db, settings, context, limiter, allowed_roles=TEAM_ROLES)
    return web_session(issued, response, settings)


@router.post(
    "/refresh",
    response_model=WebSessionResponse,
    summary="Rafraîchir la session du back-office",
    description="Lit le cookie `elecpay_refresh` ; exige l'en-tête `X-CSRF-Token`.",
    responses={
        401: {"model": ErrorResponse, "description": "Session absente, expirée ou révoquée"},
        403: {"model": ErrorResponse, "description": "Jeton CSRF invalide ou compte désactivé"},
    },
)
def web_refresh(
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> WebSessionResponse:
    verify_csrf(request)
    refresh_token = request.cookies.get(REFRESH_COOKIE)
    if not refresh_token:
        raise NotAuthenticatedError()
    issued = AuthService(db, settings).refresh(refresh_token, context.user_agent)
    return web_session(issued, response, settings)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Déconnexion du back-office",
    description="Révoque la session et efface les cookies ; exige l'en-tête `X-CSRF-Token`.",
    responses={403: {"model": ErrorResponse, "description": "Jeton CSRF invalide"}},
)
def web_logout(
    request: Request,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Response:
    verify_csrf(request)  # sinon, un autre site pourrait déconnecter un administrateur
    refresh_token = request.cookies.get(REFRESH_COOKIE)
    if refresh_token:
        AuthService(db, settings).logout(refresh_token)
    response = Response(status_code=status.HTTP_204_NO_CONTENT)
    clear_session_cookies(response, settings)
    return response
