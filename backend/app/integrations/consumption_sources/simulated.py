"""Source des consommations simulée : 18 mois d'historique (voir app/simulators/history.py)."""

from datetime import date

from sqlalchemy.orm import Session

from app.integrations.consumption_sources.base import HistoryImport
from app.modules.bills.periods import BillingSettings
from app.modules.meters.models import Meter
from app.simulators.history import backfill_meter_history


class SimulatedConsumptionSource:
    def __init__(self, settings: BillingSettings) -> None:
        self.settings = settings

    def import_history(self, session: Session, meter: Meter, *, today: date) -> HistoryImport:
        imported = backfill_meter_history(session, meter, today=today, settings=self.settings)
        return HistoryImport(readings=imported.readings, bills=imported.bills, source="simulated")
