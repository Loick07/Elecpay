"""Utilisateurs dans le back-office (B10.3, maquettes A2 et A3).

Lecture (support, admin, super admin) : liste filtrée, détail. Le support voit les numéros
MASQUÉS (il peut quand même chercher par numéro) ; admin et super admin les voient en entier.

Écriture (admin, super admin), chaque action au journal avec son motif :
- désactiver : motif obligatoire ; ferme toutes les sessions ; factures et historique gardés ;
- réactiver ;
- envoyer un code de réinitialisation du mot de passe par SMS (le code n'est jamais montré
  à l'équipe ni écrit au journal).
Garde-fous : personne ne se désactive soi-même ; seul un super admin agit sur un compte de
l'équipe.
"""

import csv
import io
from collections import Counter
from collections.abc import Callable
from datetime import date, datetime

from fastapi import status
from sqlalchemy import Select, func, or_, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.request_context import RequestContext
from app.core.timezone import local_date, local_midnight_utc
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.integrations.sms.base import SmsSender
from app.modules.admin.activity import action_label
from app.modules.admin.audit import STAFF_ROLES, record_admin_action
from app.modules.admin.users_schemas import (
    AccountChange,
    AccountStatus,
    AdminUserDetail,
    AdminUserList,
    AdminUserRow,
    Deactivation,
    FinancialSummary,
    HouseholdLine,
    JournalLine,
    MeterLine,
    ResetCodeSent,
    SessionLine,
    TransactionLine,
    UnpaidSummary,
    UserKind,
)
from app.modules.audit.models import AuditLog
from app.modules.auth.models import RefreshToken
from app.modules.auth.passwords import PasswordService
from app.modules.auth.sessions import SessionService
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.queries import bill_period_label
from app.modules.households.access import HouseholdRole
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.users.models import User, UserRole

TO_PAY = (BillStatus.UNPAID, BillStatus.OVERDUE, BillStatus.PENDING_PAYMENT)
EXPORT_LIMIT = 10_000
RECENT = 10
JOURNAL = 20


class UserNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "USER_NOT_FOUND"
    message = "Utilisateur introuvable."


class AccountActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "ACCOUNT_ACTION_REFUSED"
    message = "Action impossible sur ce compte."


class ExportTooLargeError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "EXPORT_TOO_LARGE"
    message = f"Plus de {EXPORT_LIMIT} lignes : précisez la recherche ou les filtres."


def shown_phone(phone: str, viewer: User) -> str:
    """Le support voit les numéros masqués ; admin et super admin en entier (décision B10)."""
    return mask_phone(phone) if viewer.role is UserRole.SUPPORT else phone


class AdminUsers:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Liste (A2) ---------------------------------------------------------------------------

    def list(
        self,
        viewer: User,
        params: PageParams,
        *,
        q: str | None = None,
        kind: UserKind | None = None,
        account_status: AccountStatus | None = None,
    ) -> AdminUserList:
        query = self._filtered(q, kind, account_status)
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        users = self.session.scalars(
            query.order_by(User.created_at.desc(), User.id.desc())
            .limit(params.size)
            .offset(params.offset)
        ).all()
        today = local_date(self.now())
        return AdminUserList(
            items=[self._row(user, viewer, today) for user in users],
            total=total,
            page=params.page,
            size=params.size,
            accounts=self.session.scalar(select(func.count()).select_from(User)),
            active_accounts=self.session.scalar(
                select(func.count()).select_from(User).where(User.is_active.is_(True))
            ),
        )

    def export_csv(
        self,
        viewer: User,
        context: RequestContext,
        *,
        q: str | None = None,
        kind: UserKind | None = None,
        account_status: AccountStatus | None = None,
    ) -> str:
        """Export CSV (séparateur « ; », pour Excel en français). Inscrit au journal."""
        query = self._filtered(q, kind, account_status)
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        if total > EXPORT_LIMIT:
            raise ExportTooLargeError(details={"rows": total, "limit": EXPORT_LIMIT})
        today = local_date(self.now())
        out = io.StringIO()
        writer = csv.writer(out, delimiter=";", lineterminator="\n")
        writer.writerow(
            [
                "id",
                "nom",
                "téléphone",
                "rôle",
                "payeur délégué",
                "foyers",
                "factures à payer",
                "montant à payer (FCFA)",
                "dernière connexion",
                "statut",
            ]
        )
        for user in self.session.scalars(query.order_by(User.id)):
            row = self._row(user, viewer, today)
            writer.writerow(
                [
                    row.id,
                    row.full_name,
                    row.phone,
                    row.role.value,
                    "oui" if row.is_delegated_payer else "non",
                    row.households,
                    row.unpaid.count,
                    row.unpaid.amount,
                    row.last_login_at.isoformat() if row.last_login_at else "",
                    "actif" if row.is_active else "désactivé",
                ]
            )
        record_admin_action(
            self.session,
            actor=viewer,
            context=context,
            action="admin.export",
            entity_type="user",
            entity_id=None,
            after={
                "export": "users",
                "rows": total,
                "q": q,
                "kind": kind.value if kind else None,
                "status": account_status.value if account_status else None,
            },
        )
        self.session.commit()
        return out.getvalue()

    # --- Détail (A3) -------------------------------------------------------------------------

    def detail(self, viewer: User, user_id: int) -> AdminUserDetail:
        user = self._get(user_id)
        now = self.now()
        today = local_date(now)
        owned = self._owned_household_ids(user)
        return AdminUserDetail(
            id=user.id,
            full_name=user.full_name,
            phone=shown_phone(user.phone, viewer),
            email=user.email,
            role=user.role,
            is_active=user.is_active,
            created_at=user.created_at,
            last_login_at=user.last_login_at,
            deactivation=None if user.is_active else self._last_deactivation(user),
            households=self._households(user, today),
            recent_transactions=self._recent_transactions(user, owned),
            summary=self._summary(user, owned, today),
            open_sessions=self._sessions(user, now),
            journal=self._journal(user),
        )

    # --- Actions (A3) ------------------------------------------------------------------------

    def deactivate(
        self, actor: User, user_id: int, reason: str, context: RequestContext, settings: Settings
    ) -> AccountChange:
        user = self._target(actor, user_id)
        if not user.is_active:
            raise AccountActionError("Ce compte est déjà désactivé.")
        user.is_active = False
        closed = SessionService(self.session, settings, self.now).close_all_sessions(user.id)
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="user.deactivate",
            entity_type="user",
            entity_id=user.id,
            before={"is_active": True},
            after={"is_active": False, "reason": reason, "sessions_closed": closed},
        )
        self.session.commit()
        return AccountChange(id=user.id, is_active=False, sessions_closed=closed)

    def reactivate(
        self, actor: User, user_id: int, reason: str | None, context: RequestContext
    ) -> AccountChange:
        user = self._target(actor, user_id)
        if user.is_active:
            raise AccountActionError("Ce compte est déjà actif.")
        user.is_active = True
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="user.reactivate",
            entity_type="user",
            entity_id=user.id,
            before={"is_active": False},
            after={"is_active": True, "reason": reason},
        )
        self.session.commit()
        return AccountChange(id=user.id, is_active=True)

    def send_reset_code(
        self,
        actor: User,
        user_id: int,
        context: RequestContext,
        settings: Settings,
        sms: SmsSender,
    ) -> ResetCodeSent:
        user = self._target(actor, user_id)
        if not user.is_active:
            raise AccountActionError("Compte désactivé : réactivez-le d'abord.")
        record_admin_action(  # ni le code, ni son empreinte : seulement le fait
            self.session,
            actor=actor,
            context=context,
            action="user.send_reset_code",
            entity_type="user",
            entity_id=user.id,
            after={"sent_to": mask_phone(user.phone)},
        )
        PasswordService(self.session, settings, sms, self.now).request_reset(user.phone)
        return ResetCodeSent(phone=mask_phone(user.phone))

    # --- Outils ------------------------------------------------------------------------------

    def _get(self, user_id: int) -> User:
        user = self.session.get(User, user_id)
        if user is None:
            raise UserNotFoundError()
        return user

    def _target(self, actor: User, user_id: int) -> User:
        user = self._get(user_id)
        if user.id == actor.id:
            raise AccountActionError("Vous ne pouvez pas agir ainsi sur votre propre compte.")
        if user.role in STAFF_ROLES and actor.role is not UserRole.SUPER_ADMIN:
            raise AccountActionError("Seul un super admin agit sur un compte de l'équipe.")
        return user

    def _filtered(
        self, q: str | None, kind: UserKind | None, account_status: AccountStatus | None
    ) -> Select:
        query = select(User)
        if q and q.strip():
            text = q.strip()
            digits = "".join(char for char in text if char.isdigit())
            conditions = [User.full_name.ilike(f"%{text}%")]
            if len(digits) >= 3:
                conditions.append(User.phone.like(f"%{digits}%"))
            query = query.where(or_(*conditions))
        match kind:
            case UserKind.CLIENT:
                query = query.where(User.role == UserRole.CLIENT)
            case UserKind.TEAM:
                query = query.where(User.role.in_(STAFF_ROLES))
            case UserKind.DELEGATED_PAYER:
                query = query.where(User.id.in_(self._active_payers()))
        if account_status is not None:
            query = query.where(User.is_active.is_(account_status is AccountStatus.ACTIVE))
        return query

    @staticmethod
    def _active_payers() -> Select:
        return select(HouseholdMember.user_id).where(
            HouseholdMember.role == MemberRole.PAYER, HouseholdMember.status == MemberStatus.ACTIVE
        )

    def _owned_household_ids(self, user: User) -> list[int]:
        return list(self.session.scalars(select(Household.id).where(Household.owner_id == user.id)))

    def _bills_to_pay(self, household_ids: list[int]) -> list[Bill]:
        if not household_ids:
            return []
        return list(
            self.session.scalars(
                select(Bill)
                .join(Meter, Meter.id == Bill.meter_id)
                .where(Meter.household_id.in_(household_ids), Bill.status.in_(TO_PAY))
            )
        )

    def _unpaid(self, household_ids: list[int], today: date) -> UnpaidSummary:
        bills = self._bills_to_pay(household_ids)
        overdue = [
            bill
            for bill in bills
            if bill.status is BillStatus.OVERDUE
            or (bill.status is BillStatus.UNPAID and bill.due_date < today)
        ]
        return UnpaidSummary(
            count=len(bills),
            amount=sum(bill.amount_total for bill in bills),
            overdue_count=len(overdue),
            pending_payment_count=sum(b.status is BillStatus.PENDING_PAYMENT for b in bills),
            oldest_overdue_days=max(((today - b.due_date).days for b in overdue), default=None),
        )

    def _row(self, user: User, viewer: User, today: date) -> AdminUserRow:
        owned = self._owned_household_ids(user)
        memberships = self.session.scalars(
            select(HouseholdMember).where(
                HouseholdMember.user_id == user.id, HouseholdMember.status == MemberStatus.ACTIVE
            )
        ).all()
        return AdminUserRow(
            id=user.id,
            full_name=user.full_name,
            phone=shown_phone(user.phone, viewer),
            email=user.email,
            role=user.role,
            is_delegated_payer=any(m.role is MemberRole.PAYER for m in memberships),
            households=len(set(owned) | {m.household_id for m in memberships}),
            unpaid=self._unpaid(owned, today),
            last_login_at=user.last_login_at,
            is_active=user.is_active,
            created_at=user.created_at,
        )

    def _households(self, user: User, today: date) -> list[HouseholdLine]:
        rows: list[tuple[Household, HouseholdRole]] = [
            (household, HouseholdRole.OWNER)
            for household in self.session.scalars(
                select(Household).where(Household.owner_id == user.id).order_by(Household.id)
            )
        ]
        for member, household in self.session.execute(
            select(HouseholdMember, Household)
            .join(Household, Household.id == HouseholdMember.household_id)
            .where(
                HouseholdMember.user_id == user.id, HouseholdMember.status == MemberStatus.ACTIVE
            )
            .order_by(Household.id)
        ):
            role = HouseholdRole.PAYER if member.role is MemberRole.PAYER else HouseholdRole.VIEWER
            rows.append((household, role))
        lines = []
        for household, role in rows:
            meters = self.session.scalars(
                select(Meter).where(Meter.household_id == household.id).order_by(Meter.id)
            ).all()
            payers = self.session.scalars(
                select(User.full_name)
                .join(HouseholdMember, HouseholdMember.user_id == User.id)
                .where(
                    HouseholdMember.household_id == household.id,
                    HouseholdMember.role == MemberRole.PAYER,
                    HouseholdMember.status == MemberStatus.ACTIVE,
                )
            ).all()
            unpaid = self._unpaid([household.id], today)
            lines.append(
                HouseholdLine(
                    id=household.id,
                    name=household.name,
                    role=role,
                    meters=[
                        MeterLine(
                            id=meter.id,
                            reference=meter.reference,
                            label=meter.label,
                            subscribed_power_va=meter.subscribed_power_va,
                        )
                        for meter in meters
                    ],
                    delegated_payers=list(payers),
                    unpaid_count=unpaid.count,
                    unpaid_amount=unpaid.amount,
                )
            )
        return lines

    def _transactions_query(self, user: User, owned: list[int]):
        on_owned = Bill.meter_id.in_(select(Meter.id).where(Meter.household_id.in_(owned)))
        return (
            select(PaymentTransaction)
            .join(Bill, Bill.id == PaymentTransaction.bill_id)
            .where(or_(PaymentTransaction.payer_id == user.id, on_owned))
        )

    def _recent_transactions(self, user: User, owned: list[int]) -> list[TransactionLine]:
        transactions = self.session.scalars(
            self._transactions_query(user, owned)
            .order_by(PaymentTransaction.initiated_at.desc(), PaymentTransaction.id.desc())
            .limit(RECENT)
        ).all()
        lines = []
        for transaction in transactions:
            bill = self.session.get(Bill, transaction.bill_id)
            meter = self.session.get(Meter, bill.meter_id)
            household = (
                self.session.get(Household, meter.household_id) if meter.household_id else None
            )
            lines.append(
                TransactionLine(
                    id=transaction.id,
                    reference=public_reference(transaction),
                    bill_id=bill.id,
                    bill_period_label=bill_period_label(bill.period_start, bill.period_end),
                    household_name=household.name if household else None,
                    amount=transaction.amount,
                    operator=transaction.operator,
                    operator_label=OPERATOR_LABELS[transaction.operator],
                    status=transaction.status,
                    failure_reason=transaction.failure_reason,
                    payer_id=transaction.payer_id,
                    payer_name=self.session.get(User, transaction.payer_id).full_name,
                    initiated_at=transaction.initiated_at,
                    confirmed_at=transaction.confirmed_at,
                )
            )
        return lines

    def _summary(self, user: User, owned: list[int], today: date) -> FinancialSummary:
        year_start = local_midnight_utc(date(today.year, 1, 1))
        mine = self.session.scalars(
            select(PaymentTransaction).where(
                PaymentTransaction.payer_id == user.id,
                PaymentTransaction.initiated_at >= year_start,
                PaymentTransaction.status != TransactionStatus.PENDING,
            )
        ).all()
        succeeded = [t for t in mine if t.status is TransactionStatus.SUCCEEDED]
        operators = Counter(t.operator for t in succeeded)
        return FinancialSummary(
            year=today.year,
            paid_this_year=sum(t.amount for t in succeeded),
            left_to_pay=self._unpaid(owned, today).amount,
            not_completed=len(mine) - len(succeeded),
            attempts=len(mine),
            preferred_operator=operators.most_common(1)[0][0] if operators else None,
        )

    def _sessions(self, user: User, now: datetime) -> list[SessionLine]:
        tokens = self.session.scalars(
            select(RefreshToken)
            .where(
                RefreshToken.user_id == user.id,
                RefreshToken.revoked_at.is_(None),
                RefreshToken.expires_at > now,
            )
            .order_by(RefreshToken.created_at.desc())
        ).all()
        return [
            SessionLine(
                id=token.id,
                user_agent=token.user_agent,
                last_activity_at=token.created_at,
                expires_at=token.expires_at,
            )
            for token in tokens
        ]

    def _journal(self, user: User) -> list[JournalLine]:
        rows = self.session.execute(
            select(AuditLog, User)
            .outerjoin(User, User.id == AuditLog.actor_id)
            .where(
                or_(
                    AuditLog.actor_id == user.id,
                    (AuditLog.entity_type == "user") & (AuditLog.entity_id == user.id),
                )
            )
            .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
            .limit(JOURNAL)
        ).all()
        return [
            JournalLine(
                at=log.created_at,
                action=log.action,
                label=action_label(log.action),
                actor_name=actor.full_name if actor else None,
                is_staff_action=actor is not None and actor.role in STAFF_ROLES,
            )
            for log, actor in rows
        ]

    def _last_deactivation(self, user: User) -> Deactivation | None:
        row = self.session.execute(
            select(AuditLog, User)
            .outerjoin(User, User.id == AuditLog.actor_id)
            .where(
                AuditLog.action == "user.deactivate",
                AuditLog.entity_type == "user",
                AuditLog.entity_id == user.id,
            )
            .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
            .limit(1)
        ).first()
        if row is None:
            return None
        log, actor = row
        return Deactivation(
            at=log.created_at,
            reason=(log.after_json or {}).get("reason", ""),
            by=actor.full_name if actor else None,
        )
