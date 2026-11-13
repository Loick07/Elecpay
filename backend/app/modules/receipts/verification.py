"""Vérification publique d'un reçu (B8.4), sans connexion.

N'importe qui (E²C, un bailleur, un proche) peut confirmer qu'un reçu est authentique avec son
code de vérification (saisi ou lu dans le QR code). On montre le MINIMUM (décision du
13/11/2026) : numéro, date, montant, période de la facture, compteur partiellement masqué,
mention « Mode démo ». Ni nom, ni numéro de téléphone, ni foyer.

Code accepté avec ou sans tirets, en majuscules ou minuscules. Code inconnu ou mal formé :
même réponse (404), sans indication. Nombre de vérifications limité par adresse IP.
"""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.bills.models import Bill
from app.modules.bills.queries import bill_period_label
from app.modules.meters.models import Meter
from app.modules.payments.models import PaymentProvider, PaymentTransaction
from app.modules.receipts.errors import UnknownVerificationCodeError
from app.modules.receipts.models import VERIFICATION_CODE_LENGTH, Receipt
from app.modules.receipts.schemas import ReceiptVerification
from app.modules.receipts.service import normalize_verification_code

KEEP_START, KEEP_END = 4, 2  # caractères visibles du N° de compteur, au début et à la fin
HIDDEN = "•"


def mask_meter_reference(reference: str) -> str:
    """« 0412-8833 » → « 0412-••33 » ; « 0018 09 5408 » → « 0018 •• ••08 »."""
    positions = [index for index, char in enumerate(reference) if char.isalnum()]
    if len(positions) <= KEEP_START + KEEP_END:
        return HIDDEN * len(reference)
    hidden = set(positions[KEEP_START : len(positions) - KEEP_END])
    return "".join(HIDDEN if index in hidden else char for index, char in enumerate(reference))


def verify_receipt(session: Session, raw_code: str) -> ReceiptVerification:
    code = normalize_verification_code(raw_code)
    receipt = None
    if len(code) == VERIFICATION_CODE_LENGTH and code.isascii():
        receipt = session.scalars(select(Receipt).where(Receipt.verification_code == code)).first()
    if receipt is None:
        raise UnknownVerificationCodeError()
    transaction = session.get(PaymentTransaction, receipt.transaction_id)
    bill = session.get(Bill, transaction.bill_id)
    meter = session.get(Meter, bill.meter_id)
    simulated = transaction.provider is PaymentProvider.SIMULATED
    return ReceiptVerification(
        number=receipt.number,
        issued_at=receipt.issued_at,
        amount=transaction.amount,
        bill_period_label=bill_period_label(bill.period_start, bill.period_end),
        meter_reference=mask_meter_reference(meter.reference),
        demo=simulated,
        message=(
            "Reçu authentique émis par ElecPay (mode démo : paiement simulé, aucun débit réel)."
            if simulated
            else "Reçu authentique émis par ElecPay."
        ),
    )
