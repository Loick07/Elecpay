"""Routes des reçus. Aucune logique ici : `ReceiptQueries` et `verify_receipt`."""

from fastapi import APIRouter, Depends, Path, Query, Response
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.pagination import Page, PageParams, page_params
from app.core.rate_limit import Limit, RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.auth.dependencies import current_user
from app.modules.receipts.queries import ReceiptQueries
from app.modules.receipts.schemas import ReceiptPublic, ReceiptVerification
from app.modules.receipts.verification import verify_receipt
from app.modules.users.models import User

router = APIRouter(prefix="/receipts", tags=["Reçus"])

# Vérification publique : largement assez pour un usage normal (QR code scanné plusieurs
# fois), bien trop peu pour essayer des codes au hasard.
VERIFICATIONS_PER_IP = Limit(30, 15 * 60)


@router.get(
    "",
    response_model=Page[ReceiptPublic],
    summary="Mes reçus, du plus récent au plus ancien",
    description="Reçus des paiements des factures de mes foyers (lecteurs compris) et de mes "
    "propres paiements. Filtres : `household_id`, `year` (année d'émission, heure de "
    "Brazzaville). Pagination : `page`, `size`.",
    responses={404: {"model": ErrorResponse, "description": "Foyer introuvable"}},
)
def list_receipts(
    params: PageParams = Depends(page_params),
    household_id: int | None = Query(default=None, ge=1),
    year: int | None = Query(default=None, ge=2000, le=2100),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Page[ReceiptPublic]:
    return ReceiptQueries(db).list(user, params, household_id=household_id, year=year)


# Déclarée AVANT « /{receipt_id}… » : « /verify/pdf » ne doit jamais être pris pour un reçu.
@router.get(
    "/verify/{code}",
    response_model=ReceiptVerification,
    summary="Vérification PUBLIQUE d'un reçu (sans connexion)",
    description="Avec le code imprimé sur le reçu (ou lu dans son QR code), avec ou sans "
    "tirets. Ne montre que le minimum : numéro, date, montant, période, compteur masqué, "
    "mode démo — ni nom, ni numéro de téléphone. Code inconnu : 404. Nombre de "
    "vérifications limité par adresse IP.",
    responses={
        404: {"model": ErrorResponse, "description": "Aucun reçu ne porte ce code"},
        429: {"model": ErrorResponse, "description": "Trop de vérifications"},
    },
)
def verify(
    code: str = Path(max_length=40),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> ReceiptVerification:
    limiter.consume(f"receipt-verify:ip:{context.ip or 'inconnue'}", VERIFICATIONS_PER_IP)
    return verify_receipt(db, code)


@router.get(
    "/{receipt_id}",
    response_model=ReceiptPublic,
    summary="Un reçu (écran 10) : montant, facture, payeur, code de vérification",
    description="Le numéro débité est toujours masqué : un reçu est fait pour être partagé.",
    responses={404: {"model": ErrorResponse, "description": "Reçu introuvable"}},
)
def get_receipt(
    receipt_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> ReceiptPublic:
    return ReceiptQueries(db).detail(user, receipt_id)


@router.get(
    "/{receipt_id}/pdf",
    response_class=Response,
    summary="Reçu en PDF (bouton « Télécharger » / « Partager » de l'écran 10)",
    description="Mêmes accès que le détail. QR code et code de vérification menant à la "
    "vérification publique ; bandeau « Mode démo » si le paiement est simulé. "
    "Généré à la demande (`Content-Disposition: attachment`).",
    responses={
        200: {"content": {"application/pdf": {}}, "description": "Le fichier PDF"},
        404: {"model": ErrorResponse, "description": "Reçu introuvable"},
    },
)
def receipt_pdf(
    receipt_id: int,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> Response:
    filename, content = ReceiptQueries(db).pdf(
        user,
        receipt_id,
        demo_mode=settings.demo_mode,
        verify_base_url=settings.receipt_verify_url,
    )
    return Response(
        content=content,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Cache-Control": "private, no-store",
        },
    )
