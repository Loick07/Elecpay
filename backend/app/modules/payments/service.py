"""Paiements Mobile Money : lancer un paiement (B7.2).

Règles :
- seuls le titulaire et les payeurs délégués du foyer paient (`HouseholdAccess.can_pay`) ;
- le montant est TOUJOURS celui de la facture (la base le vérifie aussi) ;
- la clé d'idempotence (`Idempotency-Key`) est obligatoire : la même demande renvoyée deux fois
  (double clic, réseau coupé) rend la même transaction, jamais un deuxième débit ; la même
  clé pour une autre demande est refusée ;
- verrou de la facture : la ligne est verrouillée (FOR UPDATE) le temps de la demande, et une
  seule transaction peut être « en attente » par facture (contrainte en base) ;
- pendant le paiement, la facture est « paiement en cours » (plus de bouton Payer) ;
- prestataire injoignable : la transaction est enregistrée « échouée » avec son motif, la
  facture redevient payable, aucun débit n'a été demandé.
"""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.request_context import RequestContext
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentProvider, ProviderUnavailableError
from app.modules.audit.service import record
from app.modules.bills.errors import BillNotFoundError
from app.modules.bills.models import Bill, BillStatus
from app.modules.households.access import meter_access
from app.modules.households.errors import MeterNotFoundError
from app.modules.payments.common import payment_request
from app.modules.payments.errors import (
    BillAlreadyPaidError,
    BillNotPayableError,
    IdempotencyKeyReusedError,
    NotMobileMoneyError,
    OperatorMismatchError,
    PaymentForbiddenError,
    PaymentInProgressError,
    PaymentNotFoundError,
)
from app.modules.payments.models import PaymentProvider as ProviderName
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.operators import operator_for_phone
from app.modules.payments.schemas import PaymentCreate
from app.modules.payments.tracking import refresh_transaction
from app.modules.users.models import User

PROVIDER_UNAVAILABLE = "Service de paiement injoignable : aucun débit n'a été demandé."


@dataclass(frozen=True, slots=True)
class InitiatedPayment:
    transaction: PaymentTransaction
    created: bool  # faux : même demande déjà reçue (même clé d'idempotence)


class PaymentService:
    def __init__(
        self,
        session: Session,
        provider: PaymentProvider,
        settings: Settings,
        now: Callable[[], datetime] = utcnow,
    ) -> None:
        self.session = session
        self.provider = provider
        self.settings = settings
        self.now = now

    def initiate(
        self,
        user: User,
        data: PaymentCreate,
        idempotency_key: str,
        context: RequestContext | None = None,
    ) -> InitiatedPayment:
        existing = self._by_key(idempotency_key)
        if existing is not None:
            return self._replay(existing, user, data)

        bill = self._payable_bill(user, data)
        # Après le verrou : une demande identique arrivée en même temps a pu passer avant.
        existing = self._by_key(idempotency_key, lock=True)
        if existing is not None:
            return self._replay(existing, user, data)
        self._check_bill_status(bill)

        now = self.now()  # une seule lecture de l'horloge : délai exact de 10 minutes
        transaction = PaymentTransaction(
            bill_id=bill.id,
            payer_id=user.id,
            provider=ProviderName(self.provider.name),
            operator=data.operator,
            phone_number=data.phone_number,
            amount=bill.amount_total,
            idempotency_key=idempotency_key,
            initiated_at=now,
            expires_at=now + timedelta(minutes=self.settings.payment_timeout_minutes),
        )
        self.session.add(transaction)
        try:
            self.session.flush()
        except IntegrityError:  # même clé validée entre-temps par une autre requête
            self.session.rollback()
            existing = self._by_key(idempotency_key)
            if existing is None:
                raise
            return self._replay(existing, user, data)

        status_before = bill.status
        bill.status = BillStatus.PENDING_PAYMENT
        try:
            transaction.provider_ref = self.provider.initiate(payment_request(transaction, bill))
        except ProviderUnavailableError:
            transaction.status = TransactionStatus.FAILED
            transaction.failure_reason = PROVIDER_UNAVAILABLE
            bill.status = status_before
        record(
            self.session,
            action="payment.initiate",
            entity_type="payment_transaction",
            entity_id=transaction.id,
            actor_id=user.id,
            context=context,
            after={
                "bill_id": bill.id,
                "amount": transaction.amount,
                "operator": transaction.operator.value,
                "phone_number": mask_phone(transaction.phone_number),
                "status": transaction.status.value,
            },
        )
        self.session.commit()
        return InitiatedPayment(transaction, created=True)

    # --- Étapes -----------------------------------------------------------------------------

    def _by_key(self, key: str, *, lock: bool = False) -> PaymentTransaction | None:
        query = select(PaymentTransaction).where(PaymentTransaction.idempotency_key == key)
        if lock:  # lecture verrouillante : voit ce qu'une autre requête vient de valider
            query = query.with_for_update()
        return self.session.scalars(query).first()

    @staticmethod
    def _replay(existing: PaymentTransaction, user: User, data: PaymentCreate) -> InitiatedPayment:
        same_request = (
            existing.payer_id == user.id
            and existing.bill_id == data.bill_id
            and existing.operator is data.operator
            and existing.phone_number == data.phone_number
        )
        if not same_request:  # même réponse que la clé vienne de quelqu'un d'autre ou non
            raise IdempotencyKeyReusedError()
        return InitiatedPayment(existing, created=False)

    def _payable_bill(self, user: User, data: PaymentCreate) -> Bill:
        """La facture verrouillée, si `user` a le droit de la payer avec ce numéro."""
        bill = self.session.get(Bill, data.bill_id)
        if bill is None:
            raise BillNotFoundError()
        try:
            _, access = meter_access(self.session, user, bill.meter_id)
        except MeterNotFoundError as error:
            raise BillNotFoundError() from error
        if not access.can_pay:
            raise PaymentForbiddenError()
        operator = operator_for_phone(data.phone_number)
        if operator is None:
            raise NotMobileMoneyError()
        if operator is not data.operator:
            raise OperatorMismatchError(
                details={"expected_operator": operator.value, "chosen_operator": data.operator}
            )
        return self.session.scalars(
            select(Bill)
            .where(Bill.id == bill.id)
            .with_for_update()
            .execution_options(populate_existing=True)  # statut relu après le verrou
        ).one()

    def _check_bill_status(self, bill: Bill) -> None:
        match bill.status:
            case BillStatus.PAID:
                raise BillAlreadyPaidError()
            case BillStatus.CANCELLED:
                raise BillNotPayableError()
            case BillStatus.PENDING_PAYMENT:
                pending = self.session.scalars(
                    select(PaymentTransaction.id).where(
                        PaymentTransaction.bill_id == bill.id,
                        PaymentTransaction.status == TransactionStatus.PENDING,
                    )
                ).first()
                if pending is not None:
                    # Le paiement en cours est peut-être terminé ou expiré : on fait le point.
                    refresh_transaction(self.session, self.provider, pending, now=self.now())
                if bill.status is BillStatus.PENDING_PAYMENT or bill.status is BillStatus.PAID:
                    self.session.commit()  # garde ce que le point a appris, avant de refuser
                    self._check_bill_status_after_refresh(bill, pending)
                # Sinon : expiré ou échoué, la facture est de nouveau payable.

    @staticmethod
    def _check_bill_status_after_refresh(bill: Bill, pending: int | None) -> None:
        if bill.status is BillStatus.PAID:
            raise BillAlreadyPaidError()
        raise PaymentInProgressError(details={"transaction_id": pending})

    # --- Suivi (écran 9) --------------------------------------------------------------------

    def track(self, user: User, transaction_id: int) -> PaymentTransaction:
        """La transaction à jour : le payeur, ou tout membre du foyer de la facture.

        Si elle est en attente, on fait le point avec le prestataire (et l'expiration).
        Une transaction d'un autre foyer répond comme une transaction inexistante.
        """
        transaction = self.session.get(PaymentTransaction, transaction_id)
        if transaction is None:
            raise PaymentNotFoundError()
        if transaction.payer_id != user.id:
            bill = self.session.get(Bill, transaction.bill_id)
            try:
                meter_access(self.session, user, bill.meter_id)
            except MeterNotFoundError as error:
                raise PaymentNotFoundError() from error
        transaction = refresh_transaction(
            self.session, self.provider, transaction_id, now=self.now()
        )
        self.session.commit()
        return transaction
