"""Fait le point sur tous les paiements en attente : état chez le prestataire, expirations.

Usage, depuis backend/ :
    python -m scripts.check_pending_payments

À planifier toutes les minutes en production (le suivi de l'écran 9 le fait déjà pour le
paiement qu'on regarde ; cette commande s'occupe de ceux que personne ne regarde plus).
Idempotent. Une transaction à la fois : un problème sur l'une n'arrête pas les autres.
"""

import sys
from collections import Counter

from sqlalchemy.orm import Session

import app.db.models  # noqa: F401 — enregistre TOUTES les tables (clés étrangères des insertions)
from app.core.config import get_settings
from app.db.base import utcnow
from app.db.session import get_sessionmaker
from app.integrations.payment_providers.factory import get_payment_provider
from app.modules.payments.models import TransactionStatus
from app.modules.payments.tracking import pending_transaction_ids, refresh_transaction


def check_pending(session: Session, provider, now) -> Counter:
    """Statut de chaque transaction en attente après le point (compteur par statut).
    Validée transaction par transaction : un problème sur l'une n'annule pas les autres."""
    counts: Counter = Counter()
    for transaction_id in pending_transaction_ids(session):
        transaction = refresh_transaction(session, provider, transaction_id, now=now)
        counts[transaction.status] += 1
        session.commit()
    return counts


def main() -> int:
    settings = get_settings()
    with get_sessionmaker()() as session:
        counts = check_pending(session, get_payment_provider(settings), utcnow())
    total = sum(counts.values())
    print(f"Paiements en attente vérifiés : {total}")
    for status in TransactionStatus:
        if counts[status]:
            print(f"  {status.value:<12} {counts[status]:>5}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
