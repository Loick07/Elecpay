"""Fabriques de données de test : créent des lignes valides, modifiables au besoin.

user = make_user(db_session, role=UserRole.ADMIN)
"""

import hashlib
import uuid
from datetime import UTC, date, datetime, timedelta
from itertools import count

from sqlalchemy.orm import Session

from app.db.base import utcnow
from app.modules.audit.models import AuditLog
from app.modules.auth.models import RefreshToken
from app.modules.bills.models import Bill, BillLine, BillLineKind, BillSource
from app.modules.consumption.models import MeterReading, ReadingSource
from app.modules.households.models import Household, HouseholdMember, MemberRole
from app.modules.meters.models import Meter
from app.modules.notifications.models import Notification, NotificationType
from app.modules.payments.models import PaymentProvider, PaymentTransaction, TransactionStatus
from app.modules.receipts.models import Receipt
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User

_sequence = count(1)


def next_phone() -> str:
    """Numéro congolais valide et unique : +24206 suivi de 7 chiffres."""
    return f"+24206{next(_sequence):07d}"


def make_user(session: Session, **overrides) -> User:
    values = {
        "phone": next_phone(),
        "full_name": "Abonné Test",
        "password_hash": "$argon2id$v=19$m=65536,t=3,p=4$faux-hash-de-test",
    } | overrides
    user = User(**values)
    session.add(user)
    session.flush()
    return user


def make_refresh_token(session: Session, user: User, **overrides) -> RefreshToken:
    values = {
        "user_id": user.id,
        "token_hash": hashlib.sha256(uuid.uuid4().bytes).hexdigest(),
        "family_id": str(uuid.uuid4()),
        "expires_at": utcnow() + timedelta(days=30),
    } | overrides
    token = RefreshToken(**values)
    session.add(token)
    session.flush()
    return token


def make_household(session: Session, owner: User | None = None, **overrides) -> Household:
    owner = owner or make_user(session)
    values = {"name": "Maison principale", "city": "Pointe-Noire", "owner_id": owner.id} | overrides
    household = Household(**values)
    session.add(household)
    session.flush()
    return household


def make_member(
    session: Session, household: Household, user: User | None = None, **overrides
) -> HouseholdMember:
    user = user or make_user(session)
    values = {
        "household_id": household.id,
        "user_id": user.id,
        "role": MemberRole.PAYER,
        "invited_by": household.owner_id,
    } | overrides
    member = HouseholdMember(**values)
    session.add(member)
    session.flush()
    return member


def next_meter_reference() -> str:
    return f"E2C-PNR-{next(_sequence):08d}"


def make_reading(session: Session, meter: Meter, **overrides) -> MeterReading:
    values = {
        "meter_id": meter.id,
        "read_at": datetime(2026, 8, 31, 23, 0, tzinfo=UTC),
        "index_wh": 14_854_000,  # 14 854 kWh
        "consumption_wh": 9_500,  # 9,5 kWh dans la journée
        "source": ReadingSource.SIMULATED,
    } | overrides
    reading = MeterReading(**values)
    session.add(reading)
    session.flush()
    return reading


def make_tariff(session: Session, **overrides) -> Tariff:
    """Tarif Basse Tension tel que lu sur une vraie facture E²C (juillet-août 2026)."""
    values = {
        "code": "BT_DOMESTIQUE",
        "label": "Basse tension domestique",
        "price_per_kwh_milli": 49_080,  # 49,08 FCFA/kWh
        "fixed_fee_per_month": 2_550,  # 5 100 FCFA sur 2 mois (hypothèse)
        "vat_rate_bp": 1_800,  # 18 %
        "additional_tax_rate_bp": 500,  # C.A. = 5 % de la TVA
        "audiovisual_fee": 1_000,  # RAV (hypothèse : par facture)
        "stamp_fee": 0,
        "valid_from": date(2026, 1, 1),
    } | overrides
    tariff = Tariff(**values)
    session.add(tariff)
    session.flush()
    return tariff


def make_bill(
    session: Session, meter: Meter | None = None, tariff: Tariff | None = None, **overrides
) -> Bill:
    """Facture reprenant les montants exacts d'une vraie facture E²C BT (juillet-août 2026)."""
    meter = meter or make_meter(session)
    tariff = tariff or make_tariff(session, code=f"BT_{next(_sequence)}")
    values = {
        "meter_id": meter.id,
        "tariff_id": tariff.id,
        "reference": f"20260801{next(_sequence):06d}",
        "period_start": date(2026, 7, 1),
        "period_end": date(2026, 8, 31),
        "months_count": 2,
        "previous_index_wh": 14_283_000,
        "current_index_wh": 14_854_000,
        "consumption_wh": 571_000,  # 571 kWh
        "billed_power_va": 3_000,
        "amount_ht": 33_124,
        "amount_tax": 6_260,  # TVA 5 962 + C.A. 298
        "amount_fees": 1_000,  # RAV 1 000 + timbre 0
        "amount_total": 40_384,
        "due_date": date(2026, 9, 30),
        "issued_at": datetime(2026, 9, 3, 8, 0, tzinfo=UTC),
        "source": BillSource.SIMULATED,
    } | overrides
    bill = Bill(**values)
    session.add(bill)
    session.flush()
    return bill


def e2c_bill_lines(bill: Bill) -> list[BillLine]:
    """Les 6 lignes de la vraie facture (total 40 384 FCFA)."""
    lines = [
        (BillLineKind.ENERGY, "Montant consommation", 571_000, "kWh", 49_080, None, None, 28_024),
        (
            BillLineKind.FIXED_FEE,
            "Droit à la consommation",
            2_000,
            "mois",
            2_550_000,
            None,
            None,
            5_100,
        ),
        (
            BillLineKind.AUDIOVISUAL_FEE,
            "Redevance audiovisuelle (RAV)",
            None,
            None,
            None,
            None,
            None,
            1_000,
        ),
        (BillLineKind.VAT, "T.V.A.", None, None, None, 1_800, 33_124, 5_962),
        (
            BillLineKind.ADDITIONAL_TAX,
            "Centimes additionnels (C.A.)",
            None,
            None,
            None,
            500,
            5_962,
            298,
        ),
        (BillLineKind.STAMP, "Timbre électronique", None, None, None, None, None, 0),
    ]
    return [
        BillLine(
            bill_id=bill.id,
            position=position,
            kind=kind,
            label=label,
            quantity_milli=quantity,
            unit=unit,
            unit_price_milli=price,
            rate_bp=rate,
            base_amount=base,
            amount=amount,
        )
        for position, (kind, label, quantity, unit, price, rate, base, amount) in enumerate(
            lines, start=1
        )
    ]


def make_bill_with_lines(session: Session, **overrides) -> Bill:
    bill = make_bill(session, **overrides)
    session.add_all(e2c_bill_lines(bill))
    session.flush()
    return bill


PAYMENT_START = datetime(2026, 9, 11, 10, 0, tzinfo=UTC)


def make_transaction(
    session: Session, bill: Bill | None = None, payer: User | None = None, **overrides
) -> PaymentTransaction:
    """Transaction en attente pour une facture, avec le bon montant."""
    bill = bill or make_bill(session)
    payer = payer or make_user(session)
    values = {
        "bill_id": bill.id,
        "payer_id": payer.id,
        "provider": PaymentProvider.SIMULATED,
        "phone_number": "+242060000001",
        "amount": bill.amount_total,
        "idempotency_key": str(uuid.uuid4()),
        "initiated_at": PAYMENT_START,
        "expires_at": PAYMENT_START + timedelta(minutes=10),
    } | overrides
    transaction = PaymentTransaction(**values)
    session.add(transaction)
    session.flush()
    return transaction


def confirm(session: Session, transaction: PaymentTransaction) -> PaymentTransaction:
    """Ce que fera le webhook du prestataire : passage à « reussie »."""
    transaction.status = TransactionStatus.SUCCEEDED
    transaction.provider_ref = f"SIM-{transaction.id:08d}"
    transaction.confirmed_at = PAYMENT_START + timedelta(seconds=30)
    session.flush()
    return transaction


def make_receipt(session: Session, transaction: PaymentTransaction | None = None, **overrides):
    transaction = transaction or confirm(session, make_transaction(session))
    number = next(_sequence)
    values = {
        "transaction_id": transaction.id,
        "number": f"EP-2026-{number:06d}",
        "issued_at": PAYMENT_START + timedelta(minutes=1),
        "verification_code": f"VC{number:010d}",
    } | overrides
    receipt = Receipt(**values)
    session.add(receipt)
    session.flush()
    return receipt


def make_notification(session: Session, user: User | None = None, **overrides) -> Notification:
    user = user or make_user(session)
    values = {
        "user_id": user.id,
        "type": NotificationType.BILL_ISSUED,
        "title": "Nouvelle facture",
        "body": "Votre facture de juillet-août 2026 est disponible : 40 384 FCFA.",
        "data_json": {"bill_id": 1},
    } | overrides
    notification = Notification(**values)
    session.add(notification)
    session.flush()
    return notification


def make_audit_log(session: Session, actor: User | None = None, **overrides) -> AuditLog:
    values = {
        "actor_id": actor.id if actor else None,
        "action": "bill.cancel",
        "entity_type": "bill",
        "entity_id": 1,
        "before_json": {"status": "unpaid"},
        "after_json": {"status": "cancelled", "cancelled_reason": "Facture émise en double"},
        "user_agent": "Mozilla/5.0 (back-office ElecPay)",
        "ip": "196.44.0.1",
    } | overrides
    log = AuditLog(**values)
    session.add(log)
    session.flush()
    return log


def make_meter(session: Session, household: Household | None = None, **overrides) -> Meter:
    values = {
        "household_id": household.id if household else None,
        "reference": next_meter_reference(),
    } | overrides
    meter = Meter(**values)
    session.add(meter)
    session.flush()
    return meter
