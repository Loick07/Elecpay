"""Tests de la source E²C (B4.4) : normalisation des numéros et source simulée."""

import re

import pytest

from app.integrations.billing_sources.base import (
    display_reference,
    normalize_customer_number,
    normalize_reference,
)
from app.integrations.billing_sources.factory import get_billing_source
from app.integrations.billing_sources.simulated import (
    SIMULATED_POWERS_VA,
    SimulatedBillingSource,
    demo_registry,
)
from app.modules.meters.models import MeterType

SOURCE = SimulatedBillingSource()


def lookup(reference, customer_number):
    return SOURCE.lookup_meter(
        normalize_reference(reference), normalize_customer_number(customer_number)
    )


# --- Normalisation des numéros de la facture ----------------------------------------


@pytest.mark.parametrize("raw", ["0018 09 5408", "0018-09-5408", "0018095408", " 0018.09.5408 "])
def test_reference_written_in_any_common_way(raw):
    assert normalize_reference(raw) == "0018095408"


@pytest.mark.parametrize("raw", ["", "0018 09", "0018 09 5408 999", "00A8 09 5408", "abcdefghij"])
def test_invalid_reference(raw):
    with pytest.raises(ValueError, match="branchement"):
        normalize_reference(raw)


@pytest.mark.parametrize("raw", ["0758340H", "0758340h", " 0758 340 H "])
def test_customer_number_written_in_any_common_way(raw):
    assert normalize_customer_number(raw) == "0758340H"


@pytest.mark.parametrize("raw", ["", "0758340", "H0758340", "07583H", "075834012345H", "0758340HH"])
def test_invalid_customer_number(raw):
    with pytest.raises(ValueError, match="client"):
        normalize_customer_number(raw)


def test_reference_display_format_of_the_bill():
    assert display_reference("0018095408") == "0018 09 5408"
    assert display_reference("04128833") == "04128833"


# --- Compteurs du jeu de démo -------------------------------------------------------


def test_demo_meters_are_all_known():
    assert len(demo_registry()) == 16


def test_demo_meter_with_the_right_customer_number():
    info = lookup("0377-1209", "3771209H")  # Boutique Tié-Tié
    assert info is not None
    assert (info.reference, info.e2c_center, info.subscribed_power_va) == (
        "0377-1209",
        "POINTE-NOIRE",
        9_000,
    )
    assert info.meter_type is MeterType.POSTPAID


def test_demo_meter_with_a_wrong_customer_number_is_refused():
    """On n'ajoute pas le compteur de quelqu'un d'autre sans sa facture."""
    assert lookup("0377-1209", "1111111H") is None


# --- Autres compteurs (simulés) -----------------------------------------------------


def test_unknown_meter_is_found_with_stable_details():
    first = lookup("0018 09 5408", "0758340H")
    again = SimulatedBillingSource().lookup_meter("0018095408", "0758340H")
    assert first == again  # même compteur, mêmes caractéristiques, à chaque fois
    assert first.reference == "0018 09 5408"
    assert first.customer_number == "0758340H"
    assert re.fullmatch(r"[0-9]{7}K", first.contract_number)
    assert first.subscribed_power_va in SIMULATED_POWERS_VA


def test_different_meters_get_varied_details():
    infos = [lookup(f"0018 09 {n:04d}", "0758340H") for n in range(1, 60)]
    assert len({i.subscribed_power_va for i in infos}) > 1
    assert len({i.e2c_center for i in infos}) > 1


def test_references_ending_with_0000_are_not_found():
    assert lookup("0018 09 0000", "0758340H") is None


# --- Choix par configuration --------------------------------------------------------


def test_configuration_selects_the_simulated_source(test_settings):
    assert isinstance(get_billing_source(test_settings), SimulatedBillingSource)
