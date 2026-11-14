"""Point d'entrée de l'API ElecPay.

Lancer en développement (depuis backend/) :  uvicorn app.main:app --reload
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import API_PREFIX, Settings, get_settings
from app.core.errors import ErrorResponse, register_error_handlers
from app.core.rate_limit import RateLimiter
from app.modules.admin.router import router as admin_router
from app.modules.auth.router import router as auth_router
from app.modules.auth.web_router import router as auth_web_router
from app.modules.bills.router import router as bills_router
from app.modules.consumption.readings_router import router as readings_router
from app.modules.consumption.router import router as consumption_router
from app.modules.health.router import router as health_router
from app.modules.households.router import invitations_router
from app.modules.households.router import router as households_router
from app.modules.meters.router import router as meters_router
from app.modules.notifications.router import preferences_router as notification_prefs_router
from app.modules.notifications.router import router as notifications_router
from app.modules.payments.router import router as payments_router
from app.modules.payments.router import webhooks_router as payment_webhooks_router
from app.modules.receipts.router import router as receipts_router
from app.modules.users.router import router as users_router

API_VERSION = "0.1.0"


def create_app(settings: Settings | None = None) -> FastAPI:
    """Construit l'application. `settings` permet aux tests d'imposer leur configuration."""
    settings = settings or get_settings()

    app = FastAPI(
        title="ElecPay API",
        version=API_VERSION,
        description=(
            "API commune de l'application client et du back-office ElecPay.\n\n"
            + ("**Mode démo** : données simulées." if settings.demo_mode else "")
        ),
        # Toute route peut renvoyer une erreur au format commun : on le documente partout.
        responses={
            422: {"model": ErrorResponse, "description": "Données invalides"},
            500: {"model": ErrorResponse, "description": "Erreur interne"},
        },
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,  # cookies httpOnly du back-office
        allow_methods=["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "X-CSRF-Token"],
    )

    register_error_handlers(app)
    # Compteurs de tentatives propres à cette application (voir app/core/rate_limit.py).
    app.state.rate_limiter = RateLimiter()
    # Les routes qui dépendent de get_settings reçoivent la même configuration que l'app.
    app.dependency_overrides[get_settings] = lambda: settings

    app.include_router(health_router, prefix=API_PREFIX)
    app.include_router(auth_router, prefix=API_PREFIX)
    app.include_router(auth_web_router, prefix=API_PREFIX)
    app.include_router(users_router, prefix=API_PREFIX)
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
