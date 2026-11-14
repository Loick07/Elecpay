"""Compteurs dans le back-office (B10.4, maquette A4).

Lecture (support, admin, super admin) : liste avec l'état du jour et les compteurs du haut de
l'écran, panneau de détail (index d'hier et d'aujourd'hui, explication, dernière facture,
anomalies, derniers relevés).

Écriture (admin, super admin), chaque action au journal :
- anomalie de relevé : « Demander un relevé de contrôle » (note facultative) ou « Classer sans
  suite » (note obligatoire). Le relevé n'est JAMAIS modifié : il reste gardé et exclu des
  factures ; seul son traitement est noté (statut, auteur, date, note) ;
- détacher un compteur de son foyer, ou rattacher un compteur détaché à un foyer (motif
  obligatoire). Refusé si un paiement est en cours sur l'une de ses factures (facture
  verrouillée). Les factures suivent le compteur.

État du jour (heure de Brazzaville), d'après le relevé de minuit :
reçu · anomalie · manquant (compteur actif et rattaché sans relevé) · inactif (suspendu,
résilié ou détaché : aucun relevé attendu).
"""

from collections.abc import Callable
from datetime import date, datetime, timedelta

from fastapi import status
from sqlalchemy import ColumnElement, and_, exists, func, not_, or_, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.request_context import RequestContext
from app.core.timezone import local_date, local_midnight_utc
from app.db.base import utcnow
from app.modules.admin.audit import record_admin_action
from app.modules.admin.meters_schemas import (
    AdminMeterDetail,
    AdminMeterList,
    AdminMeterRow,
    AnomalyHandled,
    AnomalyLine,
    HouseholdBrief,
    LastBill,
    MeterCounters,
    MeterLink,
    ReadingLine,
    TodayStatus,
)
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.pdf import kwh_text
from app.modules.bills.queries import bill_period_label, displayed_status
from app.modules.consumption.models import AnomalyStatus, MeterReading
from app.modules.households.models import Household
from app.modules.meters.errors import MeterLimitError
from app.modules.meters.models import Meter, MeterStatus
from app.modules.meters.service import MAX_METERS_PER_HOUSEHOLD
from app.modules.users.models import User

TO_PAY = (BillStatus.UNPAID, BillStatus.OVERDUE, BillStatus.PENDING_PAYMENT)
RECENT_READINGS = 14
ANOMALIES = 20
# Compteur du haut de l'écran : anomalies à traiter des 30 derniers jours (décision B10.4).
# Le détail d'un compteur, lui, montre toutes ses anomalies non classées.
OPEN_ANOMALIES_WINDOW = timedelta(days=30)


class AdminMeterNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "METER_NOT_FOUND"
    message = "Compteur introuvable."


class ReadingNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "READING_NOT_FOUND"
    message = "Relevé introuvable sur ce compteur."


class HouseholdNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "HOUSEHOLD_NOT_FOUND"
    message = "Foyer introuvable."


class MeterActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "METER_ACTION_REFUSED"
    message = "Action impossible sur ce compteur."


def expects_reading() -> ColumnElement[bool]:
    """Un relevé est attendu chaque matin : compteur actif ET rattaché à un foyer."""
    return and_(Meter.status == MeterStatus.ACTIVE, Meter.household_id.is_not(None))


def is_open_anomaly() -> ColumnElement[bool]:
    return and_(MeterReading.is_anomaly.is_(True), MeterReading.anomaly_status.is_(None))


def not_dismissed() -> ColumnElement[bool]:
    """Anomalie encore à suivre : à traiter, ou relevé de contrôle demandé."""
    return and_(
        MeterReading.is_anomaly.is_(True),
        or_(
            MeterReading.anomaly_status.is_(None),
            MeterReading.anomaly_status != AnomalyStatus.DISMISSED,
        ),
    )


def reading_line(reading: MeterReading) -> ReadingLine:
    return ReadingLine(
        id=reading.id,
        read_at=reading.read_at,
        index_wh=reading.index_wh,
        consumption_wh=reading.consumption_wh,
        is_estimated=reading.is_estimated,
        is_anomaly=reading.is_anomaly,
        anomaly_reason=reading.anomaly_reason,
        anomaly_status=reading.anomaly_status,
    )


class AdminMeters:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Liste (A4) --------------------------------------------------------------------------

    def list(
        self,
        params: PageParams,
        *,
        q: str | None = None,
        today_status: TodayStatus | None = None,
        attached: bool | None = None,
    ) -> AdminMeterList:
        day = local_date(self.now())
        start, end = self._day_bounds(day)
        query = (
            select(Meter, Household, User)
            .outerjoin(Household, Household.id == Meter.household_id)
            .outerjoin(User, User.id == Household.owner_id)
        )
        if q and q.strip():
            text = f"%{q.strip()}%"
            query = query.where(
                or_(
                    Meter.reference.ilike(text),
                    Meter.customer_number.ilike(text),
                    Meter.label.ilike(text),
                    Household.name.ilike(text),
                    User.full_name.ilike(text),
                )
            )
        if attached is not None:
            query = query.where(
                Meter.household_id.is_not(None) if attached else Meter.household_id.is_(None)
            )
        if today_status is not None:
            query = query.where(self._status_condition(today_status, start, end))
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = self.session.execute(
            query.order_by(Meter.reference, Meter.id).limit(params.size).offset(params.offset)
        ).all()

        # Lectures groupées pour la page (pas de requête par ligne).
        meter_ids = [meter.id for meter, _, _ in rows]
        today_readings = {
            reading.meter_id: reading
            for reading in self.session.scalars(
                select(MeterReading).where(
                    MeterReading.meter_id.in_(meter_ids),
                    MeterReading.read_at >= start,
                    MeterReading.read_at < end,
                )
            )
        }
        last_read = dict(
            self.session.execute(
                select(MeterReading.meter_id, func.max(MeterReading.read_at))
                .where(MeterReading.meter_id.in_(meter_ids))
                .group_by(MeterReading.meter_id)
            ).all()
        )
        open_counts = dict(
            self.session.execute(
                select(MeterReading.meter_id, func.count())
                .where(MeterReading.meter_id.in_(meter_ids), is_open_anomaly())
                .group_by(MeterReading.meter_id)
            ).all()
        )
        items = []
        for meter, household, owner in rows:
            reading = today_readings.get(meter.id)
            items.append(
                AdminMeterRow(
                    id=meter.id,
                    reference=meter.reference,
                    label=meter.label,
                    customer_number=meter.customer_number,
                    e2c_center=meter.e2c_center,
                    status=meter.status,
                    household_id=meter.household_id,
                    household_name=household.name if household else None,
                    district=household.district if household else None,
                    owner_name=owner.full_name if owner else None,
                    today_status=self._today_status(meter, reading),
                    today_index_wh=reading.index_wh if reading else None,
                    last_reading_at=last_read.get(meter.id),
                    open_anomalies=open_counts.get(meter.id, 0),
                )
            )
        return AdminMeterList(
            items=items,
            total=total,
            page=params.page,
            size=params.size,
            day=day,
            counters=self._counters(start, end),
        )

    # --- Détail (A4, panneau) ------------------------------------------------------------------

    def detail(self, meter_id: int) -> AdminMeterDetail:
        meter = self._get(meter_id)
        day = local_date(self.now())
        start, end = self._day_bounds(day)
        today = self._reading_between(meter.id, start, end)
        yesterday = self._reading_between(meter.id, start - timedelta(days=1), start)
        recent = self.session.scalars(
            select(MeterReading)
            .where(MeterReading.meter_id == meter.id)
            .order_by(MeterReading.read_at.desc())
            .limit(RECENT_READINGS)
        ).all()
        today_status = self._today_status(meter, today)
        return AdminMeterDetail(
            id=meter.id,
            reference=meter.reference,
            label=meter.label,
            customer_number=meter.customer_number,
            contract_number=meter.contract_number,
            e2c_center=meter.e2c_center,
            subscribed_power_va=meter.subscribed_power_va,
            status=meter.status,
            installed_at=meter.installed_at,
            household=self._household(meter),
            day=day,
            today_status=today_status,
            yesterday=reading_line(yesterday) if yesterday else None,
            today=reading_line(today) if today else None,
            explanation=self._explanation(meter, today_status, today, yesterday),
            last_bill=self._last_bill(meter, day),
            anomalies=self._anomalies(meter),
            recent_readings=[reading_line(reading) for reading in recent],
        )

    # --- Actions sur une anomalie ------------------------------------------------------------

    def request_control(
        self,
        actor: User,
        meter_id: int,
        reading_id: int,
        note: str | None,
        context: RequestContext,
    ) -> AnomalyHandled:
        reading = self._anomaly(meter_id, reading_id)
        if reading.anomaly_status is not None:
            raise MeterActionError("Cette anomalie a déjà été traitée.")
        return self._handle(
            actor, reading, AnomalyStatus.CONTROL_REQUESTED, note, "meter.anomaly_control", context
        )

    def dismiss(
        self, actor: User, meter_id: int, reading_id: int, note: str, context: RequestContext
    ) -> AnomalyHandled:
        reading = self._anomaly(meter_id, reading_id)
        if reading.anomaly_status is AnomalyStatus.DISMISSED:
            raise MeterActionError("Cette anomalie est déjà classée sans suite.")
        return self._handle(
            actor, reading, AnomalyStatus.DISMISSED, note, "meter.anomaly_dismiss", context
        )

    # --- Rattacher / détacher ------------------------------------------------------------------

    def detach(self, actor: User, meter_id: int, reason: str, context: RequestContext) -> MeterLink:
        meter = self._get(meter_id, lock=True)
        if meter.household_id is None:
            raise MeterActionError("Ce compteur n'est rattaché à aucun foyer.")
        self._refuse_if_payment_in_progress(meter)
        before = meter.household_id
        meter.household_id = None
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="meter.detach",
            entity_type="meter",
            entity_id=meter.id,
            before={"household_id": before},
            after={"household_id": None, "reason": reason},
        )
        self.session.commit()
        return MeterLink(meter_id=meter.id, household_id=None, unpaid_bills=self._unpaid(meter))

    def attach(
        self,
        actor: User,
        meter_id: int,
        household_id: int,
        reason: str,
        context: RequestContext,
    ) -> MeterLink:
        meter = self._get(meter_id, lock=True)
        if meter.household_id is not None:
            raise MeterActionError("Ce compteur est déjà rattaché : détachez-le d'abord.")
        household = self.session.scalars(
            select(Household).where(Household.id == household_id).with_for_update()
        ).first()
        if household is None:
            raise HouseholdNotFoundError()
        self._refuse_if_payment_in_progress(meter)
        count = self.session.scalar(
            select(func.count()).select_from(Meter).where(Meter.household_id == household.id)
        )
        if count >= MAX_METERS_PER_HOUSEHOLD:
            raise MeterLimitError(f"Un foyer compte au plus {MAX_METERS_PER_HOUSEHOLD} compteurs.")
        meter.household_id = household.id
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="meter.attach",
            entity_type="meter",
            entity_id=meter.id,
            before={"household_id": None},
            after={"household_id": household.id, "reason": reason},
        )
        self.session.commit()
        return MeterLink(
            meter_id=meter.id, household_id=household.id, unpaid_bills=self._unpaid(meter)
        )

    # --- Outils ------------------------------------------------------------------------------

    @staticmethod
    def _day_bounds(day: date) -> tuple[datetime, datetime]:
        return local_midnight_utc(day), local_midnight_utc(day + timedelta(days=1))

    def _get(self, meter_id: int, *, lock: bool = False) -> Meter:
        query = select(Meter).where(Meter.id == meter_id)
        if lock:
            query = query.with_for_update()
        meter = self.session.scalars(query).first()
        if meter is None:
            raise AdminMeterNotFoundError()
        return meter

    def _anomaly(self, meter_id: int, reading_id: int) -> MeterReading:
        self._get(meter_id)
        reading = self.session.scalars(
            select(MeterReading)
            .where(MeterReading.id == reading_id, MeterReading.meter_id == meter_id)
            .with_for_update()
        ).first()
        if reading is None:
            raise ReadingNotFoundError()
        if not reading.is_anomaly:
            raise MeterActionError("Ce relevé n'est pas en anomalie.")
        return reading

    def _handle(
        self,
        actor: User,
        reading: MeterReading,
        new_status: AnomalyStatus,
        note: str | None,
        action: str,
        context: RequestContext,
    ) -> AnomalyHandled:
        before = reading.anomaly_status
        reading.anomaly_status = new_status
        reading.anomaly_handled_by = actor.id
        reading.anomaly_handled_at = self.now()
        reading.anomaly_note = note
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action=action,
            entity_type="meter",
            entity_id=reading.meter_id,
            before={"reading_id": reading.id, "status": before.value if before else None},
            after={"reading_id": reading.id, "status": new_status.value, "note": note},
        )
        self.session.commit()
        return AnomalyHandled(
            reading_id=reading.id,
            meter_id=reading.meter_id,
            status=new_status,
            handled_at=reading.anomaly_handled_at,
        )

    def _refuse_if_payment_in_progress(self, meter: Meter) -> None:
        pending = self.session.scalar(
            select(func.count())
            .select_from(Bill)
            .where(Bill.meter_id == meter.id, Bill.status == BillStatus.PENDING_PAYMENT)
        )
        if pending:
            raise MeterActionError(
                "Un paiement est en cours sur une facture de ce compteur : réessayez après "
                "sa confirmation ou son échec."
            )

    def _unpaid(self, meter: Meter) -> int:
        return self.session.scalar(
            select(func.count())
            .select_from(Bill)
            .where(Bill.meter_id == meter.id, Bill.status.in_(TO_PAY))
        )

    def _status_condition(
        self, wanted: TodayStatus, start: datetime, end: datetime
    ) -> ColumnElement[bool]:
        today = select(MeterReading.id).where(
            MeterReading.meter_id == Meter.id,
            MeterReading.read_at >= start,
            MeterReading.read_at < end,
        )
        anomaly_today = exists(today.where(MeterReading.is_anomaly.is_(True)))
        match wanted:
            case TodayStatus.INACTIVE:
                return not_(expects_reading())
            case TodayStatus.MISSING:
                return and_(expects_reading(), not_(exists(today)))
            case TodayStatus.ANOMALY:
                return and_(expects_reading(), anomaly_today)
            case TodayStatus.RECEIVED:
                return and_(expects_reading(), exists(today), not_(anomaly_today))

    @staticmethod
    def _today_status(meter: Meter, reading: MeterReading | None) -> TodayStatus:
        if meter.status is not MeterStatus.ACTIVE or meter.household_id is None:
            return TodayStatus.INACTIVE
        if reading is None:
            return TodayStatus.MISSING
        return TodayStatus.ANOMALY if reading.is_anomaly else TodayStatus.RECEIVED

    def _counters(self, start: datetime, end: datetime) -> MeterCounters:
        def count_meters(condition: ColumnElement[bool]) -> int:
            return self.session.scalar(select(func.count()).select_from(Meter).where(condition))

        def count_readings(*conditions: ColumnElement[bool]) -> int:
            return self.session.scalar(
                select(func.count()).select_from(MeterReading).where(*conditions)
            )

        return MeterCounters(
            attached=count_meters(Meter.household_id.is_not(None)),
            received_today=count_readings(
                MeterReading.read_at >= start,
                MeterReading.read_at < end,
                MeterReading.meter_id.in_(select(Meter.id).where(expects_reading())),
            ),
            missing_today=count_meters(self._status_condition(TodayStatus.MISSING, start, end)),
            open_anomalies=count_readings(
                is_open_anomaly(), MeterReading.read_at >= start - OPEN_ANOMALIES_WINDOW
            ),
            control_requested=count_readings(
                MeterReading.anomaly_status == AnomalyStatus.CONTROL_REQUESTED
            ),
            inactive=count_meters(not_(expects_reading())),
        )

    def _reading_between(
        self, meter_id: int, start: datetime, end: datetime
    ) -> MeterReading | None:
        return self.session.scalars(
            select(MeterReading)
            .where(
                MeterReading.meter_id == meter_id,
                MeterReading.read_at >= start,
                MeterReading.read_at < end,
            )
            .order_by(MeterReading.read_at.desc())
            .limit(1)
        ).first()

    def _household(self, meter: Meter) -> HouseholdBrief | None:
        if meter.household_id is None:
            return None
        household = self.session.get(Household, meter.household_id)
        owner = self.session.get(User, household.owner_id)
        return HouseholdBrief(
            id=household.id,
            name=household.name,
            district=household.district,
            city=household.city,
            owner_id=owner.id,
            owner_name=owner.full_name,
        )

    @staticmethod
    def _explanation(
        meter: Meter,
        today_status: TodayStatus,
        today: MeterReading | None,
        yesterday: MeterReading | None,
    ) -> str:
        match today_status:
            case TodayStatus.INACTIVE if meter.household_id is None:
                return "Compteur détaché de tout foyer : aucun relevé n'est attendu."
            case TodayStatus.INACTIVE:
                return "Compteur suspendu ou résilié : aucun relevé n'est attendu."
            case TodayStatus.MISSING:
                return (
                    "Aucun relevé reçu ce matin (attendu à minuit). La consommation sera "
                    "rattrapée par le prochain relevé reçu."
                )
            case TodayStatus.ANOMALY:
                previous = f" ({kwh_text(yesterday.index_wh)} hier)" if yesterday else ""
                return (
                    f"Index lu ce matin : {kwh_text(today.index_wh)}, inférieur au précédent"
                    f"{previous}. Un compteur ne recule pas : erreur de lecture probable. Le "
                    "relevé est gardé mais exclu des factures ; le relevé suivant rattrape la "
                    "consommation."
                )
            case _:
                return f"Relevé normal : {kwh_text(today.consumption_wh)} consommés hier."

    def _last_bill(self, meter: Meter, day: date) -> LastBill | None:
        bill = self.session.scalars(
            select(Bill)
            .where(Bill.meter_id == meter.id, Bill.issued_at <= self.now())
            .order_by(Bill.period_start.desc(), Bill.id.desc())
            .limit(1)
        ).first()
        if bill is None:
            return None
        return LastBill(
            id=bill.id,
            reference=bill.reference,
            period_label=bill_period_label(bill.period_start, bill.period_end),
            amount_total=bill.amount_total,
            status=displayed_status(bill, day),
            due_date=bill.due_date,
        )

    def _anomalies(self, meter: Meter) -> list[AnomalyLine]:
        rows = self.session.execute(
            select(MeterReading, User)
            .outerjoin(User, User.id == MeterReading.anomaly_handled_by)
            .where(MeterReading.meter_id == meter.id, not_dismissed())
            .order_by(MeterReading.read_at.desc())
            .limit(ANOMALIES)
        ).all()
        lines = []
        for reading, handler in rows:
            previous = self.session.scalar(
                select(MeterReading.index_wh)
                .where(
                    MeterReading.meter_id == meter.id,
                    MeterReading.read_at < reading.read_at,
                    MeterReading.is_anomaly.is_(False),
                )
                .order_by(MeterReading.read_at.desc())
                .limit(1)
            )
            lines.append(
                AnomalyLine(
                    reading_id=reading.id,
                    read_at=reading.read_at,
                    index_wh=reading.index_wh,
                    previous_index_wh=previous,
                    reason=reading.anomaly_reason,
                    status=reading.anomaly_status,
                    handled_by=handler.full_name if handler else None,
                    handled_at=reading.anomaly_handled_at,
                    note=reading.anomaly_note,
                )
            )
        return lines
