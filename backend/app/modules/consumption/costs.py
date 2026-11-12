"""Coût estimé d'une période de consommation (fonctions pures).

Deux coûts (choix validé le 12/11/2026) :
- `energy_cost`     : énergie seule (kWh × tarif en vigueur), ce qu'affiche l'écran
                      Consommation de la maquette ;
- `estimated_total` : facture estimée complète de la période (droit à la consommation, TVA,
                      C.A., RAV et timbre au prorata), à partir du mois. Toujours une ESTIMATION :
                      la facture officielle reste celle émise par E²C (bimestrielle).

Tout passe par le moteur unique `compute_bill` : mêmes règles, mêmes troncatures.
"""

from collections import defaultdict
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Protocol

from app.core.calendar import month_end
from app.modules.bills.calculator import MAX_MONTHS, TariffLike, compute_bill, energy_amount
from app.modules.consumption.aggregation import DailyValue, Period


class DatedTariff(TariffLike, Protocol):
    """Un tarif daté (le modèle `Tariff` convient tel quel)."""

    id: int
    valid_from: date
    valid_to: date | None  # exclu ; None = sans fin
    is_assumption: bool


@dataclass(frozen=True, slots=True)
class _ProratedRates:
    """Tarif dont les redevances « par facture » sont ramenées à la durée de la période."""

    price_per_kwh_milli: int
    fixed_fee_per_month: int
    vat_rate_bp: int
    additional_tax_rate_bp: int
    audiovisual_fee: int
    stamp_fee: int


@dataclass(frozen=True, slots=True)
class CostEstimate:
    energy_cost: int | None  # None : aucun tarif connu pour ces journées
    estimated_total: int | None  # None : période plus courte qu'un mois, ou aucun tarif
    months_count: int | None  # mois calendaires entiers couverts par la période
    priced_days: int
    unpriced_days: int  # journées relevées sans tarif en vigueur (coût alors incomplet)
    is_assumption: bool  # au moins un tarif utilisé n'est pas encore vérifié


def tariff_on(day: date, tariffs: Sequence[DatedTariff]) -> DatedTariff | None:
    """Tarif en vigueur un jour donné (périodes [valid_from, valid_to[ sans chevauchement)."""
    candidates = [
        t for t in tariffs if t.valid_from <= day and (t.valid_to is None or day < t.valid_to)
    ]
    return max(candidates, key=lambda t: t.valid_from, default=None)


def whole_months(period: Period) -> int | None:
    """Nombre de mois si la période va du 1er d'un mois au dernier jour d'un mois, sinon None."""
    if period.start.day != 1 or period.end != month_end(period.end):
        return None
    return (period.end.year - period.start.year) * 12 + period.end.month - period.start.month + 1


def estimated_bill_total(
    consumption_wh: int,
    months: int,
    tariff: TariffLike,
    *,
    billing_period_months: int,
    energy: int | None = None,
) -> int:
    """Facture estimée de `months` mois : RAV et timbre (facturés une fois par facture de
    `billing_period_months` mois) ramenés au prorata. `energy` : montant déjà calculé (sinon
    consommation × prix du tarif)."""
    rates = _ProratedRates(
        price_per_kwh_milli=tariff.price_per_kwh_milli,
        fixed_fee_per_month=tariff.fixed_fee_per_month,
        vat_rate_bp=tariff.vat_rate_bp,
        additional_tax_rate_bp=tariff.additional_tax_rate_bp,
        audiovisual_fee=tariff.audiovisual_fee * months // billing_period_months,
        stamp_fee=tariff.stamp_fee * months // billing_period_months,
    )
    return compute_bill(consumption_wh, months, rates, energy_override=energy).amount_total


def estimate_cost(
    values: Mapping[date, DailyValue],
    period: Period,
    tariffs: Sequence[DatedTariff],
    *,
    billing_period_months: int,
) -> CostEstimate:
    """Coûts de `period` d'après les journées relevées et les tarifs en vigueur chaque jour.

    `billing_period_months` : durée d'une facture E²C (2). Sert à répartir la RAV et le timbre,
    facturés une fois par facture : 1 000 FCFA pour 2 mois → 500 FCFA pour 1 mois.
    """
    consumption_by_tariff: dict[int, int] = defaultdict(int)
    used: dict[int, DatedTariff] = {}
    priced_days = unpriced_days = 0
    day = period.start
    while day <= period.end:
        value = values.get(day)
        if value is not None:
            tariff = tariff_on(day, tariffs)
            if tariff is None:
                unpriced_days += 1
            else:
                consumption_by_tariff[tariff.id] += value.consumption_wh
                used[tariff.id] = tariff
                priced_days += 1
        day += timedelta(days=1)

    if not used:
        return CostEstimate(None, None, whole_months(period), 0, unpriced_days, False)

    # Énergie : un calcul par tarif (si le prix change en cours de période, chaque tranche
    # garde son prix), tronqué comme sur la facture — jamais jour par jour.
    energy = sum(
        energy_amount(consumption_by_tariff[tariff_id], used[tariff_id].price_per_kwh_milli)
        for tariff_id in consumption_by_tariff
    )
    months = whole_months(period)
    estimated_total = None
    # Au-delà de 12 mois (ex. une comparaison sur 18 mois), une « facture estimée » d'un bloc
    # n'a pas de sens et le moteur la refuse : seule l'énergie est chiffrée.
    if months is not None and months <= MAX_MONTHS:
        reference = tariff_on(period.start, tariffs) or next(iter(used.values()))
        estimated_total = estimated_bill_total(
            sum(consumption_by_tariff.values()),
            months,
            reference,
            billing_period_months=billing_period_months,
            energy=energy,
        )

    return CostEstimate(
        energy_cost=energy,
        estimated_total=estimated_total,
        months_count=months,
        priced_days=priced_days,
        unpriced_days=unpriced_days,
        is_assumption=any(t.is_assumption for t in used.values()),
    )
