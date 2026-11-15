"""Chiffrement des petits secrets stockés en base (ex. secret TOTP de la 2FA), AES-256-GCM.

La clé vient de `TWO_FACTOR_KEY` (obligatoire en production, différente de `JWT_SECRET`) ; à
défaut, en développement et en test, elle est dérivée de `JWT_SECRET`. Dérivation HKDF-SHA256 :
une clé de 256 bits propre à cet usage. Une base volée sans la clé ne livre aucun secret.
"""

import base64
import os

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

NONCE_BYTES = 12
VERSION = "v1"


def derive_key(material: str, purpose: str) -> bytes:
    return HKDF(
        algorithm=hashes.SHA256(), length=32, salt=None, info=f"elecpay:{purpose}".encode()
    ).derive(material.encode())


def encrypt(plaintext: str, key: bytes) -> str:
    nonce = os.urandom(NONCE_BYTES)
    sealed = AESGCM(key).encrypt(nonce, plaintext.encode(), None)
    return f"{VERSION}:" + base64.urlsafe_b64encode(nonce + sealed).decode()


def decrypt(token: str, key: bytes) -> str:
    """Lève `ValueError` si le texte est abîmé ou chiffré avec une autre clé."""
    version, _, payload = token.partition(":")
    if version != VERSION:
        raise ValueError("Format de secret chiffré inconnu")
    raw = base64.urlsafe_b64decode(payload)
    try:
        plain = AESGCM(key).decrypt(raw[:NONCE_BYTES], raw[NONCE_BYTES:], None)
    except Exception as error:  # InvalidTag : mauvaise clé ou donnée modifiée
        raise ValueError("Secret chiffré illisible (clé différente ou donnée modifiée)") from error
    return plain.decode()
