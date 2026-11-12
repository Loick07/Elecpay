"""Tests du moteur de calcul de facture (B2.1).

Test de référence : reproduire au franc près une vraie facture E²C BT (juillet-août 2026).
"""

import random
from dataclasses import asdict, dataclass, replace
from datetime import UTC, date, datetime

import pytest
from sqlalchemy import func, select

from app.modules.bills.calculator import compute_bill, energy_amount
from app.modules.bills.models import Bill, BillLine, BillLineKind, BillSource
from tests.factories import make_meter, make_tariff


@dataclass(frozen=True)
class Rates:
    """Tarif lu sur la vraie facture (hypothèses : frais fixes mensuels, RAV par facture)."""

    price_per_kwh_milli: int = 49_080  # 49,08 FCFA/kWh
    fixed_fee_per_month: int = 2_550  # 5 100 sur 2 mois
    vat_rate_bp: int = 1_800  # 18 %
    additional_tax_rate_bp: int = 500  # 5 % de la TVA
    audiovisual_fee: int = 1_000
    stamp_fee: int = 0


E2C = Rates()


# --- La facture de référence --------------------------------------------------------


def test_reproduces_the_real_e2c_bill_exactly():
    result = compute_bill(571_000, 2, E2C)  # 571 kWh sur 2 mois

    amounts = {line.kind: line.amount for line in result.lines}
    assert amounts == {
        BillLineKind.ENERGY: 28_024,  # 571 × 49,08 = 28 024,68 → tronqué
        BillLineKind.FIXED_FEE: 5_100,
        BillLineKind.AUDIOVISUAL_FEE: 1_000,
        BillLineKind.VAT: 5_962,  # 33 124 × 18 % = 5 962,32
        BillLineKind.ADDITIONAL_TAX: 298,  # 5 962 × 5 % = 298,1
        BillLineKind.STAMP: 0,
    }
    assert result.amount_ht == 33_124
    assert result.amount_tax == 6_260
    assert result.amount_fees == 1_000
    assert result.amount_total == 40_384  # « TOTAL A PAYER » de la facture


def test_lines_carry_what_is_needed_to_redo_the_math():
    energy, fixed, rav, vat, additional, stamp = compute_bill(571_000, 2, E2C).lines
    assert (energy.quantity_milli, energy.unit, energy.unit_price_milli) == (571_000, "kWh", 49_080)
    assert (fixed.quantity_milli, fixed.unit, fixed.unit_price_milli) == (2_000, "mois", 2_550_000)
    assert (vat.rate_bp, vat.base_amount) == (1_800, 33_124)
    assert (additional.rate_bp, additional.base_amount) == (500, 5_962)  # C.A. sur la TVA
    assert rav.rate_bp is None and rav.quantity_milli is None
    assert stamp.amount == 0


def test_lines_are_in_e2c_order():
    result = compute_bill(571_000, 2, E2C)
    assert [line.position for line in result.lines] == [1, 2, 3, 4, 5, 6]
    assert [line.label for line in result.lines] == [
        "Montant consommation",
        "Droit à la consommation",
        "Redevance audiovisuelle (RAV)",
        "T.V.A.",
        "Centimes additionnels (C.A.)",
        "Timbre électronique",
    ]


# --- Troncature ---------------------------------------------------------------------


@pytest.mark.parametrize(
    ("wh", "expected"),
    [
        (571_000, 28_024),  # 28 024,68 : jamais arrondi à 28 025
        (999, 49),  # 0,999 kWh → 49,03
        (20, 0),  # 0,98 FCFA → 0
        (0, 0),
        (1_000, 49),  # 1 kWh → 49,08
        (212_400, 10_424),  # 212,4 kWh (maquettes) → 10 424,59
    ],
)
def test_energy_is_truncated_never_rounded(wh, expected):
    assert energy_amount(wh, 49_080) == expected


def test_vat_and_additional_tax_are_truncated():
    # HT = 1 FCFA d'énergie + 0 de frais fixes → TVA 0,18 → 0
    tiny = replace(E2C, fixed_fee_per_month=0, audiovisual_fee=0)
    result = compute_bill(21, 1, tiny)  # 21 Wh × 49,08 = 1,03 → 1
    assert result.amount_ht == 1
    assert result.amount_tax == 0


# --- Autres cas ---------------------------------------------------------------------


def test_zero_consumption_still_pays_fixed_fees_and_taxes():
    result = compute_bill(0, 2, E2C)
    assert result.amount_ht == 5_100
    assert result.amount_tax == 918 + 45  # TVA 918, C.A. 45,9 → 45
    assert result.amount_total == 5_100 + 963 + 1_000


@pytest.mark.parametrize(("months", "fixed"), [(1, 2_550), (2, 5_100), (3, 7_650), (12, 30_600)])
def test_fixed_fee_follows_the_number_of_months(months, fixed):
    assert compute_bill(0, months, E2C).lines[1].amount == fixed


def test_very_large_consumption_is_exact():
    result = compute_bill(10_000_000_000, 12, E2C)  # 10 GWh, aucun dépassement en Python
    assert result.lines[0].amount == 490_800_000


def test_accepts_the_tariff_model_directly(db_session):
    tariff = make_tariff(db_session)  # les valeurs de la vraie facture
    assert compute_bill(571_000, 2, tariff).amount_total == 40_384


def test_total_is_always_the_sum_of_lines_and_never_negative():
    rng = random.Random(2026)  # hasard fixé : test reproductible
    for _ in range(2_000):
        rates = Rates(
            price_per_kwh_milli=rng.randint(1, 200_000),
            fixed_fee_per_month=rng.randint(0, 20_000),
            vat_rate_bp=rng.randint(0, 10_000),
            additional_tax_rate_bp=rng.randint(0, 10_000),
            audiovisual_fee=rng.randint(0, 5_000),
            stamp_fee=rng.randint(0, 1_000),
        )
        result = compute_bill(rng.randint(0, 5_000_000), rng.randint(1, 12), rates)
        assert result.amount_total == sum(line.amount for line in result.lines)
        assert result.amount_total == result.amount_ht + result.amount_tax + result.amount_fees
        assert all(line.amount >= 0 for line in result.lines)


# --- Énergie déjà calculée (estimations multi-tarifs, B5.2) -------------------------


def test_energy_override_replaces_only_the_energy_line():
    normal = compute_bill(571_000, 2, E2C)
    overridden = compute_bill(571_000, 2, E2C, energy_override=30_000)
    assert overridden.lines[0].amount == 30_000
    assert overridden.lines[1:3] == normal.lines[1:3]  # frais fixes et RAV inchangés
    assert overridden.amount_ht == 30_000 + 5_100
    assert (
        overridden.amount_tax
        == 35_100 * 1_800 // 10_000 + (35_100 * 1_800 // 10_000) * 500 // 10_000
    )


@pytest.mark.parametrize("bad", [30_000.5, -1, True])
def test_invalid_energy_override_is_refused(bad):
    with pytest.raises((TypeError, ValueError)):
        compute_bill(571_000, 2, E2C, energy_override=bad)


# --- Entrées refusées ---------------------------------------------------------------


@pytest.mark.parametrize("consumption", [571.0, "571000", True, None])
def test_non_integer_consumption_is_refused(consumption):
    with pytest.raises(TypeError, match="entier attendu"):
        compute_bill(consumption, 2, E2C)


@pytest.mark.parametrize(("consumption", "months"), [(-1, 2), (571_000, 0), (571_000, 13)])
def test_out_of_range_inputs_are_refused(consumption, months):
    with pytest.raises(ValueError, match="doit être"):
        compute_bill(consumption, months, E2C)


@pytest.mark.parametrize(
    "bad",
    [
        {"price_per_kwh_milli": 49.08},
        {"price_per_kwh_milli": 0},
        {"fixed_fee_per_month": -1},
        {"vat_rate_bp": 10_001},
        {"additional_tax_rate_bp": -5},
        {"audiovisual_fee": 1_000.0},
    ],
)
def test_invalid_tariff_is_refused(bad):
    with pytest.raises((TypeError, ValueError)):
        compute_bill(571_000, 2, replace(E2C, **bad))


# --- Le résultat s'enregistre tel quel en base --------------------------------------


def test_computation_is_accepted_by_the_database(db_session):
    """Les lignes et totaux calculés respectent toutes les contraintes de `bills`."""
    tariff = make_tariff(db_session)
    meter = make_meter(db_session)
    result = compute_bill(571_000, 2, tariff)
    bill = Bill(
        meter_id=meter.id,
        tariff_id=tariff.id,
        reference="CALC-0001",
        period_start=date(2026, 7, 1),
        period_end=date(2026, 8, 31),
        months_count=result.months_count,
        previous_index_wh=14_283_000,
        current_index_wh=14_283_000 + result.consumption_wh,
        consumption_wh=result.consumption_wh,
        amount_ht=result.amount_ht,
        amount_tax=result.amount_tax,
        amount_fees=result.amount_fees,
        amount_total=result.amount_total,
        due_date=date(2026, 9, 18),
        issued_at=datetime(2026, 9, 3, tzinfo=UTC),
        source=BillSource.SIMULATED,
    )
    db_session.add(bill)
    db_session.flush()
    db_session.add_all(BillLine(bill_id=bill.id, **asdict(line)) for line in result.lines)
    db_session.flush()

    total_of_lines = db_session.scalar(
        select(func.sum(BillLine.amount)).where(BillLine.bill_id == bill.id)
    )
    assert total_of_lines == bill.amount_total == 40_384
