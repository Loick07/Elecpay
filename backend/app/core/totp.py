"""Codes à usage unique basés sur le temps (TOTP, RFC 6238), comme Google Authenticator.

Paramètres standard (compatibles avec toutes les applications) : SHA-1, 6 chiffres, 30 s.
Implémenté ici (une vingtaine de lignes) plutôt qu'avec une dépendance de plus ; vérifié avec
les valeurs officielles de la RFC dans les tests.
"""

import base64
import hashlib
import hmac
import secrets
import struct
from urllib.parse import quote, urlencode

DIGITS = 6
PERIOD_SECONDS = 30
DRIFT_STEPS = 1  # tolère ±30 s de décalage d'horloge du téléphone
SECRET_BYTES = 20  # 160 bits, recommandé par la RFC 4226


def new_secret() -> str:
    """Secret aléatoire en base32 (ce que l'application scanne ou que l'on saisit à la main)."""
    return base64.b32encode(secrets.token_bytes(SECRET_BYTES)).decode().rstrip("=")


def _key(secret: str) -> bytes:
    padded = secret.upper() + "=" * (-len(secret) % 8)
    return base64.b32decode(padded)


def hotp(secret: str, counter: int, digits: int = DIGITS) -> str:
    """Code HOTP (RFC 4226) pour un compteur donné."""
    digest = hmac.new(_key(secret), struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    number = struct.unpack(">I", digest[offset : offset + 4])[0] & 0x7FFFFFFF
    return str(number % 10**digits).zfill(digits)


def time_step(unix_seconds: float) -> int:
    return int(unix_seconds // PERIOD_SECONDS)


def matching_step(
    secret: str, code: str, unix_seconds: float, *, last_used_step: int | None = None
) -> int | None:
    """Pas de temps auquel `code` correspond (fenêtre ±1), ou None.

    Un code d'un pas déjà utilisé (ou plus ancien) est refusé : un code intercepté ne peut pas
    être rejoué, même dans ses 30 secondes de validité.
    """
    if len(code) != DIGITS or not code.isdigit():
        return None
    current = time_step(unix_seconds)
    for step in range(current - DRIFT_STEPS, current + DRIFT_STEPS + 1):
        if last_used_step is not None and step <= last_used_step:
            continue
        if hmac.compare_digest(hotp(secret, step), code):
            return step
    return None


def provisioning_uri(secret: str, account: str, issuer: str = "ElecPay") -> str:
    """Adresse `otpauth://` à mettre dans le QR code (format Google Authenticator)."""
    label = quote(f"{issuer}:{account}")
    query = urlencode(
        {"secret": secret, "issuer": issuer, "digits": DIGITS, "period": PERIOD_SECONDS}
    )
    return f"otpauth://totp/{label}?{query}"
