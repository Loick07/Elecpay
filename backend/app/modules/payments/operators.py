"""Quel opérateur Mobile Money pour quel numéro (Congo-Brazzaville).

HYPOTHÈSE À VÉRIFIER (validée par Loick le 13/11/2026 en attendant confirmation) :
MTN = numéros en 06 ; Airtel = numéros en 05 et 04. Les fixes (22) ne paient pas en
Mobile Money. Un seul endroit à corriger si la numérotation est différente.
"""

from app.core.validation import COUNTRY_CODE
from app.modules.payments.models import MobileOperator

OPERATOR_PREFIXES: dict[MobileOperator, tuple[str, ...]] = {
    MobileOperator.MTN: ("06",),
    MobileOperator.AIRTEL: ("05", "04"),
}

OPERATOR_LABELS = {MobileOperator.MTN: "MTN MoMo", MobileOperator.AIRTEL: "Airtel Money"}


def operator_for_phone(phone: str) -> MobileOperator | None:
    """Opérateur d'un numéro normalisé (+242…) ; None pour un fixe ou un numéro inconnu."""
    national = phone.removeprefix(f"+{COUNTRY_CODE}")
    for operator, prefixes in OPERATOR_PREFIXES.items():
        if national.startswith(prefixes):
            return operator
    return None
