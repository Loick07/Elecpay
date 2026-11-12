"""Heure locale du Congo-Brazzaville.

Brazzaville et Pointe-Noire sont à UTC+1 toute l'année (pas d'heure d'été).
La base stocke tout en UTC ; ce fuseau sert à découper les journées locales
(un relevé « du 14 octobre » couvre de 0 h à 24 h, heure de Brazzaville).
"""

from datetime import UTC, date, datetime, time, timedelta, timezone

CONGO_TZ = timezone(timedelta(hours=1), "WAT")  # West Africa Time


def local_midnight_utc(day: date) -> datetime:
    """Minuit au début de `day`, heure du Congo, exprimé en UTC (la veille à 23 h UTC)."""
    return datetime.combine(day, time.min, tzinfo=CONGO_TZ).astimezone(UTC)


def local_date(instant: datetime) -> date:
    """Date locale (Congo) d'un instant UTC."""
    return instant.astimezone(CONGO_TZ).date()
