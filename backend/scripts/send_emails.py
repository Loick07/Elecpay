"""Envoie les e-mails en attente (récapitulatifs de paiement, reçu PDF joint).

Usage, depuis backend/ :
    python -m scripts.send_emails

À planifier toutes les minutes en production. Idempotent : un e-mail envoyé ne l'est jamais
deux fois, même si deux exécutions se chevauchent. En cas de panne du service d'envoi, l'e-mail
est retenté plus tard (1 min, 5 min, 15 min, 1 h, 3 h), puis abandonné.
"""

import sys

import app.db.models  # noqa: F401 — enregistre TOUTES les tables (clés étrangères des insertions)
from app.core.config import get_settings
from app.db.base import utcnow
from app.db.session import get_sessionmaker
from app.integrations.email.factory import get_email_sender
from app.modules.emails.receipts import send_pending_emails


def main() -> int:
    settings = get_settings()
    with get_sessionmaker()() as session:
        counts = send_pending_emails(session, get_email_sender(), settings, now=utcnow())
    print(
        f"E-mails : {counts['sent']} envoyé(s), {counts['retry']} à retenter, "
        f"{counts['failed']} abandonné(s)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
