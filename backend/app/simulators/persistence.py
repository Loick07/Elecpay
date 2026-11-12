"""Écriture en base des relevés simulés, commune au seed (B2.5) et au relevé quotidien (B2.6).

Les factures, elles, ne s'écrivent QUE par `app.modules.bills.service.generate_bill` (B6).
"""

from collections.abc import Sequence
from dataclasses import asdict
from datetime import datetime, timedelta

from sqlalchemy import insert
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.modules.consumption.models import MeterReading, ReadingSource
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import notification_row
from app.simulators.readings import SimulatedReading


def insert_readings(session: Session, meter_id: int, readings: Sequence[SimulatedReading]) -> int:
    """Insertion groupée (rapide) de relevés simulés. Renvoie le nombre inséré."""
    rows = [
        {"meter_id": meter_id, "source": ReadingSource.SIMULATED, **asdict(r)} for r in readings
    ]
    if rows:
        session.execute(insert(MeterReading), rows)
    return len(rows)


def anomaly_notification(user_id: int, meter_id: int, reference: str, read_at: datetime):
    return notification_row(
        user_id,
        NotificationType.CONSUMPTION_ANOMALY,
        "Relevé inhabituel",
        f"Le relevé du {local_date(read_at):%d/%m/%Y} sur le compteur {reference} semble "
        "erroné. Il a été signalé pour vérification.",
        {"meter_id": meter_id},
        at=read_at + timedelta(hours=7),
    )
