"""Périodes de facturation et dates d'une facture (fonctions pures, sans base de données).

Périodes calées sur le calendrier, comme E²C (« Juillet-Août 2026 ») : pour une durée de
2 mois, janvier-février, mars-avril, mai-juin… La durée doit diviser 12.

Dates d'une facture (hypothèses B2, voir backend/docs/FACTURE_E2C.md) :
- émission = fin de période + `bill_issue_delay_days` (3 j), à 8 h heure du Congo ;
- échéance = émission + `bill_due_delay_days` (15 j).
"""

from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from typing import Protocol

from app.core.calendar import MONTHS_PER_YEAR, add_months
from app.core.timezone import CONGO_TZ

ISSUE_HOUR = time(8, 0)  # factures émises à 8 h, heure du Congo
MAX_SEQUENCE = 999_999  # 6 chiffres dans le numéro de facture


class BillingSettings(Protocol):
    """Réglages de facturation (`Settings` convient tel quel)."""

    billing_period_months: int
    bill_issue_delay_days: int
    bill_due_delay_days: int


@dataclass(frozen=True, slots=True)
class BillingPeriod:
    start: date  # premier jour (inclus)
    end: date  # dernier jour (inclus)
    months_count: int


def check_period_length(months: int) -> None:
    if months < 1 or MONTHS_PER_YEAR % months != 0:
        raise ValueError(f"Durée de période invalide : {months} (doit diviser 12)")


def is_period_start(day: date, months: int) -> bool:
    """Vrai si `day` ouvre une période calendaire de `months` mois (1er janvier, 1er mars…)."""
    check_period_length(months)
    return day.day == 1 and (day.month - 1) % months == 0


def billing_period(start: date, months: int) -> BillingPeriod:
    """La période de `months` mois qui commence le `start` (qui doit être un début de période)."""
    if not is_period_start(start, months):
        raise ValueError(f"{start:%d/%m/%Y} n'est pas un début de période de {months} mois")
    return BillingPeriod(start, add_months(start, months) - timedelta(days=1), months)


def billing_periods(first_day: date, last_day: date, months: int) -> list[BillingPeriod]:
    """Périodes calendaires complètes comprises entre `first_day` et `last_day` (inclus)."""
    check_period_length(months)
    # Premier début de période aligné (mois 1, 1 + n, 1 + 2n…) au plus tôt le first_day.
    start = date(first_day.year, 1, 1)
    while start < first_day:
        start = add_months(start, months)
    periods = []
    while True:
        period = billing_period(start, months)
        if period.end > last_day:
            return periods
        periods.append(period)
        start = add_months(start, months)


def issue_day(period: BillingPeriod, settings: BillingSettings) -> date:
    """Jour d'émission (date locale) : fin de période + délai d'émission."""
    return period.end + timedelta(days=settings.bill_issue_delay_days)


def issued_at(day: date) -> datetime:
    """Instant d'émission (UTC) : 8 h, heure du Congo, le jour d'émission."""
    return datetime.combine(day, ISSUE_HOUR, tzinfo=CONGO_TZ).astimezone(UTC)


def due_date(period: BillingPeriod, settings: BillingSettings) -> date:
    return issue_day(period, settings) + timedelta(days=settings.bill_due_delay_days)


def bill_reference(day: date, sequence: int) -> str:
    """Numéro de facture sur 14 chiffres, comme E²C : date d'émission AAAAMMJJ + 6 chiffres."""
    if not 0 < sequence <= MAX_SEQUENCE:
        raise ValueError("Le numéro de séquence doit être compris entre 1 et 999 999")
    return f"{day:%Y%m%d}{sequence:06d}"
