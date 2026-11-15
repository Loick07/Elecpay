"""Informations sur la requête utiles au journal d'audit, aux sessions et aux limites.

IP du client (B11.1) : l'adresse de la connexion, SAUF si elle vient d'un proxy inverse de
confiance (`TRUSTED_PROXIES`) : on lit alors `X-Forwarded-For` de droite à gauche et on garde
la première adresse qui n'est pas un proxy de confiance. Sans proxy configuré, l'en-tête est
ignoré : un client ne peut pas se faire passer pour une autre IP (et contourner les limites).
"""

from collections.abc import Sequence
from dataclasses import dataclass
from ipaddress import IPv4Network, IPv6Network, ip_address

from fastapi import Request

USER_AGENT_MAX_LENGTH = 255
IP_MAX_LENGTH = 45  # IPv6 complète

Network = IPv4Network | IPv6Network


@dataclass(frozen=True, slots=True)
class RequestContext:
    ip: str | None
    user_agent: str | None


def _trusted(address: str, networks: Sequence[Network]) -> bool:
    try:
        ip = ip_address(address)
    except ValueError:
        return False
    return any(ip in network for network in networks)


def resolve_client_ip(
    peer: str | None, forwarded_for: str | None, networks: Sequence[Network]
) -> str | None:
    """IP réelle du client (voir le module). Une valeur invalide dans l'en-tête l'invalide."""
    if peer is None or not networks or not forwarded_for or not _trusted(peer, networks):
        return peer
    hops = [hop.strip() for hop in forwarded_for.split(",") if hop.strip()]
    for hop in reversed(hops):
        try:
            ip_address(hop)
        except ValueError:
            return peer  # en-tête mal formé : on ne lui fait pas confiance
        if not _trusted(hop, networks):
            return hop
    return hops[0] if hops else peer  # toute la chaîne est de confiance


def client_ip(request: Request) -> str | None:
    settings = getattr(request.app.state, "settings", None)
    networks = settings.trusted_networks if settings is not None else ()
    peer = request.client.host if request.client else None
    ip = resolve_client_ip(peer, request.headers.get("x-forwarded-for"), networks)
    return ip[:IP_MAX_LENGTH] if ip else None


def request_context(request: Request) -> RequestContext:
    """Dépendance FastAPI : adresse IP réelle et navigateur / application du client."""
    user_agent = request.headers.get("user-agent")
    return RequestContext(
        ip=client_ip(request),
        user_agent=user_agent[:USER_AGENT_MAX_LENGTH] if user_agent else None,
    )
