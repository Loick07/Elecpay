"""Prestataire simulé (mode démo) : aucun débit réel, des scénarios réglés par le numéro.

Le débit « avance » avec le temps écoulé depuis la demande : `check_status` dit où il en est
(code PIN saisi après 5 s, résultat après 10 s). Aucun processus en arrière-plan : c'est le
suivi du paiement par l'application qui fait avancer la démo (décision B7 du 13/11/2026).

Scénarios réservés aux NUMÉROS DE TEST, qui finissent par « 00 00 0N » (ex. 06 000 00 02).
Tout autre numéro — dont ceux des comptes de démo — réussit (décision du 13/11/2026 : sinon
le compte de démo …01 02 échouerait toujours) :

| Numéro de test | Scénario                                                       |
|----------------|----------------------------------------------------------------|
| … 00 00 02     | PIN saisi, puis échec « Solde insuffisant »                     |
| … 00 00 03     | échec « Paiement refusé par l'abonné », sans PIN                |
| … 00 00 04     | PIN jamais saisi : reste en attente (ElecPay la fait expirer)   |
| … 00 00 05     | PIN saisi, débit jamais confirmé : reste en attente (cas A8)    |
| … 00 00 06     | prestataire injoignable : la demande elle-même échoue           |
| tout autre     | PIN saisi, puis succès                                          |

Webhooks : en-tête `X-ElecPay-Signature: t=<horodatage unix>,v1=<HMAC-SHA256 hex>`, calculé
sur « <t>.<corps brut> » avec PAYMENT_WEBHOOK_SECRET. Refusé s'il a plus de 5 minutes
(protection contre le rejeu). `signed_webhook` fabrique une notification valide (tests, démo).
"""

import hashlib
import hmac
import json
from collections.abc import Callable, Mapping
from datetime import UTC, datetime, timedelta
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, ValidationError, model_validator

from app.db.base import utcnow
from app.integrations.payment_providers.base import (
    InvalidWebhookError,
    InvalidWebhookPayloadError,
    PaymentRequest,
    ProviderState,
    ProviderUnavailableError,
    ProviderUpdate,
)

PIN_DELAY = timedelta(seconds=5)
RESULT_DELAY = timedelta(seconds=10)
SIGNATURE_HEADER = "X-ElecPay-Signature"
SIGNATURE_TOLERANCE = timedelta(minutes=5)

INSUFFICIENT_FUNDS = "Solde insuffisant"
REFUSED = "Paiement refusé par l'abonné"


class Scenario(StrEnum):
    SUCCESS = "success"
    INSUFFICIENT_FUNDS = "insufficient_funds"
    REFUSED = "refused"
    NO_PIN = "no_pin"
    PIN_NO_CONFIRMATION = "pin_no_confirmation"
    UNAVAILABLE = "unavailable"


TEST_NUMBER_ENDINGS = {
    "000002": Scenario.INSUFFICIENT_FUNDS,
    "000003": Scenario.REFUSED,
    "000004": Scenario.NO_PIN,
    "000005": Scenario.PIN_NO_CONFIRMATION,
    "000006": Scenario.UNAVAILABLE,
}


def scenario_for(phone_number: str) -> Scenario:
    return TEST_NUMBER_ENDINGS.get(phone_number[-6:], Scenario.SUCCESS)


class WebhookBody(BaseModel):
    """Corps JSON d'une notification du prestataire simulé."""

    model_config = ConfigDict(extra="forbid")

    provider_ref: str = Field(min_length=1, max_length=64)
    state: ProviderState
    occurred_at: datetime
    amount: int | None = Field(default=None, gt=0)
    failure_reason: str | None = Field(default=None, min_length=1, max_length=255)

    @model_validator(mode="after")
    def coherent(self) -> WebhookBody:
        if self.occurred_at.tzinfo is None:
            raise ValueError("occurred_at doit préciser son fuseau (UTC)")
        if (self.state is ProviderState.FAILED) != (self.failure_reason is not None):
            raise ValueError("failure_reason est obligatoire pour un échec, et seulement là")
        return self


class SimulatedPaymentProvider:
    name = "simulated"

    def __init__(self, webhook_secret: str, now: Callable[[], datetime] = utcnow) -> None:
        self._secret = webhook_secret.encode()
        self._now = now

    # --- Débit ------------------------------------------------------------------------------

    def initiate(self, request: PaymentRequest) -> str:
        if scenario_for(request.phone_number) is Scenario.UNAVAILABLE:
            raise ProviderUnavailableError()
        # Même demande → même référence : relancer une demande ne crée pas un 2e débit.
        digest = hashlib.sha256(request.reference.encode()).hexdigest()[:16].upper()
        return f"SIM-{digest}"

    def check_status(self, provider_ref: str, request: PaymentRequest) -> ProviderUpdate:
        scenario = scenario_for(request.phone_number)
        if scenario is Scenario.UNAVAILABLE:
            raise ProviderUnavailableError()
        elapsed = self._now() - request.initiated_at
        pin_at = request.initiated_at + PIN_DELAY
        result_at = request.initiated_at + RESULT_DELAY

        def update(state, at, reason=None) -> ProviderUpdate:
            amount = request.amount if state is ProviderState.SUCCEEDED else None
            return ProviderUpdate(provider_ref, state, at, amount=amount, failure_reason=reason)

        pending = update(ProviderState.PENDING, request.initiated_at)
        match scenario:
            case Scenario.NO_PIN:
                return pending
            case _ if elapsed < PIN_DELAY:
                return pending
            case Scenario.REFUSED:  # refusé au moment où le code PIN est demandé
                return update(ProviderState.FAILED, pin_at, REFUSED)
            case Scenario.PIN_NO_CONFIRMATION:
                return update(ProviderState.PIN_ENTERED, pin_at)
            case _ if elapsed < RESULT_DELAY:
                return update(ProviderState.PIN_ENTERED, pin_at)
            case Scenario.INSUFFICIENT_FUNDS:
                return update(ProviderState.FAILED, result_at, INSUFFICIENT_FUNDS)
            case _:
                return update(ProviderState.SUCCEEDED, result_at)

    # --- Webhooks ---------------------------------------------------------------------------

    def verify_webhook(self, headers: Mapping[str, str], body: bytes) -> ProviderUpdate:
        if not self._secret:
            raise InvalidWebhookError(
                "Notifications désactivées : PAYMENT_WEBHOOK_SECRET n'est pas configuré."
            )
        timestamp, signature = _parse_signature(_header(headers, SIGNATURE_HEADER))
        expected = self._sign(timestamp, body)
        if not hmac.compare_digest(signature, expected):
            raise InvalidWebhookError()
        sent_at = datetime.fromtimestamp(timestamp, UTC)
        if abs(self._now() - sent_at) > SIGNATURE_TOLERANCE:
            raise InvalidWebhookError("Notification trop ancienne (ou horloge décalée).")
        try:
            parsed = WebhookBody.model_validate_json(body)
        except ValidationError as error:
            raise InvalidWebhookPayloadError() from error
        return ProviderUpdate(
            provider_ref=parsed.provider_ref,
            state=parsed.state,
            occurred_at=parsed.occurred_at.astimezone(UTC),
            amount=parsed.amount,
            failure_reason=parsed.failure_reason,
        )

    def signed_webhook(self, update: ProviderUpdate) -> tuple[dict[str, str], bytes]:
        """Une notification signée, comme l'enverrait le prestataire : (en-têtes, corps)."""
        body = json.dumps(
            {
                "provider_ref": update.provider_ref,
                "state": update.state.value,
                "occurred_at": update.occurred_at.astimezone(UTC).isoformat(),
                "amount": update.amount,
                "failure_reason": update.failure_reason,
            }
        ).encode()
        timestamp = int(self._now().timestamp())
        header = f"t={timestamp},v1={self._sign(timestamp, body)}"
        return {SIGNATURE_HEADER: header, "Content-Type": "application/json"}, body

    def _sign(self, timestamp: int, body: bytes) -> str:
        return hmac.new(self._secret, f"{timestamp}.".encode() + body, hashlib.sha256).hexdigest()


def _header(headers: Mapping[str, str], name: str) -> str:
    """En-tête HTTP, sans tenir compte de la casse."""
    for key, value in headers.items():
        if key.lower() == name.lower():
            return value
    raise InvalidWebhookError("Signature absente.")


def _parse_signature(value: str) -> tuple[int, str]:
    parts = dict(part.split("=", 1) for part in value.split(",") if "=" in part)
    try:
        return int(parts["t"]), parts["v1"]
    except (KeyError, ValueError) as error:
        raise InvalidWebhookError("Signature mal formée.") from error
