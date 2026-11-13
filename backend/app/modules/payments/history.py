"""Historique des paiements (B7.5, écran client 12).

Ce qu'un abonné voit : les paiements des factures de ses foyers (propriétaire, payeur délégué
ou lecteur, comme pour les factures — décision du 13/11/2026), plus ses propres paiements
(même s'il a quitté le foyer depuis). Numéros des autres masqués (voir `views.py`).
Du plus récent au plus ancien. L'historique ne contacte pas le prestataire : c'est le suivi
d'un paiement (`GET /payments/{id}`) ou la tâche planifiée qui fait avancer les transactions.
"""

from datetime import date

from sqlalchemy import ColumnElement, or_, select
from sqlalchemy.orm import Session

from app.core.calendar import add_months
from app.core.pagination import Page, PageParams, paginate
from app.core.timezone import local_midnight_utc
from app.modules.bills.errors import BillNotFoundError
from app.modules.bills.models import Bill
from app.modules.households.access import accessible_household_accesses
from app.modules.households.errors import HouseholdNotFoundError
from app.modules.meters.models import Meter
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.payments.schemas import PaymentPublic
from app.modules.payments.views import payment_public
from app.modules.users.models import User


def month_bounds(month: str) -> tuple:
    """« 2026-10 » → [1er octobre 0 h, 1er novembre 0 h[, heure de Brazzaville, en UTC."""
    year, number = (int(part) for part in month.split("-"))
    first = date(year, number, 1)
    return local_midnight_utc(first), local_midnight_utc(add_months(first, 1))


class PaymentHistory:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list(
        self,
        user: User,
        params: PageParams,
        *,
        status: TransactionStatus | None = None,
        bill_id: int | None = None,
        household_id: int | None = None,
        month: str | None = None,
    ) -> Page[PaymentPublic]:
        accesses = accessible_household_accesses(self.session, user)
        if household_id is not None and household_id not in accesses:
            raise HouseholdNotFoundError()
        households = [household_id] if household_id is not None else list(accesses)
        visible_meters = select(Meter.id).where(Meter.household_id.in_(households))

        conditions: list[ColumnElement[bool]] = [Bill.meter_id.in_(visible_meters)]
        if household_id is None:  # ses propres paiements, même hors de ses foyers actuels
            conditions = [or_(conditions[0], PaymentTransaction.payer_id == user.id)]
        if bill_id is not None:
            self._check_bill_visible(user, bill_id, visible_meters)
            conditions.append(PaymentTransaction.bill_id == bill_id)
        if status is not None:
            conditions.append(PaymentTransaction.status == status)
        if month is not None:
            start, end = month_bounds(month)
            conditions.append(PaymentTransaction.initiated_at >= start)
            conditions.append(PaymentTransaction.initiated_at < end)

        query = (
            select(PaymentTransaction)
            .join(Bill, Bill.id == PaymentTransaction.bill_id)
            .where(*conditions)
            .order_by(PaymentTransaction.initiated_at.desc(), PaymentTransaction.id.desc())
        )
        return paginate(
            self.session, query, params, lambda row: payment_public(self.session, row, user)
        )

    def _check_bill_visible(self, user: User, bill_id: int, visible_meters) -> None:
        """404 si la facture n'existe pas, ou si `user` ne la voit pas et ne l'a jamais payée."""
        visible = self.session.scalar(
            select(Bill.id).where(
                Bill.id == bill_id,
                or_(
                    Bill.meter_id.in_(visible_meters),
                    Bill.id.in_(
                        select(PaymentTransaction.bill_id).where(
                            PaymentTransaction.payer_id == user.id
                        )
                    ),
                ),
            )
        )
        if visible is None:
            raise BillNotFoundError()
