"""Consultation des reçus par l'abonné (B8.2) : liste et détail.

Mêmes accès que les paiements (décision du 13/11/2026) : le payeur, et tous les membres du
foyer de la facture (lecteurs compris). Un reçu d'un autre foyer répond comme un reçu
inexistant (404).
"""

from datetime import date, datetime

from sqlalchemy import ColumnElement, or_, select
from sqlalchemy.orm import Session

from app.core.pagination import Page, PageParams, paginate
from app.core.timezone import local_midnight_utc
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.modules.bills.models import Bill
from app.modules.bills.queries import bill_period_label
from app.modules.households.access import accessible_household_accesses, meter_access
from app.modules.households.errors import HouseholdNotFoundError, MeterNotFoundError
from app.modules.households.models import Household
from app.modules.meters.models import Meter
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentProvider, PaymentTransaction
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.receipts.errors import ReceiptNotFoundError
from app.modules.receipts.models import Receipt
from app.modules.receipts.pdf import receipt_filename, render_receipt_pdf
from app.modules.receipts.schemas import ReceiptPublic
from app.modules.receipts.service import format_verification_code
from app.modules.users.models import User


class ReceiptQueries:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list(
        self,
        user: User,
        params: PageParams,
        *,
        household_id: int | None = None,
        year: int | None = None,
    ) -> Page[ReceiptPublic]:
        """Mes reçus, du plus récent au plus ancien."""
        accesses = accessible_household_accesses(self.session, user)
        if household_id is not None and household_id not in accesses:
            raise HouseholdNotFoundError()
        households = [household_id] if household_id is not None else list(accesses)
        visible_meters = select(Meter.id).where(Meter.household_id.in_(households))

        visible: ColumnElement[bool] = Bill.meter_id.in_(visible_meters)
        if household_id is None:  # mes propres paiements, même hors de mes foyers actuels
            visible = or_(visible, PaymentTransaction.payer_id == user.id)
        conditions = [visible]
        if year is not None:
            conditions.append(Receipt.issued_at >= local_midnight_utc(date(year, 1, 1)))
            conditions.append(Receipt.issued_at < local_midnight_utc(date(year + 1, 1, 1)))

        query = (
            select(Receipt)
            .join(PaymentTransaction, PaymentTransaction.id == Receipt.transaction_id)
            .join(Bill, Bill.id == PaymentTransaction.bill_id)
            .where(*conditions)
            .order_by(Receipt.issued_at.desc(), Receipt.id.desc())
        )
        return paginate(
            self.session, query, params, lambda row: receipt_public(self.session, row, user)
        )

    def detail(self, user: User, receipt_id: int) -> ReceiptPublic:
        receipt = self.session.get(Receipt, receipt_id)
        if receipt is None:
            raise ReceiptNotFoundError()
        transaction = self.session.get(PaymentTransaction, receipt.transaction_id)
        if transaction.payer_id != user.id:
            bill = self.session.get(Bill, transaction.bill_id)
            try:
                meter_access(self.session, user, bill.meter_id)
            except MeterNotFoundError as error:
                raise ReceiptNotFoundError() from error
        return receipt_public(self.session, receipt, user)

    def pdf(
        self,
        user: User,
        receipt_id: int,
        *,
        demo_mode: bool,
        verify_base_url: str,
        generated_at: datetime | None = None,
    ) -> tuple[str, bytes]:
        """Le PDF du reçu (mêmes accès que le détail) : (nom de fichier, octets).
        Généré à la demande, jamais stocké : un reçu ne change jamais."""
        receipt = self.detail(user, receipt_id)
        content = render_receipt_pdf(
            receipt,
            verify_base_url=verify_base_url,
            generated_at=generated_at or utcnow(),
            demo_mode=demo_mode,
        )
        return receipt_filename(receipt), content


def receipt_public(session: Session, receipt: Receipt, viewer: User) -> ReceiptPublic:
    transaction = session.get(PaymentTransaction, receipt.transaction_id)
    bill = session.get(Bill, transaction.bill_id)
    meter = session.get(Meter, bill.meter_id)
    household = session.get(Household, meter.household_id) if meter.household_id else None
    payer = session.get(User, transaction.payer_id)
    return ReceiptPublic(
        id=receipt.id,
        number=receipt.number,
        issued_at=receipt.issued_at,
        amount=transaction.amount,
        verification_code=format_verification_code(receipt.verification_code),
        bill_id=bill.id,
        bill_reference=bill.reference,
        bill_period_label=bill_period_label(bill.period_start, bill.period_end),
        meter_id=meter.id,
        meter_reference=meter.reference,
        household_id=household.id if household else None,
        household_name=household.name if household else None,
        payer_id=payer.id,
        payer_name=payer.full_name,
        is_mine=payer.id == viewer.id,
        operator=transaction.operator,
        operator_label=OPERATOR_LABELS[transaction.operator],
        phone_number=mask_phone(transaction.phone_number),
        transaction_id=transaction.id,
        transaction_reference=public_reference(transaction),
        source=(
            "simulated"
            if transaction.provider is PaymentProvider.SIMULATED
            else transaction.provider.value
        ),
    )
