"""Jetons du back-office transportés dans des cookies (mode navigateur).

- `elecpay_access`  : jeton d'accès. httpOnly → illisible par le JavaScript de la page
                      (une faille XSS ne peut pas le voler). Envoyé sur toute l'API.
- `elecpay_refresh` : jeton de rafraîchissement. httpOnly, et envoyé UNIQUEMENT aux routes
                      /auth/web/* (refresh, logout) : jamais exposé ailleurs.
- `elecpay_csrf`    : jeton anti-CSRF, LISIBLE par le JavaScript, qui doit le recopier dans
                      l'en-tête `X-CSRF-Token` de chaque requête qui modifie des données.
                      Un site malveillant peut faire envoyer les cookies, mais pas les lire :
                      il ne peut donc pas fournir le bon en-tête (« double cookie »).
Tous : SameSite=Strict (jamais envoyés depuis un autre site) et Secure (HTTPS).
"""

import hmac
import secrets

from fastapi import Request, Response

from app.core.config import API_PREFIX, Settings
from app.modules.auth.errors import CsrfError
from app.modules.auth.sessions import IssuedTokens

ACCESS_COOKIE = "elecpay_access"
REFRESH_COOKIE = "elecpay_refresh"
CSRF_COOKIE = "elecpay_csrf"
CSRF_HEADER = "X-CSRF-Token"

ACCESS_COOKIE_PATH = API_PREFIX
REFRESH_COOKIE_PATH = f"{API_PREFIX}/auth/web"
CSRF_COOKIE_PATH = "/"

SAFE_METHODS = frozenset({"GET", "HEAD", "OPTIONS"})  # ne modifient rien : pas de contrôle CSRF


def set_session_cookies(response: Response, issued: IssuedTokens, settings: Settings) -> None:
    """Dépose les trois cookies après une connexion ou un rafraîchissement."""
    common = {"secure": settings.auth_cookie_secure, "samesite": "strict"}
    response.set_cookie(
        ACCESS_COOKIE,
        issued.access_token,
        max_age=settings.access_token_minutes * 60,
        path=ACCESS_COOKIE_PATH,
        httponly=True,
        **common,
    )
    refresh_max_age = settings.refresh_token_days * 24 * 3600
    response.set_cookie(
        REFRESH_COOKIE,
        issued.refresh_token,
        max_age=refresh_max_age,
        path=REFRESH_COOKIE_PATH,
        httponly=True,
        **common,
    )
    response.set_cookie(
        CSRF_COOKIE,
        secrets.token_urlsafe(32),  # renouvelé à chaque connexion / rafraîchissement
        max_age=refresh_max_age,
        path=CSRF_COOKIE_PATH,
        httponly=False,  # volontaire : le JavaScript du back-office doit pouvoir le lire
        **common,
    )


def clear_session_cookies(response: Response, settings: Settings) -> None:
    """Efface les trois cookies (déconnexion). Mêmes chemin et attributs qu'à la création."""
    for name, path, httponly in (
        (ACCESS_COOKIE, ACCESS_COOKIE_PATH, True),
        (REFRESH_COOKIE, REFRESH_COOKIE_PATH, True),
        (CSRF_COOKIE, CSRF_COOKIE_PATH, False),
    ):
        response.delete_cookie(
            name,
            path=path,
            secure=settings.auth_cookie_secure,
            httponly=httponly,
            samesite="strict",
        )


def verify_csrf(request: Request) -> None:
    """Exige un en-tête X-CSRF-Token identique au cookie elecpay_csrf."""
    header = request.headers.get(CSRF_HEADER)
    cookie = request.cookies.get(CSRF_COOKIE)
    if not header or not cookie or not hmac.compare_digest(header, cookie):
        raise CsrfError()
