"""Une transaction telle que l'abonné la voit (écrans 9 et 12)."""

from app.core.validation import mask_phone
from app.modules.bills.models import Bill
from app.modules.payments.common import public_reference
from app.modules.payments.models import PaymentProvider, PaymentTransaction, TransactionStatus
from app.modules.payments.operators import OPERATOR_LABELS
from app.modules.payments.schemas import PaymentPublic, PaymentStep
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


def payment_public(transaction: PaymentTransaction, bill: Bill, viewer: User) -> PaymentPublic:
    mine = transaction.payer_id == viewer.id
    return PaymentPublic(
        id=transaction.id,
        reference=public_reference(transaction),
        bill_id=bill.id,
        bill_reference=bill.reference,
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
        is_mine=mine,
        source=(
            "simulated"
            if transaction.provider is PaymentProvider.SIMULATED
            else transaction.provider.value
        ),
    )
