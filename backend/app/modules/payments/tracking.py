"""Suivi des paiements en attente et expiration (B7.4).

`refresh_transaction` fait le point sur une transaction en attente :
1. il demande d'abord l'état au prestataire (`check_status`) et l'applique avec
   `apply_provider_update` — le prestataire a pu confirmer à la dernière seconde ;
2. puis, si elle est toujours en attente, SANS code PIN saisi, et que le délai (10 min) est
   dépassé, elle expire : la facture redevient payable et le payeur est prévenu.
Une transaction dont le code PIN a été saisi n'expire jamais d'elle-même : elle attend la
réponse de l'opérateur ou une relance par l'administration (maquette A8).

Appelé par : le suivi de l'écran 9 (`GET /payments/{id}`), une nouvelle demande sur une
facture « paiement en cours », et la commande `scripts.check_pending_payments` (tâche
planifiée, toutes les minutes en production).
"""

import threading
from collections.abc import Sequence
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.integrations.payment_providers.base import PaymentProvider, ProviderUnavailableError
from app.modules.audit.service import record
from app.modules.bills.models import Bill
from app.modules.notifications.service import insert_notifications
from app.modules.payments.common import payment_request
from app.modules.payments.confirmation import apply_provider_update, release_bill
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.notifications import payment_failed_row

EXPIRY_REASON = "Délai de confirmation dépassé (code PIN non saisi)"
CHECK_STATUS_EVERY = timedelta(seconds=5)


class StatusCheckThrottle:
    """Au plus une demande d'état au prestataire par transaction toutes les 5 s (B11.5).

    L'écran 9 interroge toutes les 2 à 3 s : sans cela, chaque client en attente ferait des
    dizaines d'appels par minute à MTN / Airtel. Mesuré avec l'horloge du SERVICE (la même que
    l'expiration), en mémoire du processus, comme les autres limites (Redis exclu pour l'instant).
    """

    def __init__(self) -> None:
        self._last: dict[int, datetime] = {}
        self._lock = threading.Lock()

    def allow(self, transaction_id: int, now: datetime) -> bool:
        with self._lock:
            last = self._last.get(transaction_id)
            if last is not None and now - last < CHECK_STATUS_EVERY:
                return False
            self._last[transaction_id] = now
            if len(self._last) > 10_000:  # transactions terminées depuis longtemps : on oublie
                self._last = {
                    tid: at for tid, at in self._last.items() if now - at < timedelta(hours=1)
                }
            return True


def refresh_transaction(
    session: Session,
    provider: PaymentProvider,
    transaction_id: int,
    *,
    now: datetime,
    ask_provider: bool = True,
) -> PaymentTransaction:
    """Fait le point sur la transaction (voir le module). Pas de commit.

    `ask_provider=False` : on ne contacte pas le prestataire cette fois (fréquence limitée,
    B11.5), mais l'expiration est quand même vérifiée.
    """
    transaction = session.get(PaymentTransaction, transaction_id)
    if transaction.status is not TransactionStatus.PENDING:
        return transaction
    if ask_provider and transaction.provider_ref is not None:
        bill = session.get(Bill, transaction.bill_id)
        try:
            update = provider.check_status(
                transaction.provider_ref, payment_request(transaction, bill)
            )
        except ProviderUnavailableError:
            update = None  # on réessaiera au prochain suivi ; l'expiration reste possible
        if update is not None:
            transaction = apply_provider_update(
                session, transaction_id, update, origin="status_check", now=now
            ).transaction
    expire_if_due(session, transaction_id, now=now)
    return transaction


def expire_if_due(session: Session, transaction_id: int, *, now: datetime) -> bool:
    """Fait expirer la transaction si son délai est passé sans code PIN. Pas de commit."""
    transaction = session.scalars(
        select(PaymentTransaction)
        .where(PaymentTransaction.id == transaction_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    ).one()
    due = (
        transaction.status is TransactionStatus.PENDING
        and transaction.pin_entered_at is None
        and now >= transaction.expires_at
    )
    if not due:
        return False
    bill = session.scalars(
        select(Bill)
        .where(Bill.id == transaction.bill_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    ).one()
    transaction.status = TransactionStatus.EXPIRED
    transaction.failure_reason = EXPIRY_REASON
    release_bill(bill, local_date(now))
    session.flush()
    insert_notifications(session, [payment_failed_row(transaction, at=transaction.expires_at)])
    record(
        session,
        action="payment.expired",
        entity_type="payment_transaction",
        entity_id=transaction.id,
        actor_id=None,
        after={
            "status": transaction.status.value,
            "expires_at": transaction.expires_at.isoformat(),
        },
    )
    return True


def pending_transaction_ids(session: Session) -> Sequence[int]:
    return session.scalars(
        select(PaymentTransaction.id)
        .where(PaymentTransaction.status == TransactionStatus.PENDING)
        .order_by(PaymentTransaction.initiated_at)
    ).all()
