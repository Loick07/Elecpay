"""Choix du prestataire de paiement selon la configuration (PAYMENT_PROVIDER)."""

from fastapi import Depends

from app.core.config import Settings, get_settings
from app.integrations.payment_providers.base import PaymentProvider
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider


def get_payment_provider(settings: Settings = Depends(get_settings)) -> PaymentProvider:
    """Dépendance FastAPI. Seul le simulateur existe pour l'instant ; la configuration refuse
    déjà toute autre valeur de PAYMENT_PROVIDER (MTN et Airtel se brancheront ici)."""
    match settings.payment_provider:
        case "simulated":
            return SimulatedPaymentProvider(settings.payment_webhook_secret.get_secret_value())
