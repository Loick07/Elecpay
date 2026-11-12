"""Affichage des montants (FCFA entiers, jamais de float)."""


def format_fcfa(amount: int) -> str:
    """40384 → « 40 384 FCFA » (séparateur de milliers comme sur la facture E²C)."""
    return f"{amount:,}".replace(",", " ") + " FCFA"
