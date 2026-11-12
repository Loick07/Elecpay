"""Moteur de calcul d'une facture E²C Basse Tension.

C'est l'UNIQUE endroit où un montant de facture est calculé. Il est utilisé par :
- le simulateur (B2) pour générer les factures de démonstration ;
- le service de facturation (B6) ;
- les estimations de consommation par période (B5).

Fonction pure : aucune base de données, aucune date, aucun hasard. Tout est en entiers.
Règles (voir backend/docs/FACTURE_E2C.md, vérifiées au franc près sur une vraie facture) :

    Montant consommation  = Wh × prix (millièmes de FCFA/kWh) ÷ 1 000 000   → tronqué
    Droit à consommation  = frais fixes mensuels × nombre de mois
    Total HT              = consommation + droit à consommation
    TVA                   = HT × taux TVA ÷ 10 000                          → tronqué
    C.A.                  = TVA × taux C.A. ÷ 10 000                         → tronqué
    RAV, timbre           = montants fixes, hors base TVA
    Total                 = HT + TVA + C.A. + RAV + timbre

« Tronqué » : on coupe les décimales (division entière), comme E²C (28 024,68 → 28 024).
"""

from dataclasses import dataclass
from typing import Protocol

from app.modules.bills.models import BillLineKind

WH_PER_KWH = 1_000
MILLI = 1_000  # prix et quantités sont exprimés en millièmes
BASIS_POINTS = 10_000  # 100 % = 10 000 points de base
MAX_MONTHS = 12


class TariffLike(Protocol):
    """Ce dont le calcul a besoin d'un tarif (le modèle `Tariff` convient tel quel)."""

    price_per_kwh_milli: int
    fixed_fee_per_month: int
    vat_rate_bp: int
    additional_tax_rate_bp: int
    audiovisual_fee: int
    stamp_fee: int


@dataclass(frozen=True, slots=True)
class ComputedLine:
    """Une ligne calculée, prête à devenir une `BillLine` (mêmes noms de champs)."""

    position: int
    kind: BillLineKind
    label: str
    amount: int
    quantity_milli: int | None = None
    unit: str | None = None
    unit_price_milli: int | None = None
    rate_bp: int | None = None
    base_amount: int | None = None


@dataclass(frozen=True, slots=True)
class BillComputation:
    """Résultat complet : les lignes et les totaux (mêmes noms que les colonnes de `Bill`)."""

    consumption_wh: int
    months_count: int
    lines: tuple[ComputedLine, ...]
    amount_ht: int
    amount_tax: int  # TVA + centimes additionnels
    amount_fees: int  # RAV + timbre (hors TVA)
    amount_total: int


def _require_int(name: str, value: object, *, minimum: int = 0) -> int:
    # bool est un int en Python : on le refuse explicitement (True ne doit pas valoir 1 kWh).
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError(f"{name} : entier attendu, reçu {type(value).__name__} ({value!r})")
    if value < minimum:
        raise ValueError(f"{name} : doit être ≥ {minimum}, reçu {value}")
    return value


def energy_amount(consumption_wh: int, price_per_kwh_milli: int) -> int:
    """Coût de l'énergie seule, tronqué au FCFA (sans frais fixes ni taxes).

    C'est aussi le « coût » affiché par l'écran Consommation (maquette client 11).
    Exemple : 571 000 Wh × 49 080 ÷ 1 000 000 = 28 024,68 → 28 024 FCFA.
    """
    _require_int("consumption_wh", consumption_wh)
    _require_int("price_per_kwh_milli", price_per_kwh_milli, minimum=1)
    return consumption_wh * price_per_kwh_milli // (WH_PER_KWH * MILLI)


def compute_bill(
    consumption_wh: int,
    months_count: int,
    tariff: TariffLike,
    *,
    energy_override: int | None = None,
) -> BillComputation:
    """Calcule les 6 lignes d'une facture E²C et ses totaux.

    `energy_override` : montant de l'énergie déjà calculé (estimation sur une période où le
    tarif a changé : chaque tranche de jours a son prix). Tout le reste (frais fixes, TVA,
    C.A., redevances, troncatures) reste calculé ici, à l'identique.
    """
    _require_int("consumption_wh", consumption_wh)
    _require_int("months_count", months_count, minimum=1)
    if months_count > MAX_MONTHS:
        raise ValueError(f"months_count : doit être ≤ {MAX_MONTHS}, reçu {months_count}")
    price = _require_int("price_per_kwh_milli", tariff.price_per_kwh_milli, minimum=1)
    fixed_fee = _require_int("fixed_fee_per_month", tariff.fixed_fee_per_month)
    vat_rate = _require_int("vat_rate_bp", tariff.vat_rate_bp)
    additional_rate = _require_int("additional_tax_rate_bp", tariff.additional_tax_rate_bp)
    audiovisual_fee = _require_int("audiovisual_fee", tariff.audiovisual_fee)
    stamp_fee = _require_int("stamp_fee", tariff.stamp_fee)
    for name, rate in (("vat_rate_bp", vat_rate), ("additional_tax_rate_bp", additional_rate)):
        if rate > BASIS_POINTS:
            raise ValueError(f"{name} : doit être ≤ {BASIS_POINTS} (100 %), reçu {rate}")

    if energy_override is None:
        energy = energy_amount(consumption_wh, price)
    else:
        energy = _require_int("energy_override", energy_override)
    fixed = fixed_fee * months_count
    amount_ht = energy + fixed
    vat = amount_ht * vat_rate // BASIS_POINTS
    additional_tax = vat * additional_rate // BASIS_POINTS

    lines = (
        ComputedLine(
            position=1,
            kind=BillLineKind.ENERGY,
            label="Montant consommation",
            amount=energy,
            quantity_milli=consumption_wh,  # Wh = millièmes de kWh
            unit="kWh",
            unit_price_milli=price,
        ),
        ComputedLine(
            position=2,
            kind=BillLineKind.FIXED_FEE,
            label="Droit à la consommation",
            amount=fixed,
            quantity_milli=months_count * MILLI,
            unit="mois",
            unit_price_milli=fixed_fee * MILLI,
        ),
        ComputedLine(
            position=3,
            kind=BillLineKind.AUDIOVISUAL_FEE,
            label="Redevance audiovisuelle (RAV)",
            amount=audiovisual_fee,
        ),
        ComputedLine(
            position=4,
            kind=BillLineKind.VAT,
            label="T.V.A.",
            amount=vat,
            rate_bp=vat_rate,
            base_amount=amount_ht,
        ),
        ComputedLine(
            position=5,
            kind=BillLineKind.ADDITIONAL_TAX,
            label="Centimes additionnels (C.A.)",
            amount=additional_tax,
            rate_bp=additional_rate,
            base_amount=vat,
        ),
        ComputedLine(
            position=6,
            kind=BillLineKind.STAMP,
            label="Timbre électronique",
            amount=stamp_fee,
        ),
    )
    amount_tax = vat + additional_tax
    amount_fees = audiovisual_fee + stamp_fee
    return BillComputation(
        consumption_wh=consumption_wh,
        months_count=months_count,
        lines=lines,
        amount_ht=amount_ht,
        amount_tax=amount_tax,
        amount_fees=amount_fees,
        amount_total=amount_ht + amount_tax + amount_fees,
    )
