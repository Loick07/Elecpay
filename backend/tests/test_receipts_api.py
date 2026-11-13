"""Tests de la consultation des reçus (B8.2) : GET /receipts, GET /receipts/{id},
et du reçu en PDF avec son QR code (B8.3)."""

import io
import re
from datetime import UTC, date, datetime, timedelta

import pytest
from pypdf import PdfReader
from sqlalchemy import update

from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.households.models import HouseholdMember, MemberRole, MemberStatus
from app.modules.payments.confirmation import apply_provider_update
from app.modules.payments.models import MobileOperator
from app.modules.receipts import pdf as receipt_pdf_module
from app.modules.receipts.models import Receipt
from app.modules.receipts.pdf import render_receipt_pdf, verification_url
from app.modules.receipts.queries import ReceiptQueries
from app.modules.receipts.router import VERIFICATIONS_PER_IP
from app.modules.receipts.verification import mask_meter_reference
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_transaction,
    make_user,
)

URL = "/api/v1/receipts"
OWNER_PHONE = "+242061110001"
DELEGATE_PHONE = "+242051110002"


def paid(session, bill, payer, phone, started):
    """Un paiement réussi par la voie normale (B7.3) : le reçu naît avec le succès."""
    transaction = make_transaction(
        session,
        bill,
        payer,
        phone_number=phone,
        operator=MobileOperator.AIRTEL if phone.startswith("+24205") else MobileOperator.MTN,
        initiated_at=started,
        expires_at=started + timedelta(minutes=10),
    )
    confirmed = started + timedelta(seconds=10)
    update_ = ProviderUpdate(
        f"SIM-{transaction.id}", ProviderState.SUCCEEDED, confirmed, amount=transaction.amount
    )
    apply_provider_update(session, transaction.id, update_, origin="test", now=confirmed)
    return session.query(Receipt).filter_by(transaction_id=transaction.id).one()


@pytest.fixture
def world(db_session):
    owner = make_user(db_session, phone=OWNER_PHONE, full_name="Arnaud Mavoungou")
    delegate = make_user(db_session, phone=DELEGATE_PHONE, full_name="Grâce Ngoma")
    viewer = make_user(db_session, full_name="Joël Mavoungou")
    home = make_household(db_session, owner, name="Maison Mpita")
    shop = make_household(db_session, owner, name="Boutique")
    make_member(db_session, home, delegate, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    home_meter = make_meter(db_session, home, reference="0412-8833")
    july = make_bill(db_session, home_meter)
    sept = make_bill(
        db_session,
        home_meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=date(2026, 11, 18),
    )
    shop_bill = make_bill(db_session, make_meter(db_session, shop))
    receipts = {
        "july": paid(db_session, july, owner, OWNER_PHONE, datetime(2026, 9, 11, 9, tzinfo=UTC)),
        "sept": paid(
            db_session, sept, delegate, DELEGATE_PHONE, datetime(2026, 11, 10, 9, tzinfo=UTC)
        ),
        "shop": paid(
            db_session, shop_bill, owner, OWNER_PHONE, datetime(2025, 12, 20, 9, tzinfo=UTC)
        ),
    }
    stranger = make_user(db_session)
    stranger_home = make_household(db_session, stranger)
    paid(
        db_session,
        make_bill(db_session, make_meter(db_session, stranger_home)),
        stranger,
        "+242069999901",
        datetime(2026, 10, 1, 9, tzinfo=UTC),
    )
    return {
        "owner": owner,
        "delegate": delegate,
        "viewer": viewer,
        "home": home,
        "shop": shop,
        "stranger": stranger,
        "stranger_home": stranger_home,
        "receipts": receipts,
    }


def get(client, headers, **params):
    return client.get(URL, params=params, headers=headers)


def ids(response):
    return [item["id"] for item in response.json()["items"]]


def receipt_ids(world, *names):
    return [world["receipts"][name].id for name in names]


# --- Liste --------------------------------------------------------------------------------


def test_owner_lists_receipts_most_recent_first(client, auth_headers, world):
    response = get(client, auth_headers(world["owner"]))
    assert response.status_code == 200
    assert ids(response) == receipt_ids(world, "sept", "july", "shop")
    assert response.json()["total"] == 3


def test_numbers_follow_the_year_of_issue(world):
    receipts = world["receipts"]
    assert receipts["shop"].number == "EP-2025-000001"
    assert (receipts["july"].number, receipts["sept"].number) == (
        "EP-2026-000001",
        "EP-2026-000002",
    )


@pytest.mark.parametrize(
    ("params", "expected"),
    [({"year": 2025}, ["shop"]), ({"year": 2026}, ["sept", "july"]), ({"year": 2024}, [])],
)
def test_year_filter(client, auth_headers, world, params, expected):
    assert ids(get(client, auth_headers(world["owner"]), **params)) == receipt_ids(world, *expected)


def test_household_filter(client, auth_headers, world):
    headers = auth_headers(world["owner"])
    assert ids(get(client, headers, household_id=world["shop"].id)) == receipt_ids(world, "shop")
    other = get(client, headers, household_id=world["stranger_home"].id)
    assert (other.status_code, other.json()["error"]["code"]) == (404, "HOUSEHOLD_NOT_FOUND")


@pytest.mark.parametrize("params", [{"year": 1999}, {"year": 2101}, {"size": 0}])
def test_invalid_filters(client, auth_headers, world, params):
    assert get(client, auth_headers(world["owner"]), **params).status_code == 422


# --- Détail (écran 10) -------------------------------------------------------------------------


def test_receipt_has_what_the_screen_shows(client, auth_headers, world):
    receipt = world["receipts"]["sept"]
    response = client.get(f"{URL}/{receipt.id}", headers=auth_headers(world["owner"]))
    assert response.status_code == 200
    body = response.json()
    assert (body["number"], body["amount"]) == ("EP-2026-000002", 40_384)
    assert re.fullmatch(r"[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}", body["verification_code"])
    assert body["verification_code"].replace("-", "") == receipt.verification_code
    assert body["bill_period_label"] == "Sept.-Oct. 2026"
    assert (body["household_name"], body["meter_reference"]) == ("Maison Mpita", "0412-8833")
    assert (body["payer_name"], body["is_mine"]) == ("Grâce Ngoma", False)
    assert (body["operator"], body["operator_label"]) == ("airtel", "Airtel Money")
    assert body["phone_number"] == "+242 05 *** ** 02"
    assert body["transaction_reference"] == f"TX-{body['transaction_id']:08d}"
    assert body["issued_at"] == "2026-11-10T09:00:10Z"
    assert body["source"] == "simulated"


def test_the_payer_sees_a_masked_number_too(client, auth_headers, world):
    """Un reçu est fait pour être partagé : numéro toujours masqué (maquette)."""
    receipt = world["receipts"]["sept"]
    body = client.get(f"{URL}/{receipt.id}", headers=auth_headers(world["delegate"])).json()
    assert (body["is_mine"], body["phone_number"]) == (True, "+242 05 *** ** 02")


# --- Qui voit quoi ------------------------------------------------------------------------------


@pytest.mark.parametrize("person", ["delegate", "viewer"])
def test_members_see_the_receipts_of_the_shared_household(client, auth_headers, world, person):
    assert ids(get(client, auth_headers(world[person]))) == receipt_ids(world, "sept", "july")


def test_a_former_member_keeps_their_own_receipts(client, auth_headers, db_session, world):
    db_session.execute(
        update(HouseholdMember)
        .where(
            HouseholdMember.household_id == world["home"].id,
            HouseholdMember.user_id == world["delegate"].id,
        )
        .values(status=MemberStatus.REVOKED)
    )
    db_session.flush()
    headers = auth_headers(world["delegate"])
    assert ids(get(client, headers)) == receipt_ids(world, "sept")
    own = world["receipts"]["sept"].id
    assert client.get(f"{URL}/{own}", headers=headers).status_code == 200
    july = world["receipts"]["july"].id
    assert client.get(f"{URL}/{july}", headers=headers).status_code == 404


def test_someone_elses_receipt_looks_like_a_missing_one(client, auth_headers, world):
    headers = auth_headers(world["stranger"])
    theirs = client.get(f"{URL}/{world['receipts']['july'].id}", headers=headers)
    missing = client.get(f"{URL}/999999999", headers=headers)
    assert theirs.status_code == missing.status_code == 404
    assert theirs.json() == missing.json()
    assert theirs.json()["error"]["code"] == "RECEIPT_NOT_FOUND"
    assert get(client, headers).json()["total"] == 1  # le sien seulement


def test_login_is_required(client, world):
    assert client.get(URL).status_code == 401
    assert client.get(f"{URL}/{world['receipts']['july'].id}").status_code == 401


# --- Du paiement au reçu (écran 9 → 10) ----------------------------------------------------


def test_a_successful_payment_points_to_its_receipt(client, auth_headers, world):
    receipt = world["receipts"]["july"]
    payment = client.get(
        f"/api/v1/payments/{receipt.transaction_id}", headers=auth_headers(world["owner"])
    ).json()
    assert (payment["receipt_id"], payment["receipt_number"]) == (receipt.id, receipt.number)
    history = client.get("/api/v1/payments", headers=auth_headers(world["owner"])).json()
    assert all(item["receipt_id"] is not None for item in history["items"])


def test_a_pending_payment_has_no_receipt_yet(client, auth_headers, db_session, world):
    bill = make_bill(db_session, make_meter(db_session, world["home"]), due_date=date(2099, 1, 1))
    transaction = make_transaction(db_session, bill, world["owner"])
    payment = client.get(
        f"/api/v1/payments/{transaction.id}", headers=auth_headers(world["owner"])
    ).json()
    assert (payment["receipt_id"], payment["receipt_number"]) == (None, None)


# --- PDF (B8.3) ------------------------------------------------------------------------------


def pdf_text(content: bytes) -> str:
    return "\n".join(page.extract_text() for page in PdfReader(io.BytesIO(content)).pages)


def download(client, headers, receipt):
    return client.get(f"{URL}/{receipt.id}/pdf", headers=headers)


def test_receipt_pdf_is_a_downloadable_file(client, auth_headers, world):
    response = download(client, auth_headers(world["owner"]), world["receipts"]["sept"])
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.headers["content-disposition"] == (
        'attachment; filename="recu-EP-2026-000002.pdf"'
    )
    assert response.headers["cache-control"] == "private, no-store"
    assert len(PdfReader(io.BytesIO(response.content)).pages) == 1


def test_receipt_pdf_shows_what_the_screen_shows(client, auth_headers, world):
    receipt = world["receipts"]["sept"]
    text = pdf_text(download(client, auth_headers(world["owner"]), receipt).content)
    for expected in (
        "Reçu de paiement",
        "EP-2026-000002",
        "Paiement réussi",
        "40 384 FCFA",
        "10/11/2026 à 10:00",  # heure de Brazzaville (09:00:10 UTC)
        "Sept.-Oct. 2026",
        "Maison Mpita · compteur 0412-8833",
        "Grâce Ngoma",
        "Airtel Money · +242 05 *** ** 02",  # numéro masqué, même sur le PDF
        "TX-",
        "MODE DÉMO",
        "aucun débit réel",
    ):
        assert expected in text, expected
    code = receipt.verification_code
    assert f"{code[:4]}-{code[4:8]}-{code[8:]}" in text
    assert f"/api/v1/receipts/verify/{code}" in text


def test_the_qr_code_leads_to_the_public_verification(
    client, auth_headers, world, monkeypatch, test_settings
):
    encoded = []
    real_make = receipt_pdf_module.segno.make

    def spy(data, **options):
        encoded.append(data)
        return real_make(data, **options)

    monkeypatch.setattr(receipt_pdf_module.segno, "make", spy)
    receipt = world["receipts"]["july"]
    download(client, auth_headers(world["owner"]), receipt)
    assert encoded == [f"{test_settings.receipt_verify_url}/{receipt.verification_code}"]


def test_verification_url():
    assert (
        verification_url("https://elecpay.cg/verifier/", "8F3K-2Q9M-7XHT")
        == "https://elecpay.cg/verifier/8F3K2Q9M7XHT"
    )


def test_receipt_pdf_access_is_the_same_as_the_detail(client, auth_headers, world):
    receipt = world["receipts"]["july"]
    assert download(client, auth_headers(world["viewer"]), receipt).status_code == 200
    stranger = download(client, auth_headers(world["stranger"]), receipt)
    assert (stranger.status_code, stranger.json()["error"]["code"]) == (404, "RECEIPT_NOT_FOUND")
    assert client.get(f"{URL}/{receipt.id}/pdf").status_code == 401


def verify(client, code, headers=None):
    return client.get(f"{URL}/verify/{code}", headers=headers or {})


# --- Vérification publique (B8.4) ------------------------------------------------------------


def test_anyone_can_verify_a_receipt_without_logging_in(client, world):
    receipt = world["receipts"]["sept"]
    response = verify(client, receipt.verification_code)
    assert response.status_code == 200
    assert response.json() == {
        "valid": True,
        "number": "EP-2026-000002",
        "issued_at": "2026-11-10T09:00:10Z",
        "amount": 40_384,
        "bill_period_label": "Sept.-Oct. 2026",
        "meter_reference": "0412-••33",
        "demo": True,
        "message": "Reçu authentique émis par ElecPay "
        "(mode démo : paiement simulé, aucun débit réel).",
    }


def test_verification_reveals_no_personal_data(client, world):
    response = verify(client, world["receipts"]["sept"].verification_code)
    for private in ("Grâce", "Ngoma", "Arnaud", "Maison Mpita", "0412-8833", "+242", "1110002"):
        assert private not in response.text, private


@pytest.mark.parametrize(
    "transform",
    [
        lambda code: f"{code[:4]}-{code[4:8]}-{code[8:]}",  # comme imprimé
        lambda code: code.lower(),
        lambda code: f" {code[:4]} {code[4:8]} {code[8:]} ",
    ],
    ids=["tirets", "minuscules", "espaces"],
)
def test_code_can_be_typed_loosely(client, world, transform):
    code = world["receipts"]["july"].verification_code
    assert verify(client, transform(code)).json()["number"] == "EP-2026-000001"


@pytest.mark.parametrize("code", ["AAAAAAAAAAAA", "court", "ÉÉÉÉÉÉÉÉÉÉÉÉ", "pdf"])
def test_unknown_or_malformed_codes_get_the_same_answer(client, world, code):
    response = verify(client, code)
    assert (response.status_code, response.json()["error"]["code"]) == (
        404,
        "RECEIPT_CODE_UNKNOWN",
    )


def test_verification_attempts_are_limited(client, world):
    for _ in range(VERIFICATIONS_PER_IP.max_events):
        verify(client, "AAAAAAAAAAAA")
    blocked = verify(client, world["receipts"]["july"].verification_code)  # même un vrai code
    assert blocked.status_code == 429
    assert blocked.headers["Retry-After"]


@pytest.mark.parametrize(
    ("reference", "masked"),
    [
        ("0412-8833", "0412-••33"),
        ("0018 09 5408", "0018 •• ••08"),
        ("E2C-PNR-00000042", "E2C-P••-••••••42"),  # séparateurs gardés à leur place
        ("ABC12", "•••••"),
    ],
)
def test_meter_reference_masking(reference, masked):
    assert mask_meter_reference(reference) == masked


def render(db_session, world, **changes):
    receipt = ReceiptQueries(db_session).detail(world["owner"], world["receipts"]["july"].id)
    return render_receipt_pdf(
        receipt.model_copy(update=changes.pop("update", {})),
        verify_base_url="https://elecpay.cg/verifier",
        generated_at=datetime(2026, 11, 13, 9, 0, tzinfo=UTC),
        **changes,
    )


@pytest.mark.parametrize("demo_mode", [True, False])
def test_demo_banner_while_the_payment_is_simulated(db_session, world, demo_mode):
    """Paiement simulé : bandeau « Mode démo », que le mode démo soit actif ou non."""
    assert "MODE DÉMO" in pdf_text(render(db_session, world, demo_mode=demo_mode))


def test_no_demo_banner_for_a_real_payment(db_session, world):
    content = render(db_session, world, demo_mode=False, update={"source": "mtn"})
    text = pdf_text(content)
    assert "MODE DÉMO" not in text
    assert "le 13/11/2026 à 10:00 (heure de Brazzaville)" in text
    metadata = PdfReader(io.BytesIO(content)).metadata
    assert (metadata.title, metadata.author) == ("Reçu EP-2026-000001", "ElecPay")
