"""Émission des factures et passage en retard.

`generate_bill` est l'UNIQUE endroit qui crée une facture ; `mark_overdue_bills` l'unique
endroit qui la passe « en retard ».

Utilisé par le relevé quotidien, le jeu de démo et l'import d'historique d'un compteur
(et demain par l'administration). Les montants viennent EXCLUSIVEMENT de `compute_bill`.

Règles :
- une facture couvre une période calendaire complète (voir `periods.py`) ;
- elle n'est émise qu'à partir de sa date d'émission (fin de période + 3 jours) ;
- index de facturation = premier relevé de la journée (minuit, heure du Congo) au premier
  jour de la période (ancien index) et au lendemain du dernier jour (nouvel index) ;
  aucun des deux ne peut être en anomalie ;
- garde-fou : consommation facturée = somme des relevés journaliers entre ces deux index ;
- tarif : celui en vigueur au premier jour de la période ;
- idempotent : si la période a déjà une facture active, on la renvoie sans rien créer ;
  si sa seule facture a été annulée, on refuse (la refacturer relève de l'administration) ;
- réémission par l'administration (`reissue_at`, B10.5) : seulement pour une période dont la
  facture a été annulée. Mêmes règles de calcul (tarif du début de période, relevés de
  facturation actuels) ; la nouvelle facture est numérotée et datée au jour de la réémission
  et a son propre délai de paiement (réémission + `bill_due_delay_days`).

Concurrence : deux émissions simultanées sont mises en file par un verrou sur les numéros
du jour d'émission ; au pire MySQL annule l'une des deux (interblocage), jamais de doublon :
les contraintes uniques (référence, compteur + période active) restent le dernier rempart.
Ne valide pas la transaction (pas de commit) : c'est à l'appelant de le faire.
"""

from dataclasses import asdict, dataclass
from datetime import date, datetime, timedelta

from sqlalchemy import case, func, insert, or_, select
from sqlalchemy.orm import Session

from app.core.timezone import local_date, local_midnight_utc
from app.modules.bills.calculator import compute_bill
from app.modules.bills.errors import (
    BillingNothingToReissueError,
    BillingPeriodCancelledError,
    BillingPeriodNotClosedError,
    BillingReadingAnomalyError,
    BillingReadingMissingError,
    BillingReadingsMismatchError,
    BillSequenceExhaustedError,
    InvalidBillingPeriodError,
    NoTariffError,
)
from app.modules.bills.models import Bill, BillLine, BillSource, BillStatus
from app.modules.bills.notifications import bill_overdue_notification
from app.modules.bills.periods import (
    MAX_SEQUENCE,
    BillingPeriod,
    BillingSettings,
    bill_reference,
    billing_period,
    due_date,
    is_period_start,
    issue_day,
    issued_at,
)
from app.modules.bills.reminders import bill_recipients
from app.modules.consumption.models import MeterReading, ReadingSource
from app.modules.meters.models import Meter
from app.modules.notifications.service import insert_notifications
from app.modules.tariffs.models import Tariff


@dataclass(frozen=True, slots=True)
class IssuedBill:
    bill: Bill
    created: bool  # faux : la facture existait déjà (appel répété)


def tariff_at(session: Session, day: date) -> Tariff | None:
    """Tarif en vigueur à une date (périodes [valid_from, valid_to[, sans chevauchement)."""
    return session.scalars(
        select(Tariff)
        .where(Tariff.valid_from <= day, or_(Tariff.valid_to.is_(None), Tariff.valid_to > day))
        .order_by(Tariff.valid_from.desc())
        .limit(1)
    ).first()


def generate_bill(
    session: Session,
    meter: Meter,
    period_start: date,
    *,
    today: date,
    settings: BillingSettings,
    reissue_at: datetime | None = None,
) -> IssuedBill:
    """Émet (ou retrouve) la facture du compteur pour la période qui commence le `period_start`.

    `today` : date locale du jour (Brazzaville). Lève une `BillingError` si c'est impossible.
    `reissue_at` : instant de la réémission d'une période annulée (administration seulement).
    """
    months = settings.billing_period_months
    if not is_period_start(period_start, months):
        raise InvalidBillingPeriodError(
            details={"period_start": period_start.isoformat(), "months": months}
        )
    period = billing_period(period_start, months)
    normal_day = issue_day(period, settings)
    details = _details(meter, period)
    if normal_day > today:
        raise BillingPeriodNotClosedError(details=details | {"issue_date": normal_day.isoformat()})
    day = normal_day if reissue_at is None else local_date(reissue_at)

    sequence = _lock_next_sequence(session, day)  # met en file les émissions du même jour
    existing = _existing_bills(session, meter, period)
    active = [bill for bill in existing if bill.status is not BillStatus.CANCELLED]
    if active:
        return IssuedBill(active[0], created=False)
    if reissue_at is None and existing:
        raise BillingPeriodCancelledError(details=details)
    if reissue_at is not None and not existing:
        raise BillingNothingToReissueError(details=details)

    tariff = tariff_at(session, period.start)
    if tariff is None:
        raise NoTariffError(details=details)
    previous = _billing_reading(session, meter, period.start)
    current = _billing_reading(session, meter, period.end + timedelta(days=1))
    consumption = current.index_wh - previous.index_wh
    source = _check_daily_readings(session, meter, previous, current, details)

    computation = compute_bill(consumption, period.months_count, tariff)
    bill = Bill(
        meter_id=meter.id,
        tariff_id=tariff.id,
        reference=bill_reference(day, sequence),
        period_start=period.start,
        period_end=period.end,
        months_count=period.months_count,
        previous_index_wh=previous.index_wh,
        current_index_wh=current.index_wh,
        consumption_wh=consumption,
        billed_power_va=meter.subscribed_power_va,
        amount_ht=computation.amount_ht,
        amount_tax=computation.amount_tax,
        amount_fees=computation.amount_fees,
        amount_total=computation.amount_total,
        due_date=(
            due_date(period, settings)
            if reissue_at is None
            else day + timedelta(days=settings.bill_due_delay_days)
        ),
        issued_at=issued_at(day) if reissue_at is None else reissue_at,
        status=BillStatus.UNPAID,
        source=source,
    )
    session.add(bill)
    session.flush()
    session.execute(
        insert(BillLine), [{"bill_id": bill.id, **asdict(line)} for line in computation.lines]
    )
    return IssuedBill(bill, created=True)


@dataclass(frozen=True, slots=True)
class OverdueReport:
    bills: list[Bill]
    notifications: int


def mark_overdue_bills(session: Session, *, today: date, notify: bool = True) -> OverdueReport:
    """Passe « en retard » les factures impayées dont l'échéance est dépassée.

    Le jour même de l'échéance, la facture n'est pas encore en retard. Une facture payée,
    annulée ou en cours de paiement n'est jamais concernée. Sont prévenus le titulaire du foyer
    et ses payeurs délégués (personne si le compteur est détaché), sauf si l'équipe a coupé
    l'alerte de retard (`notify=False`, A9 : le statut change quand même). Idempotent. Pas de
    commit. Les rappels suivants (tous les 7 jours) : `reminders.send_overdue_reminders`.
    """
    bills = session.scalars(
        select(Bill)
        .where(Bill.status == BillStatus.UNPAID, Bill.due_date < today)
        .order_by(Bill.id)
        .with_for_update()
    ).all()
    notifications = []
    for bill in bills:
        bill.status = BillStatus.OVERDUE
        if not notify:
            continue
        notifications += [
            bill_overdue_notification(user_id, bill) for user_id in bill_recipients(session, bill)
        ]
    session.flush()
    return OverdueReport(
        bills=list(bills), notifications=insert_notifications(session, notifications)
    )


# --- Étapes ------------------------------------------------------------------------------


def _details(meter: Meter, period: BillingPeriod) -> dict[str, str]:
    return {
        "meter_reference": meter.reference,
        "period_start": period.start.isoformat(),
        "period_end": period.end.isoformat(),
    }


def _lock_next_sequence(session: Session, day: date) -> int:
    """Prochain numéro du jour d'émission, en verrouillant le dernier numéro de ce jour.

    Les numéros repartent de 1 chaque jour (AAAAMMJJ + 6 chiffres) : la limite est donc
    de 999 999 factures par jour d'émission. Lecture verrouillante (FOR UPDATE) : elle voit
    les numéros validés par une autre émission et bloque les autres jusqu'au commit.
    """
    first, last = bill_reference(day, 1), bill_reference(day, MAX_SEQUENCE)
    latest = session.scalars(
        select(Bill.reference)
        .where(Bill.reference.between(first, last))
        .order_by(Bill.reference.desc())
        .limit(1)
        .with_for_update()
    ).first()
    sequence = int(latest[8:]) + 1 if latest else 1
    if sequence > MAX_SEQUENCE:
        raise BillSequenceExhaustedError(details={"issue_date": day.isoformat()})
    return sequence


def _existing_bills(session: Session, meter: Meter, period: BillingPeriod) -> list[Bill]:
    """Toutes les factures de la période, annulées comprises (lecture verrouillante)."""
    return list(
        session.scalars(
            select(Bill)
            .where(Bill.meter_id == meter.id, Bill.period_start == period.start)
            .order_by(Bill.id)
            .with_for_update()
        )
    )


def _billing_reading(session: Session, meter: Meter, day: date) -> MeterReading:
    """Premier relevé de la journée locale `day` (celui de minuit)."""
    reading = session.scalars(
        select(MeterReading)
        .where(
            MeterReading.meter_id == meter.id,
            MeterReading.read_at >= local_midnight_utc(day),
            MeterReading.read_at < local_midnight_utc(day + timedelta(days=1)),
        )
        .order_by(MeterReading.read_at)
        .limit(1)
    ).first()
    details = {"meter_reference": meter.reference, "reading_date": day.isoformat()}
    if reading is None:
        raise BillingReadingMissingError(
            f"Relevé de facturation manquant au {day:%d/%m/%Y}.", details=details
        )
    if reading.is_anomaly:
        raise BillingReadingAnomalyError(
            f"Relevé de facturation en anomalie au {day:%d/%m/%Y}.", details=details
        )
    return reading


def _check_daily_readings(
    session: Session,
    meter: Meter,
    previous: MeterReading,
    current: MeterReading,
    details: dict[str, str],
) -> BillSource:
    """Garde-fou : somme des relevés après l'ancien index jusqu'au nouvel index = consommation.

    Renvoie aussi la source de la facture : « e2c » seulement si TOUS ces relevés viennent
    d'E²C ; sinon « simulated » (une donnée simulée n'est jamais présentée comme réelle).
    """
    total, not_from_e2c = session.execute(
        select(
            func.coalesce(func.sum(MeterReading.consumption_wh), 0),
            func.count(case((MeterReading.source != ReadingSource.E2C, 1))),
        ).where(
            MeterReading.meter_id == meter.id,
            MeterReading.read_at > previous.read_at,
            MeterReading.read_at <= current.read_at,
        )
    ).one()
    expected = current.index_wh - previous.index_wh
    if int(total) != expected:
        raise BillingReadingsMismatchError(
            details=details | {"readings_wh": int(total), "index_wh": expected}
        )
    return BillSource.SIMULATED if not_from_e2c else BillSource.E2C
