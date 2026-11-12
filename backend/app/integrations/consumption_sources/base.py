"""Source des consommations : importer l'historique d'un compteur nouvellement ajouté.

Aujourd'hui : `SimulatedConsumptionSource` (génère un historique de démo). Demain : une source
E²C qui téléchargera les vrais relevés et factures — sans rien changer au reste de l'application.
"""

from dataclasses import dataclass
from datetime import date
from typing import Protocol

from sqlalchemy.orm import Session

from app.modules.meters.models import Meter


@dataclass(frozen=True, slots=True)
class HistoryImport:
    readings: int
    bills: int
    source: str  # « simulated » en mode démo : jamais présenté comme réel


class ConsumptionSource(Protocol):
    def import_history(self, session: Session, meter: Meter, *, today: date) -> HistoryImport:
        """Ajoute en base l'historique connu du compteur (sans valider la transaction)."""
        ...
