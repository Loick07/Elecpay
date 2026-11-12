"""Validation et normalisation des données saisies par les utilisateurs.

Chaque fonction renvoie la valeur normalisée ou lève `ValueError` avec un message en français
(Pydantic le transforme en erreur 422 au format commun). Les types `Annotated` s'utilisent
directement dans les schémas d'API : `phone: CongoPhone`.
"""

import re
from typing import Annotated

from pydantic import AfterValidator

# --- Téléphone (Congo-Brazzaville) --------------------------------------------------

COUNTRY_CODE = "242"
NATIONAL_LENGTH = 9  # ex. 06 123 45 67
# Mobiles : 04, 05, 06 (MTN, Airtel…) ; fixes : 22.
VALID_PREFIXES = ("04", "05", "06", "22")
_SEPARATORS = re.compile(r"[\s.\-()/]")


def normalize_congo_phone(raw: str) -> str:
    """« 06 123 45 67 », « 061234567 », « 00242… », « 242… » → « +242061234567 »."""
    digits = _SEPARATORS.sub("", raw.strip())
    if digits.startswith("+"):
        digits = digits[1:]
    elif digits.startswith("00"):
        digits = digits[2:]
    if not digits:
        raise ValueError("Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)")
    if not digits.isdigit():
        raise ValueError("Numéro invalide : seuls les chiffres, espaces et « + » sont acceptés")
    if len(digits) == len(COUNTRY_CODE) + NATIONAL_LENGTH and digits.startswith(COUNTRY_CODE):
        national = digits[len(COUNTRY_CODE) :]
    elif len(digits) == NATIONAL_LENGTH:
        national = digits
    else:
        raise ValueError("Numéro invalide : 9 chiffres attendus (ex. 06 123 45 67)")
    if not national.startswith(VALID_PREFIXES):
        raise ValueError("Numéro invalide : il doit commencer par 04, 05, 06 ou 22")
    return f"+{COUNTRY_CODE}{national}"


def mask_phone(phone: str) -> str:
    """« +242061234567 » → « +242 06 *** ** 67 » (journaux, back-office : jamais en entier)."""
    national = phone.removeprefix(f"+{COUNTRY_CODE}")
    if len(national) != NATIONAL_LENGTH:
        return "***"
    return f"+{COUNTRY_CODE} {national[:2]} *** ** {national[-2:]}"


# --- Mot de passe -------------------------------------------------------------------

PASSWORD_MIN_LENGTH = 8
PASSWORD_MAX_LENGTH = 128  # au-delà, le hachage Argon2 coûterait cher pour rien (déni de service)


def check_password_strength(password: str) -> str:
    """Règle de la maquette d'inscription : 8 caractères minimum, dont au moins un chiffre."""
    if len(password) < PASSWORD_MIN_LENGTH:
        raise ValueError(f"Mot de passe trop court : {PASSWORD_MIN_LENGTH} caractères minimum")
    if len(password) > PASSWORD_MAX_LENGTH:
        raise ValueError(f"Mot de passe trop long : {PASSWORD_MAX_LENGTH} caractères maximum")
    if not any(char.isdigit() for char in password):
        raise ValueError("Le mot de passe doit contenir au moins un chiffre")
    if not any(char.isalpha() for char in password):
        raise ValueError("Le mot de passe doit contenir au moins une lettre")
    if password != password.strip():
        raise ValueError("Le mot de passe ne doit pas commencer ni finir par un espace")
    return password


# --- E-mail et nom ------------------------------------------------------------------

EMAIL_MAX_LENGTH = 254
_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s.]{2,}$")


def normalize_email(raw: str) -> str:
    """Contrôle simple de forme + minuscules (la vraie preuve est l'envoi d'un message)."""
    email = raw.strip().lower()
    if len(email) > EMAIL_MAX_LENGTH or not _EMAIL.fullmatch(email):
        raise ValueError("Adresse e-mail invalide")
    return email


FULL_NAME_MIN_LENGTH = 2
FULL_NAME_MAX_LENGTH = 120


def normalize_full_name(raw: str) -> str:
    """Espaces superflus retirés : «  Grâce   Ngoma » → « Grâce Ngoma »."""
    name = " ".join(raw.split())
    if len(name) < FULL_NAME_MIN_LENGTH:
        raise ValueError("Nom trop court")
    if len(name) > FULL_NAME_MAX_LENGTH:
        raise ValueError(f"Nom trop long : {FULL_NAME_MAX_LENGTH} caractères maximum")
    if not any(char.isalpha() for char in name):
        raise ValueError("Le nom doit contenir des lettres")
    return name


# --- Types prêts à l'emploi dans les schémas Pydantic -------------------------------

CongoPhone = Annotated[str, AfterValidator(normalize_congo_phone)]
NewPassword = Annotated[str, AfterValidator(check_password_strength)]
Email = Annotated[str, AfterValidator(normalize_email)]
FullName = Annotated[str, AfterValidator(normalize_full_name)]
