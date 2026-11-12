"""Choix de la source E²C selon la configuration (BILLING_SOURCE)."""

from fastapi import Depends

from app.core.config import Settings, get_settings
from app.integrations.billing_sources.base import BillingSource
from app.integrations.billing_sources.simulated import SimulatedBillingSource

_SOURCES = {"simulated": SimulatedBillingSource}


def get_billing_source(settings: Settings = Depends(get_settings)) -> BillingSource:
    """Dépendance FastAPI. Seule la source simulée existe pour l'instant ; la configuration
    refuse déjà toute autre valeur de BILLING_SOURCE."""
    return _SOURCES[settings.billing_source]()
