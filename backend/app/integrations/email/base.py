"""Envoi d'e-mails : une interface, plusieurs implémentations choisies par configuration (B11.4).

Aujourd'hui : `SimulatedEmailSender` (aucun e-mail réel ne part). Demain : un vrai service
(Brevo, Mailjet, Amazon SES…) qui implémentera la même méthode `send`.
"""

from dataclasses import dataclass, field
from typing import Protocol


@dataclass(frozen=True, slots=True)
class Attachment:
    filename: str
    content_type: str
    content: bytes


@dataclass(frozen=True, slots=True)
class EmailMessage:
    to: str
    subject: str
    text: str  # version texte, lisible partout (pas de HTML pour l'instant)
    attachments: tuple[Attachment, ...] = field(default=())


class EmailSendError(RuntimeError):
    """Le service d'envoi n'a pas pu envoyer (panne, refus) : l'envoi sera retenté plus tard."""


class EmailSender(Protocol):
    def send(self, message: EmailMessage) -> None:
        """Envoie le message. Lève `EmailSendError` en cas d'échec."""
        ...
