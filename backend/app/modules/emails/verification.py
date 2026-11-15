"""Vérification de l'adresse e-mail (B11.4) : un code à 6 chiffres envoyé à cette adresse.

Même principe que le code SMS du mot de passe oublié : empreinte HMAC seulement, 15 minutes,
5 essais, un seul code valable à la fois. Le code ne vaut que pour l'adresse à laquelle il a été
envoyé. En mode démo (aucun e-mail réel ne part), l'API renvoie aussi le code dans sa réponse.
"""

import hashlib
import hmac
import secrets
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta

from fastapi import status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import AppError
from app.core.request_context import RequestContext
from app.core.validation import mask_email
from app.db.base import utcnow
from app.integrations.email.base import EmailMessage, EmailSender, EmailSendError
from app.modules.audit.service import record
from app.modules.emails.models import VERIFICATION_MAX_ATTEMPTS, EmailVerificationCode
from app.modules.users.models import User

CODE_TTL = timedelta(minutes=15)


class EmailMissingError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "EMAIL_MISSING"
    message = "Ajoutez d'abord une adresse e-mail à votre profil."


class EmailAlreadyVerifiedError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "EMAIL_ALREADY_VERIFIED"
    message = "Cette adresse e-mail est déjà vérifiée."


class EmailCodeInvalidError(AppError):
    """Code faux, expiré, déjà utilisé, trop d'essais ou adresse changée : une seule erreur."""

    status_code = status.HTTP_400_BAD_REQUEST
    code = "EMAIL_CODE_INVALID"
    message = "Code invalide ou expiré. Demandez un nouveau code."


class EmailUnavailableError(AppError):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    code = "EMAIL_UNAVAILABLE"
    message = "L'envoi d'e-mails ne répond pas. Réessayez dans quelques minutes."


def verification_code_hash(secret: str, user_id: int, email: str, code: str) -> str:
    message = f"email-verification:{user_id}:{email}:{code}".encode()
    return hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()


def verification_email(user: User, code: str) -> EmailMessage:
    minutes = int(CODE_TTL.total_seconds() // 60)
    return EmailMessage(
        to=user.email,
        subject="ElecPay : votre code de vérification",
        text=(
            f"Bonjour {user.full_name},\n\n"
            f"Votre code pour vérifier cette adresse e-mail est : {code}\n"
            f"Il expire dans {minutes} minutes.\n\n"
            "Une fois l'adresse vérifiée, vous recevrez vos reçus de paiement par e-mail.\n"
            "Si vous n'avez rien demandé, ignorez ce message.\n\n"
            "L'équipe ElecPay"
        ),
    )


@dataclass(frozen=True, slots=True)
class CodeSent:
    sent_to: str  # adresse masquée
    expires_at: datetime
    demo_code: str | None  # seulement en mode démo


class EmailVerificationService:
    def __init__(
        self,
        session: Session,
        settings: Settings,
        sender: EmailSender,
        now: Callable[[], datetime] = utcnow,
    ) -> None:
        self.session = session
        self.settings = settings
        self.sender = sender
        self.secret = settings.jwt_secret.get_secret_value()
        self.now = now

    def request(self, user: User) -> CodeSent:
        if not user.email:
            raise EmailMissingError()
        if user.email_verified_at is not None:
            raise EmailAlreadyVerifiedError()
        now = self.now()
        code = f"{secrets.randbelow(1_000_000):06d}"
        try:  # d'abord l'envoi : en cas de panne, rien n'est enregistré ni invalidé
            self.sender.send(verification_email(user, code))
        except EmailSendError as error:
            raise EmailUnavailableError() from error
        self._invalidate_pending(user, now)
        self.session.add(
            EmailVerificationCode(
                user_id=user.id,
                email=user.email,
                code_hash=verification_code_hash(self.secret, user.id, user.email, code),
                expires_at=now + CODE_TTL,
                created_at=now,
                updated_at=now,
            )
        )
        self.session.commit()
        return CodeSent(
            sent_to=mask_email(user.email),
            expires_at=now + CODE_TTL,
            demo_code=code if self.settings.demo_mode else None,
        )

    def confirm(self, user: User, code: str, context: RequestContext | None) -> User:
        if user.email_verified_at is not None:
            raise EmailAlreadyVerifiedError()
        now = self.now()
        pending = self.session.scalars(
            select(EmailVerificationCode)
            .where(
                EmailVerificationCode.user_id == user.id,
                EmailVerificationCode.used_at.is_(None),
                EmailVerificationCode.invalidated_at.is_(None),
            )
            .order_by(EmailVerificationCode.id.desc())
            .limit(1)
            .with_for_update()
        ).first()
        usable = (
            pending is not None
            and pending.expires_at > now
            and pending.email == user.email  # l'adresse n'a pas changé depuis l'envoi
        )
        if not usable:
            raise EmailCodeInvalidError()
        expected = verification_code_hash(self.secret, user.id, pending.email, code.strip())
        if not hmac.compare_digest(pending.code_hash, expected):
            pending.attempts += 1
            if pending.attempts >= VERIFICATION_MAX_ATTEMPTS:
                pending.invalidated_at = now
            self.session.commit()
            raise EmailCodeInvalidError()
        pending.used_at = now
        user.email_verified_at = now
        record(
            self.session,
            action="user.email_verified",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            context=context,
            after={"email": mask_email(user.email)},
        )
        self.session.commit()
        return user

    def _invalidate_pending(self, user: User, now: datetime) -> None:
        self.session.execute(
            update(EmailVerificationCode)
            .where(
                EmailVerificationCode.user_id == user.id,
                EmailVerificationCode.used_at.is_(None),
                EmailVerificationCode.invalidated_at.is_(None),
            )
            .values(invalidated_at=now)
        )
