"""Transactions dans le back-office (B10.6, maquettes A7 et A8).

Lecture (support, admin, super admin) : liste avec les indicateurs du jour, détail de
rapprochement (comparaison ElecPay ↔ opérateur, chronologie, clé d'idempotence, verrou de
facture, anomalies signalées, litiges). Numéros toujours masqués.

Écriture, chaque action au journal :
- « Relancer la vérification auprès de l'opérateur » (admin) : demande l'état au prestataire
  (`check_status`) et l'applique avec `apply_provider_update`, l'UNIQUE chemin vers
  « réussie » ; puis expiration si le délai est passé sans code PIN. La réponse de l'opérateur
  est notée au journal (`payment.recheck`) : c'est elle que compare l'écran A8 ;
- ouvrir un litige (admin) quand le client affirme avoir été débité ;
- clore un litige (admin) avec la conclusion de l'opérateur et une note.
Un litige ne change JAMAIS une transaction ni une facture. Aucun « marquer comme payée ».

« À rapprocher » : transaction avec une anomalie signalée au journal (montant différent,
réponse contradictoire, paiement reçu sur une facture annulée) et sans litige clos.
"""

from collections.abc import Callable
from datetime import date, datetime, timedelta

from fastapi import status
from sqlalchemy import ColumnElement, Select, and_, exists, func, or_, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.request_context import RequestContext
from app.core.timezone import local_date, local_midnight_utc
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentProvider, ProviderState
from app.modules.admin.activity import action_label
from app.modules.admin.audit import record_admin_action
from app.modules.admin.transactions_schemas import (
    AdminTransactionDetail,
    AdminTransactionList,
    AdminTransactionRow,
    Anomaly,
    BillLock,
    Comparison,
    DayIndicators,
    DisputePublic,
    OperatorView,
    RecheckResult,
    TimelineEvent,
    TransactionFilter,
)
from app.modules.audit.models import AuditLog
from app.modules.bills.models import Bill
from app.modules.disputes.models import DisputeResolution, DisputeStatus, PaymentDispute
from app.modules.payments.common import payment_request, public_reference
from app.modules.payments.confirmation import apply_provider_update
from app.modules.payments.models import MobileOperator, PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.payments.tracking import expire_if_due
from app.modules.users.models import User

ANOMALY_ACTIONS = (
    "payment.amount_mismatch",
    "payment.provider_conflict",
    "payment.bill_not_payable",
)
NOT_COMPLETED = (TransactionStatus.FAILED, TransactionStatus.EXPIRED)
ENTITY = "payment_transaction"
# Statut ElecPay attendu pour chaque réponse de l'opérateur.
EXPECTED: dict[ProviderState, tuple[TransactionStatus, ...]] = {
    ProviderState.PENDING: (TransactionStatus.PENDING,),
    ProviderState.PIN_ENTERED: (TransactionStatus.PENDING,),
    ProviderState.SUCCEEDED: (TransactionStatus.SUCCEEDED,),
    ProviderState.FAILED: (TransactionStatus.FAILED, TransactionStatus.EXPIRED),
}
MESSAGES = {
    "unchanged": "Rien de nouveau : la réponse de l'opérateur correspond à ElecPay.",
    "pin_entered": "L'opérateur indique que le code PIN a été saisi : débit en cours.",
    "succeeded": "L'opérateur a confirmé le débit : paiement réussi, facture payée, reçu émis.",
    "failed": "L'opérateur a refusé le débit : la facture redevient payable.",
    "expired": "Délai dépassé sans code PIN : transaction expirée, facture de nouveau payable.",
    "amount_mismatch": "Montant annoncé différent : paiement NON confirmé, anomalie signalée.",
    "conflict": "Réponse contradictoire avec ElecPay : rien n'est modifié, anomalie signalée.",
}


class TransactionNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "TRANSACTION_NOT_FOUND"
    message = "Transaction introuvable."


class DisputeNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "DISPUTE_NOT_FOUND"
    message = "Litige introuvable sur cette transaction."


class TransactionActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "TRANSACTION_ACTION_REFUSED"
    message = "Action impossible sur cette transaction."


def has_anomaly() -> ColumnElement[bool]:
    return exists().where(
        AuditLog.entity_type == ENTITY,
        AuditLog.entity_id == PaymentTransaction.id,
        AuditLog.action.in_(ANOMALY_ACTIONS),
    )


def has_dispute(dispute_status: DisputeStatus) -> ColumnElement[bool]:
    return exists().where(
        PaymentDispute.transaction_id == PaymentTransaction.id,
        PaymentDispute.status == dispute_status,
    )


def to_reconcile() -> ColumnElement[bool]:
    return and_(has_anomaly(), ~has_dispute(DisputeStatus.CLOSED))


class AdminTransactions:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Liste (A7) ---------------------------------------------------------------------------

    def list(
        self,
        params: PageParams,
        *,
        q: str | None = None,
        wanted: TransactionFilter | None = None,
        operator: MobileOperator | None = None,
        day: date | None = None,
    ) -> AdminTransactionList:
        query = self._filtered(q, wanted, operator, day)
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = self.session.execute(
            query.order_by(PaymentTransaction.initiated_at.desc(), PaymentTransaction.id.desc())
            .limit(params.size)
            .offset(params.offset)
        ).all()
        return AdminTransactionList(
            items=[self._row(*row) for row in rows],
            total=total,
            page=params.page,
            size=params.size,
            today=self._indicators(),
        )

    # --- Détail (A8) --------------------------------------------------------------------------

    def detail(self, transaction_id: int) -> AdminTransactionDetail:
        row = self.session.execute(
            self._base().where(PaymentTransaction.id == transaction_id)
        ).first()
        if row is None:
            raise TransactionNotFoundError()
        transaction, bill, payer, reconcile, open_dispute = row
        view = self._operator_view(transaction)
        return AdminTransactionDetail(
            **self._row(transaction, bill, payer, reconcile, open_dispute).model_dump(),
            provider=transaction.provider,
            provider_ref=transaction.provider_ref,
            idempotency_key=transaction.idempotency_key,
            pin_entered_at=transaction.pin_entered_at,
            expires_at=transaction.expires_at,
            bill_lock=BillLock(
                bill_id=bill.id,
                bill_reference=bill.reference,
                bill_status=bill.status,
                amount_total=bill.amount_total,
                locked_by_this_transaction=transaction.status is TransactionStatus.PENDING,
            ),
            operator_view=view,
            comparison=self._comparison(transaction, view),
            anomalies=self._anomalies(transaction),
            timeline=self._timeline(transaction),
            disputes=self._disputes(transaction),
            can_recheck=transaction.provider_ref is not None,
            can_open_dispute=not open_dispute,
        )

    # --- Relancer la vérification -------------------------------------------------------------

    def recheck(
        self,
        actor: User,
        transaction_id: int,
        provider: PaymentProvider,
        context: RequestContext,
    ) -> RecheckResult:
        transaction = self.session.get(PaymentTransaction, transaction_id)
        if transaction is None:
            raise TransactionNotFoundError()
        if transaction.provider_ref is None:
            raise TransactionActionError(
                "Cette transaction n'a pas de référence chez l'opérateur : rien à vérifier."
            )
        before = transaction.status
        bill = self.session.get(Bill, transaction.bill_id)
        # ProviderUnavailableError (503) remonte telle quelle : rien n'est modifié ni noté.
        update = provider.check_status(transaction.provider_ref, payment_request(transaction, bill))
        now = self.now()
        applied = apply_provider_update(
            self.session, transaction.id, update, origin="admin_recheck", now=now
        )
        outcome = applied.outcome.value
        if expire_if_due(self.session, transaction.id, now=now):
            outcome = "expired"
        transaction = applied.transaction
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="payment.recheck",
            entity_type=ENTITY,
            entity_id=transaction.id,
            before={"status": before.value},
            after={
                "status": transaction.status.value,
                "outcome": outcome,
                "operator_state": update.state.value,
                "operator_ref": update.provider_ref,
                "operator_amount": update.amount,
                "operator_failure_reason": update.failure_reason,
                "operator_at": update.occurred_at.isoformat(),
            },
        )
        self.session.commit()
        return RecheckResult(
            transaction_id=transaction.id,
            status_before=before,
            status_after=transaction.status,
            operator_state=update.state,
            outcome=outcome,
            message=MESSAGES[outcome],
        )

    # --- Litiges ------------------------------------------------------------------------------

    def open_dispute(
        self,
        actor: User,
        transaction_id: int,
        reason: str,
        customer_reference: str | None,
        context: RequestContext,
    ) -> DisputePublic:
        transaction = self.session.scalars(
            select(PaymentTransaction)
            .where(PaymentTransaction.id == transaction_id)
            .with_for_update()
        ).first()
        if transaction is None:
            raise TransactionNotFoundError()
        if self._open_dispute_of(transaction.id) is not None:
            raise TransactionActionError("Un litige est déjà ouvert sur cette transaction.")
        dispute = PaymentDispute(
            transaction_id=transaction.id,
            status=DisputeStatus.OPEN,
            reason=reason,
            customer_reference=customer_reference,
            opened_by=actor.id,
            opened_at=self.now(),
        )
        self.session.add(dispute)
        self.session.flush()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="dispute.open",
            entity_type=ENTITY,
            entity_id=transaction.id,
            after={
                "dispute_id": dispute.id,
                "reason": reason,
                "customer_reference": customer_reference,
                "transaction_status": transaction.status.value,
            },
        )
        self.session.commit()
        return self._dispute(dispute)

    def close_dispute(
        self,
        actor: User,
        transaction_id: int,
        dispute_id: int,
        resolution: DisputeResolution,
        note: str,
        context: RequestContext,
    ) -> DisputePublic:
        dispute = self.session.scalars(
            select(PaymentDispute)
            .where(PaymentDispute.id == dispute_id, PaymentDispute.transaction_id == transaction_id)
            .with_for_update()
        ).first()
        if dispute is None:
            raise DisputeNotFoundError()
        if dispute.status is DisputeStatus.CLOSED:
            raise TransactionActionError("Ce litige est déjà clos.")
        dispute.status = DisputeStatus.CLOSED
        dispute.resolution = resolution
        dispute.resolution_note = note
        dispute.resolved_by = actor.id
        dispute.resolved_at = self.now()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="dispute.resolve",
            entity_type=ENTITY,
            entity_id=transaction_id,
            before={"dispute_id": dispute.id, "status": DisputeStatus.OPEN.value},
            after={
                "dispute_id": dispute.id,
                "status": DisputeStatus.CLOSED.value,
                "resolution": resolution.value,
                "reason": note,
            },
        )
        self.session.commit()
        return self._dispute(dispute)

    # --- Outils -------------------------------------------------------------------------------

    @staticmethod
    def _base() -> Select:
        return (
            select(
                PaymentTransaction,
                Bill,
                User,
                to_reconcile().label("to_reconcile"),
                has_dispute(DisputeStatus.OPEN).label("open_dispute"),
            )
            .join(Bill, Bill.id == PaymentTransaction.bill_id)
            .join(User, User.id == PaymentTransaction.payer_id)
        )

    def _filtered(
        self,
        q: str | None,
        wanted: TransactionFilter | None,
        operator: MobileOperator | None,
        day: date | None,
    ) -> Select:
        query = self._base()
        if q and q.strip():
            text = q.strip()
            digits = "".join(char for char in text if char.isdigit())
            conditions = [
                User.full_name.ilike(f"%{text}%"),
                Bill.reference.like(f"%{text}%"),
                PaymentTransaction.provider_ref.like(f"%{text}%"),
            ]
            if text.upper().startswith("TX-") and digits:
                conditions.append(PaymentTransaction.id == int(digits))
            if len(digits) >= 3:
                conditions.append(PaymentTransaction.phone_number.like(f"%{digits}%"))
            query = query.where(or_(*conditions))
        match wanted:
            case None:
                pass
            case TransactionFilter.TO_RECONCILE:
                query = query.where(to_reconcile())
            case TransactionFilter.OPEN_DISPUTE:
                query = query.where(has_dispute(DisputeStatus.OPEN))
            case _:
                query = query.where(PaymentTransaction.status == TransactionStatus(wanted.value))
        if operator is not None:
            query = query.where(PaymentTransaction.operator == operator)
        if day is not None:
            query = query.where(
                PaymentTransaction.initiated_at >= local_midnight_utc(day),
                PaymentTransaction.initiated_at < local_midnight_utc(day + timedelta(days=1)),
            )
        return query

    @staticmethod
    def _row(
        transaction: PaymentTransaction,
        bill: Bill,
        payer: User,
        reconcile: bool,
        open_dispute: bool,
    ) -> AdminTransactionRow:
        return AdminTransactionRow(
            id=transaction.id,
            reference=public_reference(transaction),
            bill_id=bill.id,
            bill_reference=bill.reference,
            payer_id=payer.id,
            payer_name=payer.full_name,
            phone_number=mask_phone(transaction.phone_number),
            operator=transaction.operator,
            operator_label=OPERATOR_LABELS[transaction.operator],
            amount=transaction.amount,
            status=transaction.status,
            failure_reason=transaction.failure_reason,
            initiated_at=transaction.initiated_at,
            confirmed_at=transaction.confirmed_at,
            pin_entered=transaction.pin_entered_at is not None,
            to_reconcile=bool(reconcile),
            open_dispute=bool(open_dispute),
        )

    def _indicators(self) -> DayIndicators:
        today = local_date(self.now())
        start, end = local_midnight_utc(today), local_midnight_utc(today + timedelta(days=1))
        succeeded = self.session.execute(
            select(
                PaymentTransaction.amount,
                PaymentTransaction.initiated_at,
                PaymentTransaction.confirmed_at,
            ).where(
                PaymentTransaction.status == TransactionStatus.SUCCEEDED,
                PaymentTransaction.confirmed_at >= start,
                PaymentTransaction.confirmed_at < end,
            )
        ).all()
        delays = [(row.confirmed_at - row.initiated_at).total_seconds() for row in succeeded]

        def count(*where: ColumnElement[bool]) -> int:
            return self.session.scalar(
                select(func.count()).select_from(PaymentTransaction).where(*where)
            )

        return DayIndicators(
            day=today,
            collected=sum(row.amount for row in succeeded),
            succeeded=len(succeeded),
            failed=count(
                PaymentTransaction.status.in_(NOT_COMPLETED),
                PaymentTransaction.initiated_at >= start,
                PaymentTransaction.initiated_at < end,
            ),
            pending=count(PaymentTransaction.status == TransactionStatus.PENDING),
            average_confirmation_seconds=round(sum(delays) / len(delays)) if delays else None,
            to_reconcile=count(to_reconcile()),
            open_disputes=self.session.scalar(
                select(func.count())
                .select_from(PaymentDispute)
                .where(PaymentDispute.status == DisputeStatus.OPEN)
            ),
        )

    def _logs(self, transaction: PaymentTransaction, *actions: str) -> list[tuple[AuditLog, User]]:
        query = (
            select(AuditLog, User)
            .outerjoin(User, User.id == AuditLog.actor_id)
            .where(AuditLog.entity_type == ENTITY, AuditLog.entity_id == transaction.id)
            .order_by(AuditLog.created_at, AuditLog.id)
        )
        if actions:
            query = query.where(AuditLog.action.in_(actions))
        return [(log, actor) for log, actor in self.session.execute(query)]

    def _operator_view(self, transaction: PaymentTransaction) -> OperatorView | None:
        rechecks = self._logs(transaction, "payment.recheck")
        if not rechecks:
            return None
        log, actor = rechecks[-1]
        after = log.after_json or {}
        return OperatorView(
            checked_at=log.created_at,
            checked_by=actor.full_name if actor else None,
            state=ProviderState(after["operator_state"]),
            provider_ref=after["operator_ref"],
            amount=after.get("operator_amount"),
            failure_reason=after.get("operator_failure_reason"),
        )

    @staticmethod
    def _comparison(transaction: PaymentTransaction, view: OperatorView | None) -> list[Comparison]:
        def line(field: str, label: str, ours: str | None, theirs: str | None, same: bool | None):
            return Comparison(field=field, label=label, elecpay=ours, operator=theirs, matches=same)

        if view is None:
            amount = ref = state = None
            same_amount = same_ref = same_state = None
        else:
            amount = None if view.amount is None else str(view.amount)
            ref, state = view.provider_ref, view.state.value
            same_amount = None if view.amount is None else view.amount == transaction.amount
            same_ref = view.provider_ref == transaction.provider_ref
            same_state = transaction.status in EXPECTED[view.state]
        return [
            line("amount", "Montant (FCFA)", str(transaction.amount), amount, same_amount),
            line("phone_number", "Numéro débité", mask_phone(transaction.phone_number), None, None),
            line("provider_ref", "Référence opérateur", transaction.provider_ref, ref, same_ref),
            line("status", "Statut", transaction.status.value, state, same_state),
        ]

    def _anomalies(self, transaction: PaymentTransaction) -> list[Anomaly]:
        return [
            Anomaly(
                at=log.created_at,
                action=log.action,
                label=action_label(log.action),
                detail={key: str(value) for key, value in (log.after_json or {}).items()},
            )
            for log, _ in self._logs(transaction, *ANOMALY_ACTIONS)
        ]

    def _timeline(self, transaction: PaymentTransaction) -> list[TimelineEvent]:
        events = [
            TimelineEvent(
                at=transaction.initiated_at,
                action="payment.requested",
                label="Demande de débit envoyée à l'opérateur",
                actor_name=None,
                detail=f"{OPERATOR_LABELS[transaction.operator]} · "
                f"{mask_phone(transaction.phone_number)} · expire à "
                f"{transaction.expires_at:%H:%M} UTC sans code PIN",
            )
        ]
        if transaction.pin_entered_at is not None:
            events.append(
                TimelineEvent(
                    at=transaction.pin_entered_at,
                    action="payment.pin_entered",
                    label="Code PIN saisi par le payeur",
                    actor_name=None,
                    detail=None,
                )
            )
        for log, actor in self._logs(transaction):
            if log.action == "payment.initiate":
                continue  # déjà représenté par la demande de débit
            after = log.after_json or {}
            events.append(
                TimelineEvent(
                    at=log.created_at,
                    action=log.action,
                    label=action_label(log.action),
                    actor_name=actor.full_name if actor else None,
                    detail=after.get("reason") or after.get("outcome") or after.get("origin"),
                )
            )
        # Sans trace au journal (historique importé, données de démo), les dates de la
        # transaction elle-même disent quand elle s'est terminée.
        logged = {event.action for event in events}
        if transaction.confirmed_at and "payment.succeeded" not in logged:
            events.append(
                TimelineEvent(
                    at=transaction.confirmed_at,
                    action="payment.succeeded",
                    label=action_label("payment.succeeded"),
                    actor_name=None,
                    detail=None,
                )
            )
        if transaction.status is TransactionStatus.EXPIRED and "payment.expired" not in logged:
            events.append(
                TimelineEvent(
                    at=transaction.expires_at,
                    action="payment.expired",
                    label=action_label("payment.expired"),
                    actor_name=None,
                    detail=transaction.failure_reason,
                )
            )
        return sorted(events, key=lambda event: event.at)

    def _open_dispute_of(self, transaction_id: int) -> PaymentDispute | None:
        return self.session.scalars(
            select(PaymentDispute).where(
                PaymentDispute.transaction_id == transaction_id,
                PaymentDispute.status == DisputeStatus.OPEN,
            )
        ).first()

    def _disputes(self, transaction: PaymentTransaction) -> list[DisputePublic]:
        disputes = self.session.scalars(
            select(PaymentDispute)
            .where(PaymentDispute.transaction_id == transaction.id)
            .order_by(PaymentDispute.opened_at.desc(), PaymentDispute.id.desc())
        ).all()
        return [self._dispute(dispute) for dispute in disputes]

    def _dispute(self, dispute: PaymentDispute) -> DisputePublic:
        def name(user_id: int | None) -> str | None:
            return None if user_id is None else self.session.get(User, user_id).full_name

        return DisputePublic(
            id=dispute.id,
            status=dispute.status,
            reason=dispute.reason,
            customer_reference=dispute.customer_reference,
            opened_by=name(dispute.opened_by),
            opened_at=dispute.opened_at,
            resolution=dispute.resolution,
            resolution_note=dispute.resolution_note,
            resolved_by=name(dispute.resolved_by),
            resolved_at=dispute.resolved_at,
        )
