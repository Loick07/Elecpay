"""Choix de l'envoi d'e-mails selon la configuration (EMAIL_PROVIDER)."""

from functools import cache

from app.integrations.email.base import EmailSender
from app.integrations.email.simulated import SimulatedEmailSender


@cache
def get_email_sender() -> EmailSender:
    """Dépendance FastAPI et commandes. Un seul fournisseur pour l'instant : le simulateur."""
    return SimulatedEmailSender()
