"""Tests du détail d'une facture (B6.4) : GET /bills/{id}, et de son PDF (B6.5)."""

import io
from datetime import UTC, date, datetime

import pytest
from pypdf import PdfReader

from app.modules.bills.calculator import compute_bill
from app.modules.bills.models import BillSource, BillStatus
from app.modules.bills.pdf import render_bill_pdf
from app.modules.bills.queries import BillQueries, change_percent
from app.modules.bills.service import generate_bill
from app.modules.households.models import MemberRole, MemberStatus
from tests.factories import (
    Billing,
    make_household,
    make_member,
    make_meter,
    make_tariff,
    make_user,
)
from tests.test_bill_service import reading

TODAY = date(2026, 11, 12)


@pytest.fixture(autouse=True)
def fixed_today(monkeypatch):
    original = BillQueries.__init__
    monkeypatch.setattr(
        BillQueries,
        "__init__",
        lambda self, session, today=None: original(self, session, lambda: TODAY),
    )


@pytest.fixture
def world(db_session):
    """Compteur de la vraie facture : mai-juin 2026 (383 kWh) puis juillet-août (571 kWh)."""
    tariff = make_tariff(db_session, valid_from=date(2025, 1, 1))
    owner = make_user(db_session)
    home = make_household(db_session, owner, name="Maison Mpita")
    meter = make_meter(
        db_session,
        home,
        reference="0018 09 5408",
        label="Maison",
        contract_number="0912345",
        customer_number="0758340H",
        e2c_center="POINTE-NOIRE",
        subscribed_power_va=3_000,
    )
    reading(db_session, meter, date(2026, 5, 1), 13_900_000, 8_000)
    reading(db_session, meter, date(2026, 7, 1), 14_283_000, 383_000)
    reading(db_session, meter, date(2026, 9, 1), 14_854_000, 571_000)

    def issue(start):
        return generate_bill(
            db_session, meter, start, today=date(2026, 9, 3), settings=Billing()
        ).bill

    may, july = issue(date(2026, 5, 1)), issue(date(2026, 7, 1))
    return {
        "owner": owner,
        "home": home,
        "meter": meter,
        "tariff": tariff,
        "may": may,
        "july": july,
    }


def detail(client, headers, bill):
    return client.get(f"/api/v1/bills/{bill.id}", headers=headers)


# --- Contenu ------------------------------------------------------------------------------


def test_detail_of_the_real_e2c_bill(client, auth_headers, world):
    response = detail(client, auth_headers(world["owner"]), world["july"])
    assert response.status_code == 200
    body = response.json()
    assert body["reference"] == world["july"].reference
    assert (body["period_label"], body["period_start"], body["period_end"]) == (
        "Juil.-Août 2026",
        "2026-07-01",
        "2026-08-31",
    )
    assert (body["previous_index_wh"], body["current_index_wh"]) == (14_283_000, 14_854_000)
    assert (body["previous_index_kwh"], body["current_index_kwh"]) == (14_283.0, 14_854.0)
    assert (body["consumption_wh"], body["consumption_kwh"]) == (571_000, 571.0)
    assert (body["amount_ht"], body["amount_tax"], body["amount_fees"]) == (33_124, 6_260, 1_000)
    assert body["amount_total"] == 40_384
    assert (body["issued_at"], body["due_date"]) == ("2026-09-03T07:00:00Z", "2026-09-18")
    assert body["billed_power_va"] == 3_000
    assert (body["meter_reference"], body["meter_label"]) == ("0018 09 5408", "Maison")
    assert (body["meter_contract_number"], body["meter_customer_number"]) == (
        "0912345",
        "0758340H",
    )
    assert body["e2c_center"] == "POINTE-NOIRE"
    assert body["household_name"] == "Maison Mpita"
    assert body["source"] == "simulated"
    assert (body["cancelled_at"], body["cancelled_reason"]) == (None, None)


def test_lines_can_be_checked_by_hand(client, auth_headers, world):
    lines = detail(client, auth_headers(world["owner"]), world["july"]).json()["lines"]
    assert [line["position"] for line in lines] == [1, 2, 3, 4, 5, 6]
    energy, fixed, rav, vat, additional, stamp = lines
    assert (energy["kind"], energy["label"]) == ("energy", "Montant consommation")
    assert (energy["quantity_milli"], energy["quantity"], energy["unit"]) == (571_000, 571.0, "kWh")
    assert (energy["unit_price_milli"], energy["unit_price"]) == (49_080, 49.08)
    assert energy["amount"] == 28_024  # 571 × 49,08 = 28 024,68 → tronqué
    assert (fixed["quantity"], fixed["unit"], fixed["unit_price"], fixed["amount"]) == (
        2.0,
        "mois",
        2_550.0,
        5_100,
    )
    assert (rav["kind"], rav["amount"], rav["quantity"], rav["rate_bp"]) == (
        "audiovisual_fee",
        1_000,
        None,
        None,
    )
    assert (vat["rate_bp"], vat["rate_percent"], vat["base_amount"], vat["amount"]) == (
        1_800,
        18.0,
        33_124,
        5_962,
    )
    assert (additional["rate_percent"], additional["base_amount"], additional["amount"]) == (
        5.0,
        5_962,
        298,
    )
    assert (stamp["kind"], stamp["amount"]) == ("stamp", 0)
    assert sum(line["amount"] for line in lines) == 40_384


def test_tariff_is_shown_as_an_assumption(client, auth_headers, world):
    tariff = detail(client, auth_headers(world["owner"]), world["july"]).json()["tariff"]
    assert tariff == {
        "id": world["tariff"].id,
        "code": "BT_DOMESTIQUE",
        "label": "Basse tension domestique",
        "price_per_kwh_milli": 49_080,
        "is_assumption": True,
    }


# --- Comparaison avec la facture précédente ------------------------------------------------


def test_comparison_with_the_previous_bill(client, auth_headers, world):
    previous = detail(client, auth_headers(world["owner"]), world["july"]).json()["previous_bill"]
    may_total = compute_bill(383_000, 2, world["tariff"]).amount_total
    assert previous == {
        "bill_id": world["may"].id,
        "reference": world["may"].reference,
        "period_label": "Mai-Juin 2026",
        "consumption_wh": 383_000,
        "consumption_kwh": 383.0,
        "amount_total": may_total,
        "consumption_change_wh": 188_000,
        "consumption_change_percent": 49.1,  # (571 − 383) / 383
        "amount_change": 40_384 - may_total,
        "amount_change_percent": change_percent(may_total, 40_384),
    }


def test_the_first_bill_has_nothing_to_compare_with(client, auth_headers, world):
    body = detail(client, auth_headers(world["owner"]), world["may"]).json()
    assert body["previous_bill"] is None


def test_a_cancelled_previous_bill_is_skipped(client, auth_headers, db_session, world):
    cancel(db_session, world["may"])
    body = detail(client, auth_headers(world["owner"]), world["july"]).json()
    assert body["previous_bill"] is None


@pytest.mark.parametrize(
    ("before", "after", "expected"),
    [(383, 571, 49.1), (100, 50, -50.0), (100, 100, 0.0), (0, 10, None)],
)
def test_change_percent(before, after, expected):
    assert change_percent(before, after) == expected


# --- Statut et paiement ------------------------------------------------------------------


def test_status_is_overdue_on_display_after_the_due_date(client, auth_headers, world):
    body = detail(client, auth_headers(world["owner"]), world["july"]).json()
    assert (body["status"], body["days_overdue"], body["can_pay"]) == ("overdue", 55, True)


def test_a_paid_bill_cannot_be_paid_again(client, auth_headers, db_session, world):
    world["july"].status = BillStatus.PAID
    world["july"].paid_at = datetime(2026, 9, 10, 9, 0, tzinfo=UTC)
    db_session.flush()
    body = detail(client, auth_headers(world["owner"]), world["july"]).json()
    assert (body["status"], body["can_pay"]) == ("paid", False)
    assert body["paid_at"] == "2026-09-10T09:00:00Z"


def test_a_cancelled_bill_stays_readable_with_its_reason(client, auth_headers, db_session, world):
    cancel(db_session, world["july"])
    response = detail(client, auth_headers(world["owner"]), world["july"])
    assert response.status_code == 200
    body = response.json()
    assert (body["status"], body["can_pay"]) == ("cancelled", False)
    assert body["cancelled_reason"] == "Index relevé par erreur"
    assert body["cancelled_at"] == "2026-09-05T00:00:00Z"


def cancel(session, bill):
    bill.status = BillStatus.CANCELLED
    bill.cancelled_at = datetime(2026, 9, 5, tzinfo=UTC)
    bill.cancelled_reason = "Index relevé par erreur"
    session.flush()


# --- Accès --------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("role", "can_pay"),
    [(MemberRole.PAYER, True), (MemberRole.VIEWER, False)],
)
def test_household_members_see_the_bill(client, auth_headers, db_session, world, role, can_pay):
    member = make_user(db_session)
    make_member(db_session, world["home"], member, role=role, status=MemberStatus.ACTIVE)
    body = detail(client, auth_headers(member), world["july"]).json()
    assert (body["my_role"], body["can_pay"]) == (role.value, can_pay)


def test_a_pending_invitation_gives_no_access(client, auth_headers, db_session, world):
    member = make_user(db_session)
    make_member(db_session, world["home"], member, status=MemberStatus.INVITED)
    assert detail(client, auth_headers(member), world["july"]).status_code == 404


def test_someone_elses_bill_looks_like_a_missing_one(client, auth_headers, db_session, world):
    stranger = make_user(db_session)
    theirs = detail(client, auth_headers(stranger), world["july"])
    missing = client.get("/api/v1/bills/999999999", headers=auth_headers(stranger))
    assert theirs.status_code == missing.status_code == 404
    assert theirs.json() == missing.json()
    assert theirs.json()["error"]["code"] == "BILL_NOT_FOUND"


def test_bill_of_a_detached_meter_is_not_found(client, auth_headers, db_session, world):
    world["meter"].household_id = None
    db_session.flush()
    assert detail(client, auth_headers(world["owner"]), world["july"]).status_code == 404


def test_login_is_required(client, world):
    assert client.get(f"/api/v1/bills/{world['july'].id}").status_code == 401


def test_bill_id_must_be_a_number(client, auth_headers, world):
    response = client.get("/api/v1/bills/abc", headers=auth_headers(world["owner"]))
    assert response.status_code == 422


# --- PDF (B6.5) -----------------------------------------------------------------------------


def pdf(client, headers, bill):
    return client.get(f"/api/v1/bills/{bill.id}/pdf", headers=headers)


def pdf_text(content: bytes) -> str:
    reader = PdfReader(io.BytesIO(content))
    return "\n".join(page.extract_text() for page in reader.pages)


def test_pdf_is_a_downloadable_file(client, auth_headers, world):
    response = pdf(client, auth_headers(world["owner"]), world["july"])
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.headers["content-disposition"] == (
        f'attachment; filename="facture-{world["july"].reference}.pdf"'
    )
    assert response.headers["cache-control"] == "private, no-store"
    assert response.content.startswith(b"%PDF-")
    assert len(PdfReader(io.BytesIO(response.content)).pages) == 1


def test_pdf_shows_the_bill_like_e2c(client, auth_headers, world):
    text = pdf_text(pdf(client, auth_headers(world["owner"]), world["july"]).content)
    for expected in (
        world["july"].reference,
        "Juil.-Août 2026",
        "du 01/07/2026 au 31/08/2026",
        "Maison Mpita",
        "0018 09 5408",  # N° Branchement
        "0912345",  # N° Police
        "0758340H",  # N° Client
        "POINTE-NOIRE",
        "3 kVA",
        "14 283 kWh",
        "14 854 kWh",
        "571 kWh",
        "49,08",
        "28 024",
        "5 100",
        "18 %",
        "33 124",
        "5 962",
        "298",
        "NET À PAYER",
        "40 384 FCFA",
        "Échéance",
        "18/09/2026",
        "En retard (55 j)",
        "Mai-Juin 2026",  # facture précédente
        "Valeurs à confirmer",  # tarif encore hypothèse
    ):
        assert expected in text, expected


def test_pdf_never_passes_for_an_official_bill(client, auth_headers, world):
    text = pdf_text(pdf(client, auth_headers(world["owner"]), world["july"]).content)
    assert "MODE DÉMO" in text
    assert "n'est pas une facture E²C" in text
    assert "seule la facture E²C fait foi" in text


def test_pdf_of_a_paid_bill(client, auth_headers, db_session, world):
    world["july"].status = BillStatus.PAID
    world["july"].paid_at = datetime(2026, 9, 10, 9, 0, tzinfo=UTC)
    db_session.flush()
    text = pdf_text(pdf(client, auth_headers(world["owner"]), world["july"]).content)
    assert "Payée le 10/09/2026" in text
    assert "TOTAL PAYÉ" in text and "NET À PAYER" not in text


def test_pdf_of_a_cancelled_bill(client, auth_headers, db_session, world):
    cancel(db_session, world["july"])
    text = pdf_text(pdf(client, auth_headers(world["owner"]), world["july"]).content)
    assert "FACTURE ANNULÉE le 05/09/2026" in text
    assert "Index relevé par erreur" in text
    assert "TOTAL ANNULÉ" in text and "NET À PAYER" not in text


def test_pdf_access_is_the_same_as_the_detail(client, auth_headers, db_session, world):
    stranger = make_user(db_session)
    response = pdf(client, auth_headers(stranger), world["july"])
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "BILL_NOT_FOUND"
    assert client.get(f"/api/v1/bills/{world['july'].id}/pdf").status_code == 401
    viewer = make_user(db_session)
    make_member(
        db_session, world["home"], viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE
    )
    assert pdf(client, auth_headers(viewer), world["july"]).status_code == 200


def test_demo_banner_follows_the_data_and_the_mode(db_session, world):
    detail = BillQueries(db_session).detail(world["owner"], world["july"].id)
    at = datetime(2026, 11, 12, 10, 0, tzinfo=UTC)
    simulated = pdf_text(render_bill_pdf(detail, generated_at=at, demo_mode=False))
    assert "MODE DÉMO" in simulated  # données simulées : toujours signalé
    real = detail.model_copy(update={"source": BillSource.E2C})
    assert "MODE DÉMO" not in pdf_text(render_bill_pdf(real, generated_at=at, demo_mode=False))
    assert "MODE DÉMO" in pdf_text(render_bill_pdf(real, generated_at=at, demo_mode=True))


def test_pdf_says_when_it_was_generated(db_session, world):
    detail = BillQueries(db_session).detail(world["owner"], world["july"].id)
    content = render_bill_pdf(
        detail, generated_at=datetime(2026, 11, 12, 9, 30, tzinfo=UTC), demo_mode=True
    )
    assert "le 12/11/2026 à 10:30 (heure de Brazzaville)" in pdf_text(content)
    metadata = PdfReader(io.BytesIO(content)).metadata
    assert metadata.title == f"Facture {world['july'].reference}"
    assert metadata.author == "ElecPay"
