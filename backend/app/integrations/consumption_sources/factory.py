"""Choix de la source des consommations selon la configuration (BILLING_SOURCE : les relevés
et les factures viennent du même fournisseur, E²C)."""

from fastapi import Depends

from app.core.config import Settings, get_settings
from app.integrations.consumption_sources.base import ConsumptionSource
from app.integrations.consumption_sources.simulated import SimulatedConsumptionSource


def get_consumption_source(settings: Settings = Depends(get_settings)) -> ConsumptionSource:
    """Dépendance FastAPI. Seule la source simulée existe pour l'instant."""
    if settings.billing_source == "simulated":
        return SimulatedConsumptionSource(settings)
    raise NotImplementedError(f"Source de consommation inconnue : {settings.billing_source}")
