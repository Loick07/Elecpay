"""Agrégation de la consommation par période (fonctions pures : ni base, ni HTTP).

Unité de base : la JOURNÉE LOCALE de Brazzaville. Le relevé pris à minuit au début du jour
J+1 porte la consommation de la journée J (convention des simulateurs et des factures).
Les périodes sont calées sur le calendrier : semaine du lundi au dimanche, mois, bimestre
(janvier-février…, comme les factures E²C), trimestre, semestre, année.

Rien n'est jamais présenté comme « temps réel » : chaque période dit si elle contient des
valeurs estimées ou des anomalies, et si elle est incomplète.
"""

from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from enum import StrEnum
from typing import Protocol

from app.core.calendar import add_months
from app.core.timezone import local_date

WH_PER_KWH = 1_000


class Granularity(StrEnum):
    DAY = "day"
    WEEK = "week"
    MONTH = "month"
    BIMESTER = "bimester"
    QUARTER = "quarter"
    SEMESTER = "semester"
    YEAR = "year"


MONTHS_PER_PERIOD = {
    Granularity.MONTH: 1,
    Granularity.BIMESTER: 2,
    Granularity.QUARTER: 3,
    Granularity.SEMESTER: 6,
    Granularity.YEAR: 12,
}


@dataclass(frozen=True, slots=True)
class Period:
    start: date  # inclus
    end: date  # inclus

    @property
    def days(self) -> int:
        return (self.end - self.start).days + 1

    def contains(self, day: date) -> bool:
        return self.start <= day <= self.end


def period_containing(day: date, granularity: Granularity) -> Period:
    """La période (calée sur le calendrier) qui contient `day`."""
    if granularity is Granularity.DAY:
        return Period(day, day)
    if granularity is Granularity.WEEK:
        monday = day - timedelta(days=day.weekday())
        return Period(monday, monday + timedelta(days=6))
    months = MONTHS_PER_PERIOD[granularity]
    first_month = (day.month - 1) // months * months + 1
    start = date(day.year, first_month, 1)
    return Period(start, add_months(start, months) - timedelta(days=1))


def periods_between(first: date, last: date, granularity: Granularity) -> list[Period]:
    """Toutes les périodes qui touchent l'intervalle [first, last], dans l'ordre."""
    if last < first:
        raise ValueError("La date de fin doit être postérieure ou égale à la date de début")
    periods = []
    current = period_containing(first, granularity)
    while current.start <= last:
        periods.append(current)
        current = period_containing(current.end + timedelta(days=1), granularity)
    return periods


# --- Valeurs journalières -----------------------------------------------------------


class ReadingLike(Protocol):
    """Ce qu'il faut d'un relevé (le modèle `MeterReading` convient tel quel)."""

    read_at: datetime
    index_wh: int
    consumption_wh: int
    is_estimated: bool
    is_anomaly: bool


@dataclass(frozen=True, slots=True)
class DailyValue:
    day: date
    consumption_wh: int
    index_end_wh: int  # index relevé à minuit à la fin de la journée
    is_estimated: bool
    is_anomaly: bool


def daily_values(
    readings: Iterable[ReadingLike], *, starting_reading_at: datetime | None = None
) -> dict[date, DailyValue]:
    """Une valeur par journée locale.

    `starting_reading_at` : instant du tout premier relevé du compteur. Ce relevé n'est que le
    point de départ de l'index (pas une journée de consommation) : il est écarté. On le passe
    explicitement, car une fenêtre de relevés ne commence pas forcément au début du compteur.
    """
    values = {}
    for reading in readings:
        if starting_reading_at is not None and reading.read_at <= starting_reading_at:
            continue
        day = local_date(reading.read_at) - timedelta(days=1)
        values[day] = DailyValue(
            day=day,
            consumption_wh=reading.consumption_wh,
            index_end_wh=reading.index_wh,
            is_estimated=reading.is_estimated,
            is_anomaly=reading.is_anomaly,
        )
    return values


# --- Agrégation ---------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class AggregatedPeriod:
    period: Period
    consumption_wh: int
    days_with_data: int
    is_estimated: bool  # au moins une journée estimée ou en anomalie
    has_anomaly: bool
    is_partial: bool  # des journées manquent (période en cours, coupure de relevés…)
    is_current: bool  # contient « aujourd'hui » : la période n'est pas terminée

    @property
    def consumption_kwh(self) -> float:
        """Pour l'AFFICHAGE seulement (3 décimales) ; la valeur exacte est `consumption_wh`."""
        return round(self.consumption_wh / WH_PER_KWH, 3)

    @property
    def daily_average_wh(self) -> int:
        """Moyenne par journée relevée (division entière)."""
        return self.consumption_wh // self.days_with_data if self.days_with_data else 0


def aggregate(
    values: Mapping[date, DailyValue], periods: Sequence[Period], *, today: date
) -> list[AggregatedPeriod]:
    """Somme des journées de chaque période. `today` : la journée en cours (jamais relevée)."""
    results = []
    for period in periods:
        days = [values[d] for d in _days(period) if d in values]
        results.append(
            AggregatedPeriod(
                period=period,
                consumption_wh=sum(v.consumption_wh for v in days),
                days_with_data=len(days),
                is_estimated=any(v.is_estimated or v.is_anomaly for v in days),
                has_anomaly=any(v.is_anomaly for v in days),
                is_partial=len(days) < period.days,
                is_current=period.contains(today),
            )
        )
    return results


def _days(period: Period) -> Iterable[date]:
    for offset in range(period.days):
        yield period.start + timedelta(days=offset)
