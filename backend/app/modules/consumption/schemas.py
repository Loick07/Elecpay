"""Schémas d'API de la consommation (écran « Consommation », maquette client 11).

Énergie : `*_wh` en Wh entiers (valeur exacte) et `*_kwh` à 3 décimales (affichage seulement).
Montants : FCFA entiers. Rien n'est « temps réel » : `measured_until` dit jusqu'où vont les relevés.
"""

from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, Field

from app.modules.consumption.aggregation import Granularity


class Comparison(StrEnum):
    PREVIOUS = "previous"  # la plage précédente, de même durée (vue Semaine)
    LAST_YEAR = "last_year"  # les mêmes dates, un an plus tôt (vue Année)


class ConsumptionPoint(BaseModel):
    start: date
    end: date
    label: str = Field(examples=["Oct. 2026"])
    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None = Field(description="Énergie seule, FCFA (affiché par la maquette)")
    estimated_total: int | None = Field(
        description="Facture estimée complète, FCFA (à partir du mois ; toujours une estimation)"
    )
    days_with_data: int
    daily_average_wh: int
    is_estimated: bool = Field(description="Contient des valeurs estimées ou des anomalies")
    has_anomaly: bool
    is_partial: bool = Field(description="Des journées manquent (période en cours…)")
    is_current: bool = Field(description="La période n'est pas terminée")


class ConsumptionTotals(BaseModel):
    start: date
    end: date
    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None
    days_with_data: int


class ConsumptionComparison(BaseModel):
    mode: Comparison
    current: ConsumptionTotals
    reference: ConsumptionTotals
    variation_percent: float | None = Field(
        description="Évolution de la consommation (%), sur les mêmes journées relevées"
    )


class EstimateBasis(StrEnum):
    CURRENT_MONTH = "current_month"  # moyenne des journées déjà relevées ce mois-ci
    LAST_7_DAYS = "last_7_days"  # le 1er du mois : moyenne des 7 dernières journées relevées


class DayPeak(BaseModel):
    day: date
    consumption_wh: int
    consumption_kwh: float


class MonthSoFar(BaseModel):
    start: date
    end: date | None = Field(description="Dernière journée relevée du mois (None le 1er du mois)")
    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None
    days_with_data: int
    daily_average_wh: int
    highest_day: DayPeak | None


class MonthEndEstimate(BaseModel):
    """ESTIMATION : consommation relevée + moyenne journalière × jours restants."""

    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None
    estimated_total: int | None = Field(description="Facture estimée du mois (FCFA)")
    basis: EstimateBasis
    remaining_days: int


class LastMonth(BaseModel):
    start: date
    end: date
    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None
    estimated_total: int | None
    days_with_data: int


class ConsumptionSummary(BaseModel):
    meter_id: int
    measured_until: date | None
    source: str
    tariff_is_assumption: bool
    this_month: MonthSoFar
    month_end_estimate: MonthEndEstimate | None = Field(
        description="None si aucune journée n'a encore été relevée"
    )
    last_month: LastMonth
    variation_percent: float | None = Field(
        description="Ce mois-ci comparé au mois dernier, sur les mêmes jours du mois"
    )


class DayDetail(BaseModel):
    """Onglet « Jour » de l'écran Consommation."""

    meter_id: int
    day: date
    label: str = Field(examples=["Mer. 14 oct."])
    consumption_wh: int
    consumption_kwh: float
    energy_cost: int | None
    index_start_wh: int | None = Field(description="Index à minuit au début de la journée")
    index_end_wh: int = Field(description="Index à minuit à la fin de la journée")
    is_estimated: bool = Field(description="Relevé non transmis : valeur estimée")
    is_anomaly: bool
    anomaly_reason: str | None
    weekday_average_wh: int | None = Field(
        description="Moyenne du même jour de la semaine sur les 12 semaines précédentes"
    )
    weekday_samples: int
    rank_in_month: int = Field(description="1 = journée la plus consommatrice du mois")
    days_ranked: int
    source: str


class ReadingPublic(BaseModel):
    """Un relevé brut tel qu'enregistré (index à minuit, heure du Congo)."""

    id: int
    read_at: datetime = Field(description="Instant du relevé (UTC)")
    day: date = Field(description="Journée dont il porte la consommation (veille du relevé)")
    index_wh: int
    consumption_wh: int
    consumption_kwh: float
    source: str
    is_estimated: bool
    is_anomaly: bool
    anomaly_reason: str | None


class ConsumptionSeries(BaseModel):
    meter_id: int
    granularity: Granularity
    start: date
    end: date
    measured_until: date | None = Field(description="Dernière journée relevée (en général hier)")
    source: str = Field(description="« simulated » en mode démo : données simulées")
    tariff_is_assumption: bool = Field(description="Le tarif utilisé n'est pas encore vérifié")
    points: list[ConsumptionPoint]
    comparison: ConsumptionComparison | None
