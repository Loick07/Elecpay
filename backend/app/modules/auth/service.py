"""Service d'authentification : inscription et connexion. Ne connaît pas HTTP."""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime
from functools import cache

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.request_context import RequestContext
from app.core.security import hash_password, needs_rehash, verify_password
from app.db.base import utcnow
from app.modules.audit.service import record
from app.modules.auth.errors import (
    AccountDisabledError,
    EmailAlreadyUsedError,
    InsufficientRoleError,
    InvalidCredentialsError,
    PhoneAlreadyUsedError,
    TwoFactorChallengeInvalidError,
    TwoFactorCodeInvalidError,
)
from app.modules.auth.schemas import RegisterRequest
from app.modules.auth.sessions import IssuedTokens, SessionService
from app.modules.auth.tokens import create_challenge_token, decode_challenge_token
from app.modules.auth.two_factor import TEAM_ROLES, TwoFactorService
from app.modules.users.models import User, UserRole

CHALLENGE_MINUTES = 5


@dataclass(frozen=True, slots=True)
class PendingTwoFactor:
    """Mot de passe correct, code de double authentification attendu (étape 2)."""

    challenge_token: str
    expires_at: datetime


@cache
def _dummy_hash() -> str:
    """Empreinte factice : vérifiée quand le numéro est inconnu, pour que la réponse prenne
    le même temps qu'un mauvais mot de passe (on ne devine pas un numéro au chronomètre)."""
    return hash_password("mot-de-passe-factice-jamais-utilise-1")


class AuthService:
    def __init__(
        self, session: Session, settings: Settings, now: Callable[[], datetime] = utcnow
    ) -> None:
        self.session = session
        self.settings = settings
        self.sessions = SessionService(session, settings, now)
        self.now = now

    def register(self, data: RegisterRequest, user_agent: str | None = None) -> IssuedTokens:
        """Crée un compte client et ouvre sa première session."""
        if self._find_by_phone(data.phone) is not None:
            raise PhoneAlreadyUsedError()
        if data.email is not None and self._find_by_email(data.email) is not None:
            raise EmailAlreadyUsedError()
        user = User(
            full_name=data.full_name,
            phone=data.phone,
            email=data.email,
            password_hash=hash_password(data.password),
            role=UserRole.CLIENT,  # jamais choisi par la personne qui s'inscrit
            last_login_at=self.now(),
        )
        self.session.add(user)
        try:
            self.session.flush()
        except IntegrityError as error:  # inscription simultanée avec le même numéro / e-mail
            self.session.rollback()
            if "uq_users_email" in str(error.orig):
                raise EmailAlreadyUsedError() from error
            raise PhoneAlreadyUsedError() from error
        issued = self.sessions.open_session(user, user_agent)
        self.session.commit()
        return issued

    def login(
        self,
        phone: str,
        password: str,
        user_agent: str | None = None,
        allowed_roles: frozenset[UserRole] | None = None,
        context: RequestContext | None = None,
    ) -> IssuedTokens | PendingTwoFactor:
        """Vérifie téléphone + mot de passe et ouvre une session.

        `allowed_roles` : restreint la connexion (ex. back-office réservé à l'équipe). Le refus
        n'intervient qu'après un mot de passe correct, et aucune session n'est alors ouverte.
        Membre de l'équipe avec la 2FA active : PAS de session, mais un défi (`PendingTwoFactor`)
        à compléter avec un code (`complete_two_factor`). Connexions de l'équipe au journal.
        """
        user = self._find_by_phone(phone)
        if user is None:
            verify_password(password, _dummy_hash())  # même durée qu'un mauvais mot de passe
            raise InvalidCredentialsError()
        if not verify_password(password, user.password_hash):
            if user.role in TEAM_ROLES:
                self._audit("team.login_failed", user, context, step="password")
                self.session.commit()
            raise InvalidCredentialsError()
        # « Désactivé » n'est révélé qu'à quelqu'un qui connaît le mot de passe.
        if not user.is_active:
            raise AccountDisabledError()
        if allowed_roles is not None and user.role not in allowed_roles:
            raise InsufficientRoleError("Cet espace est réservé à l'équipe ElecPay.")
        if needs_rehash(user.password_hash):  # paramètres Argon2 renforcés depuis : on met à jour
            user.password_hash = hash_password(password)
        if user.role in TEAM_ROLES and TwoFactorService(self.session, self.settings).is_enabled(
            user
        ):
            token, expires_at = create_challenge_token(
                user.id,
                secret=self.settings.jwt_secret.get_secret_value(),
                minutes=CHALLENGE_MINUTES,
                now=self.now(),
            )
            self.session.commit()
            return PendingTwoFactor(challenge_token=token, expires_at=expires_at)
        return self._open(user, user_agent, context, method="password")

    def complete_two_factor(
        self,
        challenge_token: str,
        code: str,
        user_agent: str | None = None,
        allowed_roles: frozenset[UserRole] | None = None,
        context: RequestContext | None = None,
    ) -> IssuedTokens:
        """Étape 2 : défi valide (5 min) + code de l'application ou code de secours."""
        user_id = decode_challenge_token(
            challenge_token, secret=self.settings.jwt_secret.get_secret_value()
        )
        user = self.session.get(User, user_id)
        if user is None or user.role not in TEAM_ROLES:
            raise TwoFactorChallengeInvalidError()
        if not user.is_active:
            raise AccountDisabledError()
        if allowed_roles is not None and user.role not in allowed_roles:
            raise InsufficientRoleError("Cet espace est réservé à l'équipe ElecPay.")
        try:
            method = TwoFactorService(self.session, self.settings, self.now).verify_login(
                user, code
            )
        except TwoFactorCodeInvalidError:
            self._audit("team.two_factor_failed", user, context)
            self.session.commit()
            raise
        return self._open(user, user_agent, context, method=f"password+{method}")

    def _open(
        self, user: User, user_agent: str | None, context: RequestContext | None, *, method: str
    ) -> IssuedTokens:
        user.last_login_at = self.now()
        issued = self.sessions.open_session(user, user_agent)
        if user.role in TEAM_ROLES:
            self._audit("team.login", user, context, method=method)
        self.session.commit()
        return issued

    def _audit(self, action: str, user: User, context: RequestContext | None, **after) -> None:
        record(
            self.session,
            action=action,
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            context=context,
            after=after or None,
        )

    def refresh(self, refresh_token: str, user_agent: str | None = None) -> IssuedTokens:
        """Nouvelle paire de jetons (rotation). Réutilisation → toute la famille révoquée."""
        issued = self.sessions.rotate(refresh_token, user_agent)
        self.session.commit()
        return issued

    def logout(self, refresh_token: str) -> None:
        """Ferme la session de cet appareil. Toujours possible, même avec un jeton invalide."""
        self.sessions.close_session(refresh_token)
        self.session.commit()

    def logout_everywhere(self, user: User) -> int:
        """Ferme les sessions de tous les appareils. Renvoie le nombre de jetons révoqués."""
        revoked = self.sessions.close_all_sessions(user.id)
        self.session.commit()
        return revoked

    def _find_by_phone(self, phone: str) -> User | None:
        return self.session.scalars(select(User).where(User.phone == phone)).first()

    def _find_by_email(self, email: str) -> User | None:
        return self.session.scalars(select(User).where(User.email == email)).first()
