"""Interrupteurs généraux des alertes automatiques (maquette A9, B10.7).

Lus par `run_daily_alerts` avant chaque passage quotidien. Pas de ligne en base = tout activé.
"""

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.announcements.models import AlertSettings

GLOBAL = "global"


@dataclass(frozen=True, slots=True)
class AlertSwitches:
    due_soon: bool = True  # rappels d'échéance (J-5 et jour J)
    overdue: bool = True  # avis de retard et rappels tous les 7 jours
    high_consumption: bool = True  # consommation inhabituelle


def alert_switches(session: Session) -> AlertSwitches:
    row = session.scalars(select(AlertSettings).where(AlertSettings.scope == GLOBAL)).first()
    if row is None:
        return AlertSwitches()
    return AlertSwitches(
        due_soon=row.due_soon, overdue=row.overdue, high_consumption=row.high_consumption
    )
