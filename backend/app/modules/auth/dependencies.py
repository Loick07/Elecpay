"""Gardiens des routes : qui est connecté, et a-t-il le bon rôle ?

@router.get("/me")
def me(user: User = Depends(current_user)): ...

@router.get("/admin/stats", dependencies=[Depends(require_role(UserRole.ADMIN))])
"""

from collections.abc import Callable

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.modules.auth.cookies import ACCESS_COOKIE, SAFE_METHODS, verify_csrf
from app.modules.auth.errors import (
    AccountDisabledError,
    InsufficientRoleError,
    NotAuthenticatedError,
    TokenInvalidError,
)
from app.modules.auth.tokens import decode_access_token
from app.modules.users.models import User, UserRole

# auto_error=False : on renvoie NOUS-MÊMES l'erreur, au format commun d'ElecPay.
# Ajoute aussi le bouton « Authorize » dans /docs.
bearer_scheme = HTTPBearer(auto_error=False, description="Jeton d'accès (POST /auth/login)")


def current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    """L'utilisateur du jeton d'accès. Toujours relu en base : un compte désactivé
    ou un rôle retiré prend effet immédiatement, sans attendre l'expiration du jeton.

    Deux façons de présenter le jeton :
    - en-tête `Authorization: Bearer …` (application mobile) ;
    - cookie `elecpay_access` (back-office) : toute requête qui modifie des données doit
      alors porter le bon `X-CSRF-Token`.
    """
    if credentials is not None:
        token = credentials.credentials
    else:
        token = request.cookies.get(ACCESS_COOKIE)
        if not token:
            raise NotAuthenticatedError()
        if request.method not in SAFE_METHODS:
            verify_csrf(request)
    claims = decode_access_token(token, secret=settings.jwt_secret.get_secret_value())
    user = db.get(User, claims.user_id)
    if user is None:
        raise TokenInvalidError()
    if not user.is_active:
        raise AccountDisabledError()
    return user


def require_role(*roles: UserRole) -> Callable[..., User]:
    """Dépendance qui n'accepte que les rôles donnés (contrôle côté serveur)."""
    allowed = frozenset(roles)

    def checker(user: User = Depends(current_user)) -> User:
        if user.role not in allowed:
            raise InsufficientRoleError()
        return user

    return checker
