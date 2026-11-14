"""Factures dans le back-office (B10.5, maquettes A5 et A6).

Lecture (support, admin, super admin) : liste filtrée avec les totaux du mois, détail complet
(lignes, index, tarif, source des relevés, payeurs autorisés, transactions, historique).

Écriture (admin, super admin), chaque action au journal :
- annuler une facture : motif d'au moins 10 caractères. JAMAIS de suppression ni de
  modification des montants (la base le garantit aussi). Refusé si la facture est payée,
  déjà annulée ou si un paiement est en cours ;
- réémettre la période d'une facture annulée : passe par `generate_bill` (l'unique endroit
  qui crée une facture), avec les relevés de facturation actuels. Le titulaire et les payeurs
  délégués sont prévenus (« Facture corrigée »).

Export CSV (admin) : 10 000 lignes au plus, inscrit au journal.
"""

import csv
import io
from collections import Counter
from collections.abc import Callable
from datetime import date, datetime, timedelta

from fastapi import status
from sqlalchemy import ColumnElement, Select, and_, func, or_, select
from sqlalchemy.orm import Session

from app.core.calendar import add_months
from app.core.config import Settings
from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.request_context import RequestContext
from app.core.timezone import local_date, local_midnight_utc
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.modules.admin.activity import action_label
from app.modules.admin.audit import record_admin_action
from app.modules.admin.bills_schemas import (
    AdminBillDetail,
    AdminBillFilter,
    AdminBillList,
    AdminBillRow,
    AuthorizedPayer,
    BillCancelled,
    BillingReading,
    BillReissued,
    BillTransaction,
    HistoryEvent,
    MonthTotals,
    ReadingSources,
    RelatedBill,
)
from app.modules.admin.users import shown_phone
from app.modules.audit.models import AuditLog
from app.modules.bills.errors import BillNotFoundError
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.notifications import bill_reissued_notification
from app.modules.bills.pdf import fr_number
from app.modules.bills.queries import (
    bill_line_items,
    bill_period_label,
    displayed_status,
    is_overdue,
)
from app.modules.bills.reminders import bill_recipients
from app.modules.bills.schemas import TariffPublic
from app.modules.bills.service import generate_bill
from app.modules.consumption.models import MeterReading
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.notifications.service import insert_notifications
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User

EXPORT_LIMIT = 10_000
CANCELLABLE = (BillStatus.UNPAID, BillStatus.OVERDUE)


class BillActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "BILL_ACTION_REFUSED"
    message = "Action impossible sur cette facture."


class BillExportTooLargeError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "EXPORT_TOO_LARGE"
    message = f"Plus de {EXPORT_LIMIT} lignes : précisez la recherche ou les filtres."


def month_bounds(month: str) -> tuple[datetime, datetime]:
    """« 2026-11 » → [1er novembre 0 h, 1er décembre 0 h[ à Brazzaville, en UTC."""
    first = date(int(month[:4]), int(month[5:7]), 1)
    return local_midnight_utc(first), local_midnight_utc(add_months(first, 1))


class AdminBills:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Liste (A5) ---------------------------------------------------------------------------

    def list(
        self,
        params: PageParams,
        *,
        q: str | None = None,
        bill_status: AdminBillFilter | None = None,
        month: str | None = None,
        meter_id: int | None = None,
    ) -> AdminBillList:
        today = local_date(self.now())
        query = self._filtered(today, q, bill_status, month, meter_id)
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = self.session.execute(
            query.order_by(Bill.issued_at.desc(), Bill.id.desc())
            .limit(params.size)
            .offset(params.offset)
        ).all()
        return AdminBillList(
            items=[self._row(*row, today) for row in rows],
            total=total,
            page=params.page,
            size=params.size,
            totals=self._totals(month or f"{today:%Y-%m}", today),
        )

    def export_csv(
        self,
        viewer: User,
        context: RequestContext,
        *,
        q: str | None = None,
        bill_status: AdminBillFilter | None = None,
        month: str | None = None,
        meter_id: int | None = None,
    ) -> str:
        """Export CSV (séparateur « ; », pour Excel en français). Inscrit au journal."""
        today = local_date(self.now())
        query = self._filtered(today, q, bill_status, month, meter_id)
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        if total > EXPORT_LIMIT:
            raise BillExportTooLargeError(details={"rows": total, "limit": EXPORT_LIMIT})
        out = io.StringIO()
        writer = csv.writer(out, delimiter=";", lineterminator="\n")
        writer.writerow(
            [
                "référence",
                "compteur",
                "foyer",
                "titulaire",
                "période",
                "consommation (kWh)",
                "montant (FCFA)",
                "émise le",
                "échéance",
                "statut",
                "payée le",
            ]
        )
        for row in self.session.execute(query.order_by(Bill.issued_at, Bill.id)):
            line = self._row(*row, today)
            writer.writerow(
                [
                    line.reference,
                    line.meter_reference,
                    line.household_name or "",
                    line.owner_name or "",
                    line.period_label,
                    fr_number(line.consumption_wh),  # Wh = millièmes de kWh
                    line.amount_total,
                    f"{local_date(line.issued_at):%d/%m/%Y}",
                    f"{line.due_date:%d/%m/%Y}",
                    line.status.value,
                    f"{local_date(line.paid_at):%d/%m/%Y}" if line.paid_at else "",
                ]
            )
        record_admin_action(
            self.session,
            actor=viewer,
            context=context,
            action="admin.export",
            entity_type="bill",
            entity_id=None,
            after={
                "export": "bills",
                "rows": total,
                "q": q,
                "status": bill_status.value if bill_status else None,
                "month": month,
                "meter_id": meter_id,
            },
        )
        self.session.commit()
        return out.getvalue()

    # --- Détail (A6) --------------------------------------------------------------------------

    def detail(self, viewer: User, bill_id: int) -> AdminBillDetail:
        bill, meter, household, owner = self._get(bill_id)
        today = local_date(self.now())
        row = self._row(bill, meter, household, owner, today)
        tariff = self.session.get(Tariff, bill.tariff_id)
        transactions = self._transactions(bill)
        cancellation = self._cancellation(bill)
        replaces, replaced_by = self._related(bill)
        return AdminBillDetail(
            **row.model_dump(),
            meter_label=meter.label,
            customer_number=meter.customer_number,
            contract_number=meter.contract_number,
            e2c_center=meter.e2c_center,
            period_end=bill.period_end,
            months_count=bill.months_count,
            previous_index_wh=bill.previous_index_wh,
            current_index_wh=bill.current_index_wh,
            billed_power_va=bill.billed_power_va,
            amount_ht=bill.amount_ht,
            amount_tax=bill.amount_tax,
            amount_fees=bill.amount_fees,
            lines=bill_line_items(self.session, bill),
            tariff=TariffPublic(
                id=tariff.id,
                code=tariff.code,
                label=tariff.label,
                price_per_kwh_milli=tariff.price_per_kwh_milli,
                is_assumption=tariff.is_assumption,
            ),
            readings=self._readings(bill),
            authorized_payers=self._payers(household, owner, viewer),
            transactions=transactions,
            history=self._history(bill, [t.id for t in transactions]),
            cancelled_at=bill.cancelled_at,
            cancelled_reason=bill.cancelled_reason,
            cancelled_by=cancellation,
            replaces=replaces,
            replaced_by=replaced_by,
            can_cancel=bill.status in CANCELLABLE and not self._payment_in_progress(bill),
            can_reissue=bill.status is BillStatus.CANCELLED and replaced_by is None,
        )

    # --- Actions (A6) -------------------------------------------------------------------------

    def cancel(
        self, actor: User, bill_id: int, reason: str, context: RequestContext
    ) -> BillCancelled:
        bill = self.session.scalars(
            select(Bill).where(Bill.id == bill_id).with_for_update()
        ).first()
        if bill is None:
            raise BillNotFoundError()
        match bill.status:
            case BillStatus.PAID:
                raise BillActionError("Une facture payée ne peut pas être annulée.")
            case BillStatus.CANCELLED:
                raise BillActionError("Cette facture est déjà annulée.")
            case BillStatus.PENDING_PAYMENT:
                raise BillActionError(self._in_progress_message())
        if self._payment_in_progress(bill):
            raise BillActionError(self._in_progress_message())
        before = bill.status
        bill.status = BillStatus.CANCELLED
        bill.cancelled_at = self.now()
        bill.cancelled_reason = reason
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="bill.cancel",
            entity_type="bill",
            entity_id=bill.id,
            before={"status": before.value},
            after={"status": BillStatus.CANCELLED.value, "reason": reason},
        )
        self.session.commit()
        return BillCancelled(
            id=bill.id,
            status=bill.status,
            cancelled_at=bill.cancelled_at,
            cancelled_reason=reason,
        )

    def reissue(
        self,
        actor: User,
        bill_id: int,
        reason: str,
        context: RequestContext,
        settings: Settings,
    ) -> BillReissued:
        cancelled, meter, household, owner = self._get(bill_id)
        if cancelled.status is not BillStatus.CANCELLED:
            raise BillActionError("Seule une facture annulée peut être réémise.")
        now = self.now()
        today = local_date(now)
        issued = generate_bill(
            self.session,
            meter,
            cancelled.period_start,
            today=today,
            settings=settings,
            reissue_at=now,
        )
        if not issued.created:
            raise BillActionError(
                "Cette période a déjà une facture active : elle a déjà été réémise.",
                details={"bill_id": issued.bill.id},
            )
        bill = issued.bill
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="bill.reissue",
            entity_type="bill",
            entity_id=bill.id,
            before={"cancelled_bill_id": cancelled.id, "amount_total": cancelled.amount_total},
            after={
                "bill_id": bill.id,
                "reference": bill.reference,
                "amount_total": bill.amount_total,
                "reason": reason,
            },
        )
        sent = insert_notifications(
            self.session,
            [
                bill_reissued_notification(user_id, bill, cancelled)
                for user_id in bill_recipients(self.session, bill)
            ],
        )
        self.session.commit()
        return BillReissued(
            cancelled_bill_id=cancelled.id,
            bill=self._row(bill, meter, household, owner, today),
            notifications=sent,
        )

    # --- Outils -------------------------------------------------------------------------------

    @staticmethod
    def _base() -> Select:
        return (
            select(Bill, Meter, Household, User)
            .join(Meter, Meter.id == Bill.meter_id)
            .outerjoin(Household, Household.id == Meter.household_id)
            .outerjoin(User, User.id == Household.owner_id)
        )

    def _get(self, bill_id: int) -> tuple[Bill, Meter, Household | None, User | None]:
        row = self.session.execute(self._base().where(Bill.id == bill_id)).first()
        if row is None:
            raise BillNotFoundError()
        bill, meter, household, owner = row
        return bill, meter, household, owner

    def _filtered(
        self,
        today: date,
        q: str | None,
        bill_status: AdminBillFilter | None,
        month: str | None,
        meter_id: int | None,
    ) -> Select:
        query = self._base()
        if q and q.strip():
            text = q.strip()
            query = query.where(
                or_(
                    Bill.reference.like(f"%{text}%"),
                    Meter.reference.like(f"%{text}%"),
                    Meter.customer_number.like(f"%{text}%"),
                    Household.name.ilike(f"%{text}%"),
                    User.full_name.ilike(f"%{text}%"),
                )
            )
        if bill_status is not None:
            query = query.where(self._status_condition(bill_status, today))
        if month is not None:
            start, end = month_bounds(month)
            query = query.where(Bill.issued_at >= start, Bill.issued_at < end)
        if meter_id is not None:
            query = query.where(Bill.meter_id == meter_id)
        return query

    @staticmethod
    def _status_condition(wanted: AdminBillFilter, today: date) -> ColumnElement[bool]:
        match wanted:
            case AdminBillFilter.UNPAID:
                return and_(Bill.status == BillStatus.UNPAID, Bill.due_date >= today)
            case AdminBillFilter.OVERDUE:
                return is_overdue(today)
            case _:
                return Bill.status == BillStatus(wanted.value)

    @staticmethod
    def _row(
        bill: Bill, meter: Meter, household: Household | None, owner: User | None, today: date
    ) -> AdminBillRow:
        shown = displayed_status(bill, today)
        return AdminBillRow(
            id=bill.id,
            reference=bill.reference,
            meter_id=meter.id,
            meter_reference=meter.reference,
            household_id=household.id if household else None,
            household_name=household.name if household else None,
            owner_name=owner.full_name if owner else None,
            period_label=bill_period_label(bill.period_start, bill.period_end),
            period_start=bill.period_start,
            consumption_wh=bill.consumption_wh,
            amount_total=bill.amount_total,
            issued_at=bill.issued_at,
            due_date=bill.due_date,
            status=shown,
            days_overdue=(today - bill.due_date).days if shown is BillStatus.OVERDUE else 0,
            paid_at=bill.paid_at,
        )

    def _totals(self, month: str, today: date) -> MonthTotals:
        start, end = month_bounds(month)
        in_month = and_(Bill.issued_at >= start, Bill.issued_at < end)
        active = and_(in_month, Bill.status != BillStatus.CANCELLED)

        def amount(*where: ColumnElement[bool]) -> int:
            return int(
                self.session.scalar(
                    select(func.coalesce(func.sum(Bill.amount_total), 0)).where(*where)
                )
            )

        def count(*where: ColumnElement[bool]) -> int:
            return self.session.scalar(select(func.count()).select_from(Bill).where(*where))

        billed = amount(active)
        collected = amount(in_month, Bill.status == BillStatus.PAID)
        return MonthTotals(
            month=month,
            issued=count(active),
            billed=billed,
            collected=collected,
            remaining=billed - collected,
            overdue=count(in_month, is_overdue(today)),
            cancelled=count(in_month, Bill.status == BillStatus.CANCELLED),
        )

    def _payment_in_progress(self, bill: Bill) -> bool:
        return bool(
            self.session.scalar(
                select(func.count())
                .select_from(PaymentTransaction)
                .where(
                    PaymentTransaction.bill_id == bill.id,
                    PaymentTransaction.status == TransactionStatus.PENDING,
                )
            )
        )

    @staticmethod
    def _in_progress_message() -> str:
        return (
            "Un paiement est en cours sur cette facture : attendez sa confirmation ou son "
            "échec avant de l'annuler."
        )

    def _readings(self, bill: Bill) -> ReadingSources:
        def at_midnight(day: date) -> MeterReading | None:
            return self.session.scalars(
                select(MeterReading)
                .where(
                    MeterReading.meter_id == bill.meter_id,
                    MeterReading.read_at >= local_midnight_utc(day),
                    MeterReading.read_at < local_midnight_utc(day + timedelta(days=1)),
                )
                .order_by(MeterReading.read_at)
                .limit(1)
            ).first()

        def billing(reading: MeterReading | None) -> BillingReading | None:
            if reading is None:
                return None
            return BillingReading(
                read_at=reading.read_at,
                index_wh=reading.index_wh,
                source=reading.source,
                is_estimated=reading.is_estimated,
            )

        previous = at_midnight(bill.period_start)
        current = at_midnight(bill.period_end + timedelta(days=1))
        readings = self.session.execute(
            select(MeterReading.source, MeterReading.is_estimated, MeterReading.is_anomaly).where(
                MeterReading.meter_id == bill.meter_id,
                MeterReading.read_at > local_midnight_utc(bill.period_start),
                MeterReading.read_at <= local_midnight_utc(bill.period_end + timedelta(days=1)),
            )
        ).all()
        return ReadingSources(
            bill_source=bill.source,
            previous=billing(previous),
            current=billing(current),
            daily_readings=len(readings),
            estimated=sum(1 for r in readings if r.is_estimated),
            anomalies=sum(1 for r in readings if r.is_anomaly),
            by_source=dict(Counter(r.source for r in readings)),
        )

    def _payers(
        self, household: Household | None, owner: User | None, viewer: User
    ) -> list[AuthorizedPayer]:
        if household is None or owner is None:
            return []
        payers = [
            AuthorizedPayer(
                user_id=owner.id,
                full_name=owner.full_name,
                phone=shown_phone(owner.phone, viewer),
                role="owner",
            )
        ]
        for user in self.session.scalars(
            select(User)
            .join(HouseholdMember, HouseholdMember.user_id == User.id)
            .where(
                HouseholdMember.household_id == household.id,
                HouseholdMember.role == MemberRole.PAYER,
                HouseholdMember.status == MemberStatus.ACTIVE,
            )
            .order_by(User.full_name)
        ):
            payers.append(
                AuthorizedPayer(
                    user_id=user.id,
                    full_name=user.full_name,
                    phone=shown_phone(user.phone, viewer),
                    role="payer",
                )
            )
        return payers

    def _transactions(self, bill: Bill) -> list[BillTransaction]:
        rows = self.session.execute(
            select(PaymentTransaction, User)
            .join(User, User.id == PaymentTransaction.payer_id)
            .where(PaymentTransaction.bill_id == bill.id)
            .order_by(PaymentTransaction.initiated_at.desc(), PaymentTransaction.id.desc())
        ).all()
        return [
            BillTransaction(
                id=transaction.id,
                reference=public_reference(transaction),
                amount=transaction.amount,
                operator=transaction.operator,
                operator_label=OPERATOR_LABELS[transaction.operator],
                phone_number=mask_phone(transaction.phone_number),
                status=transaction.status,
                failure_reason=transaction.failure_reason,
                payer_id=payer.id,
                payer_name=payer.full_name,
                initiated_at=transaction.initiated_at,
                confirmed_at=transaction.confirmed_at,
            )
            for transaction, payer in rows
        ]

    def _history(self, bill: Bill, transaction_ids: list[int]) -> list[HistoryEvent]:
        events = [
            HistoryEvent(
                at=bill.issued_at,
                action="bill.issued",
                label="Facture émise",
                actor_name=None,
                detail=f"{bill.reference} · à payer avant le {bill.due_date:%d/%m/%Y}",
            )
        ]
        about_bill = and_(AuditLog.entity_type == "bill", AuditLog.entity_id == bill.id)
        about_payments = and_(
            AuditLog.entity_type == "payment_transaction",
            AuditLog.entity_id.in_(transaction_ids),
        )
        for log, actor in self.session.execute(
            select(AuditLog, User)
            .outerjoin(User, User.id == AuditLog.actor_id)
            .where(or_(about_bill, about_payments) if transaction_ids else about_bill)
            .order_by(AuditLog.created_at, AuditLog.id)
        ):
            after = log.after_json or {}
            events.append(
                HistoryEvent(
                    at=log.created_at,
                    action=log.action,
                    label=action_label(log.action),
                    actor_name=actor.full_name if actor else None,
                    detail=after.get("reason") or after.get("failure_reason"),
                )
            )
        if bill.paid_at and not any(e.action == "payment.succeeded" for e in events):
            events.append(  # payée sans trace de paiement ElecPay (historique importé)
                HistoryEvent(
                    at=bill.paid_at,
                    action="bill.paid",
                    label="Facture payée (hors ElecPay)",
                    actor_name=None,
                    detail=None,
                )
            )
        return sorted(events, key=lambda event: event.at)

    def _cancellation(self, bill: Bill) -> str | None:
        if bill.status is not BillStatus.CANCELLED:
            return None
        return self.session.scalar(
            select(User.full_name)
            .join(AuditLog, AuditLog.actor_id == User.id)
            .where(
                AuditLog.action == "bill.cancel",
                AuditLog.entity_type == "bill",
                AuditLog.entity_id == bill.id,
            )
            .order_by(AuditLog.created_at.desc())
            .limit(1)
        )

    def _related(self, bill: Bill) -> tuple[RelatedBill | None, RelatedBill | None]:
        same_period = and_(
            Bill.meter_id == bill.meter_id,
            Bill.period_start == bill.period_start,
            Bill.id != bill.id,
        )

        def related(found: Bill | None) -> RelatedBill | None:
            if found is None:
                return None
            return RelatedBill(
                id=found.id,
                reference=found.reference,
                status=found.status,
                amount_total=found.amount_total,
            )

        if bill.status is BillStatus.CANCELLED:
            active = self.session.scalars(
                select(Bill).where(same_period, Bill.status != BillStatus.CANCELLED).limit(1)
            ).first()
            return None, related(active)
        replaced = self.session.scalars(
            select(Bill)
            .where(same_period, Bill.status == BillStatus.CANCELLED, Bill.id < bill.id)
            .order_by(Bill.id.desc())
            .limit(1)
        ).first()
        return related(replaced), None
