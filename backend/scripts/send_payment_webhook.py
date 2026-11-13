"""Envoie à l'API locale un webhook signé, comme le ferait le prestataire simulé (démo, tests).

Usage, depuis backend/ (API lancée, PAYMENT_WEBHOOK_SECRET renseigné dans .env) :
    python -m scripts.send_payment_webhook 162                      # débit confirmé
    python -m scripts.send_payment_webhook 162 --state failed --reason "Solde insuffisant"
    python -m scripts.send_payment_webhook 162 --state pin_entered
    python -m scripts.send_payment_webhook 162 --url http://127.0.0.1:8765

Refuse de tourner en production ou hors du prestataire simulé.
"""

import argparse
import json
import sys
import urllib.error
import urllib.request

from app.core.config import API_PREFIX, Settings, get_settings
from app.db.base import utcnow
from app.db.session import get_sessionmaker
from app.integrations.payment_providers.base import ProviderState, ProviderUpdate
from app.integrations.payment_providers.simulated import SimulatedPaymentProvider
from app.modules.payments.models import PaymentTransaction


def refusal_reason(settings: Settings) -> str | None:
    if settings.is_production:
        return "Refusé : APP_ENV=production."
    if settings.payment_provider != "simulated":
        return "Refusé : prestataire simulé uniquement (PAYMENT_PROVIDER=simulated)."
    if not settings.payment_webhook_secret.get_secret_value():
        return "PAYMENT_WEBHOOK_SECRET est vide dans .env : l'API refuserait la notification."
    return None


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Webhook de paiement simulé et signé")
    parser.add_argument("transaction_id", type=int)
    parser.add_argument(
        "--state", choices=[s.value for s in ProviderState], default=ProviderState.SUCCEEDED.value
    )
    parser.add_argument("--reason", default="Solde insuffisant", help="motif d'un échec")
    parser.add_argument("--url", default="http://127.0.0.1:8000", help="adresse de l'API")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    settings = get_settings()
    reason = refusal_reason(settings)
    if reason:
        print(reason, file=sys.stderr)
        return 1
    with get_sessionmaker()() as session:
        transaction = session.get(PaymentTransaction, args.transaction_id)
        if transaction is None or transaction.provider_ref is None:
            print("Transaction introuvable (ou sans référence prestataire).", file=sys.stderr)
            return 1
        state = ProviderState(args.state)
        update = ProviderUpdate(
            provider_ref=transaction.provider_ref,
            state=state,
            occurred_at=utcnow(),
            amount=transaction.amount if state is ProviderState.SUCCEEDED else None,
            failure_reason=args.reason if state is ProviderState.FAILED else None,
        )
    if not args.url.startswith(("http://", "https://")):
        print("L'adresse de l'API doit commencer par http:// ou https://", file=sys.stderr)
        return 1
    provider = SimulatedPaymentProvider(settings.payment_webhook_secret.get_secret_value())
    headers, body = provider.signed_webhook(update)
    request = urllib.request.Request(  # noqa: S310 (schéma http(s) vérifié ci-dessus)
        f"{args.url}{API_PREFIX}/webhooks/payments/{provider.name}",
        data=body,
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=10) as response:  # noqa: S310
            print(response.status, json.loads(response.read()))
    except urllib.error.HTTPError as error:
        print(error.code, json.loads(error.read()), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
