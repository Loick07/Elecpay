"""Tableau de bord du back-office (B10.2, maquette A1).

Tous les calculs se font en base (agrégats SQL) sur des montants entiers ; les journées et le
mois suivent l'heure de Brazzaville. « Encaissé » = paiements réussis via ElecPay (les factures
de l'historique payées hors ElecPay n'y figurent pas).

Points « À surveiller » :
- paiement en attente depuis plus de 10 minutes (code PIN saisi mais débit non confirmé, ou pas
  encore expiré) ;
- au moins 2 paiements non aboutis aujourd'hui pour une même personne ;
- relevés en anomalie des 7 derniers jours (sauf ceux classés sans suite, B10.4), et compteurs
  actifs sans relevé ce matin ;
- factures en retard depuis plus de 30 jours.
"""

from collections import Counter, defaultdict
from collections.abc import Callable
from datetime import date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.calendar import add_months
from app.core.money import format_fcfa
from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.modules.admin.activity import action_label
from app.modules.admin.meters import not_dismissed
from app.modules.admin.stats_schemas import (
    AdminStats,
    Collected,
    Collections30Days,
    DailyCollection,
    FailureRate,
    LatestBills,
    PendingTransactions,
    StatusCount,
    TeamActivity,
    UnpaidBills,
    WatchItem,
)
from app.modules.audit.models import AuditLog
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.queries import bill_period_label, displayed_status, is_overdue
from app.modules.consumption.models import MeterReading
from app.modules.meters.models import Meter, MeterStatus
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.users.models import User, UserRole

MONTHS = (
    "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
)  # fmt: skip
STUCK_AFTER = timedelta(minutes=10)
REPEATED_FAILURES = 2
LONG_OVERDUE_DAYS = 30
TEAM = (UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN)
NOT_COMPLETED = (TransactionStatus.FAILED, TransactionStatus.EXPIRED)
TO_PAY = (BillStatus.UNPAID, BillStatus.OVERDUE, BillStatus.PENDING_PAYMENT)
WATCH_LIMIT = 5
ACTIVITY_LIMIT = 8


def change_percent(before: int, after: int) -> float | None:
    return None if before == 0 else round((after - before) * 100 / before, 1)


class AdminStatsService:
    def __init__(
        self, session: Session, *, demo: bool, now: Callable[[], datetime] = utcnow
    ) -> None:
        self.session = session
        self.demo = demo
        self.now = now

    def stats(self) -> AdminStats:
        now = self.now()
        today = local_date(now)
        return AdminStats(
            generated_at=now,
            demo=self.demo,
            month_label=f"{MONTHS[today.month - 1]} {today.year}",
            collected_this_month=self._collected(now, today),
            unpaid_bills=self._unpaid(today),
            failure_rate_7_days=self._failure_rate(now),
            pending_transactions=self._pending(now),
            collections_30_days=self._collections(today),
            latest_bills=self._latest_bills(now, today),
            watchlist=self._watchlist(now, today),
            team_activity=self._team_activity(),
        )

    # --- Indicateurs --------------------------------------------------------------------------

    def _succeeded_between(self, start: datetime, end: datetime) -> tuple[int, int]:
        amount, count = self.session.execute(
            select(func.coalesce(func.sum(PaymentTransaction.amount), 0), func.count()).where(
                PaymentTransaction.status == TransactionStatus.SUCCEEDED,
                PaymentTransaction.confirmed_at >= start,
                PaymentTransaction.confirmed_at < end,
            )
        ).one()
        return int(amount), int(count)

    def _collected(self, now: datetime, today: date) -> Collected:
        month_start = local_midnight_utc(today.replace(day=1))
        amount, payments = self._succeeded_between(month_start, now)
        previous_start = local_midnight_utc(add_months(today.replace(day=1), -1))
        previous_end = min(previous_start + (now - month_start), month_start)
        previous, _ = self._succeeded_between(previous_start, previous_end)
        return Collected(
            amount=amount,
            payments=payments,
            previous_month_same_point=previous,
            change_percent=change_percent(previous, amount),
        )

    def _unpaid(self, today: date) -> UnpaidBills:
        count, amount = self.session.execute(
            select(func.count(), func.coalesce(func.sum(Bill.amount_total), 0)).where(
                Bill.status.in_(TO_PAY)
            )
        ).one()
        overdue = self.session.scalar(
            select(func.count()).select_from(Bill).where(is_overdue(today))
        )
        return UnpaidBills(count=count, amount=int(amount), overdue_count=overdue)

    def _rate(self, start: datetime, end: datetime) -> tuple[float | None, int, int]:
        rows = dict(
            self.session.execute(
                select(PaymentTransaction.status, func.count())
                .where(
                    PaymentTransaction.status != TransactionStatus.PENDING,
                    PaymentTransaction.initiated_at >= start,
                    PaymentTransaction.initiated_at < end,
                )
                .group_by(PaymentTransaction.status)
            ).all()
        )
        finished = sum(rows.values())
        not_completed = sum(rows.get(status, 0) for status in NOT_COMPLETED)
        rate = round(not_completed * 100 / finished, 1) if finished else None
        return rate, finished, not_completed

    def _failure_rate(self, now: datetime) -> FailureRate:
        week = timedelta(days=7)
        rate, finished, not_completed = self._rate(now - week, now)
        previous, _, _ = self._rate(now - 2 * week, now - week)
        change = round(rate - previous, 1) if rate is not None and previous is not None else None
        return FailureRate(
            rate_percent=rate,
            finished=finished,
            not_completed=not_completed,
            previous_rate_percent=previous,
            change_points=change,
        )

    def _pending(self, now: datetime) -> PendingTransactions:
        pending = PaymentTransaction.status == TransactionStatus.PENDING
        count = self.session.scalar(
            select(func.count()).select_from(PaymentTransaction).where(pending)
        )
        old = self.session.scalar(
            select(func.count())
            .select_from(PaymentTransaction)
            .where(pending, PaymentTransaction.initiated_at < now - STUCK_AFTER)
        )
        return PendingTransactions(count=count, older_than_10_minutes=old)

    def _collections(self, today: date) -> Collections30Days:
        first = today - timedelta(days=29)
        per_day: dict[date, list[int]] = defaultdict(list)
        for confirmed_at, amount in self.session.execute(
            select(PaymentTransaction.confirmed_at, PaymentTransaction.amount).where(
                PaymentTransaction.status == TransactionStatus.SUCCEEDED,
                PaymentTransaction.confirmed_at >= local_midnight_utc(first),
                PaymentTransaction.confirmed_at < local_midnight_utc(today + timedelta(days=1)),
            )
        ):
            per_day[local_date(confirmed_at)].append(amount)
        days = [
            DailyCollection(
                day=first + timedelta(days=offset),
                amount=sum(per_day[first + timedelta(days=offset)]),
                payments=len(per_day[first + timedelta(days=offset)]),
            )
            for offset in range(30)
        ]
        return Collections30Days(
            total=sum(day.amount for day in days),
            payments=sum(day.payments for day in days),
            days=days,
        )

    def _latest_bills(self, now: datetime, today: date) -> LatestBills:
        period_start = self.session.scalar(
            select(func.max(Bill.period_start)).where(Bill.issued_at <= now)
        )
        if period_start is None:
            return LatestBills(
                period_start=None, period_label=None, issued=0, issued_on=None, by_status=[]
            )
        bills = self.session.scalars(
            select(Bill).where(Bill.period_start == period_start, Bill.issued_at <= now)
        ).all()
        counts = Counter(displayed_status(bill, today) for bill in bills)
        order = (
            BillStatus.PAID,
            BillStatus.UNPAID,
            BillStatus.PENDING_PAYMENT,
            BillStatus.OVERDUE,
            BillStatus.CANCELLED,
        )
        return LatestBills(
            period_start=period_start,
            period_label=bill_period_label(bills[0].period_start, bills[0].period_end),
            issued=len(bills),
            issued_on=min(local_date(bill.issued_at) for bill in bills),
            by_status=[
                StatusCount(
                    status=status,
                    count=counts[status],
                    percent=round(counts[status] * 100 / len(bills), 1),
                )
                for status in order
            ],
        )

    # --- À surveiller ------------------------------------------------------------------------

    def _watchlist(self, now: datetime, today: date) -> list[WatchItem]:
        return [
            *self._stuck_payments(now),
            *self._repeated_failures(today),
            *self._reading_anomalies(now, today),
            *self._long_overdue(today),
        ]

    def _stuck_payments(self, now: datetime) -> list[WatchItem]:
        stuck = self.session.scalars(
            select(PaymentTransaction)
            .where(
                PaymentTransaction.status == TransactionStatus.PENDING,
                PaymentTransaction.initiated_at < now - STUCK_AFTER,
            )
            .order_by(PaymentTransaction.initiated_at)
            .limit(WATCH_LIMIT)
        ).all()
        items = []
        for transaction in stuck:
            minutes = int((now - transaction.initiated_at).total_seconds() // 60)
            payer = self.session.get(User, transaction.payer_id)
            pin = (
                "PIN saisi, débit non confirmé"
                if transaction.pin_entered_at
                else "code PIN pas encore saisi"
            )
            items.append(
                WatchItem(
                    kind="stuck_payment",
                    title=f"Paiement en attente depuis {minutes} min",
                    detail=f"{public_reference(transaction)} · {payer.full_name} · "
                    f"{format_fcfa(transaction.amount)} · "
                    f"{OPERATOR_LABELS[transaction.operator]} · {pin}",
                    entity_type="payment_transaction",
                    entity_id=transaction.id,
                )
            )
        return items

    def _repeated_failures(self, today: date) -> list[WatchItem]:
        failures = self.session.scalars(
            select(PaymentTransaction)
            .where(
                PaymentTransaction.status.in_(NOT_COMPLETED),
                PaymentTransaction.initiated_at >= local_midnight_utc(today),
            )
            .order_by(PaymentTransaction.initiated_at)
        ).all()
        by_payer: dict[int, list[PaymentTransaction]] = defaultdict(list)
        for transaction in failures:
            by_payer[transaction.payer_id].append(transaction)
        items = []
        for payer_id, attempts in by_payer.items():
            if len(attempts) < REPEATED_FAILURES:
                continue
            last = attempts[-1]
            items.append(
                WatchItem(
                    kind="repeated_failures",
                    title=f"{len(attempts)} paiements échoués aujourd'hui",
                    detail=f"{self.session.get(User, payer_id).full_name} · "
                    f"{OPERATOR_LABELS[last.operator]} · {(last.failure_reason or '').lower()}",
                    entity_type="user",
                    entity_id=payer_id,
                )
            )
        return items[:WATCH_LIMIT]

    def _reading_anomalies(self, now: datetime, today: date) -> list[WatchItem]:
        anomalies = self.session.execute(
            select(MeterReading, Meter.reference)
            .join(Meter, Meter.id == MeterReading.meter_id)
            .where(not_dismissed(), MeterReading.read_at >= now - timedelta(days=7))
            .order_by(MeterReading.read_at.desc())
        ).all()
        read_this_morning = select(MeterReading.meter_id).where(
            MeterReading.read_at >= local_midnight_utc(today),
            MeterReading.read_at < local_midnight_utc(today + timedelta(days=1)),
        )
        missing = self.session.scalar(
            select(func.count())
            .select_from(Meter)
            .where(
                Meter.status == MeterStatus.ACTIVE,
                Meter.household_id.is_not(None),
                Meter.id.not_in(read_this_morning),
            )
        )
        if not anomalies and not missing:
            return []
        parts = []
        if anomalies:
            reading, reference = anomalies[0]
            parts.append(f"{reading.anomaly_reason} sur le compteur {reference}")
        if missing:
            parts.append(
                f"{missing} relevé{'s' if missing > 1 else ''} manquant{'s' if missing > 1 else ''}"
            )
        first_meter = anomalies[0][0].meter_id if anomalies else None
        return [
            WatchItem(
                kind="reading_anomalies",
                title=f"{len(anomalies)} relevé{'s' if len(anomalies) > 1 else ''} anorma"
                f"{'ux' if len(anomalies) > 1 else 'l'}",
                detail=" · ".join(parts),
                entity_type="meter" if first_meter else None,
                entity_id=first_meter,
            )
        ]

    def _long_overdue(self, today: date) -> list[WatchItem]:
        count, amount = self.session.execute(
            select(func.count(), func.coalesce(func.sum(Bill.amount_total), 0)).where(
                is_overdue(today), Bill.due_date < today - timedelta(days=LONG_OVERDUE_DAYS)
            )
        ).one()
        if not count:
            return []
        return [
            WatchItem(
                kind="long_overdue",
                title=f"{count} facture{'s' if count > 1 else ''} en retard depuis plus de "
                f"{LONG_OVERDUE_DAYS} jours",
                detail=f"Total {format_fcfa(int(amount))} · rappel automatique tous les 7 jours",
                entity_type=None,
                entity_id=None,
            )
        ]

    # --- Activité de l'équipe -------------------------------------------------------------------

    def _team_activity(self) -> list[TeamActivity]:
        rows = self.session.execute(
            select(AuditLog, User)
            .join(User, User.id == AuditLog.actor_id)
            .where(User.role.in_(TEAM))
            .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
            .limit(ACTIVITY_LIMIT)
        ).all()
        return [
            TeamActivity(
                at=log.created_at,
                actor_id=actor.id,
                actor_name=actor.full_name,
                actor_role=actor.role,
                action=log.action,
                label=action_label(log.action),
                entity_type=log.entity_type,
                entity_id=log.entity_id,
            )
            for log, actor in rows
        ]
