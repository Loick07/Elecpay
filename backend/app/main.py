"""Point d'entrée de l'API ElecPay.

Lancer en développement (depuis backend/) :  uvicorn app.main:app --reload
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import API_PREFIX, Settings, get_settings
from app.core.errors import ErrorResponse, install_error_guard, register_error_handlers
from app.core.http_security import install_http_security, install_security_headers
from app.core.logs import REQUEST_ID_HEADER, configure_logging, install_request_logging
from app.core.rate_limit import RateLimiter
from app.modules.admin.router import router as admin_router
from app.modules.auth.router import router as auth_router
from app.modules.auth.two_factor_router import router as two_factor_router
from app.modules.auth.web_router import router as auth_web_router
from app.modules.bills.router import router as bills_router
from app.modules.consumption.readings_router import router as readings_router
from app.modules.consumption.router import router as consumption_router
from app.modules.emails.router import router as email_router
from app.modules.health.router import router as health_router
from app.modules.households.router import invitations_router
from app.modules.households.router import router as households_router
from app.modules.meters.router import router as meters_router
from app.modules.notifications.router import preferences_router as notification_prefs_router
from app.modules.notifications.router import router as notifications_router
from app.modules.payments.router import router as payments_router
from app.modules.payments.router import webhooks_router as payment_webhooks_router
from app.modules.payments.tracking import StatusCheckThrottle
from app.modules.receipts.router import router as receipts_router
from app.modules.users.router import router as users_router

API_VERSION = "0.1.0"


def create_app(settings: Settings | None = None) -> FastAPI:
    """Construit l'application. `settings` permet aux tests d'imposer leur configuration."""
    settings = settings or get_settings()

    app = FastAPI(
        title="ElecPay API",
        version=API_VERSION,
        # Description FIXE : le contrat exporté (backend/openapi.json) ne dépend d'aucun réglage.
        description=(
            "API commune de l'application client et du back-office ElecPay.\n\n"
            "Mode démo (données simulées, aucun débit réel) : voir `demo_mode` dans "
            "`GET /api/v1/health`, et le champ `source` des factures et des reçus."
        ),
        # Toute route peut renvoyer une erreur au format commun : on le documente partout.
        responses={
            422: {"model": ErrorResponse, "description": "Données invalides"},
            500: {"model": ErrorResponse, "description": "Erreur interne"},
        },
    )

    # Ordre important (le dernier ajouté est le plus extérieur) : journal d'accès → en-têtes de
    # sécurité → CORS → limite globale par IP → routes. Voir app/core/http_security.py.
    install_error_guard(app)  # le plus intérieur : erreurs inattendues → 500 propre
    install_http_security(app, settings)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,  # cookies httpOnly du back-office
        allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "X-CSRF-Token"],
        # exports CSV et PDF ; limites ; identifiant à donner à l'assistance en cas de souci
        expose_headers=["Content-Disposition", "Retry-After", REQUEST_ID_HEADER],
        max_age=600,
    )
    install_security_headers(app, settings)
    install_request_logging(app)  # le plus extérieur : identifiant et durée de toute la requête
    configure_logging(settings)

    register_error_handlers(app)
    # Configuration et compteurs de tentatives propres à cette application.
    app.state.settings = settings
    app.state.rate_limiter = RateLimiter()
    # Demandes d'état au prestataire pendant le suivi d'un paiement : 1 toutes les 5 s (B11.5).
    app.state.status_check_throttle = StatusCheckThrottle()
    # Les routes qui dépendent de get_settings reçoivent la même configuration que l'app.
    app.dependency_overrides[get_settings] = lambda: settings

    app.include_router(health_router, prefix=API_PREFIX)
    app.include_router(auth_router, prefix=API_PREFIX)
    app.include_router(auth_web_router, prefix=API_PREFIX)
    app.include_router(two_factor_router, prefix=API_PREFIX)
    app.include_router(users_router, prefix=API_PREFIX)
    app.include_router(email_router, prefix=API_PREFIX)
    app.include_router(households_router, prefix=API_PREFIX)
    app.include_router(invitations_router, prefix=API_PREFIX)
    app.include_router(meters_router, prefix=API_PREFIX)
    app.include_router(consumption_router, prefix=API_PREFIX)
    app.include_router(readings_router, prefix=API_PREFIX)
    app.include_router(bills_router, prefix=API_PREFIX)
    app.include_router(payments_router, prefix=API_PREFIX)
    app.include_router(payment_webhooks_router, prefix=API_PREFIX)
    app.include_router(receipts_router, prefix=API_PREFIX)
    app.include_router(notifications_router, prefix=API_PREFIX)
    app.include_router(notification_prefs_router, prefix=API_PREFIX)
    app.include_router(admin_router, prefix=API_PREFIX)

    return app


app = create_app()
