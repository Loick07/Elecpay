"""Envoi d'e-mails simulé (mode démo) : rien ne part, l'envoi est seulement journalisé.

Le contenu du message n'est JAMAIS écrit dans les journaux, et l'adresse y est masquée.
Les messages « envoyés » restent en mémoire (`outbox`) pour les tests et les démonstrations.
Une adresse de test qui finit par « @echec.example » simule une panne du service d'envoi.
"""

import logging
from dataclasses import dataclass, field

from app.core.validation import mask_email
from app.integrations.email.base import EmailMessage, EmailSendError

logger = logging.getLogger("elecpay.email")
FAILING_DOMAIN = "@echec.example"


@dataclass
class SimulatedEmailSender:
    outbox: list[EmailMessage] = field(default_factory=list)

    def send(self, message: EmailMessage) -> None:
        if message.to.endswith(FAILING_DOMAIN):
            raise EmailSendError("Service d'envoi simulé indisponible")
        self.outbox.append(message)
        logger.info(
            "E-mail simulé vers %s : « %s » (%d pièce(s) jointe(s))",
            mask_email(message.to),
            message.subject,
            len(message.attachments),
        )
