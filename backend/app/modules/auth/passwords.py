"""Mot de passe : réinitialisation par code SMS et changement depuis le compte.

Ne connaît pas HTTP. Chaque réinitialisation ou changement :
- déconnecte les appareils (toutes les sessions sont révoquées) ;
- laisse une trace dans le journal d'audit (sans aucune donnée secrète).
"""

import hashlib
import hmac
import secrets
from collections.abc import Callable
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.request_context import RequestContext
from app.core.security import hash_password, verify_password
from app.db.base import utcnow
from app.integrations.sms.base import SmsSender
from app.modules.audit.service import record
from app.modules.auth.errors import (
    ResetCodeInvalidError,
    SamePasswordError,
    WrongCurrentPasswordError,
)
from app.modules.auth.models import RESET_CODE_MAX_ATTEMPTS, PasswordResetCode
from app.modules.auth.sessions import IssuedTokens, SessionService
from app.modules.users.models import User

RESET_CODE_DIGITS = 6
RESET_CODE_TTL = timedelta(minutes=10)


def generate_reset_code() -> str:
    """Code à 6 chiffres tiré avec `secrets` (imprévisible), ex. « 048213 »."""
    return f"{secrets.randbelow(10**RESET_CODE_DIGITS):0{RESET_CODE_DIGITS}d}"


def reset_code_hash(secret: str, user_id: int, code: str) -> str:
    """Empreinte HMAC-SHA256 liée au compte : le même code n'a pas la même empreinte
    pour deux comptes, et sans la clé du serveur on ne peut rien retrouver."""
    message = f"password-reset:{user_id}:{code}".encode()
    return hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()


def reset_sms(code: str) -> str:
    minutes = int(RESET_CODE_TTL.total_seconds() // 60)
    return (
        f"ElecPay : votre code de réinitialisation est {code}. "
        f"Il expire dans {minutes} minutes. Ne le communiquez à personne."
    )


class PasswordService:
    def __init__(
        self,
        session: Session,
        settings: Settings,
        sms: SmsSender,
        now: Callable[[], datetime] = utcnow,
    ) -> None:
        self.session = session
        self.secret = settings.jwt_secret.get_secret_value()
        self.sms = sms
        self.now = now
        self.sessions = SessionService(session, settings, now)

    # --- Mot de passe oublié --------------------------------------------------------

    def request_reset(self, phone: str) -> str | None:
        """Envoie un code par SMS. Renvoie le code (affiché en mode démo) ou None si aucun
        compte actif n'a ce numéro — la réponse de l'API, elle, est la même dans les deux cas."""
        user = self._find_by_phone(phone)
        if user is None or not user.is_active:
            return None
        now = self.now()
        # Un seul code valable à la fois : demander un nouveau code annule le précédent.
        self.session.execute(
            update(PasswordResetCode)
            .where(
                PasswordResetCode.user_id == user.id,
                PasswordResetCode.used_at.is_(None),
                PasswordResetCode.invalidated_at.is_(None),
            )
            .values(invalidated_at=now)
        )
        code = generate_reset_code()
        self.session.add(
            PasswordResetCode(
                user_id=user.id,
                code_hash=reset_code_hash(self.secret, user.id, code),
                expires_at=now + RESET_CODE_TTL,
                created_at=now,
                updated_at=now,
            )
        )
        self.session.flush()
        self.sms.send(user.phone, reset_sms(code))
        self.session.commit()
        return code

    def reset(
        self, phone: str, code: str, new_password: str, context: RequestContext | None = None
    ) -> None:
        """Change le mot de passe avec le code reçu, puis déconnecte tous les appareils."""
        user = self._find_by_phone(phone)
        if user is None or not user.is_active:
            raise ResetCodeInvalidError()
        now = self.now()
        pending = self.session.scalars(
            select(PasswordResetCode)
            .where(
                PasswordResetCode.user_id == user.id,
                PasswordResetCode.used_at.is_(None),
                PasswordResetCode.invalidated_at.is_(None),
                PasswordResetCode.expires_at > now,
            )
            .order_by(PasswordResetCode.id.desc())
            .limit(1)
            .with_for_update()  # deux essais simultanés ne peuvent pas contourner le compteur
        ).first()
        if pending is None:
            raise ResetCodeInvalidError()

        expected = reset_code_hash(self.secret, user.id, code)
        if not hmac.compare_digest(pending.code_hash, expected):  # comparaison à temps constant
            pending.attempts += 1
            if pending.attempts >= RESET_CODE_MAX_ATTEMPTS:
                pending.invalidated_at = now  # trop d'essais : il faut un nouveau code
            self.session.commit()  # le compteur d'essais doit survivre à l'erreur
            raise ResetCodeInvalidError()

        pending.used_at = now
        user.password_hash = hash_password(new_password)
        closed = self.sessions.close_all_sessions(user.id)
        record(
            self.session,
            action="user.password_reset",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            context=context,
            after={"sessions_closed": closed},
        )
        self.session.commit()

    # --- Changement depuis le compte ------------------------------------------------

    def change(
        self,
        user: User,
        current_password: str,
        new_password: str,
        context: RequestContext | None = None,
    ) -> IssuedTokens:
        """Change le mot de passe ; les AUTRES appareils sont déconnectés, celui-ci reçoit
        une nouvelle paire de jetons."""
        if not verify_password(current_password, user.password_hash):
            raise WrongCurrentPasswordError()
        if verify_password(new_password, user.password_hash):
            raise SamePasswordError()
        user.password_hash = hash_password(new_password)
        closed = self.sessions.close_all_sessions(user.id)
        issued = self.sessions.open_session(user, context.user_agent if context else None)
        record(
            self.session,
            action="user.password_change",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            context=context,
            after={"sessions_closed": closed},
        )
        self.session.commit()
        return issued

    def _find_by_phone(self, phone: str) -> User | None:
        return self.session.scalars(select(User).where(User.phone == phone)).first()
