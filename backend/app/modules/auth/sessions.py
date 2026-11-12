"""Sessions : ouverture, rotation, détection de réutilisation et fermeture.

Une « famille » = tous les jetons de rafraîchissement issus d'une même connexion.
À chaque rafraîchissement, le jeton présenté est révoqué et remplacé (rotation).
Si un jeton DÉJÀ révoqué est présenté, quelqu'un l'a probablement volé et utilisé :
toute la famille est révoquée (le voleur ET l'utilisateur doivent se reconnecter).

Ce service ne connaît pas HTTP. Il valide lui-même (commit) les révocations de sécurité
avant de lever l'erreur, pour qu'elles ne soient jamais annulées par un rollback.
"""

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.db.base import utcnow
from app.modules.auth.errors import (
    AccountDisabledError,
    RefreshTokenReusedError,
    TokenExpiredError,
    TokenInvalidError,
)
from app.modules.auth.models import RefreshToken
from app.modules.auth.tokens import create_access_token, hash_refresh_token, new_refresh_token
from app.modules.users.models import User

USER_AGENT_MAX_LENGTH = 255


@dataclass(frozen=True, slots=True)
class IssuedTokens:
    """Ce que reçoit le client après connexion ou rafraîchissement."""

    user: User
    access_token: str
    access_expires_at: datetime
    refresh_token: str  # en clair : remis UNE fois au client, jamais stocké
    refresh_expires_at: datetime


class SessionService:
    def __init__(
        self, session: Session, settings: Settings, now: Callable[[], datetime] = utcnow
    ) -> None:
        self.session = session
        self.settings = settings
        self.now = now

    # --- Ouverture ------------------------------------------------------------------

    def open_session(self, user: User, user_agent: str | None = None) -> IssuedTokens:
        """Nouvelle connexion : nouvelle famille de jetons."""
        issued, _ = self._issue(user, family_id=str(uuid.uuid4()), user_agent=user_agent)
        return issued

    # --- Rotation -------------------------------------------------------------------

    def rotate(self, refresh_token: str, user_agent: str | None = None) -> IssuedTokens:
        """Échange un jeton de rafraîchissement valide contre une nouvelle paire de jetons."""
        current = self.session.scalars(
            select(RefreshToken)
            .where(RefreshToken.token_hash == hash_refresh_token(refresh_token))
            .with_for_update()  # deux rafraîchissements simultanés ne tournent pas en double
        ).first()
        if current is None:
            raise TokenInvalidError()

        now = self.now()
        if current.revoked_at is not None:
            self._revoke_family_and_commit(current.family_id, now)
            raise RefreshTokenReusedError()
        if current.expires_at <= now:
            raise TokenExpiredError()

        user = self.session.get(User, current.user_id)
        if user is None or not user.is_active:
            self._revoke_family_and_commit(current.family_id, now)
            raise AccountDisabledError()

        issued, replacement = self._issue(user, family_id=current.family_id, user_agent=user_agent)
        current.revoked_at = now
        current.replaced_by_id = replacement.id
        self.session.flush()
        return issued

    # --- Fermeture ------------------------------------------------------------------

    def close_session(self, refresh_token: str) -> None:
        """Déconnexion : révoque la famille du jeton. Sans effet si le jeton est inconnu."""
        current = self.session.scalars(
            select(RefreshToken).where(RefreshToken.token_hash == hash_refresh_token(refresh_token))
        ).first()
        if current is not None:
            self._revoke_family(current.family_id, self.now())

    def close_all_sessions(self, user_id: int) -> int:
        """Déconnecte tous les appareils d'un compte. Renvoie le nombre de jetons révoqués."""
        result = self.session.execute(
            update(RefreshToken)
            .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=self.now())
        )
        return result.rowcount

    # --- Interne --------------------------------------------------------------------

    def _issue(
        self, user: User, *, family_id: str, user_agent: str | None
    ) -> tuple[IssuedTokens, RefreshToken]:
        """Crée une paire de jetons ; renvoie aussi la ligne `refresh_tokens` créée."""
        now = self.now()
        access_token, access_expires_at = create_access_token(
            user.id,
            user.role.value,
            secret=self.settings.jwt_secret.get_secret_value(),
            minutes=self.settings.access_token_minutes,
            now=now,
        )
        refresh_token = new_refresh_token()
        refresh_expires_at = now + timedelta(days=self.settings.refresh_token_days)
        row = RefreshToken(
            user_id=user.id,
            token_hash=hash_refresh_token(refresh_token),
            family_id=family_id,
            expires_at=refresh_expires_at,
            user_agent=user_agent[:USER_AGENT_MAX_LENGTH] if user_agent else None,
            created_at=now,
            updated_at=now,
        )
        self.session.add(row)
        self.session.flush()
        issued = IssuedTokens(
            user, access_token, access_expires_at, refresh_token, refresh_expires_at
        )
        return issued, row

    def _revoke_family(self, family_id: str, now: datetime) -> None:
        self.session.execute(
            update(RefreshToken)
            .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=now)
        )

    def _revoke_family_and_commit(self, family_id: str, now: datetime) -> None:
        self._revoke_family(family_id, now)
        self.session.commit()  # la révocation doit survivre à l'erreur qui va suivre
