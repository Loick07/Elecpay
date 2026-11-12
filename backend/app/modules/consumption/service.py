"""Service de la consommation : séries agrégées et comparaisons. Ne connaît pas HTTP.

Lit les relevés journaliers d'un compteur, les agrège (aggregation.py) et chiffre chaque
période avec le moteur de facturation (costs.py). L'accès suit celui du foyer (meter_access) :
tous les membres, lecteurs compris, peuvent consulter.
"""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import AppError
from app.core.pagination import Page, PageParams, paginate
from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.modules.bills.calculator import energy_amount
from app.modules.consumption.aggregation import (
    WH_PER_KWH,
    DailyValue,
    Granularity,
    Period,
    aggregate,
    daily_values,
    period_containing,
    periods_between,
)
from app.modules.consumption.costs import (
    DatedTariff,
    estimate_cost,
    estimated_bill_total,
    tariff_on,
)
from app.modules.consumption.labels import period_label
from app.modules.consumption.models import MeterReading
from app.modules.consumption.schemas import (
    Comparison,
    ConsumptionComparison,
    ConsumptionPoint,
    ConsumptionSeries,
    ConsumptionSummary,
    ConsumptionTotals,
    DayDetail,
    DayPeak,
    EstimateBasis,
    LastMonth,
    MonthEndEstimate,
    MonthSoFar,
    ReadingPublic,
)
from app.modules.households.access import meter_access
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User

# Plage maximale par granularité (en jours) : l'API reste rapide.
MAX_SPAN_DAYS = {
    Granularity.DAY: 400,
    Granularity.WEEK: 1_100,  # ~3 ans
}
DEFAULT_MAX_SPAN_DAYS = 3_700  # ~10 ans pour mois, bimestre, trimestre, semestre, année


class InvalidRangeError(AppError):
    code = "INVALID_RANGE"
    message = "Plage de dates invalide."


def reading_public(reading: MeterReading) -> ReadingPublic:
    return ReadingPublic(
        id=reading.id,
        read_at=reading.read_at,
        day=local_date(reading.read_at) - timedelta(days=1),
        index_wh=reading.index_wh,
        consumption_wh=reading.consumption_wh,
        consumption_kwh=round(reading.consumption_wh / WH_PER_KWH, 3),
        source=reading.source.value,
        is_estimated=reading.is_estimated,
        is_anomaly=reading.is_anomaly,
        anomaly_reason=reading.anomaly_reason,
    )


class DayNotMeasuredError(AppError):
    status_code = 404
    code = "CONSUMPTION_DAY_NOT_FOUND"
    message = "Aucun relevé pour cette journée (pas encore relevée, ou avant l'installation)."


WEEKDAY_AVERAGE_WEEKS = 12  # « moyenne du même jour de la semaine » : 12 semaines précédentes
FALLBACK_DAYS = 7  # le 1er du mois, l'estimation part des 7 dernières journées relevées


@dataclass(frozen=True, slots=True)
class MeterData:
    values: dict[date, DailyValue]
    sources: set[str]


def default_range(granularity: Granularity, today: date) -> tuple[date, date]:
    """Plage affichée quand l'application n'en précise pas (maquette client 11)."""
    match granularity:
        case Granularity.DAY:  # vue Mois : le mois en cours, jour par jour
            period = period_containing(today, Granularity.MONTH)
            return period.start, period.end
        case Granularity.WEEK:  # les 12 dernières semaines
            return today - timedelta(weeks=11), today
        case Granularity.YEAR:  # les 5 dernières années
            return date(today.year - 4, 1, 1), date(today.year, 12, 31)
        case _:  # vue Année : l'année en cours
            return date(today.year, 1, 1), date(today.year, 12, 31)


def default_comparison(granularity: Granularity) -> Comparison:
    if granularity in (Granularity.DAY, Granularity.WEEK):
        return Comparison.PREVIOUS
    return Comparison.LAST_YEAR


def one_year_earlier(day: date) -> date:
    """Même date un an plus tôt ; le 29 février devient le 28."""
    if day.month == 2 and day.day == 29:
        return date(day.year - 1, 2, 28)
    return day.replace(year=day.year - 1)


class ConsumptionService:
    def __init__(
        self,
        session: Session,
        settings: Settings,
        today: Callable[[], date] | None = None,
    ) -> None:
        self.session = session
        self.settings = settings
        self.today = today or (lambda: local_date(utcnow()))

    def series(
        self,
        user: User,
        meter_id: int,
        granularity: Granularity,
        start: date | None = None,
        end: date | None = None,
        compare: Comparison | None = None,
    ) -> ConsumptionSeries:
        meter, _ = meter_access(self.session, user, meter_id)
        today = self.today()
        default_start, default_end = default_range(granularity, today)
        start, end = start or default_start, end or default_end
        if end < start:
            raise InvalidRangeError("La date de fin doit être postérieure à la date de début.")
        periods = periods_between(start, end, granularity)
        range_start, range_end = periods[0].start, periods[-1].end
        max_span = MAX_SPAN_DAYS.get(granularity, DEFAULT_MAX_SPAN_DAYS)
        if (range_end - range_start).days + 1 > max_span:
            raise InvalidRangeError(
                f"Plage trop longue pour cette vue : {max_span} jours au plus.",
                details={"max_days": max_span},
            )

        data = self._load(meter.id, range_start, range_end)
        tariffs = self._tariffs()
        points = []
        for aggregated in aggregate(data.values, periods, today=today):
            cost = self._cost(data.values, aggregated.period, tariffs)
            points.append(
                ConsumptionPoint(
                    start=aggregated.period.start,
                    end=aggregated.period.end,
                    label=period_label(aggregated.period, granularity),
                    consumption_wh=aggregated.consumption_wh,
                    consumption_kwh=aggregated.consumption_kwh,
                    energy_cost=cost.energy_cost,
                    estimated_total=cost.estimated_total,
                    days_with_data=aggregated.days_with_data,
                    daily_average_wh=aggregated.daily_average_wh,
                    is_estimated=aggregated.is_estimated,
                    has_anomaly=aggregated.has_anomaly,
                    is_partial=aggregated.is_partial,
                    is_current=aggregated.is_current,
                )
            )

        measured_until = self._measured_until(meter.id)
        comparison = self._comparison(
            meter.id,
            Period(range_start, range_end),
            measured_until,
            compare or default_comparison(granularity),
            data.values,
            tariffs,
        )
        return ConsumptionSeries(
            meter_id=meter.id,
            granularity=granularity,
            start=range_start,
            end=range_end,
            measured_until=measured_until,
            source=self._source_label(data.sources),
            tariff_is_assumption=any(t.is_assumption for t in tariffs),
            points=points,
            comparison=comparison,
        )

    # --- Résumé (accueil, onglet Mois) -----------------------------------------------

    def summary(self, user: User, meter_id: int) -> ConsumptionSummary:
        meter, _ = meter_access(self.session, user, meter_id)
        today = self.today()
        month = period_containing(today, Granularity.MONTH)
        last_month = period_containing(month.start - timedelta(days=1), Granularity.MONTH)
        load_from = min(last_month.start, today - timedelta(days=FALLBACK_DAYS + 1))
        data = self._load(meter.id, load_from, month.end)
        values, tariffs = data.values, self._tariffs()
        measured_until = self._measured_until(meter.id)

        # Ce mois-ci, jusqu'à la dernière journée relevée (au plus hier).
        so_far_end = min(today - timedelta(days=1), measured_until) if measured_until else None
        so_far = (
            Period(month.start, so_far_end)
            if so_far_end is not None and so_far_end >= month.start
            else None
        )
        this_days = [v for d, v in values.items() if so_far and so_far.contains(d)]
        consumption = sum(v.consumption_wh for v in this_days)
        highest = max(this_days, key=lambda v: v.consumption_wh, default=None)
        this_month = MonthSoFar(
            start=month.start,
            end=so_far.end if so_far else None,
            consumption_wh=consumption,
            consumption_kwh=round(consumption / WH_PER_KWH, 3),
            energy_cost=self._cost(values, so_far, tariffs).energy_cost if so_far else None,
            days_with_data=len(this_days),
            daily_average_wh=consumption // len(this_days) if this_days else 0,
            highest_day=DayPeak(
                day=highest.day,
                consumption_wh=highest.consumption_wh,
                consumption_kwh=round(highest.consumption_wh / WH_PER_KWH, 3),
            )
            if highest
            else None,
        )

        last_values = [v for d, v in values.items() if last_month.contains(d)]
        last_cost = self._cost(values, last_month, tariffs)
        last_consumption = sum(v.consumption_wh for v in last_values)
        return ConsumptionSummary(
            meter_id=meter.id,
            measured_until=measured_until,
            source=self._source_label(data.sources),
            tariff_is_assumption=any(t.is_assumption for t in tariffs),
            this_month=this_month,
            month_end_estimate=self._month_end_estimate(
                values, month, this_days, measured_until, tariffs, today
            ),
            last_month=LastMonth(
                start=last_month.start,
                end=last_month.end,
                consumption_wh=last_consumption,
                consumption_kwh=round(last_consumption / WH_PER_KWH, 3),
                energy_cost=last_cost.energy_cost,
                estimated_total=last_cost.estimated_total,
                days_with_data=len(last_values),
            ),
            variation_percent=self._same_days_variation(values, so_far, last_month),
        )

    def _month_end_estimate(
        self, values, month: Period, this_days, measured_until, tariffs, today: date
    ) -> MonthEndEstimate | None:
        """Consommation relevée + moyenne journalière × journées restantes. ESTIMATION."""
        if this_days:
            basis, sample = EstimateBasis.CURRENT_MONTH, this_days
        else:  # le 1er du mois : rien de relevé ce mois-ci, on part des 7 derniers jours
            recent = [
                values[measured_until - timedelta(days=offset)]
                for offset in range(FALLBACK_DAYS)
                if measured_until and measured_until - timedelta(days=offset) in values
            ]
            if not recent:
                return None
            basis, sample = EstimateBasis.LAST_7_DAYS, recent
        average = sum(v.consumption_wh for v in sample) // len(sample)
        remaining = month.days - len(this_days)
        projected = sum(v.consumption_wh for v in this_days) + average * remaining
        tariff = tariff_on(today, tariffs) or tariff_on(month.start, tariffs)
        months = self.settings.billing_period_months
        return MonthEndEstimate(
            consumption_wh=projected,
            consumption_kwh=round(projected / WH_PER_KWH, 3),
            energy_cost=energy_amount(projected, tariff.price_per_kwh_milli) if tariff else None,
            estimated_total=estimated_bill_total(projected, 1, tariff, billing_period_months=months)
            if tariff
            else None,
            basis=basis,
            remaining_days=remaining,
        )

    @staticmethod
    def _same_days_variation(values, so_far: Period | None, last_month: Period) -> float | None:
        """Du 1er au N de ce mois, comparé au 1er au N du mois dernier."""
        if so_far is None:
            return None
        last_end = min(last_month.start + (so_far.end - so_far.start), last_month.end)
        current = sum(v.consumption_wh for d, v in values.items() if so_far.contains(d))
        reference = sum(
            v.consumption_wh for d, v in values.items() if last_month.start <= d <= last_end
        )
        if not reference:
            return None
        return round((current - reference) * 100 / reference, 1)

    # --- Détail d'une journée (onglet Jour) -------------------------------------------

    def day_detail(self, user: User, meter_id: int, day: date) -> DayDetail:
        meter, _ = meter_access(self.session, user, meter_id)
        month = period_containing(day, Granularity.MONTH)
        load_from = min(month.start, day - timedelta(weeks=WEEKDAY_AVERAGE_WEEKS))
        data = self._load(meter.id, load_from, month.end)
        value = data.values.get(day)
        if value is None:
            raise DayNotMeasuredError()
        reading = self._reading_at(meter.id, day + timedelta(days=1))  # porte la journée
        previous = self._reading_at(meter.id, day)  # index au début de la journée

        same_weekdays = [
            data.values[day - timedelta(weeks=week)].consumption_wh
            for week in range(1, WEEKDAY_AVERAGE_WEEKS + 1)
            if day - timedelta(weeks=week) in data.values
        ]
        month_values = [v.consumption_wh for d, v in data.values.items() if month.contains(d)]
        return DayDetail(
            meter_id=meter.id,
            day=day,
            label=period_label(Period(day, day), Granularity.DAY),
            consumption_wh=value.consumption_wh,
            consumption_kwh=round(value.consumption_wh / WH_PER_KWH, 3),
            energy_cost=self._cost(data.values, Period(day, day), self._tariffs()).energy_cost,
            index_start_wh=previous.index_wh if previous else None,
            index_end_wh=value.index_end_wh,
            is_estimated=value.is_estimated,
            is_anomaly=value.is_anomaly,
            anomaly_reason=reading.anomaly_reason if reading else None,
            weekday_average_wh=sum(same_weekdays) // len(same_weekdays) if same_weekdays else None,
            weekday_samples=len(same_weekdays),
            rank_in_month=1 + sum(1 for c in month_values if c > value.consumption_wh),
            days_ranked=len(month_values),
            source=reading.source.value if reading else "none",
        )

    # --- Relevés bruts ---------------------------------------------------------------

    def readings(
        self,
        user: User,
        meter_id: int,
        params: PageParams,
        start: date | None = None,
        end: date | None = None,
    ) -> Page[ReadingPublic]:
        """Relevés du plus récent au plus ancien. `start` / `end` : journées consommées."""
        meter, _ = meter_access(self.session, user, meter_id)
        if start and end and end < start:
            raise InvalidRangeError("La date de fin doit être postérieure à la date de début.")
        query = select(MeterReading).where(MeterReading.meter_id == meter.id)
        if start:  # la journée J est portée par le relevé de minuit au début de J+1
            query = query.where(MeterReading.read_at > local_midnight_utc(start))
        if end:
            query = query.where(MeterReading.read_at <= local_midnight_utc(end + timedelta(days=1)))
        query = query.order_by(MeterReading.read_at.desc())
        return paginate(self.session, query, params, reading_public)

    def _reading_at(self, meter_id: int, day: date) -> MeterReading | None:
        """Le relevé pris à minuit au début de `day` (heure du Congo)."""
        return self.session.scalars(
            select(MeterReading).where(
                MeterReading.meter_id == meter_id,
                MeterReading.read_at == local_midnight_utc(day),
            )
        ).first()

    # --- Données ----------------------------------------------------------------------

    def _load(self, meter_id: int, first_day: date, last_day: date) -> MeterData:
        """Journées [first_day, last_day] : relevés pris de minuit après first_day à minuit
        après last_day (le relevé de minuit au début de J+1 porte la journée J)."""
        rows = self.session.scalars(
            select(MeterReading)
            .where(
                MeterReading.meter_id == meter_id,
                MeterReading.read_at > local_midnight_utc(first_day),
                MeterReading.read_at <= local_midnight_utc(last_day + timedelta(days=1)),
            )
            .order_by(MeterReading.read_at)
        ).all()
        starting = self.session.scalar(
            select(func.min(MeterReading.read_at)).where(MeterReading.meter_id == meter_id)
        )
        return MeterData(
            values=daily_values(rows, starting_reading_at=starting),
            sources={row.source.value for row in rows},
        )

    def _tariffs(self) -> list[Tariff]:
        return list(self.session.scalars(select(Tariff).order_by(Tariff.valid_from)))

    def _measured_until(self, meter_id: int) -> date | None:
        last = self.session.scalar(
            select(func.max(MeterReading.read_at)).where(MeterReading.meter_id == meter_id)
        )
        return local_date(last) - timedelta(days=1) if last else None

    def _cost(self, values, period: Period, tariffs: list[DatedTariff]):
        return estimate_cost(
            values, period, tariffs, billing_period_months=self.settings.billing_period_months
        )

    @staticmethod
    def _source_label(sources: set[str]) -> str:
        if not sources:
            return "none"
        return sources.pop() if len(sources) == 1 else "mixed"

    # --- Comparaison ------------------------------------------------------------------

    def _comparison(
        self,
        meter_id: int,
        requested: Period,
        measured_until: date | None,
        mode: Comparison,
        values: dict[date, DailyValue],
        tariffs: list[Tariff],
    ) -> ConsumptionComparison | None:
        """Compare les MÊMES journées relevées : un mois en cours (11 jours) n'est jamais
        comparé à un mois complet."""
        if measured_until is None:
            return None
        current = Period(requested.start, min(requested.end, measured_until))
        if current.end < current.start:
            return None
        if mode is Comparison.LAST_YEAR:
            reference = Period(one_year_earlier(current.start), one_year_earlier(current.end))
        else:
            shift = timedelta(days=requested.days)
            reference = Period(current.start - shift, current.end - shift)
        reference_values = self._load(meter_id, reference.start, reference.end).values

        current_totals = self._totals(values, current, tariffs)
        reference_totals = self._totals(reference_values, reference, tariffs)
        variation = None
        if reference_totals.consumption_wh:
            change = current_totals.consumption_wh - reference_totals.consumption_wh
            variation = round(change * 100 / reference_totals.consumption_wh, 1)
        return ConsumptionComparison(
            mode=mode,
            current=current_totals,
            reference=reference_totals,
            variation_percent=variation,
        )

    def _totals(self, values, period: Period, tariffs) -> ConsumptionTotals:
        days = [v for d, v in values.items() if period.contains(d)]
        consumption = sum(v.consumption_wh for v in days)
        return ConsumptionTotals(
            start=period.start,
            end=period.end,
            consumption_wh=consumption,
            consumption_kwh=round(consumption / WH_PER_KWH, 3),
            energy_cost=self._cost(values, period, tariffs).energy_cost,
            days_with_data=len(days),
        )
