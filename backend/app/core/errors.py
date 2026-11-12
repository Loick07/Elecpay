"""Erreurs de l'API, toujours renvoyées au même format :

    {"error": {"code": "BILL_ALREADY_PAID", "message": "...", "details": {...}}}

Le `code` est stable (le mobile et l'admin s'en servent), le `message` est lisible en français.
Aucun détail technique (trace, requête SQL, valeur saisie) n'est jamais renvoyé au client.
"""

import logging
from http import HTTPStatus
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("elecpay.errors")


class ErrorBody(BaseModel):
    code: str
    message: str
    details: dict[str, Any] = {}


class ErrorResponse(BaseModel):
    """Format de toutes les erreurs (documenté dans OpenAPI)."""

    error: ErrorBody


class AppError(Exception):
    """Erreur métier prévue. Les services lèvent des sous-classes ou des instances de celle-ci."""

    status_code: int = status.HTTP_400_BAD_REQUEST
    code: str = "BAD_REQUEST"
    message: str = "Requête invalide."

    def __init__(
        self,
        message: str | None = None,
        *,
        code: str | None = None,
        status_code: int | None = None,
        details: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        self.message = message or self.message
        self.code = code or self.code
        self.status_code = status_code or self.status_code
        self.details = details or {}
        # En-têtes HTTP à joindre, ex. Retry-After (429) ou WWW-Authenticate (401).
        self.headers = headers
        super().__init__(self.message)


class TooManyAttemptsError(AppError):
    """Limite de tentatives atteinte (429). Indique combien de secondes attendre."""

    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    code = "TOO_MANY_ATTEMPTS"
    message = "Trop de tentatives. Réessayez dans quelques minutes."

    def __init__(self, retry_after_seconds: int, message: str | None = None) -> None:
        super().__init__(
            message,
            details={"retry_after_seconds": retry_after_seconds},
            headers={"Retry-After": str(retry_after_seconds)},
        )


# Codes et messages pour les erreurs HTTP produites par FastAPI lui-même (route inconnue, etc.).
HTTP_ERRORS: dict[int, tuple[str, str]] = {
    400: ("BAD_REQUEST", "Requête invalide."),
    401: ("UNAUTHORIZED", "Authentification requise."),
    403: ("FORBIDDEN", "Accès refusé."),
    404: ("NOT_FOUND", "Ressource introuvable."),
    405: ("METHOD_NOT_ALLOWED", "Méthode non autorisée sur cette route."),
    429: ("TOO_MANY_REQUESTS", "Trop de requêtes, réessayez plus tard."),
}


def error_response(
    status_code: int,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    body = ErrorResponse(error=ErrorBody(code=code, message=message, details=details or {}))
    return JSONResponse(status_code=status_code, content=jsonable_encoder(body), headers=headers)


async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
    return error_response(exc.status_code, exc.code, exc.message, exc.details, exc.headers)


async def handle_http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    if exc.status_code in HTTP_ERRORS:
        code, message = HTTP_ERRORS[exc.status_code]
    else:
        known = exc.status_code in {s.value for s in HTTPStatus}
        code = HTTPStatus(exc.status_code).name if known else "HTTP_ERROR"
        message = "Erreur."
    return error_response(exc.status_code, code, message, headers=exc.headers)


async def handle_validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
    # On ne renvoie PAS la valeur saisie ("input") : elle peut contenir un mot de passe.
    fields = [
        {
            "field": ".".join(str(part) for part in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
        }
        for error in exc.errors()
    ]
    return error_response(
        status.HTTP_422_UNPROCESSABLE_CONTENT,
        "VALIDATION_ERROR",
        "Les données envoyées sont invalides.",
        {"fields": fields},
    )


async def handle_unexpected_error(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Erreur inattendue sur %s %s", request.method, request.url.path)
    return error_response(
        status.HTTP_500_INTERNAL_SERVER_ERROR,
        "INTERNAL_ERROR",
        "Une erreur interne est survenue. Réessayez plus tard.",
    )


def register_error_handlers(app: FastAPI) -> None:
    # Starlette type ces handlers avec `Exception` ; chacun reçoit bien le type enregistré.
    app.add_exception_handler(AppError, handle_app_error)  # type: ignore[arg-type]
    app.add_exception_handler(StarletteHTTPException, handle_http_error)  # type: ignore[arg-type]
    app.add_exception_handler(RequestValidationError, handle_validation_error)  # type: ignore[arg-type]
    app.add_exception_handler(Exception, handle_unexpected_error)
