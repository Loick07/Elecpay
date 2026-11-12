"""Jetons d'authentification.

- Jeton d'ACCÈS : JWT signé (HS256), courte durée (15 min). Présenté à chaque requête
  (en-tête `Authorization: Bearer …`). Vérifié sans base de données.
- Jeton de RAFRAÎCHISSEMENT : chaîne aléatoire opaque (pas un JWT), longue durée (30 j).
  Seule son empreinte SHA-256 est stockée ; il sert uniquement à obtenir de nouveaux jetons.
"""

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt

from app.modules.auth.errors import TokenExpiredError, TokenInvalidError

ALGORITHM = "HS256"  # imposé à la vérification : un jeton signé autrement est refusé
ISSUER = "elecpay-api"
ACCESS_TYPE = "access"
REFRESH_TOKEN_BYTES = 48  # → 64 caractères en base64 URL


@dataclass(frozen=True, slots=True)
class AccessClaims:
    """Ce que contient un jeton d'accès valide."""

    user_id: int
    role: str
    token_id: str  # identifiant unique (jti)
    issued_at: datetime
    expires_at: datetime


def create_access_token(
    user_id: int, role: str, *, secret: str, minutes: int, now: datetime | None = None
) -> tuple[str, datetime]:
    """Jeton d'accès signé et sa date d'expiration (UTC)."""
    issued_at = (now or datetime.now(UTC)).replace(microsecond=0)
    expires_at = issued_at + timedelta(minutes=minutes)
    payload = {
        "sub": str(user_id),  # la norme JWT veut une chaîne
        "role": role,
        "type": ACCESS_TYPE,
        "jti": uuid.uuid4().hex,
        "iss": ISSUER,
        "iat": issued_at,
        "exp": expires_at,
    }
    return jwt.encode(payload, secret, algorithm=ALGORITHM), expires_at


def decode_access_token(token: str, *, secret: str) -> AccessClaims:
    """Vérifie signature, algorithme, émetteur, expiration et type. Sinon : erreur 401."""
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=[ALGORITHM],
            issuer=ISSUER,
            options={"require": ["sub", "exp", "iat", "jti", "iss"]},
        )
    except jwt.ExpiredSignatureError as error:
        raise TokenExpiredError() from error
    except jwt.InvalidTokenError as error:  # signature, algorithme, format, émetteur…
        raise TokenInvalidError() from error

    if payload.get("type") != ACCESS_TYPE:
        raise TokenInvalidError()
    try:
        user_id = int(payload["sub"])
    except (TypeError, ValueError) as error:
        raise TokenInvalidError() from error
    role = payload.get("role")
    if not isinstance(role, str):
        raise TokenInvalidError()
    return AccessClaims(
        user_id=user_id,
        role=role,
        token_id=payload["jti"],
        issued_at=datetime.fromtimestamp(payload["iat"], UTC),
        expires_at=datetime.fromtimestamp(payload["exp"], UTC),
    )


def new_refresh_token() -> str:
    """Jeton de rafraîchissement aléatoire (module `secrets` : imprévisible)."""
    return secrets.token_urlsafe(REFRESH_TOKEN_BYTES)


def hash_refresh_token(token: str) -> str:
    """Empreinte SHA-256 (64 caractères hexadécimaux) : c'est elle qui est stockée.

    SHA-256 suffit ici (pas Argon2) : le jeton est long et aléatoire, impossible à deviner.
    """
    return hashlib.sha256(token.encode()).hexdigest()
