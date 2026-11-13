"""Simulateur d'historique de paiements (mode démo) : l'« histoire » de chaque facture.

Pour chaque facture simulée, décide si elle est payée, impayée ou en retard, et produit
les tentatives de paiement Mobile Money qui y mènent (échecs, expirations, réussite).

Règles (plan B2) : les anciennes factures sont payées ; quelques récentes restent impayées ;
une ou deux sont en retard ; certains paiements sont faits par un payeur délégué.
L'histoire respecte le cycle de vie imposé par la base (B1) : chaque tentative commence
« en attente », une seule tentative à la fois, une seule réussite par facture.

Déterministe (graine fixe). Le hasard ne sert qu'à la démo : en production, références et
codes de vérification sont tirés avec `secrets` (B7 / B8).
"""

import random
import string
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum

from app.modules.payments.models import TransactionStatus
from app.simulators.bills import SimulatedBill

PAYMENT_TIMEOUT = timedelta(minutes=10)  # sans saisie du code PIN, la transaction expire
VERIFICATION_CODE_ALPHABET = string.ascii_uppercase + string.digits
VERIFICATION_CODE_LENGTH = 12

FAILURE_REASONS = (
    "Solde insuffisant",
    "Paiement refusé par l'abonné",
    "Code PIN incorrect",
)
EXPIRY_REASON = "Délai de confirmation dépassé (code PIN non saisi)"
PIN_FAILURES = frozenset({"Solde insuffisant", "Code PIN incorrect"})  # échecs après saisie du PIN


class BillOutcome(StrEnum):
    PAID = "paid"
    UNPAID = "unpaid"  # pas encore payée, échéance non dépassée
    OVERDUE = "overdue"  # échéance dépassée, toujours impayée


@dataclass(frozen=True, slots=True)
class Payer:
    key: str  # identifiant libre (ex. « owner », « delegate ») résolu par l'appelant
    phone_number: str  # numéro Mobile Money débité (+242…)


@dataclass(frozen=True, slots=True)
class SimulatedAttempt:
    """Une tentative de paiement (mêmes noms de champs que `PaymentTransaction`)."""

    payer_key: str
    phone_number: str
    amount: int
    status: TransactionStatus  # statut FINAL (la transaction commence toujours en attente)
    idempotency_key: str
    initiated_at: datetime
    expires_at: datetime
    confirmed_at: datetime | None = None
    provider_ref: str | None = None
    failure_reason: str | None = None
    receipt_verification_code: str | None = None  # seulement si réussie

    @property
    def pin_entered(self) -> bool:
        """Le payeur a saisi son code PIN (réussite, solde insuffisant, PIN incorrect)."""
        return self.status is TransactionStatus.SUCCEEDED or self.failure_reason in PIN_FAILURES

    @property
    def finished_at(self) -> datetime:
        """Moment où la tentative a quitté l'état « en attente »."""
        if self.confirmed_at is not None:
            return self.confirmed_at
        if self.status is TransactionStatus.EXPIRED:
            return self.expires_at
        return self.initiated_at + timedelta(seconds=45)  # échec signalé par l'opérateur


@dataclass(frozen=True, slots=True)
class BillPaymentStory:
    bill: SimulatedBill
    outcome: BillOutcome
    attempts: tuple[SimulatedAttempt, ...]

    @property
    def paid_at(self) -> datetime | None:
        if self.outcome is not BillOutcome.PAID:
            return None
        return self.attempts[-1].confirmed_at


@dataclass(frozen=True, slots=True)
class PaymentBehaviour:
    """Probabilités du simulateur (réglables pour les tests)."""

    recent_unpaid_probability: float = 0.6  # facture pas encore échue : laissée impayée
    overdue_probability: float = 0.15  # facture échue récente : jamais payée (en retard)
    failed_first_probability: float = 0.2  # un échec avant la réussite
    abandoned_attempt_probability: float = 0.3  # facture non payée : une tentative ratée
    delegate_probability: float = 0.35  # payée par le payeur délégué (s'il existe)
    recent_bills_that_may_stay_overdue: int = 2  # seules les plus récentes peuvent rester dues


def simulate_payments(
    bills: Sequence[SimulatedBill],
    *,
    owner: Payer,
    delegate: Payer | None,
    as_of: datetime,
    seed: int,
    behaviour: PaymentBehaviour | None = None,
) -> list[BillPaymentStory]:
    """Histoire de paiement de chaque facture, vue à l'instant `as_of` (UTC)."""
    behaviour = behaviour or PaymentBehaviour()
    rng = random.Random(seed)
    stories = []
    ordered = sorted(bills, key=lambda bill: bill.period_start)
    for position, bill in enumerate(ordered):
        if bill.issued_at > as_of:
            raise ValueError(f"Facture du {bill.period_start} émise après {as_of:%d/%m/%Y}")
        is_recent = position >= len(ordered) - behaviour.recent_bills_that_may_stay_overdue
        stories.append(_story(bill, is_recent, owner, delegate, as_of, rng, behaviour))
    return stories


def _story(
    bill: SimulatedBill,
    is_recent: bool,
    owner: Payer,
    delegate: Payer | None,
    as_of: datetime,
    rng: random.Random,
    behaviour: PaymentBehaviour,
) -> BillPaymentStory:
    due_passed = bill.due_date < as_of.date()
    if not due_passed:
        stays_unpaid = rng.random() < behaviour.recent_unpaid_probability
        outcome = BillOutcome.UNPAID if stays_unpaid else BillOutcome.PAID
    elif is_recent and rng.random() < behaviour.overdue_probability:
        outcome = BillOutcome.OVERDUE
    else:
        outcome = BillOutcome.PAID

    use_delegate = delegate is not None and rng.random() < behaviour.delegate_probability
    payer = delegate if use_delegate and delegate is not None else owner

    # Moment du paiement : entre le lendemain de l'émission et quelques jours après l'échéance,
    # jamais après `as_of`.
    earliest = bill.issued_at + timedelta(days=1)
    latest = min(
        datetime.combine(bill.due_date, bill.issued_at.timetz()) + timedelta(days=5),
        as_of - timedelta(hours=1),
    )
    latest = max(latest, earliest)
    moment = earliest + (latest - earliest) * rng.random()

    attempts: list[SimulatedAttempt] = []
    if outcome is BillOutcome.PAID:
        if rng.random() < behaviour.failed_first_probability:
            attempts.append(_failed_attempt(bill, payer, moment, rng))
            moment = attempts[-1].finished_at + timedelta(minutes=rng.randint(5, 240))
        attempts.append(_successful_attempt(bill, payer, moment, rng))
    elif rng.random() < behaviour.abandoned_attempt_probability:
        attempts.append(_failed_attempt(bill, payer, moment, rng))

    # Garde-fou : rien dans le futur (une réussite repoussée trop loin est avancée).
    if attempts and attempts[-1].finished_at > as_of:
        return _story_without_future(bill, outcome, attempts, as_of)
    return BillPaymentStory(bill, outcome, tuple(attempts))


def _story_without_future(
    bill: SimulatedBill,
    outcome: BillOutcome,
    attempts: list[SimulatedAttempt],
    as_of: datetime,
) -> BillPaymentStory:
    """Ne garde que les tentatives terminées avant `as_of` (la facture reste alors due)."""
    kept = tuple(a for a in attempts if a.finished_at <= as_of)
    if outcome is BillOutcome.PAID and (not kept or kept[-1].confirmed_at is None):
        outcome = BillOutcome.OVERDUE if bill.due_date < as_of.date() else BillOutcome.UNPAID
    return BillPaymentStory(bill, outcome, kept)


def _base_attempt(bill: SimulatedBill, payer: Payer, at: datetime, rng: random.Random) -> dict:
    return {
        "payer_key": payer.key,
        "phone_number": payer.phone_number,
        "amount": bill.computation.amount_total,  # jamais choisi par le client
        "idempotency_key": f"{rng.getrandbits(128):032x}",
        "initiated_at": at,
        "expires_at": at + PAYMENT_TIMEOUT,
    }


def _failed_attempt(
    bill: SimulatedBill, payer: Payer, at: datetime, rng: random.Random
) -> SimulatedAttempt:
    if rng.random() < 0.3:
        return SimulatedAttempt(
            **_base_attempt(bill, payer, at, rng),
            status=TransactionStatus.EXPIRED,
            failure_reason=EXPIRY_REASON,
        )
    return SimulatedAttempt(
        **_base_attempt(bill, payer, at, rng),
        status=TransactionStatus.FAILED,
        failure_reason=rng.choice(FAILURE_REASONS),
    )


def _successful_attempt(
    bill: SimulatedBill, payer: Payer, at: datetime, rng: random.Random
) -> SimulatedAttempt:
    code = "".join(rng.choice(VERIFICATION_CODE_ALPHABET) for _ in range(VERIFICATION_CODE_LENGTH))
    return SimulatedAttempt(
        **_base_attempt(bill, payer, at, rng),
        status=TransactionStatus.SUCCEEDED,
        confirmed_at=at + timedelta(seconds=rng.randint(15, 120)),
        provider_ref=f"SIM-{rng.getrandbits(48):012X}",
        receipt_verification_code=code,
    )
