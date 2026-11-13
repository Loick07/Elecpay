"""Prestataires de paiement Mobile Money : une interface, plusieurs implémentations.

Aujourd'hui : `SimulatedPaymentProvider` (mode démo, aucun débit réel). Demain : MTN MoMo et
Airtel Money, choisis par `PAYMENT_PROVIDER`, avec exactement les mêmes trois actions :

- `initiate`      : demander le débit ; le payeur reçoit l'invite de code PIN sur son téléphone ;
- `check_status`  : demander au prestataire où en est un débit (suivi, relance par un admin) ;
- `verify_webhook`: vérifier qu'une notification reçue vient bien du prestataire (signature).

Le métier ne voit que ces types : il ne sait jamais quel prestataire est branché. Un succès
ne vient JAMAIS d'ailleurs que d'un `ProviderUpdate` rendu par l'une de ces actions.
"""

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from typing import Protocol

from fastapi import status

from app.core.errors import AppError


class ProviderState(StrEnum):
    """Où en est le débit, vu par le prestataire."""

    PENDING = "pending"  # invite envoyée, code PIN pas encore saisi
    PIN_ENTERED = "pin_entered"  # code PIN saisi, débit pas encore confirmé
    SUCCEEDED = "succeeded"  # débit confirmé
    FAILED = "failed"  # refusé (solde insuffisant, refus, PIN incorrect…)


@dataclass(frozen=True, slots=True)
class PaymentRequest:
    """Ce que le prestataire reçoit pour un débit (montant = celui de la facture)."""

    reference: str  # notre identifiant unique de la demande (clé d'idempotence)
    operator: str  # « mtn » ou « airtel »
    phone_number: str  # +242…
    amount: int  # FCFA
    initiated_at: datetime  # UTC
    description: str  # libellé affiché par l'opérateur (« Facture E²C 0412-8833 »)


@dataclass(frozen=True, slots=True)
class ProviderUpdate:
    """Nouvelles d'un débit, venues du prestataire (suivi ou webhook)."""

    provider_ref: str
    state: ProviderState
    occurred_at: datetime  # UTC
    amount: int | None = None  # montant débité annoncé par le prestataire, si connu
    failure_reason: str | None = None  # obligatoire si `state` = FAILED


class PaymentProvider(Protocol):
    name: str  # valeur de `payment_transactions.provider`

    def initiate(self, request: PaymentRequest) -> str:
        """Demande le débit. Renvoie la référence du prestataire.
        Lève `ProviderUnavailableError` si le prestataire ne répond pas."""
        ...

    def check_status(self, provider_ref: str, request: PaymentRequest) -> ProviderUpdate:
        """État actuel du débit. Lève `ProviderUnavailableError` si le prestataire ne répond pas."""
        ...

    def verify_webhook(self, headers: Mapping[str, str], body: bytes) -> ProviderUpdate:
        """Vérifie la signature d'une notification et la lit.
        Lève `InvalidWebhookError` (signature) ou `InvalidWebhookPayloadError` (contenu)."""
        ...


# --- Erreurs --------------------------------------------------------------------------------


class ProviderUnavailableError(AppError):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    code = "PAYMENT_PROVIDER_UNAVAILABLE"
    message = "Le service de paiement ne répond pas. Réessayez dans quelques instants."


class InvalidWebhookError(AppError):
    """Signature absente, fausse ou trop ancienne : la notification est ignorée."""

    status_code = status.HTTP_401_UNAUTHORIZED
    code = "WEBHOOK_SIGNATURE_INVALID"
    message = "Signature de la notification invalide."


class InvalidWebhookPayloadError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "WEBHOOK_PAYLOAD_INVALID"
    message = "Contenu de la notification invalide."
