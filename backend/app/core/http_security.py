"""Protections appliquées à TOUTES les réponses de l'API (B11.1).

En-têtes de sécurité :
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`,
  `Permissions-Policy` (ni caméra, ni micro, ni position, ni paiement navigateur),
  `Cross-Origin-Opener-Policy: same-origin` ;
- `Content-Security-Policy` stricte (l'API ne sert que du JSON et des PDF), sauf sur la
  documentation `/docs` et `/redoc` : Swagger UI charge ses scripts depuis un CDN ;
- `Cache-Control: no-store` par défaut (réponses personnelles : factures, reçus, numéros…) ;
- `Strict-Transport-Security` en production (HTTPS imposé au navigateur pendant un an).

Limite globale : `RATE_LIMIT_PER_MINUTE` requêtes par IP réelle et par minute (300 par défaut),
en plus des limites propres à la connexion et à la vérification des reçus. Exemptés : la
santé de l'API (supervision), les webhooks des prestataires (signés, ne doivent jamais être
perdus) et les requêtes préliminaires CORS. Réponse 429 au format commun, avec `Retry-After`.
"""

from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request, Response, status

from app.core.config import API_PREFIX, Settings
from app.core.errors import TooManyAttemptsError, error_response
from app.core.rate_limit import Limit
from app.core.request_context import client_ip

API_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"
DOCS_PATHS = ("/docs", "/redoc")
BASE_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=()",
    "Cross-Origin-Opener-Policy": "same-origin",
}
HSTS = "max-age=31536000; includeSubDomains"
RATE_LIMIT_EXEMPT = (f"{API_PREFIX}/health", f"{API_PREFIX}/webhooks/")
WINDOW_SECONDS = 60

Handler = Callable[[Request], Awaitable[Response]]


def install_http_security(app: FastAPI, settings: Settings) -> None:
    """À appeler AVANT d'ajouter le CORS : l'ordre d'ajout fixe l'imbrication (le dernier
    ajouté est le plus extérieur). Résultat : en-têtes de sécurité (extérieur) → CORS →
    limite globale → routes. Un 429 porte donc les en-têtes CORS et de sécurité."""
    limit = Limit(settings.rate_limit_per_minute, WINDOW_SECONDS)

    @app.middleware("http")
    async def global_rate_limit(request: Request, call_next: Handler) -> Response:
        path = request.url.path
        exempt = request.method == "OPTIONS" or path.startswith(RATE_LIMIT_EXEMPT)
        if limit.max_events and not exempt:
            key = f"global:ip:{client_ip(request) or 'inconnue'}"
            try:
                request.app.state.rate_limiter.consume(key, limit)
            except TooManyAttemptsError as error:
                return error_response(
                    status.HTTP_429_TOO_MANY_REQUESTS,
                    "TOO_MANY_REQUESTS",
                    "Trop de requêtes depuis cette adresse. Réessayez dans un instant.",
                    error.details,
                    error.headers,
                )
        return await call_next(request)


def install_security_headers(app: FastAPI, settings: Settings) -> None:
    """À appeler APRÈS le CORS : en-têtes posés sur toutes les réponses, erreurs comprises."""

    @app.middleware("http")
    async def security_headers(request: Request, call_next: Handler) -> Response:
        response = await call_next(request)
        for name, value in BASE_HEADERS.items():
            response.headers.setdefault(name, value)
        if not request.url.path.startswith(DOCS_PATHS):
            response.headers.setdefault("Content-Security-Policy", API_CSP)
        response.headers.setdefault("Cache-Control", "no-store")
        if settings.is_production:
            response.headers.setdefault("Strict-Transport-Security", HSTS)
        return response
