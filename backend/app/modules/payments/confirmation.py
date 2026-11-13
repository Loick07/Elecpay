"""Appliquer les nouvelles du prestataire à une transaction (B7.3).

`apply_provider_update` est l'UNIQUE endroit qui fait avancer une transaction d'après le
prestataire, que la nouvelle arrive par webhook signé ou par une demande d'état
(`check_status`, suivi de l'écran 9 ou relance par un administrateur). Aucune autre voie ne
peut passer une transaction à « réussie » : pas de route, pas de bouton.

| Nouvelle du prestataire | Transaction en attente devient… | Facture            |
|-------------------------|---------------------------------|--------------------|
| débit en attente        | inchangée                       | paiement en cours  |
| code PIN saisi          | « PIN saisi » (n'expire plus)   | paiement en cours  |
| débit confirmé          | réussie                         | payée              |
| débit refusé            | échouée, avec le motif          | à payer / en retard|

Idempotent : la même nouvelle reçue deux fois (double webhook, suivi + webhook) ne change
rien la deuxième fois. Une nouvelle qui CONTREDIT une transaction terminée (par ex. un succès
annoncé après l'expiration) ne modifie rien — la base l'interdit — mais est inscrite au
journal d'audit pour le rapprochement par l'administration (maquette A8).
Montant annoncé différent du montant demandé : la transaction n'est pas confirmée, elle reste
en attente et l'anomalie est inscrite au journal.
"""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.modules.audit.service import record
from app.modules.bills.models import Bill, BillStatus
from app.modules.households.models import Household
from app.modules.meters.models import Meter
from app.modules.notifications.service import insert_notifications
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.notifications import payment_failed_row, payment_succeeded_rows
from app.modules.users.models import User

DEFAULT_FAILURE = "Paiement refusé par l'opérateur"


class Outcome(StrEnum):
    UNCHANGED = "unchanged"  # rien de nouveau
    PIN_ENTERED = "pin_entered"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    AMOUNT_MISMATCH = "amount_mismatch"  # non confirmée, signalée
    CONFLICT = "conflict"  # contredit une transaction terminée, signalée


@dataclass(frozen=True, slots=True)
class Applied:
    transaction: PaymentTransaction
    outcome: Outcome


def released_status(bill: Bill, today) -> BillStatus:
    """Statut d'une facture dont le paiement n'a pas abouti : de nouveau payable."""
    return BillStatus.OVERDUE if bill.due_date < today else BillStatus.UNPAID


def release_bill(bill: Bill, today) -> None:
    """La facture redevient payable (si elle attendait ce paiement)."""
    if bill.status is BillStatus.PENDING_PAYMENT:
        bill.status = released_status(bill, today)


def apply_provider_update(
    session: Session,
    transaction_id: int,
    update: ProviderUpdate,
    *,
    origin: str,
    now: datetime,
) -> Applied:
    """Applique `update` (venu de `origin` : « webhook » ou « status_check »). Pas de commit."""
    transaction = _locked(session, PaymentTransaction, transaction_id)
    if transaction.status is not TransactionStatus.PENDING:
        return _already_final(session, transaction, update, origin)
    bill = _locked(session, Bill, transaction.bill_id)
    at = _clamp(update.occurred_at, transaction.initiated_at, now)

    match update.state:
        case ProviderState.PENDING:
            return Applied(transaction, Outcome.UNCHANGED)
        case ProviderState.PIN_ENTERED:
            if transaction.pin_entered_at is not None:
                return Applied(transaction, Outcome.UNCHANGED)
            transaction.pin_entered_at = at
            session.flush()
            return Applied(transaction, Outcome.PIN_ENTERED)
        case ProviderState.SUCCEEDED:
            if update.amount is not None and update.amount != transaction.amount:
                _audit(
                    session,
                    "payment.amount_mismatch",
                    transaction,
                    origin,
                    announced_amount=update.amount,
                )
                return Applied(transaction, Outcome.AMOUNT_MISMATCH)
            return _succeed(session, transaction, bill, update, at, origin)
        case ProviderState.FAILED:
            return _fail(session, transaction, bill, update, at, now, origin)


# --- Issues ----------------------------------------------------------------------------------


def _succeed(session, transaction, bill, update, at, origin) -> Applied:
    if transaction.pin_entered_at is None:  # un débit confirmé suppose le code PIN saisi
        transaction.pin_entered_at = at
    transaction.provider_ref = update.provider_ref
    transaction.confirmed_at = at
    transaction.status = TransactionStatus.SUCCEEDED
    if bill.status in (BillStatus.PENDING_PAYMENT, BillStatus.UNPAID, BillStatus.OVERDUE):
        bill.status, bill.paid_at = BillStatus.PAID, at
    else:  # facture annulée entre-temps : l'argent est pris, à régulariser par un admin
        _audit(session, "payment.bill_not_payable", transaction, origin, bill_status=bill.status)
    session.flush()
    payer = session.get(User, transaction.payer_id)
    insert_notifications(
        session, payment_succeeded_rows(transaction, bill, payer, _owner_id(session, bill))
    )
    _audit(session, "payment.succeeded", transaction, origin)
    return Applied(transaction, Outcome.SUCCEEDED)


def _fail(session, transaction, bill, update, at, now, origin) -> Applied:
    transaction.status = TransactionStatus.FAILED
    transaction.failure_reason = (update.failure_reason or DEFAULT_FAILURE)[:255]
    release_bill(bill, local_date(now))
    session.flush()
    insert_notifications(session, [payment_failed_row(transaction, at=at)])
    _audit(session, "payment.failed", transaction, origin)
    return Applied(transaction, Outcome.FAILED)


def _already_final(session, transaction, update, origin) -> Applied:
    succeeded = transaction.status is TransactionStatus.SUCCEEDED
    contradiction = (update.state is ProviderState.SUCCEEDED and not succeeded) or (
        update.state is ProviderState.FAILED and succeeded
    )
    if not contradiction:
        return Applied(transaction, Outcome.UNCHANGED)  # nouvelle déjà prise en compte
    _audit(
        session,
        "payment.provider_conflict",
        transaction,
        origin,
        provider_state=update.state.value,
    )
    session.flush()
    return Applied(transaction, Outcome.CONFLICT)


# --- Outils ----------------------------------------------------------------------------------


def _locked(session: Session, model, row_id: int):
    """La ligne verrouillée (FOR UPDATE) et relue : deux nouvelles simultanées passent l'une
    après l'autre, la seconde voit l'effet de la première."""
    return session.scalars(
        select(model)
        .where(model.id == row_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    ).one()


def _clamp(at: datetime, earliest: datetime, latest: datetime) -> datetime:
    """Date annoncée par le prestataire, ramenée entre la demande et maintenant (horloges)."""
    return min(max(at, earliest), max(latest, earliest))


def _owner_id(session: Session, bill: Bill) -> int | None:
    return session.scalar(
        select(Household.owner_id)
        .join(Meter, Meter.household_id == Household.id)
        .where(Meter.id == bill.meter_id)
    )


def _audit(session, action: str, transaction: PaymentTransaction, origin: str, **extra) -> None:
    record(
        session,
        action=action,
        entity_type="payment_transaction",
        entity_id=transaction.id,
        actor_id=None,  # le prestataire, pas une personne
        after={
            "status": transaction.status.value,
            "provider_ref": transaction.provider_ref,
            "origin": origin,
            **{key: str(value) for key, value in extra.items()},
        },
    )
