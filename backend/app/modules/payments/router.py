"""Routes des paiements. Aucune logique ici : `PaymentService`, `PaymentHistory`, webhooks."""

from fastapi import APIRouter, Depends, Header, Query, Request, Response, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import Page, PageParams, page_params
from app.core.rate_limit import Limit, RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.payment_providers.base import PaymentProvider
from app.integrations.payment_providers.factory import get_payment_provider
from app.modules.auth.dependencies import current_user
from app.modules.payments.history import PaymentHistory
from app.modules.payments.models import TransactionStatus
from app.modules.payments.schemas import (
    IDEMPOTENCY_KEY_PATTERN,
    MONTH_PATTERN,
    PaymentCreate,
    PaymentPublic,
    WebhookAck,
)
from app.modules.payments.service import PaymentService
from app.modules.payments.views import payment_public
from app.modules.payments.webhooks import receive_webhook
from app.modules.users.models import User

router = APIRouter(prefix="/payments", tags=["Paiements"])
webhooks_router = APIRouter(prefix="/webhooks/payments", tags=["Paiements"])

# Demandes de paiement par compte : de quoi réessayer plusieurs fois, pas de harceler
# un numéro d'invites de code PIN.
PAYMENTS_PER_USER = Limit(10, 15 * 60)


@router.post(
    "",
    response_model=PaymentPublic,
    status_code=status.HTTP_201_CREATED,
    summary="Payer une facture en Mobile Money (le montant est celui de la facture)",
    description="En-tête `Idempotency-Key` obligatoire (8 à 64 caractères : lettres, chiffres, "
    "`-`, `_`), une nouvelle clé par tentative. Renvoyer la même demande avec la même clé "
    "(double clic, réseau coupé) rend la même transaction (`200`), sans second débit. "
    "Ensuite, suivre l'état avec `GET /payments/{id}`. Prestataire injoignable : la "
    "transaction est créée `echouee` avec son motif, et la facture reste payable.",
    responses={
        200: {"model": PaymentPublic, "description": "Même demande déjà reçue (même clé)"},
        403: {"model": ErrorResponse, "description": "Lecteur du foyer : ne peut pas payer"},
        404: {"model": ErrorResponse, "description": "Facture introuvable"},
        409: {
            "model": ErrorResponse,
            "description": "Facture payée ou annulée, paiement déjà en cours, clé déjà utilisée",
        },
        422: {"model": ErrorResponse, "description": "Numéro, opérateur ou clé invalides"},
        429: {"model": ErrorResponse, "description": "Trop de demandes de paiement"},
    },
)
def create_payment(
    data: PaymentCreate,
    response: Response,
    idempotency_key: str = Header(
        alias="Idempotency-Key",
        pattern=IDEMPOTENCY_KEY_PATTERN,
        description="Une clé par tentative",
    ),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    provider: PaymentProvider = Depends(get_payment_provider),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> PaymentPublic:
    limiter.consume(f"payment:user:{user.id}", PAYMENTS_PER_USER)
    initiated = PaymentService(db, provider, settings).initiate(
        user, data, idempotency_key, context
    )
    if not initiated.created:
        response.status_code = status.HTTP_200_OK
    return payment_public(db, initiated.transaction, user)


@router.get(
    "",
    response_model=Page[PaymentPublic],
    summary="Historique des paiements (écran 12), du plus récent au plus ancien",
    description="Paiements des factures de mes foyers (lecteurs compris) et mes propres "
    "paiements. Réussis, échoués (avec le motif), expirés et en cours ; `payer_name` dit "
    "qui a payé (titulaire ou payeur délégué). Filtres combinables : `status`, `bill_id`, "
    "`household_id`, `month` (AAAA-MM, heure de Brazzaville). Pagination : `page`, `size`.",
    responses={404: {"model": ErrorResponse, "description": "Foyer ou facture introuvable"}},
)
def list_payments(
    params: PageParams = Depends(page_params),
    status_filter: TransactionStatus | None = Query(default=None, alias="status"),
    bill_id: int | None = Query(default=None, ge=1),
    household_id: int | None = Query(default=None, ge=1),
    month: str | None = Query(
        default=None, pattern=MONTH_PATTERN, examples=["2026-10"], description="AAAA-MM"
    ),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Page[PaymentPublic]:
    return PaymentHistory(db).list(
        user,
        params,
        status=status_filter,
        bill_id=bill_id,
        household_id=household_id,
        month=month,
    )


@router.get(
    "/{payment_id}",
    response_model=PaymentPublic,
    summary="État d'un paiement (écran 9 « Confirmez sur votre téléphone »)",
    description="À interroger toutes les 2 à 3 secondes pendant l'attente. Une transaction en "
    "attente est vérifiée auprès du prestataire à chaque lecture ; sans code PIN au bout de "
    "10 minutes, elle expire et la facture redevient payable. `step` donne l'étape : "
    "`requested` → `pin_entered` → `succeeded` | `failed` | `expired`. Visible par le payeur "
    "et les membres du foyer (numéro masqué pour les autres).",
    responses={404: {"model": ErrorResponse, "description": "Paiement introuvable"}},
)
def get_payment(
    payment_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    provider: PaymentProvider = Depends(get_payment_provider),
) -> PaymentPublic:
    transaction = PaymentService(db, provider, settings).track(user, payment_id)
    return payment_public(db, transaction, user)


async def raw_body(request: Request) -> bytes:
    """Corps BRUT de la requête : la signature porte sur ces octets exacts."""
    return await request.body()


@webhooks_router.post(
    "/{provider}",
    response_model=WebhookAck,
    summary="Notification du prestataire de paiement (signée)",
    description="Réservée au prestataire : pas de jeton, mais une signature HMAC obligatoire "
    "(`X-ElecPay-Signature: t=<horodatage>,v1=<hmac>` pour le simulateur). Seule voie, avec "
    "le suivi d'état, qui peut confirmer un paiement. Une notification reçue deux fois ne "
    "change rien la seconde fois.",
    responses={
        400: {"model": ErrorResponse, "description": "Contenu invalide"},
        401: {"model": ErrorResponse, "description": "Signature absente, fausse ou trop ancienne"},
        404: {"model": ErrorResponse, "description": "Prestataire ou transaction inconnus"},
    },
)
def payment_webhook(
    provider: str,
    request: Request,
    body: bytes = Depends(raw_body),
    db: Session = Depends(get_db),
    payment_provider: PaymentProvider = Depends(get_payment_provider),
) -> WebhookAck:
    applied = receive_webhook(db, payment_provider, provider, dict(request.headers), body)
    return WebhookAck(transaction_status=applied.transaction.status, outcome=applied.outcome.value)
