"""Routes de vérification de l'adresse e-mail (B11.4). Logique : `EmailVerificationService`."""

from datetime import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.rate_limit import Limit, RateLimiter, get_rate_limiter
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.email.base import EmailSender
from app.integrations.email.factory import get_email_sender
from app.modules.auth.dependencies import current_user
from app.modules.emails.verification import EmailVerificationService
from app.modules.users.models import User
from app.modules.users.schemas import UserPublic

router = APIRouter(prefix="/me/email", tags=["Mon compte"])
CODES_PER_USER = Limit(3, 3600)  # chaque code part par e-mail : pas d'envoi en rafale


class VerificationSent(BaseModel):
    sent_to: str = Field(description="Adresse masquée", examples=["g***@example.com"])
    expires_at: datetime
    demo_code: str | None = Field(
        description="Mode démo seulement (aucun e-mail réel ne part) : le code envoyé"
    )


class VerificationConfirm(BaseModel):
    model_config = ConfigDict(extra="forbid")

    code: str = Field(pattern=r"^[0-9]{6}$", examples=["048213"])


@router.post(
    "/verification",
    response_model=VerificationSent,
    summary="Recevoir un code pour vérifier mon adresse e-mail",
    description="Code à 6 chiffres envoyé à l'adresse du profil, valable 15 minutes ; un nouveau "
    "code annule le précédent. 3 demandes par heure. Une adresse vérifiée reçoit les reçus.",
    responses={
        409: {"model": ErrorResponse, "description": "Pas d'e-mail, ou déjà vérifié"},
        429: {"model": ErrorResponse, "description": "Trop de demandes"},
        503: {"model": ErrorResponse, "description": "Envoi d'e-mails indisponible"},
    },
)
def request_verification(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    sender: EmailSender = Depends(get_email_sender),
    limiter: RateLimiter = Depends(get_rate_limiter),
) -> VerificationSent:
    limiter.consume(f"email-verify:user:{user.id}", CODES_PER_USER)
    sent = EmailVerificationService(db, settings, sender).request(user)
    return VerificationSent(
        sent_to=sent.sent_to, expires_at=sent.expires_at, demo_code=sent.demo_code
    )


@router.post(
    "/verification/confirm",
    response_model=UserPublic,
    summary="Confirmer mon adresse e-mail avec le code reçu",
    description="5 essais par code. Renvoie le profil avec `email_verified_at`.",
    responses={
        400: {"model": ErrorResponse, "description": "Code invalide ou expiré"},
        409: {"model": ErrorResponse, "description": "Déjà vérifiée"},
    },
)
def confirm_verification(
    data: VerificationConfirm,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    sender: EmailSender = Depends(get_email_sender),
    context: RequestContext = Depends(request_context),
) -> User:
    return EmailVerificationService(db, settings, sender).confirm(user, data.code, context)
