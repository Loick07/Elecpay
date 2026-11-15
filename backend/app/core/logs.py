"""Journaux techniques de l'API (B11.2) : structurés, reliés à la requête, sans donnée sensible.

- Format : JSON (une ligne par événement, pour la supervision) en production, texte lisible en
  développement ; réglable avec `LOG_FORMAT`.
- Chaque requête reçoit un identifiant (`X-Request-ID` : repris du client s'il est sûr, sinon
  créé), renvoyé dans la réponse et présent sur chaque ligne écrite pendant la requête.
  Un client qui signale un problème donne cet identifiant ; l'équipe retrouve les lignes.
- Journal d'accès maison (méthode, chemin SANS les paramètres, statut, durée, IP réelle) :
  celui d'uvicorn est coupé, car il écrit l'adresse complète (`?q=0612…` = un numéro).
- Masquage de TOUT ce qui sort (messages et traces d'erreur, qui peuvent contenir une
  requête SQL et ses valeurs) : numéros de téléphone, jetons, mots de passe et secrets.
"""

import json
import logging
import re
import sys
import time
import uuid
from collections.abc import Awaitable, Callable
from contextvars import ContextVar
from datetime import UTC, datetime
from typing import Any

from fastapi import FastAPI, Request, Response

from app.core.config import Settings
from app.core.request_context import client_ip

REQUEST_ID_HEADER = "X-Request-ID"
SAFE_REQUEST_ID = re.compile(r"^[A-Za-z0-9._-]{8,64}$")
QUIET_PATHS = ("/api/v1/health",)  # interrogée sans arrêt par la supervision : niveau DEBUG

request_id_var: ContextVar[str | None] = ContextVar("request_id", default=None)

# --- Masquage -------------------------------------------------------------------------------

# Numéro congolais : +242 06 123 45 67 (séparateurs facultatifs) ou 06 123 45 67 / 061234567.
INTERNATIONAL_PHONE = re.compile(r"\+?242[\s.-]?(0[4-6])[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?(\d{2})")
LOCAL_PHONE = re.compile(r"(?<![\d+])(0[4-6])[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?(\d{2})(?!\d)")
JWT = re.compile(r"\beyJ[\w-]+\.[\w-]+\.[\w-]+")
BEARER = re.compile(r"(?i)\bbearer\s+\S+")
SECRET_FIELD = re.compile(
    r"(?i)([\"']?(?:password|new_password|current_password|password_hash|code_hash|"
    r"refresh_token|access_token|token|secret|jwt_secret|webhook_secret|api_key)[\"']?"
    r"\s*[:=]\s*)(\"[^\"]*\"|'[^']*'|[^\s,;)}]+)"
)


def redact(text: str) -> str:
    """Retire d'un texte tout ce qui ne doit jamais apparaître dans un journal."""
    text = JWT.sub("[jeton]", text)
    text = BEARER.sub("Bearer [jeton]", text)
    text = SECRET_FIELD.sub(r"\1[masqué]", text)
    text = INTERNATIONAL_PHONE.sub(r"+242 \1 *** ** \2", text)
    return LOCAL_PHONE.sub(r"\1 *** ** \2", text)


# --- Mise en forme --------------------------------------------------------------------------


class RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_var.get() or "-"
        return True


class TextFormatter(logging.Formatter):
    def __init__(self) -> None:
        super().__init__("%(asctime)s %(levelname)-7s %(name)s [%(request_id)s] %(message)s")

    def format(self, record: logging.LogRecord) -> str:
        return redact(super().format(record))


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        event: dict[str, Any] = {
            "time": datetime.fromtimestamp(record.created, UTC).isoformat(timespec="milliseconds"),
            "level": record.levelname,
            "logger": record.name,
            "request_id": getattr(record, "request_id", "-"),
            "message": record.getMessage(),
        }
        http = getattr(record, "http", None)
        if http:
            event["http"] = http
        if record.exc_info:
            event["error"] = self.formatException(record.exc_info)
        return redact(json.dumps(event, ensure_ascii=False, default=str))


HANDLER_NAME = "elecpay"


class StdoutHandler(logging.StreamHandler):
    """Écrit dans la sortie standard ACTUELLE (relue à chaque ligne), pas dans celle du moment
    de la configuration : la sortie peut être remplacée (outils de test, de supervision…)."""

    def __init__(self) -> None:
        super().__init__(sys.stdout)

    @property
    def stream(self):  # type: ignore[override]
        return sys.stdout

    @stream.setter
    def stream(self, value) -> None:
        pass  # toujours la sortie standard actuelle


def configure_logging(settings: Settings) -> None:
    """Installe (ou remplace) le gestionnaire ElecPay sur la racine. Idempotent."""
    use_json = settings.log_format == "json" or (
        settings.log_format is None and settings.is_production
    )
    handler = StdoutHandler()
    handler.set_name(HANDLER_NAME)
    handler.setFormatter(JsonFormatter() if use_json else TextFormatter())
    handler.addFilter(RequestIdFilter())
    root = logging.getLogger()
    for existing in list(root.handlers):
        if existing.get_name() == HANDLER_NAME:
            root.removeHandler(existing)
    root.addHandler(handler)
    root.setLevel(settings.log_level)
    # Le journal d'accès d'uvicorn écrit l'adresse complète (paramètres de recherche compris) :
    # remplacé par le nôtre. Ses autres messages passent par notre gestionnaire (masqués).
    logging.getLogger("uvicorn.access").disabled = True
    for name in ("uvicorn", "uvicorn.error"):
        uvicorn_logger = logging.getLogger(name)
        uvicorn_logger.handlers.clear()
        uvicorn_logger.propagate = True


# --- Identifiant de requête et journal d'accès ----------------------------------------------

access_logger = logging.getLogger("elecpay.http")
Handler = Callable[[Request], Awaitable[Response]]


def install_request_logging(app: FastAPI) -> None:
    """À ajouter EN DERNIER (middleware le plus extérieur) : l'identifiant existe pour toute
    la requête et la durée mesurée comprend tout le reste."""

    @app.middleware("http")
    async def request_logging(request: Request, call_next: Handler) -> Response:
        incoming = request.headers.get(REQUEST_ID_HEADER, "")
        request_id = incoming if SAFE_REQUEST_ID.match(incoming) else uuid.uuid4().hex
        token = request_id_var.set(request_id)
        started = time.perf_counter()
        try:
            try:
                response = await call_next(request)
            except Exception:
                _log_access(request, 500, started)  # l'erreur elle-même est déjà journalisée
                raise
            _log_access(request, response.status_code, started)
            response.headers[REQUEST_ID_HEADER] = request_id
            return response
        finally:
            request_id_var.reset(token)


def _log_access(request: Request, status: int, started: float) -> None:
    duration_ms = round((time.perf_counter() - started) * 1000, 1)
    path = request.url.path  # jamais les paramètres (recherche par numéro…)
    level = logging.DEBUG if path.startswith(QUIET_PATHS) else logging.INFO
    access_logger.log(
        level,
        "%s %s %s %.1f ms",
        request.method,
        path,
        status,
        duration_ms,
        extra={
            "http": {
                "method": request.method,
                "path": path,
                "status": status,
                "duration_ms": duration_ms,
                "ip": client_ip(request),
            }
        },
    )
