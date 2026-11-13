"""Une transaction telle que l'abonné la voit (écrans 9 et 12)."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.validation import mask_phone
from app.modules.bills.models import Bill
from app.modules.bills.queries import bill_period_label
from app.modules.households.models import Household
from app.modules.meters.models import Meter
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentProvider, PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.payments.schemas import PaymentPublic, PaymentStep
from app.modules.receipts.models import Receipt
from app.modules.users.models import User

FINAL_STEPS = {
    TransactionStatus.SUCCEEDED: PaymentStep.SUCCEEDED,
    TransactionStatus.FAILED: PaymentStep.FAILED,
    TransactionStatus.EXPIRED: PaymentStep.EXPIRED,
}


def payment_step(transaction: PaymentTransaction) -> PaymentStep:
    if transaction.status in FINAL_STEPS:
        return FINAL_STEPS[transaction.status]
    if transaction.pin_entered_at is not None:
        return PaymentStep.PIN_ENTERED
    return PaymentStep.REQUESTED


def payment_public(
    session: Session, transaction: PaymentTransaction, viewer: User
) -> PaymentPublic:
    """La transaction vue par `viewer` : son propre numéro en clair, celui des autres masqué.
    Facture, compteur, foyer et payeur sont relus (mis en cache par la session)."""
    bill = session.get(Bill, transaction.bill_id)
    meter = session.get(Meter, bill.meter_id)
    household = session.get(Household, meter.household_id) if meter.household_id else None
    payer = session.get(User, transaction.payer_id)
    mine = transaction.payer_id == viewer.id
    receipt = (
        session.execute(
            select(Receipt.id, Receipt.number).where(Receipt.transaction_id == transaction.id)
        ).first()
        if transaction.status is TransactionStatus.SUCCEEDED
        else None
    )
    return PaymentPublic(
        id=transaction.id,
        reference=public_reference(transaction),
        bill_id=bill.id,
        bill_reference=bill.reference,
        bill_period_label=bill_period_label(bill.period_start, bill.period_end),
        meter_id=meter.id,
        meter_reference=meter.reference,
        household_id=household.id if household else None,
        household_name=household.name if household else None,
        amount=transaction.amount,
        operator=transaction.operator,
        operator_label=OPERATOR_LABELS[transaction.operator],
        phone_number=transaction.phone_number if mine else mask_phone(transaction.phone_number),
        status=transaction.status,
        step=payment_step(transaction),
        failure_reason=transaction.failure_reason,
        initiated_at=transaction.initiated_at,
        pin_entered_at=transaction.pin_entered_at,
        confirmed_at=transaction.confirmed_at,
        expires_at=transaction.expires_at,
        payer_id=transaction.payer_id,
        payer_name=payer.full_name,
        is_mine=mine,
        receipt_id=receipt.id if receipt else None,
        receipt_number=receipt.number if receipt else None,
        source=(
            "simulated"
            if transaction.provider is PaymentProvider.SIMULATED
            else transaction.provider.value
        ),
    )
