"""Double authentification de l'équipe (B11.3, maquette A11) : TOTP + codes de secours.

Cycle :
1. `start_setup` : secret créé (chiffré en base), QR code affiché, PAS encore actif ;
2. `enable` : le membre saisit un premier code → active ; 10 codes de secours montrés UNE fois ;
3. à chaque connexion : mot de passe, puis `verify_login` (code de l'application, ou code de
   secours à usage unique) ; un code déjà accepté n'est jamais réaccepté ;
4. `disable` (mot de passe + code) : seulement si la 2FA n'est pas obligatoire pour le rôle ;
5. `reset` par un super admin (téléphone perdu) : 2FA effacée, sessions du membre fermées.

Obligatoire pour admin et super admin (`TEAM_2FA_REQUIRED`) : sans 2FA active, le back-office
leur répond `403 TWO_FACTOR_SETUP_REQUIRED` (garde `require_team_two_factor`). Chaque étape est
inscrite au journal, sans jamais le secret ni un code.
"""

import hashlib
import hmac
import secrets
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime

from fastapi import Depends
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core import totp
from app.core.config import Settings, get_settings
from app.core.request_context import RequestContext
from app.core.secret_box import decrypt, encrypt
from app.core.security import verify_password
from app.db.base import utcnow
from app.db.session import get_db
from app.modules.audit.service import record
from app.modules.auth.dependencies import current_user
from app.modules.auth.errors import (
    InvalidCredentialsError,
    TwoFactorCodeInvalidError,
    TwoFactorRequiredForRoleError,
    TwoFactorSetupRequiredError,
    TwoFactorStateError,
)
from app.modules.auth.models import BACKUP_CODES, TwoFactorBackupCode, TwoFactorSecret
from app.modules.auth.sessions import SessionService
from app.modules.users.models import User, UserRole

TEAM_ROLES = frozenset({UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN})
REQUIRED_ROLES = frozenset({UserRole.ADMIN, UserRole.SUPER_ADMIN})
BACKUP_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"  # sans 0/O, 1/I/L : se recopie sans erreur
BACKUP_LENGTH = 8


def new_backup_code() -> str:
    raw = "".join(secrets.choice(BACKUP_ALPHABET) for _ in range(BACKUP_LENGTH))
    return f"{raw[:4]}-{raw[4:]}"


def normalize_backup_code(code: str) -> str:
    return "".join(char for char in code.upper() if char.isalnum())


def backup_code_hash(secret: str, user_id: int, code: str) -> str:
    message = f"two-factor-backup:{user_id}:{normalize_backup_code(code)}".encode()
    return hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()


def two_factor_required(user: User, settings: Settings) -> bool:
    return settings.team_2fa_required and user.role in REQUIRED_ROLES


@dataclass(frozen=True, slots=True)
class TwoFactorState:
    enabled: bool
    pending_setup: bool
    required: bool
    enabled_at: datetime | None
    backup_codes_left: int


@dataclass(frozen=True, slots=True)
class SetupStart:
    secret: str
    otpauth_uri: str


class TwoFactorService:
    def __init__(
        self, session: Session, settings: Settings, now: Callable[[], datetime] = utcnow
    ) -> None:
        self.session = session
        self.settings = settings
        self.key = settings.two_factor_cipher_key
        self.hmac_secret = settings.jwt_secret.get_secret_value()
        self.now = now

    # --- État -------------------------------------------------------------------------------

    def row(self, user: User, *, lock: bool = False) -> TwoFactorSecret | None:
        query = select(TwoFactorSecret).where(TwoFactorSecret.user_id == user.id)
        if lock:
            query = query.with_for_update()
        return self.session.scalars(query).first()

    def is_enabled(self, user: User) -> bool:
        row = self.row(user)
        return row is not None and row.enabled_at is not None

    def state(self, user: User) -> TwoFactorState:
        row = self.row(user)
        enabled = row is not None and row.enabled_at is not None
        return TwoFactorState(
            enabled=enabled,
            pending_setup=row is not None and row.enabled_at is None,
            required=two_factor_required(user, self.settings),
            enabled_at=row.enabled_at if row else None,
            backup_codes_left=self._backup_codes_left(user) if enabled else 0,
        )

    # --- Activation -------------------------------------------------------------------------

    def start_setup(self, user: User) -> SetupStart:
        """Nouveau secret (remplace une activation commencée et jamais confirmée)."""
        row = self.row(user, lock=True)
        if row is not None and row.enabled_at is not None:
            raise TwoFactorStateError("La double authentification est déjà active.")
        secret = totp.new_secret()
        if row is None:
            row = TwoFactorSecret(user_id=user.id, secret_encrypted="")
            self.session.add(row)
        row.secret_encrypted = encrypt(secret, self.key)
        row.last_used_step = None
        self.session.commit()
        return SetupStart(secret=secret, otpauth_uri=totp.provisioning_uri(secret, user.phone))

    def enable(self, user: User, code: str, context: RequestContext | None) -> list[str]:
        row = self.row(user, lock=True)
        if row is None or row.enabled_at is not None:
            raise TwoFactorStateError("Commencez par afficher le QR code (activation).")
        self._consume_totp(row, code)  # rien n'est modifié si le code est faux
        row.enabled_at = self.now()
        codes = self._new_backup_codes(user)
        self._audit("team.two_factor_enable", user, user, context)
        self.session.commit()
        return codes

    def regenerate_backup_codes(
        self, user: User, code: str, context: RequestContext | None
    ) -> list[str]:
        row = self._enabled_row(user)
        self._consume_totp(row, code)
        codes = self._new_backup_codes(user)
        self._audit("team.backup_codes", user, user, context)
        self.session.commit()
        return codes

    def disable(self, user: User, password: str, code: str, context: RequestContext | None) -> None:
        if two_factor_required(user, self.settings):
            raise TwoFactorRequiredForRoleError()
        if not verify_password(password, user.password_hash):
            raise InvalidCredentialsError("Mot de passe incorrect.")
        row = self._enabled_row(user)
        self._consume_totp(row, code)
        self._erase(user, row)
        self._audit("team.two_factor_disable", user, user, context)
        self.session.commit()

    def reset(self, actor: User, member: User, reason: str, context: RequestContext | None) -> int:
        """Téléphone perdu : 2FA effacée par un super admin, sessions du membre fermées.
        Renvoie le nombre de sessions fermées. Pas de commit (l'appelant valide)."""
        row = self.row(member, lock=True)
        if row is None:
            raise TwoFactorStateError("Ce membre n'a pas de double authentification.")
        self._erase(member, row)
        closed = SessionService(self.session, self.settings, self.now).close_all_sessions(member.id)
        self._audit(
            "team.two_factor_reset",
            actor,
            member,
            context,
            reason=reason,
            sessions_closed=closed,
        )
        return closed

    # --- Connexion --------------------------------------------------------------------------

    def verify_login(self, user: User, code: str) -> str:
        """Vérifie le code de l'étape 2. Renvoie la méthode : « totp » ou « backup_code ».
        Pas de commit : la connexion valide avec l'ouverture de la session."""
        row = self._enabled_row(user)
        if normalize_backup_code(code).isdigit():
            self._consume_totp(row, code)
            return "totp"
        backup = self.session.scalars(
            select(TwoFactorBackupCode)
            .where(
                TwoFactorBackupCode.user_id == user.id,
                TwoFactorBackupCode.code_hash == backup_code_hash(self.hmac_secret, user.id, code),
                TwoFactorBackupCode.used_at.is_(None),
                TwoFactorBackupCode.invalidated_at.is_(None),
            )
            .with_for_update()
        ).first()
        if backup is None:
            raise TwoFactorCodeInvalidError()
        backup.used_at = self.now()
        return "backup_code"

    # --- Outils -----------------------------------------------------------------------------

    def _enabled_row(self, user: User) -> TwoFactorSecret:
        row = self.row(user, lock=True)
        if row is None or row.enabled_at is None:
            raise TwoFactorStateError("La double authentification n'est pas active.")
        return row

    def _match(self, row: TwoFactorSecret, code: str) -> int | None:
        secret = decrypt(row.secret_encrypted, self.key)
        return totp.matching_step(
            secret, code.strip(), self.now().timestamp(), last_used_step=row.last_used_step
        )

    def _consume_totp(self, row: TwoFactorSecret, code: str) -> None:
        step = self._match(row, code)
        if step is None:
            raise TwoFactorCodeInvalidError()
        row.last_used_step = step  # ce code (et les plus anciens) ne resservira plus

    def _new_backup_codes(self, user: User) -> list[str]:
        now = self.now()
        self.session.execute(
            update(TwoFactorBackupCode)
            .where(
                TwoFactorBackupCode.user_id == user.id,
                TwoFactorBackupCode.used_at.is_(None),
                TwoFactorBackupCode.invalidated_at.is_(None),
            )
            .values(invalidated_at=now)
        )
        codes = [new_backup_code() for _ in range(BACKUP_CODES)]
        self.session.add_all(
            TwoFactorBackupCode(
                user_id=user.id, code_hash=backup_code_hash(self.hmac_secret, user.id, code)
            )
            for code in codes
        )
        return codes

    def _backup_codes_left(self, user: User) -> int:
        return len(
            self.session.scalars(
                select(TwoFactorBackupCode.id).where(
                    TwoFactorBackupCode.user_id == user.id,
                    TwoFactorBackupCode.used_at.is_(None),
                    TwoFactorBackupCode.invalidated_at.is_(None),
                )
            ).all()
        )

    def _erase(self, user: User, row: TwoFactorSecret) -> None:
        self.session.delete(row)
        self.session.execute(
            update(TwoFactorBackupCode)
            .where(
                TwoFactorBackupCode.user_id == user.id,
                TwoFactorBackupCode.used_at.is_(None),
                TwoFactorBackupCode.invalidated_at.is_(None),
            )
            .values(invalidated_at=self.now())
        )

    def _audit(
        self,
        action: str,
        actor: User,
        member: User,
        context: RequestContext | None,
        **after,
    ) -> None:
        record(
            self.session,
            action=action,
            entity_type="user",
            entity_id=member.id,
            actor_id=actor.id,
            context=context,
            after=after or None,
        )


def require_team_two_factor(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    """Garde des routes `/admin` : admin et super admin doivent avoir activé la 2FA."""
    if two_factor_required(user, settings) and not TwoFactorService(db, settings).is_enabled(user):
        raise TwoFactorSetupRequiredError()
    return user
