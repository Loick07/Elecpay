"""Choix de l'envoi de SMS selon la configuration (SMS_PROVIDER)."""

from functools import cache

from app.integrations.sms.base import SmsSender
from app.integrations.sms.simulated import SimulatedSmsSender


@cache
def get_sms_sender() -> SmsSender:
    """Dépendance FastAPI. Un seul fournisseur existe pour l'instant : le simulateur."""
    return SimulatedSmsSender()
