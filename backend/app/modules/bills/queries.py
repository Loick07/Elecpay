"""Consultation des factures par l'abonné : liste (B6.3) et détail (B6.4).

Accès : les factures des compteurs des foyers que l'utilisateur voit (propriétaire, payeur
délégué ou lecteur ; voir `households/access.py`). Un foyer ou un compteur auquel il n'a pas
accès répond 404, comme s'il n'existait pas. Un compteur détaché n'est visible de personne.

Retard « à la lecture » : une facture impayée dont l'échéance est dépassée est AFFICHÉE en
retard dès le lendemain de l'échéance ; le statut enregistré, lui, n'est changé que par
`mark_overdue_bills` (relevé quotidien), qui prévient aussi le propriétaire.
"""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import date, datetime

from sqlalchemy import ColumnElement, and_, func, or_, select
from sqlalchemy.orm import Session

from app.core.pagination import PageParams, paginate
from app.core.timezone import local_date
from app.db.base import utcnow
from app.modules.bills.calculator import MILLI, WH_PER_KWH
from app.modules.bills.errors import BillNotFoundError
from app.modules.bills.models import Bill, BillLine, BillStatus
from app.modules.bills.pdf import bill_filename, render_bill_pdf
from app.modules.bills.schemas import (
    BillDetail,
    BillFilter,
    BillLinePublic,
    BillList,
    BillSummary,
    Outstanding,
    PreviousBillComparison,
    TariffPublic,
)
from app.modules.consumption.labels import MONTHS_SHORT
from app.modules.households.access import (
    HouseholdAccess,
    accessible_household_accesses,
    meter_access,
)
from app.modules.households.errors import HouseholdNotFoundError, MeterNotFoundError
from app.modules.meters.models import Meter
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User

TO_PAY = (BillStatus.UNPAID, BillStatus.OVERDUE, BillStatus.PENDING_PAYMENT)
PAYABLE = (BillStatus.UNPAID, BillStatus.OVERDUE)  # en cours de paiement : pas de 2e paiement


def bill_period_label(start: date, end: date) -> str:
    """« Oct. 2026 » pour un mois, « Juil.-Août 2026 » pour plusieurs (comme E²C)."""
    first = MONTHS_SHORT[start.month - 1]
    if (start.year, start.month) == (end.year, end.month):
        return f"{first} {start.year}"
    return f"{first}-{MONTHS_SHORT[end.month - 1]} {end.year}"


def displayed_status(bill: Bill, today: date) -> BillStatus:
    """Statut affiché : impayée + échéance dépassée → en retard (sans attendre le relevé)."""
    if bill.status is BillStatus.UNPAID and bill.due_date < today:
        return BillStatus.OVERDUE
    return bill.status


def is_overdue(today: date) -> ColumnElement[bool]:
    """Même règle que `displayed_status`, en SQL."""
    return or_(
        Bill.status == BillStatus.OVERDUE,
        and_(Bill.status == BillStatus.UNPAID, Bill.due_date < today),
    )


@dataclass(frozen=True, slots=True)
class _Scope:
    """Ce que l'utilisateur voit : ses foyers (avec son rôle) et leurs compteurs."""

    accesses: dict[int, HouseholdAccess]
    meters: dict[int, Meter]


class BillQueries:
    def __init__(self, session: Session, today: Callable[[], date] | None = None) -> None:
        self.session = session
        self.today = today or (lambda: local_date(utcnow()))

    def list(
        self,
        user: User,
        params: PageParams,
        *,
        status: BillFilter | None = None,
        meter_id: int | None = None,
        household_id: int | None = None,
        year: int | None = None,
    ) -> BillList:
        """Mes factures, de la plus récente à la plus ancienne, et le reste à payer."""
        today = self.today()
        scope = self._scope(user, meter_id=meter_id, household_id=household_id)
        in_scope = Bill.meter_id.in_(list(scope.meters))

        query = select(Bill).where(in_scope, *self._status_filter(status, today))
        if year is not None:
            query = query.where(Bill.period_start.between(date(year, 1, 1), date(year, 12, 31)))
        query = query.order_by(Bill.period_start.desc(), Bill.id.desc())

        page = paginate(self.session, query, params, lambda bill: self._summary(bill, scope, today))
        return BillList(**page.model_dump(), outstanding=self._outstanding(in_scope, today))

    def detail(self, user: User, bill_id: int) -> BillDetail:
        """Une facture avec ses lignes, ses index et la comparaison avec la précédente.

        Les factures annulées restent consultables (avec leur motif). 404 si la facture
        n'existe pas ou si son compteur n'est pas dans un foyer visible par `user`.
        """
        bill = self.session.get(Bill, bill_id)
        if bill is None:
            raise BillNotFoundError()
        try:
            meter, access = meter_access(self.session, user, bill.meter_id)
        except MeterNotFoundError as error:
            raise BillNotFoundError() from error
        tariff = self.session.get(Tariff, bill.tariff_id)
        return BillDetail(
            **_summary_fields(bill, meter, access, self.today()),
            meter_contract_number=meter.contract_number,
            meter_customer_number=meter.customer_number,
            e2c_center=meter.e2c_center,
            previous_index_wh=bill.previous_index_wh,
            current_index_wh=bill.current_index_wh,
            previous_index_kwh=kwh(bill.previous_index_wh),
            current_index_kwh=kwh(bill.current_index_wh),
            billed_power_va=bill.billed_power_va,
            amount_ht=bill.amount_ht,
            amount_tax=bill.amount_tax,
            amount_fees=bill.amount_fees,
            lines=self._lines(bill),
            tariff=TariffPublic(
                id=tariff.id,
                code=tariff.code,
                label=tariff.label,
                price_per_kwh_milli=tariff.price_per_kwh_milli,
                is_assumption=tariff.is_assumption,
            ),
            previous_bill=self._previous_bill(bill),
            cancelled_at=bill.cancelled_at,
            cancelled_reason=bill.cancelled_reason,
        )

    def pdf(
        self,
        user: User,
        bill_id: int,
        *,
        demo_mode: bool,
        generated_at: datetime | None = None,
    ) -> tuple[str, bytes]:
        """Le PDF de la facture (mêmes accès que le détail) : (nom de fichier, octets).

        Généré à la demande, jamais stocké : une facture émise ne change pas.
        """
        bill = self.detail(user, bill_id)
        content = render_bill_pdf(bill, generated_at=generated_at or utcnow(), demo_mode=demo_mode)
        return bill_filename(bill), content

    # --- Étapes ------------------------------------------------------------------------

    def _scope(self, user: User, *, meter_id: int | None, household_id: int | None) -> _Scope:
        accesses = accessible_household_accesses(self.session, user)
        if household_id is not None:
            if household_id not in accesses:
                raise HouseholdNotFoundError()
            accesses = {household_id: accesses[household_id]}
        meters = {
            meter.id: meter
            for meter in self.session.scalars(
                select(Meter).where(Meter.household_id.in_(list(accesses))).order_by(Meter.id)
            )
        }
        if meter_id is not None:
            if meter_id not in meters:
                raise MeterNotFoundError()
            meters = {meter_id: meters[meter_id]}
        return _Scope(accesses, meters)

    @staticmethod
    def _status_filter(status: BillFilter | None, today: date) -> list[ColumnElement[bool]]:
        match status:
            case None:
                return [Bill.status != BillStatus.CANCELLED]
            case BillFilter.TO_PAY:
                return [Bill.status.in_(TO_PAY)]
            case BillFilter.OVERDUE:
                return [is_overdue(today)]
            case BillFilter.PAID:
                return [Bill.status == BillStatus.PAID]
            case BillFilter.PENDING_PAYMENT:
                return [Bill.status == BillStatus.PENDING_PAYMENT]
            case BillFilter.CANCELLED:
                return [Bill.status == BillStatus.CANCELLED]

    def _outstanding(self, in_scope: ColumnElement[bool], today: date) -> Outstanding:
        def totals(*where: ColumnElement[bool]) -> tuple[int, int]:
            amount, count = self.session.execute(
                select(func.coalesce(func.sum(Bill.amount_total), 0), func.count()).where(
                    in_scope, *where
                )
            ).one()
            return int(amount), int(count)

        amount, count = totals(Bill.status.in_(TO_PAY))
        overdue_amount, overdue_count = totals(is_overdue(today))
        return Outstanding(
            amount=amount, count=count, overdue_amount=overdue_amount, overdue_count=overdue_count
        )

    @staticmethod
    def _summary(bill: Bill, scope: _Scope, today: date) -> BillSummary:
        meter = scope.meters[bill.meter_id]
        return BillSummary(
            **_summary_fields(bill, meter, scope.accesses[meter.household_id], today)
        )

    # --- Détail ------------------------------------------------------------------------

    def _previous_bill(self, bill: Bill) -> PreviousBillComparison | None:
        previous = self.session.scalars(
            select(Bill)
            .where(
                Bill.meter_id == bill.meter_id,
                Bill.period_start < bill.period_start,
                Bill.status != BillStatus.CANCELLED,
            )
            .order_by(Bill.period_start.desc())
            .limit(1)
        ).first()
        if previous is None:
            return None
        return PreviousBillComparison(
            bill_id=previous.id,
            reference=previous.reference,
            period_label=bill_period_label(previous.period_start, previous.period_end),
            consumption_wh=previous.consumption_wh,
            consumption_kwh=kwh(previous.consumption_wh),
            amount_total=previous.amount_total,
            consumption_change_wh=bill.consumption_wh - previous.consumption_wh,
            consumption_change_percent=change_percent(previous.consumption_wh, bill.consumption_wh),
            amount_change=bill.amount_total - previous.amount_total,
            amount_change_percent=change_percent(previous.amount_total, bill.amount_total),
        )

    def _lines(self, bill: Bill) -> list[BillLinePublic]:
        return bill_line_items(self.session, bill)


def bill_line_items(session: Session, bill: Bill) -> list[BillLinePublic]:
    """Les lignes d'une facture, dans l'ordre (mêmes données pour l'abonné et l'équipe)."""
    lines = session.scalars(
        select(BillLine).where(BillLine.bill_id == bill.id).order_by(BillLine.position)
    )
    return [
        BillLinePublic(
            position=line.position,
            kind=line.kind,
            label=line.label,
            quantity_milli=line.quantity_milli,
            quantity=_from_milli(line.quantity_milli),
            unit=line.unit,
            unit_price_milli=line.unit_price_milli,
            unit_price=_from_milli(line.unit_price_milli),
            rate_bp=line.rate_bp,
            rate_percent=None if line.rate_bp is None else line.rate_bp / 100,
            base_amount=line.base_amount,
            amount=line.amount,
        )
        for line in lines
    ]


def kwh(wh: int) -> float:
    """Wh → kWh à 3 décimales, pour l'AFFICHAGE seulement (la valeur exacte reste en Wh)."""
    return round(wh / WH_PER_KWH, 3)


def _from_milli(value: int | None) -> float | None:
    return None if value is None else value / MILLI


def change_percent(before: int, after: int) -> float | None:
    """Évolution en % (1 décimale) ; None si la valeur de départ est 0."""
    if before == 0:
        return None
    return round((after - before) * 100 / before, 1)


def _summary_fields(bill: Bill, meter: Meter, access: HouseholdAccess, today: date) -> dict:
    """Champs communs à la liste et au détail (statut affiché, droit de payer…)."""
    status = displayed_status(bill, today)
    return dict(
        id=bill.id,
        reference=bill.reference,
        meter_id=meter.id,
        meter_reference=meter.reference,
        meter_label=meter.label,
        household_id=access.household.id,
        household_name=access.household.name,
        period_start=bill.period_start,
        period_end=bill.period_end,
        period_label=bill_period_label(bill.period_start, bill.period_end),
        months_count=bill.months_count,
        consumption_wh=bill.consumption_wh,
        consumption_kwh=kwh(bill.consumption_wh),
        amount_total=bill.amount_total,
        issued_at=bill.issued_at,
        due_date=bill.due_date,
        status=status,
        days_overdue=max(0, (today - bill.due_date).days) if status is BillStatus.OVERDUE else 0,
        paid_at=bill.paid_at,
        my_role=access.role,
        can_pay=access.can_pay and status in PAYABLE,
        source=bill.source,
    )
