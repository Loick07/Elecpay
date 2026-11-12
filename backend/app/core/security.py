"""Hachage des mots de passe (Argon2id).

Le mot de passe n'est jamais stocké : seule son empreinte Argon2 l'est (`users.password_hash`).
Chaque hachage utilise un sel aléatoire : deux comptes avec le même mot de passe ont des
empreintes différentes.
"""

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

# Paramètres par défaut de argon2-cffi (Argon2id, recommandés par la RFC 9106).
_hasher = PasswordHasher()


def hash_password(password: str) -> str:
    """Empreinte Argon2id d'un mot de passe (commence par « $argon2id$ »)."""
    if not password:
        raise ValueError("Le mot de passe ne peut pas être vide")
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    """Vrai si le mot de passe correspond à l'empreinte. Jamais d'exception pour un mauvais mot."""
    try:
        return _hasher.verify(password_hash, password)
    except VerifyMismatchError, VerificationError, InvalidHashError:
        return False
    except UnicodeEncodeError:
        # Empreinte corrompue (caractère non ASCII) : argon2 plante au lieu de refuser.
        return False


def needs_rehash(password_hash: str) -> bool:
    """Vrai si l'empreinte a été faite avec d'anciens paramètres (à refaire à la connexion)."""
    return _hasher.check_needs_rehash(password_hash)
