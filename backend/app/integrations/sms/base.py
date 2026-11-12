"""Envoi de SMS : une interface, plusieurs implémentations choisies par configuration.

Aujourd'hui : `SimulatedSmsSender` (aucun SMS réel). Demain : un vrai fournisseur
(opérateur local ou agrégateur) qui implémentera la même méthode `send`.
"""

from typing import Protocol


class SmsSender(Protocol):
    def send(self, phone: str, message: str) -> None:
        """Envoie `message` au numéro `phone` (format +242…). Lève une exception en cas d'échec."""
        ...
