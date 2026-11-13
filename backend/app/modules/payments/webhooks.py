"""Réception des webhooks du prestataire de paiement (B7.3).

1. le prestataire de l'URL doit être celui configuré (sinon 404) ;
2. la signature est vérifiée par le prestataire lui-même (`verify_webhook`) : une notification
   non signée, mal signée ou trop ancienne est refusée (401) avant toute lecture en base ;
3. la transaction est retrouvée par (prestataire, référence du prestataire) ;
4. la nouvelle est appliquée par `apply_provider_update`, comme pour un suivi d'état.
Une notification reçue deux fois ne change rien la seconde fois.
"""

from collections.abc import Callable, Mapping
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.base import utcnow
from app.integrations.payment_providers.base import PaymentProvider
from app.modules.payments.confirmation import Applied, apply_provider_update
from app.modules.payments.errors import PaymentNotFoundError, UnknownPaymentProviderError
from app.modules.payments.models import PaymentProvider as ProviderName
from app.modules.payments.models import PaymentTransaction


def receive_webhook(
    session: Session,
    provider: PaymentProvider,
    provider_in_url: str,
    headers: Mapping[str, str],
    body: bytes,
    now: Callable[[], datetime] = utcnow,
) -> Applied:
    if provider_in_url != provider.name:
        raise UnknownPaymentProviderError()
    update = provider.verify_webhook(headers, body)
    transaction_id = session.scalar(
        select(PaymentTransaction.id).where(
            PaymentTransaction.provider == ProviderName(provider.name),
            PaymentTransaction.provider_ref == update.provider_ref,
        )
    )
    if transaction_id is None:
        raise PaymentNotFoundError()
    applied = apply_provider_update(session, transaction_id, update, origin="webhook", now=now())
    session.commit()
    return applied
