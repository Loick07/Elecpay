"""Simulateur de relevés de compteur (mode démo).

Produit un relevé par jour, à minuit heure du Congo, avec des motifs réalistes :
profil de consommation, saisons, jours de la semaine, coupures, relevés estimés
et, rarement, une anomalie (index lu en baisse).

Déterministe : même profil + mêmes dates + même graine → exactement les mêmes relevés.
Le hasard ne sert qu'à la démo (jamais à la sécurité).

Convention : le relevé du jour J est pris à minuit au DÉBUT de J+1 et porte la
consommation de la journée J. Le tout premier relevé (minuit au début du premier jour)
sert de point de départ : sa consommation vaut 0.
"""

import math
import random
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from enum import StrEnum

from app.core.timezone import local_midnight_utc

DAYS_PER_YEAR = 365.25
ANOMALY_REASON = "Index relevé inférieur au relevé précédent (erreur de lecture probable)"


class ProfileName(StrEnum):
    SMALL_HOUSEHOLD = "petit_menage"
    FAMILY = "famille"
    SHOP = "commerce"


@dataclass(frozen=True, slots=True)
class ConsumptionProfile:
    """Paramètres d'un type d'abonné. Les énergies sont en Wh par jour."""

    name: ProfileName
    base_daily_wh: int
    # Facteur multiplicatif par jour de la semaine, lundi (0) → dimanche (6).
    weekday_factors: tuple[float, float, float, float, float, float, float]
    # Saison chaude et humide (pic vers mars) plus gourmande : ventilateurs, climatisation.
    seasonal_amplitude: float = 0.15
    noise: float = 0.12  # variation aléatoire d'un jour à l'autre (écart type relatif)
    outage_probability: float = 0.012  # coupure E²C (journée entière ou partielle)
    estimated_probability: float = 0.02  # relevé non transmis : valeur estimée
    anomaly_probability: float = 0.003  # index lu en baisse (rare)


PROFILES: dict[ProfileName, ConsumptionProfile] = {
    # ~4 kWh/jour : un studio, éclairage, télévision, réfrigérateur.
    ProfileName.SMALL_HOUSEHOLD: ConsumptionProfile(
        name=ProfileName.SMALL_HOUSEHOLD,
        base_daily_wh=4_000,
        weekday_factors=(0.95, 0.95, 0.95, 0.95, 1.0, 1.1, 1.15),
    ),
    # ~9,2 kWh/jour : ordre de grandeur de la vraie facture analysée (571 kWh sur 62 jours).
    ProfileName.FAMILY: ConsumptionProfile(
        name=ProfileName.FAMILY,
        base_daily_wh=9_200,
        weekday_factors=(0.95, 0.95, 0.95, 0.95, 1.0, 1.1, 1.1),
    ),
    # ~22 kWh/jour : boutique avec congélateurs ; ouvert le samedi, presque fermé le dimanche.
    ProfileName.SHOP: ConsumptionProfile(
        name=ProfileName.SHOP,
        base_daily_wh=22_000,
        weekday_factors=(1.05, 1.05, 1.05, 1.05, 1.1, 1.15, 0.4),
        seasonal_amplitude=0.2,
    ),
}


@dataclass(frozen=True, slots=True)
class SimulatedReading:
    """Un relevé simulé (mêmes noms de champs que `MeterReading`)."""

    read_at: datetime  # UTC
    index_wh: int
    consumption_wh: int
    is_estimated: bool = False
    is_anomaly: bool = False
    anomaly_reason: str | None = None


def seasonal_factor(day: date, amplitude: float) -> float:
    """1 + amplitude au plus chaud (vers le 15 mars), 1 − amplitude au plus frais (septembre)."""
    peak = date(day.year, 3, 15)
    phase = 2 * math.pi * (day - peak).days / DAYS_PER_YEAR
    return 1 + amplitude * math.cos(phase)


def generate_readings(
    profile: ConsumptionProfile,
    first_day: date,
    last_day: date,
    *,
    start_index_wh: int,
    seed: int,
    anomaly_on_last_day: bool = False,
) -> list[SimulatedReading]:
    """Relevés de `first_day` à `last_day` inclus : (nombre de jours + 1) relevés.

    `start_index_wh` doit être le dernier index VALIDE connu (jamais celui d'une anomalie).
    `anomaly_on_last_day` : autorise une anomalie sur le dernier relevé (relevé quotidien,
    où chaque jour est le dernier ; le passage suivant repart du dernier index valide).

    - L'index réel ne baisse jamais. Une anomalie est un index LU plus bas que le précédent :
      le relevé est gardé, marqué en anomalie avec son motif, et sa consommation vaut 0.
      Le relevé suivant repart de l'index réel et récupère la consommation manquante.
    - Pas d'anomalie sur le premier jour d'un mois (début de période de facturation) ni sur
      le dernier relevé : les index de facturation sont donc toujours fiables.
    """
    if last_day < first_day:
        raise ValueError("last_day doit être postérieur ou égal à first_day")
    if isinstance(start_index_wh, bool) or not isinstance(start_index_wh, int):
        raise TypeError("start_index_wh : entier attendu")
    if start_index_wh < 0:
        raise ValueError("start_index_wh doit être ≥ 0")

    rng = random.Random(seed)
    readings = [SimulatedReading(local_midnight_utc(first_day), start_index_wh, 0)]
    true_index = start_index_wh  # ce que le compteur affiche réellement
    last_valid_index = start_index_wh  # dernier index lu correctement

    day = first_day
    while day <= last_day:
        read_day = day + timedelta(days=1)  # le relevé est pris à minuit au début du lendemain
        true_index += _daily_consumption(profile, day, rng)

        is_last = day == last_day
        anomaly_allowed = read_day.day != 1 and (anomaly_on_last_day or not is_last)
        if anomaly_allowed and rng.random() < profile.anomaly_probability:
            misread = max(0, last_valid_index - rng.randint(500, 50_000))
            readings.append(
                SimulatedReading(
                    read_at=local_midnight_utc(read_day),
                    index_wh=misread,
                    consumption_wh=0,
                    is_anomaly=True,
                    anomaly_reason=ANOMALY_REASON,
                )
            )
        else:
            readings.append(
                SimulatedReading(
                    read_at=local_midnight_utc(read_day),
                    index_wh=true_index,
                    consumption_wh=true_index - last_valid_index,
                    is_estimated=rng.random() < profile.estimated_probability,
                )
            )
            last_valid_index = true_index
        day = read_day
    return readings


def _daily_consumption(profile: ConsumptionProfile, day: date, rng: random.Random) -> int:
    """Consommation d'une journée, en Wh entiers (≥ 0)."""
    expected = (
        profile.base_daily_wh
        * profile.weekday_factors[day.weekday()]
        * seasonal_factor(day, profile.seasonal_amplitude)
    )
    value = expected * max(0.0, rng.gauss(1.0, profile.noise))
    if rng.random() < profile.outage_probability:
        value *= rng.choice((0.0, rng.uniform(0.1, 0.6)))  # coupure totale ou partielle
    return round(value)
