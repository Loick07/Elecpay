"""Routes des écrans Transactions du back-office (A7, A8). Logique : `AdminTransactions`.

Aucune route ne fait passer une transaction à « réussie » : seule la relance de la
vérification interroge l'opérateur, dont la réponse passe par `apply_provider_update`.
"""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.errors import ErrorResponse
from app.core.pagination import PageParams, page_params
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.payment_providers.base import PaymentProvider
from app.integrations.payment_providers.factory import get_payment_provider
from app.modules.admin.permissions import Permission, admin_route
from app.modules.admin.transactions import AdminTransactions
from app.modules.admin.transactions_schemas import (
    AdminTransactionDetail,
    AdminTransactionList,
    DisputeCloseRequest,
    DisputeOpenRequest,
    DisputePublic,
    RecheckResult,
    TransactionFilter,
)
from app.modules.auth.dependencies import current_user
from app.modules.payments.models import MobileOperator
from app.modules.users.models import User

router = APIRouter(prefix="/transactions")
NOT_FOUND = {404: {"model": ErrorResponse, "description": "Transaction ou litige introuvable"}}
REFUSED = {409: {"model": ErrorResponse, "description": "Action impossible"}}


@admin_route(
    router,
    "GET",
    "",
    Permission.STAFF,
    response_model=AdminTransactionList,
    summary="Transactions (A7) : indicateurs du jour, filtres, numéros masqués",
    description="`status` : en_attente, reussie, echouee, expiree, to_reconcile (anomalie "
    "signalée par l'opérateur, sans litige clos), open_dispute. Recherche par TX-…, N° de "
    "facture, nom du payeur, référence opérateur ou numéro (au moins 3 chiffres). `day` : "
    "transactions lancées ce jour-là. Les plus récentes d'abord.",
)
def list_transactions(
    params: PageParams = Depends(page_params),
    q: str | None = Query(default=None, max_length=120),
    wanted: TransactionFilter | None = Query(default=None, alias="status"),
    operator: MobileOperator | None = Query(default=None),
    day: date | None = Query(default=None),
    db: Session = Depends(get_db),
) -> AdminTransactionList:
    return AdminTransactions(db).list(params, q=q, wanted=wanted, operator=operator, day=day)


@admin_route(
    router,
    "GET",
    "/{transaction_id}",
    Permission.STAFF,
    response_model=AdminTransactionDetail,
    summary="Détail et rapprochement d'une transaction (A8)",
    description="Comparaison ElecPay ↔ opérateur (d'après la dernière vérification par "
    "l'équipe), chronologie, clé d'idempotence, verrou de facture, anomalies signalées, "
    "litiges. Pas de bouton « Marquer comme payée » : il n'existe pas.",
    responses=NOT_FOUND,
)
def transaction_detail(
    transaction_id: int, db: Session = Depends(get_db)
) -> AdminTransactionDetail:
    return AdminTransactions(db).detail(transaction_id)


@admin_route(
    router,
    "POST",
    "/{transaction_id}/recheck",
    Permission.ADMIN,
    response_model=RecheckResult,
    summary="Relancer la vérification auprès de l'opérateur",
    description="Demande l'état du débit à l'opérateur et l'applique par le même chemin que "
    "les webhooks : un succès n'est enregistré que si l'opérateur le confirme (montant "
    "identique). Une réponse qui contredit une transaction terminée ne modifie rien et est "
    "signalée. 503 si l'opérateur ne répond pas (rien n'est modifié). Inscrit au journal.",
    responses=NOT_FOUND | REFUSED | {503: {"model": ErrorResponse, "description": "Opérateur"}},
)
def recheck_transaction(
    transaction_id: int,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
    provider: PaymentProvider = Depends(get_payment_provider),
) -> RecheckResult:
    return AdminTransactions(db).recheck(actor, transaction_id, provider, context)


@admin_route(
    router,
    "POST",
    "/{transaction_id}/disputes",
    Permission.ADMIN,
    response_model=DisputePublic,
    status_code=201,
    summary="Ouvrir un litige (le client affirme avoir été débité)",
    description="Motif d'au moins 10 caractères ; référence du SMS de débit facultative. Un "
    "seul litige ouvert par transaction. Ne change ni la transaction ni la facture. Inscrit "
    "au journal.",
    responses=NOT_FOUND | REFUSED,
)
def open_dispute(
    transaction_id: int,
    data: DisputeOpenRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> DisputePublic:
    return AdminTransactions(db).open_dispute(
        actor, transaction_id, data.reason, data.customer_reference, context
    )


@admin_route(
    router,
    "POST",
    "/{transaction_id}/disputes/{dispute_id}/close",
    Permission.ADMIN,
    response_model=DisputePublic,
    summary="Clore un litige avec la conclusion de l'opérateur",
    description="`resolution` : no_debit, refunded, debit_confirmed ; note d'au moins 10 "
    "caractères. La conclusion est enregistrée, jamais appliquée au paiement : un débit "
    "confirmé se régularise hors ElecPay. Un litige clos ne change plus. Inscrit au journal.",
    responses=NOT_FOUND | REFUSED,
)
def close_dispute(
    transaction_id: int,
    dispute_id: int,
    data: DisputeCloseRequest,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> DisputePublic:
    return AdminTransactions(db).close_dispute(
        actor, transaction_id, dispute_id, data.resolution, data.note, context
    )
