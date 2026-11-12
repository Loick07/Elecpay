"""Contraintes des tables `meter_readings` et `tariffs` (B1.4), et nouveaux champs de `meters`."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import text
from sqlalchemy.exc import StatementError

from app.modules.consumption.models import ReadingSource
from tests.db_helpers import expect_db_rejection
from tests.factories import make_meter, make_reading, make_tariff

READ_AT = datetime(2026, 8, 31, 23, 0, tzinfo=UTC)


# --- meters : correspondance avec la facture E²C ------------------------------------


def test_meter_stores_e2c_identifiers(db_session):
    meter = make_meter(
        db_session,
        reference="0018 00 0000",  # N° Branchement (valeur fictive)
        contract_number="0000000X",  # N° Police
        customer_number="0000000Y",  # N° Client
        e2c_center="POINTE-NOIRE",
        subscribed_power_va=3_000,  # « Puissance souscrite 03 »
    )
    db_session.expire(meter)
    assert (meter.customer_number, meter.e2c_center) == ("0000000Y", "POINTE-NOIRE")


# --- meter_readings -----------------------------------------------------------------


def test_reading_defaults(db_session):
    reading = make_reading(db_session, make_meter(db_session))
    db_session.expire(reading)
    assert reading.is_estimated is False
    assert reading.is_anomaly is False
    assert reading.anomaly_reason is None
    assert reading.source is ReadingSource.SIMULATED
    assert reading.read_at == READ_AT


def test_one_reading_per_meter_and_instant(db_session):
    meter = make_meter(db_session)
    make_reading(db_session, meter, read_at=READ_AT)
    with expect_db_rejection(db_session, "uq_meter_readings_meter_id_read_at"):
        make_reading(db_session, meter, read_at=READ_AT)


def test_same_instant_on_two_meters_is_allowed(db_session):
    make_reading(db_session, make_meter(db_session), read_at=READ_AT)
    make_reading(db_session, make_meter(db_session), read_at=READ_AT)


def test_large_index_is_stored_exactly(db_session):
    reading = make_reading(db_session, make_meter(db_session), index_wh=987_654_321_123)
    db_session.expire(reading)
    assert reading.index_wh == 987_654_321_123


@pytest.mark.parametrize("column", ["index_wh", "consumption_wh"])
def test_float_energy_is_refused(db_session, column):
    with pytest.raises(StatementError, match="Entier attendu"):
        make_reading(db_session, make_meter(db_session), **{column: 9.5})
    db_session.rollback()


@pytest.mark.parametrize("column", ["index_wh", "consumption_wh"])
def test_negative_energy_is_refused(db_session, column):
    with expect_db_rejection(db_session, f"ck_meter_readings_{column}_non_negative"):
        make_reading(db_session, make_meter(db_session), **{column: -1})


def test_anomaly_with_reason_is_accepted(db_session):
    reading = make_reading(
        db_session,
        make_meter(db_session),
        consumption_wh=0,
        is_anomaly=True,
        anomaly_reason="Index inférieur au relevé précédent",
    )
    assert reading.is_anomaly is True


@pytest.mark.parametrize("reason", [None, "", "   "])
def test_anomaly_without_reason_is_refused(db_session, reason):
    with expect_db_rejection(db_session, "ck_meter_readings_anomaly_has_reason"):
        make_reading(db_session, make_meter(db_session), is_anomaly=True, anomaly_reason=reason)


def test_reason_without_anomaly_is_refused(db_session):
    with expect_db_rejection(db_session, "ck_meter_readings_anomaly_has_reason"):
        make_reading(db_session, make_meter(db_session), anomaly_reason="motif orphelin")


def test_unknown_reading_source_is_refused(db_session):
    reading = make_reading(db_session, make_meter(db_session))
    with expect_db_rejection(db_session, "ck_meter_readings_source"):
        db_session.execute(
            text("UPDATE meter_readings SET source = 'excel' WHERE id = :id"), {"id": reading.id}
        )


def test_meter_with_readings_cannot_be_deleted(db_session):
    meter = make_meter(db_session)
    make_reading(db_session, meter)
    with expect_db_rejection(db_session, "fk_meter_readings_meter_id_meters"):
        db_session.execute(text("DELETE FROM meters WHERE id = :id"), {"id": meter.id})


# --- tariffs : valeurs ---------------------------------------------------------------


def test_tariff_from_real_e2c_bill(db_session):
    tariff = make_tariff(db_session, source_note="Facture E²C BT juillet-août 2026")
    db_session.expire(tariff)
    assert tariff.price_per_kwh_milli == 49_080
    assert tariff.is_assumption is True  # tant que non vérifié sur plusieurs factures
    assert tariff.valid_to is None


@pytest.mark.parametrize(
    ("column", "value", "constraint"),
    [
        ("price_per_kwh_milli", 0, "ck_tariffs_price_positive"),
        ("fixed_fee_per_month", -1, "ck_tariffs_fixed_fee_per_month_non_negative"),
        ("audiovisual_fee", -1, "ck_tariffs_audiovisual_fee_non_negative"),
        ("stamp_fee", -1, "ck_tariffs_stamp_fee_non_negative"),
        ("vat_rate_bp", 10_001, "ck_tariffs_vat_rate_bp_range"),
        ("vat_rate_bp", -1, "ck_tariffs_vat_rate_bp_range"),
        ("additional_tax_rate_bp", 10_001, "ck_tariffs_additional_tax_rate_bp_range"),
        ("code", "  ", "ck_tariffs_code_not_blank"),
    ],
)
def test_invalid_tariff_values_are_refused(db_session, column, value, constraint):
    with expect_db_rejection(db_session, constraint):
        make_tariff(db_session, **{column: value})


def test_float_price_is_refused(db_session):
    with pytest.raises(StatementError, match="Entier attendu"):
        make_tariff(db_session, price_per_kwh_milli=49.08)
    db_session.rollback()


@pytest.mark.parametrize("valid_to", [date(2026, 1, 1), date(2025, 12, 31)])
def test_period_must_end_after_it_starts(db_session, valid_to):
    with expect_db_rejection(db_session, "ck_tariffs_valid_period"):
        make_tariff(db_session, valid_from=date(2026, 1, 1), valid_to=valid_to)


# --- tariffs : périodes sans chevauchement (triggers MySQL) -------------------------


def test_consecutive_periods_are_allowed(db_session):
    make_tariff(db_session, valid_from=date(2025, 1, 1), valid_to=date(2026, 1, 1))
    make_tariff(db_session, valid_from=date(2026, 1, 1))  # commence le jour où l'autre finit


@pytest.mark.parametrize(
    ("valid_from", "valid_to"),
    [
        (date(2025, 6, 1), date(2025, 9, 1)),  # entièrement dedans
        (date(2024, 6, 1), date(2025, 2, 1)),  # déborde au début
        (date(2025, 12, 1), None),  # déborde à la fin, sans fin
        (date(2024, 1, 1), date(2027, 1, 1)),  # englobe
    ],
)
def test_overlapping_period_is_refused(db_session, valid_from, valid_to):
    make_tariff(db_session, valid_from=date(2025, 1, 1), valid_to=date(2026, 1, 1))
    with expect_db_rejection(db_session, "tariff_period_overlap"):
        make_tariff(db_session, valid_from=valid_from, valid_to=valid_to)


def test_open_ended_tariff_blocks_any_later_start(db_session):
    make_tariff(db_session, valid_from=date(2026, 1, 1))  # sans fin
    with expect_db_rejection(db_session, "tariff_period_overlap"):
        make_tariff(db_session, valid_from=date(2027, 1, 1))


def test_closing_then_opening_a_new_tariff(db_session):
    """Changement de tarif normal : on ferme l'ancien, puis on ouvre le nouveau."""
    old = make_tariff(db_session, valid_from=date(2026, 1, 1))
    old.valid_to = date(2027, 1, 1)
    db_session.flush()
    make_tariff(db_session, valid_from=date(2027, 1, 1), price_per_kwh_milli=52_000)


def test_update_creating_an_overlap_is_refused(db_session):
    make_tariff(db_session, valid_from=date(2025, 1, 1), valid_to=date(2026, 1, 1))
    later = make_tariff(db_session, valid_from=date(2026, 1, 1))
    with expect_db_rejection(db_session, "tariff_period_overlap"):
        later.valid_from = date(2025, 6, 1)
        db_session.flush()


def test_updating_a_tariff_does_not_conflict_with_itself(db_session):
    tariff = make_tariff(db_session, valid_from=date(2026, 1, 1))
    tariff.label = "Basse tension domestique (vérifié)"
    tariff.is_assumption = False
    db_session.flush()


def test_different_codes_may_overlap(db_session):
    make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2026, 1, 1))
    make_tariff(db_session, code="BT_PROFESSIONNEL", valid_from=date(2026, 1, 1))


def test_unique_code_and_start_date(db_session):
    make_tariff(db_session, valid_from=date(2026, 1, 1), valid_to=date(2026, 6, 1))
    # Même code, même date de début : refusé (par le trigger ou par l'unicité).
    with expect_db_rejection(db_session):
        make_tariff(db_session, valid_from=date(2026, 1, 1), valid_to=date(2026, 3, 1))


def test_trigger_also_protects_raw_sql(db_session):
    make_tariff(db_session, valid_from=date(2026, 1, 1))
    with expect_db_rejection(db_session, "tariff_period_overlap"):
        db_session.execute(
            text(
                "INSERT INTO tariffs (code, label, price_per_kwh_milli, fixed_fee_per_month,"
                " vat_rate_bp, additional_tax_rate_bp, audiovisual_fee, stamp_fee, valid_from,"
                " created_at, updated_at) VALUES ('BT_DOMESTIQUE', 'x', 1, 0, 0, 0, 0, 0,"
                " :d, NOW(6), NOW(6))"
            ),
            {"d": date(2026, 1, 1) + timedelta(days=30)},
        )
