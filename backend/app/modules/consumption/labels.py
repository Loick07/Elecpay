"""Libellés français des périodes, comme sur l'écran Consommation et les factures E²C."""

from app.modules.consumption.aggregation import Granularity, Period

MONTHS_SHORT = (
    "Janv.", "Févr.", "Mars", "Avr.", "Mai", "Juin",
    "Juil.", "Août", "Sept.", "Oct.", "Nov.", "Déc.",
)  # fmt: skip
WEEKDAYS_SHORT = ("Lun.", "Mar.", "Mer.", "Jeu.", "Ven.", "Sam.", "Dim.")


def period_label(period: Period, granularity: Granularity) -> str:
    """Mer. 14 oct. · Sem. du 12 oct. · Oct. 2026 · Juil.-Août 2026 · T4 2026 · S2 2026 · 2026."""
    start = period.start
    month = MONTHS_SHORT[start.month - 1]
    match granularity:
        case Granularity.DAY:
            return f"{WEEKDAYS_SHORT[start.weekday()]} {start.day} {month.lower()}"
        case Granularity.WEEK:
            return f"Sem. du {start.day} {month.lower()}"
        case Granularity.MONTH:
            return f"{month} {start.year}"
        case Granularity.BIMESTER:
            return f"{month}-{MONTHS_SHORT[period.end.month - 1]} {start.year}"
        case Granularity.QUARTER:
            return f"T{(start.month - 1) // 3 + 1} {start.year}"
        case Granularity.SEMESTER:
            return f"S{(start.month - 1) // 6 + 1} {start.year}"
        case Granularity.YEAR:
            return str(start.year)
