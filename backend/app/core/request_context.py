"""Informations sur la requête utiles au journal d'audit et aux sessions."""

from dataclasses import dataclass

from fastapi import Request

USER_AGENT_MAX_LENGTH = 255
IP_MAX_LENGTH = 45  # IPv6 complète


@dataclass(frozen=True, slots=True)
class RequestContext:
    ip: str | None
    user_agent: str | None


def request_context(request: Request) -> RequestContext:
    """Dépendance FastAPI : adresse IP et navigateur / application du client.

    Derrière un proxy (déploiement), l'IP réelle viendra de X-Forwarded-For, configuré en B11.
    """
    user_agent = request.headers.get("user-agent")
    ip = request.client.host if request.client else None
    return RequestContext(
        ip=ip[:IP_MAX_LENGTH] if ip else None,
        user_agent=user_agent[:USER_AGENT_MAX_LENGTH] if user_agent else None,
    )
