"""Source des données E²C : une interface, plusieurs implémentations choisies par configuration.

Aujourd'hui : `SimulatedBillingSource` (mode démo). Demain : `E2CBillingSource`, branchée sur
l'API d'E²C quand elle existera — sans rien changer au reste de l'application.

Identifiants (voir backend/docs/FACTURE_E2C.md) :
- N° Branchement : ex. « 0018 09 5408 » → `meters.reference`
- N° Client      : ex. « 0758340H »     → `meters.customer_number`
Demander LES DEUX prouve qu'on a la facture en main (on n'ajoute pas le compteur du voisin).
"""

import re
from dataclasses import dataclass
from typing import Protocol

from app.modules.meters.models import MeterType

REFERENCE_DIGITS = (8, 12)  # 10 chiffres sur les factures E²C ; marge pour les anciens formats
_SEPARATORS = re.compile(r"[\s.\-/]")
_CUSTOMER_NUMBER = re.compile(r"^[0-9]{6,8}[A-Z]$")


@dataclass(frozen=True, slots=True)
class E2CMeterInfo:
    """Ce qu'E²C connaît d'un compteur (repris dans la table `meters`)."""

    reference: str  # N° Branchement, au format d'affichage d'E²C
    customer_number: str  # N° Client
    contract_number: str  # N° Police
    e2c_center: str  # ex. POINTE-NOIRE
    subscribed_power_va: int
    meter_type: MeterType


class BillingSource(Protocol):
    def lookup_meter(self, reference: str, customer_number: str) -> E2CMeterInfo | None:
        """Le compteur si le couple (branchement, client) existe chez E²C, sinon None.

        Les deux numéros sont déjà normalisés (`normalize_reference`, `normalize_customer_number`).
        """
        ...


def normalize_reference(raw: str) -> str:
    """« 0018 09 5408 », « 0018-09-5408 », « 0018095408 » → « 0018095408 » (chiffres seuls)."""
    digits = _SEPARATORS.sub("", raw.strip())
    low, high = REFERENCE_DIGITS
    if not digits.isdigit() or not low <= len(digits) <= high:
        raise ValueError(
            "N° de branchement invalide : 10 chiffres attendus, comme sur la facture "
            "(ex. 0018 09 5408)"
        )
    return digits


def normalize_customer_number(raw: str) -> str:
    """« 0758340 h » → « 0758340H »."""
    value = _SEPARATORS.sub("", raw.strip()).upper()
    if not _CUSTOMER_NUMBER.fullmatch(value):
        raise ValueError("N° client invalide : des chiffres suivis d'une lettre (ex. 0758340H)")
    return value


def display_reference(digits: str) -> str:
    """Format d'affichage E²C : 10 chiffres → « 0018 09 5408 » ; sinon inchangé."""
    if len(digits) == 10:
        return f"{digits[:4]} {digits[4:6]} {digits[6:]}"
    return digits
