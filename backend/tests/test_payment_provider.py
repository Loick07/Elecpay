"""Tests du prestataire de paiement simulé et des opérateurs (B7.1). Sans base de données."""

import json
from datetime import UTC, datetime, timedelta

import pytest
from pydantic import SecretStr

from app.core.config import Settings
from app.integrations.payment_providers.base import (
    InvalidWebhookError,
    InvalidWebhookPayloadError,
    PaymentRequest,
    ProviderState,
    ProviderUnavailableError,
    ProviderUpdate,
)
from app.integrations.payment_providers.factory import get_payment_provider
from app.integrations.payment_providers.simulated import (
    INSUFFICIENT_FUNDS,
    REFUSED,
    SIGNATURE_HEADER,
    Scenario,
    SimulatedPaymentProvider,
    scenario_for,
)
from app.modules.payments.models import MobileOperator
from app.modules.payments.operators import operator_for_phone

START = datetime(2026, 11, 13, 10, 0, tzinfo=UTC)
SECRET = "secret-de-test-des-webhooks-" + "x" * 20


class Clock:
    def __init__(self, now: datetime = START) -> None:
        self.now = now

    def __call__(self) -> datetime:
        return self.now


def provider(clock: Clock | None = None, secret: str = SECRET) -> SimulatedPaymentProvider:
    return SimulatedPaymentProvider(secret, now=clock or Clock())


def request(phone="+242060000001", reference="cle-1") -> PaymentRequest:
    return PaymentRequest(
        reference=reference,
        operator="mtn",
        phone_number=phone,
        amount=40_384,
        initiated_at=START,
        description="Facture E²C 0412-8833",
    )


def state_after(phone: str, seconds: float) -> ProviderUpdate:
    clock = Clock(START + timedelta(seconds=seconds))
    simulated = provider(clock)
    ref = simulated.initiate(request(phone))
    return simulated.check_status(ref, request(phone))


# --- Opérateurs -------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("phone", "operator"),
    [
        ("+242061234567", MobileOperator.MTN),
        ("+242051234567", MobileOperator.AIRTEL),
        ("+242041234567", MobileOperator.AIRTEL),
        ("+242221234567", None),  # fixe : pas de Mobile Money
    ],
)
def test_operator_of_a_number(phone, operator):
    assert operator_for_phone(phone) is operator


# --- Demande de débit ---------------------------------------------------------------------------


def test_same_request_gives_the_same_reference():
    simulated = provider()
    first = simulated.initiate(request(reference="cle-1"))
    assert first == simulated.initiate(request(reference="cle-1"))
    assert first != simulated.initiate(request(reference="cle-2"))
    assert first.startswith("SIM-") and len(first) == 20


def test_unreachable_provider():
    with pytest.raises(ProviderUnavailableError) as error:
        provider().initiate(request("+242060000006"))
    assert error.value.status_code == 503


# --- Scénarios ---------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("ending", "scenario"),
    [
        ("01", Scenario.SUCCESS),
        ("99", Scenario.SUCCESS),
        ("02", Scenario.INSUFFICIENT_FUNDS),
        ("03", Scenario.REFUSED),
        ("04", Scenario.NO_PIN),
        ("05", Scenario.PIN_NO_CONFIRMATION),
        ("06", Scenario.UNAVAILABLE),
    ],
)
def test_test_numbers_choose_the_scenario(ending, scenario):
    assert scenario_for(f"+2420600000{ending}") is scenario  # « 06 000 00 0N »


@pytest.mark.parametrize(
    "phone",
    [
        "+242060000102",  # compte de démo : finit par 02, mais n'est pas un numéro de test
        "+242060000103",
        "+242060000106",
        "+242051234502",
        "+242061110004",
    ],
)
def test_ordinary_numbers_always_succeed(phone):
    assert scenario_for(phone) is Scenario.SUCCESS


def test_success_goes_through_pin_entry():
    phone = "+242060000001"
    assert state_after(phone, 0).state is ProviderState.PENDING
    assert state_after(phone, 4.9).state is ProviderState.PENDING
    pin = state_after(phone, 5)
    assert (pin.state, pin.occurred_at) == (ProviderState.PIN_ENTERED, START + timedelta(seconds=5))
    done = state_after(phone, 10)
    assert (done.state, done.amount, done.failure_reason) == (ProviderState.SUCCEEDED, 40_384, None)
    assert done.occurred_at == START + timedelta(seconds=10)
    assert state_after(phone, 3_600).state is ProviderState.SUCCEEDED  # et ça ne bouge plus


def test_insufficient_funds_after_pin_entry():
    assert state_after("+242060000002", 7).state is ProviderState.PIN_ENTERED
    failed = state_after("+242060000002", 10)
    assert (failed.state, failed.failure_reason, failed.amount) == (
        ProviderState.FAILED,
        INSUFFICIENT_FUNDS,
        None,
    )


def test_refused_without_pin():
    assert state_after("+242060000003", 4).state is ProviderState.PENDING
    refused = state_after("+242060000003", 5)
    assert (refused.state, refused.failure_reason) == (ProviderState.FAILED, REFUSED)


def test_pin_never_entered_stays_pending():
    assert state_after("+242060000004", 3_600).state is ProviderState.PENDING


def test_pin_entered_but_never_confirmed():
    assert state_after("+242060000005", 3_600).state is ProviderState.PIN_ENTERED


def test_status_of_an_unreachable_provider():
    with pytest.raises(ProviderUnavailableError):
        provider().check_status("SIM-X", request("+242060000006"))


# --- Webhooks signés ------------------------------------------------------------------------------


SUCCESS = ProviderUpdate("SIM-ABC", ProviderState.SUCCEEDED, START, amount=40_384)


def test_a_signed_webhook_is_accepted():
    simulated = provider()
    headers, body = simulated.signed_webhook(SUCCESS)
    assert simulated.verify_webhook(headers, body) == SUCCESS


def test_header_name_is_case_insensitive():
    simulated = provider()
    headers, body = simulated.signed_webhook(SUCCESS)
    lowered = {key.lower(): value for key, value in headers.items()}
    assert simulated.verify_webhook(lowered, body) == SUCCESS


def test_a_tampered_body_is_refused():
    simulated = provider()
    headers, body = simulated.signed_webhook(SUCCESS)
    tampered = body.replace(b"40384", b"1")
    with pytest.raises(InvalidWebhookError):
        simulated.verify_webhook(headers, tampered)


def test_a_webhook_signed_with_another_secret_is_refused():
    headers, body = provider(secret="un-autre-secret-" + "y" * 30).signed_webhook(SUCCESS)
    with pytest.raises(InvalidWebhookError):
        provider().verify_webhook(headers, body)


@pytest.mark.parametrize(
    "headers",
    [{}, {SIGNATURE_HEADER: "n'importe quoi"}, {SIGNATURE_HEADER: "t=abc,v1=00"}],
)
def test_missing_or_malformed_signature_is_refused(headers):
    with pytest.raises(InvalidWebhookError):
        provider().verify_webhook(headers, b"{}")


@pytest.mark.parametrize("minutes", [6, -6])
def test_an_old_or_future_webhook_is_refused(minutes):
    """Protection contre le rejeu : une notification n'est valable que 5 minutes."""
    sender = provider(Clock(START))
    headers, body = sender.signed_webhook(SUCCESS)
    receiver = provider(Clock(START + timedelta(minutes=minutes)))
    with pytest.raises(InvalidWebhookError, match="ancienne"):
        receiver.verify_webhook(headers, body)
    assert provider(Clock(START + timedelta(minutes=4))).verify_webhook(headers, body) == SUCCESS


def test_webhooks_are_refused_without_a_secret():
    headers, body = provider().signed_webhook(SUCCESS)
    with pytest.raises(InvalidWebhookError, match="PAYMENT_WEBHOOK_SECRET"):
        provider(secret="").verify_webhook(headers, body)


@pytest.mark.parametrize(
    "payload",
    [
        {"provider_ref": "SIM-1", "state": "failed", "occurred_at": START.isoformat()},
        {
            "provider_ref": "SIM-1",
            "state": "succeeded",
            "occurred_at": START.isoformat(),
            "failure_reason": "pas pour un succès",
        },
        {"provider_ref": "SIM-1", "state": "inconnu", "occurred_at": START.isoformat()},
        {"provider_ref": "SIM-1", "state": "succeeded", "occurred_at": "2026-11-13T10:00:00"},
        {"provider_ref": "SIM-1", "state": "succeeded", "occurred_at": START.isoformat(), "x": 1},
        {
            "provider_ref": "SIM-1",
            "state": "succeeded",
            "occurred_at": START.isoformat(),
            "amount": 0,
        },
    ],
)
def test_a_well_signed_but_invalid_payload_is_refused(payload):
    simulated = provider()
    body = json.dumps(payload).encode()
    timestamp = int(START.timestamp())
    headers = {SIGNATURE_HEADER: f"t={timestamp},v1={simulated._sign(timestamp, body)}"}
    with pytest.raises(InvalidWebhookPayloadError) as error:
        simulated.verify_webhook(headers, body)
    assert error.value.status_code == 400


def test_failure_webhook_carries_its_reason():
    simulated = provider()
    update = ProviderUpdate("SIM-1", ProviderState.FAILED, START, failure_reason=INSUFFICIENT_FUNDS)
    headers, body = simulated.signed_webhook(update)
    assert simulated.verify_webhook(headers, body) == update


# --- Choix par la configuration -----------------------------------------------------------------


def test_factory_gives_the_simulated_provider_with_the_configured_secret(test_settings):
    settings: Settings = test_settings.model_copy(
        update={"payment_webhook_secret": SecretStr(SECRET)}
    )
    chosen = get_payment_provider(settings)
    assert isinstance(chosen, SimulatedPaymentProvider)
    assert chosen.name == "simulated"
    # Signé maintenant (horloge réelle), avec le même secret : accepté.
    headers, body = SimulatedPaymentProvider(SECRET).signed_webhook(SUCCESS)
    assert chosen.verify_webhook(headers, body).provider_ref == "SIM-ABC"
