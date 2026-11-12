"""Envoi de SMS simulé (mode démo) : rien ne part, le message est seulement journalisé.

Le contenu du message (qui contient le code) n'est JAMAIS écrit dans les journaux,
et le numéro y est masqué. En mode démo, l'API renvoie le code dans sa réponse.
"""

import logging
from dataclasses import dataclass, field

from app.core.validation import mask_phone

logger = logging.getLogger("elecpay.sms")


@dataclass
class SentSms:
    phone: str
    message: str


@dataclass
class SimulatedSmsSender:
    # Les derniers messages « envoyés », pour les tests (jamais exposés par l'API).
    outbox: list[SentSms] = field(default_factory=list)

    def send(self, phone: str, message: str) -> None:
        self.outbox.append(SentSms(phone, message))
        logger.info("SMS simulé vers %s (%d caractères)", mask_phone(phone), len(message))
