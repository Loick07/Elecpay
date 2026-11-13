"""Alerte « Consommation inhabituelle » (B9.3), lancée une fois par jour.

Règle (décision du 13/11/2026) : la journée d'hier (relevée à minuit ce matin) dépasse de
PLUS de 30 % la moyenne des 30 journées précédentes. Ne comptent que les relevés réels :
ni estimés ni en anomalie, ni pour la journée testée ni pour la moyenne ; il faut au moins
7 journées dans la moyenne. Au plus une alerte par compteur et par journée.

Destinataires : le titulaire et tous les membres actifs du foyer (c'est une information, pas
une demande de paiement). Désactivée par défaut : seuls ceux qui ont activé l'interrupteur
« Consommation inhabituelle » (écran 14) la reçoivent (`insert_notifications`).
Calcul en entiers (Wh) ; les kWh du message servent seulement à l'affichage.
"""

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timezone import local_midnight_utc
from app.modules.consumption.models import MeterReading
from app.modules.households.models import Household, HouseholdMember, MemberStatus
from app.modules.meters.models import Meter, MeterStatus
from app.modules.notifications.models import Notification, NotificationType
from app.modules.notifications.service import insert_notifications, notification_row

THRESHOLD_PERCENT = 130  # au-dessus de 130 % de la moyenne
WINDOW_DAYS = 30
MIN_DAYS = 7
NOTICE_HOUR = timedelta(hours=7)


def send_high_consumption_alerts(session: Session, *, today: date) -> int:
    """Alertes pour la journée d'hier. Renvoie le nombre de notifications créées."""
    day = today - timedelta(days=1)
    meters = session.execute(
        select(Meter, Household)
        .join(Household, Household.id == Meter.household_id)
        .where(Meter.status == MeterStatus.ACTIVE)
        .order_by(Meter.id)
    ).all()
    rows = []
    for meter, household in meters:
        excess = _excess_percent(session, meter, today)
        if excess is None or _already_alerted(session, meter, day):
            continue
        consumed = _reading_of(session, meter, today).consumption_wh
        rows += [
            notification_row(
                user_id,
                NotificationType.HIGH_CONSUMPTION,
                "Consommation inhabituelle",
                f"{household.name} : {_kwh(consumed)} kWh le {day:%d/%m}, "
                f"{excess} % au-dessus de votre moyenne.",
                {"meter_id": meter.id, "household_id": household.id, "day": day.isoformat()},
                at=local_midnight_utc(today) + NOTICE_HOUR,
            )
            for user_id in _members(session, household)
        ]
    return insert_notifications(session, rows)


def _excess_percent(session: Session, meter: Meter, today: date) -> int | None:
    """De combien (%) la journée d'hier dépasse la moyenne, si c'est plus de 30 % ; sinon None."""
    reading = _reading_of(session, meter, today)
    if reading is None or reading.is_anomaly or reading.is_estimated:
        return None
    history = session.scalars(
        select(MeterReading.consumption_wh).where(
            MeterReading.meter_id == meter.id,
            MeterReading.read_at >= local_midnight_utc(today - timedelta(days=WINDOW_DAYS)),
            MeterReading.read_at < local_midnight_utc(today),
            MeterReading.is_anomaly.is_(False),
            MeterReading.is_estimated.is_(False),
        )
    ).all()
    total = sum(history)
    if len(history) < MIN_DAYS or total == 0:
        return None
    # reading / (total / n) > 130 % ⇔ reading × n × 100 > total × 130 (entiers, sans arrondi)
    if reading.consumption_wh * len(history) * 100 <= total * THRESHOLD_PERCENT:
        return None
    return reading.consumption_wh * len(history) * 100 // total - 100


def _reading_of(session: Session, meter: Meter, today: date) -> MeterReading | None:
    """Relevé de minuit ce matin : il porte la consommation d'hier."""
    return session.scalars(
        select(MeterReading)
        .where(
            MeterReading.meter_id == meter.id,
            MeterReading.read_at >= local_midnight_utc(today),
            MeterReading.read_at < local_midnight_utc(today + timedelta(days=1)),
        )
        .order_by(MeterReading.read_at)
        .limit(1)
    ).first()


def _already_alerted(session: Session, meter: Meter, day: date) -> bool:
    return (
        session.scalar(
            select(Notification.id)
            .where(
                Notification.type == NotificationType.HIGH_CONSUMPTION,
                Notification.data_json["meter_id"].as_integer() == meter.id,
                Notification.data_json["day"].as_string() == day.isoformat(),
            )
            .limit(1)
        )
        is not None
    )


def _members(session: Session, household: Household) -> list[int]:
    members = session.scalars(
        select(HouseholdMember.user_id).where(
            HouseholdMember.household_id == household.id,
            HouseholdMember.status == MemberStatus.ACTIVE,
        )
    ).all()
    return [household.owner_id, *sorted(set(members) - {household.owner_id})]


def _kwh(wh: int) -> str:
    """9 812 Wh → « 9,8 » (affichage seulement)."""
    return f"{wh / 1000:.1f}".replace(".", ",")
