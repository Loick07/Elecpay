"""Petits calculs de calendrier (dates locales), partagés par la facturation et la consommation."""

from datetime import date, timedelta

MONTHS_PER_YEAR = 12


def add_months(day: date, months: int) -> date:
    """Premier jour du mois situé `months` mois après celui de `day` (négatif : avant)."""
    month_index = day.year * MONTHS_PER_YEAR + (day.month - 1) + months
    return date(month_index // MONTHS_PER_YEAR, month_index % MONTHS_PER_YEAR + 1, 1)


def month_start(day: date) -> date:
    return day.replace(day=1)


def month_end(day: date) -> date:
    """Dernier jour du mois de `day` (gère février et les années bissextiles)."""
    return add_months(day, 1) - timedelta(days=1)


def days_in_month(day: date) -> int:
    return month_end(day).day
