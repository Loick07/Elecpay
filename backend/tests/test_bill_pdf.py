"""Tests des petites fonctions de mise en forme du PDF de facture (B6.5)."""

import pytest

from app.modules.bills.pdf import fr_number, fr_percent, kwh_text, latin1


@pytest.mark.parametrize(
    ("milli", "expected"),
    [
        (571_000, "571"),
        (49_080, "49,08"),
        (14_854_482, "14 854,482"),
        (2_550_000, "2 550"),
        (0, "0"),
        (100_000, "100"),
        (1_000_000_000, "1 000 000"),
    ],
)
def test_numbers_are_written_the_french_way(milli, expected):
    assert fr_number(milli) == expected


@pytest.mark.parametrize(
    ("rate_bp", "expected"), [(1_800, "18 %"), (500, "5 %"), (1_250, "12,5 %")]
)
def test_rates(rate_bp, expected):
    assert fr_percent(rate_bp) == expected


def test_energy():
    assert kwh_text(214_482) == "214,482 kWh"


def test_text_outside_latin1_is_replaced_not_lost():
    assert latin1("Index relevé par erreur – facture refaite") == (
        "Index relevé par erreur - facture refaite"
    )
    assert latin1("L’abonné « Mpita »…") == "L'abonné « Mpita »..."
    assert latin1("E²C") == "E²C"
    assert latin1("Ngoma 🙂") == "Ngoma ?"
