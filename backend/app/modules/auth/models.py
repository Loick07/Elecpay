"""Tables `refresh_tokens` (sessions de 30 jours), `password_reset_codes` (codes SMS),
`two_factor_secrets` et `two_factor_backup_codes` (double authentification de l'équipe)."""

from datetime import datetime

from sqlalchemy import BigInteger, CheckConstraint, SmallInteger, String
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import foreign_key

TOKEN_HASH_LENGTH = 64  # SHA-256 en hexadécimal
FAMILY_ID_LENGTH = 36  # UUID


class RefreshToken(IdMixin, TimestampMixin, Base):
    """Un jeton de rafraîchissement. Seule son empreinte SHA-256 est stockée.

    Rotation : chaque utilisation crée un nouveau jeton (`replaced_by_id` pointe vers lui)
    et révoque l'ancien. Tous les jetons issus d'une même connexion partagent un
    `family_id` : si un jeton déjà révoqué est réutilisé (vol probable), on révoque
    toute la famille d'un coup.
    """

    __tablename__ = "refresh_tokens"
    __table_args__ = (
        CheckConstraint(f"CHAR_LENGTH(token_hash) = {TOKEN_HASH_LENGTH}", name="token_hash_length"),
        CheckConstraint("expires_at > created_at", name="expires_after_creation"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)
    token_hash: Mapped[str] = mapped_column(CHAR(TOKEN_HASH_LENGTH), unique=True)
    family_id: Mapped[str] = mapped_column(CHAR(FAMILY_ID_LENGTH), index=True)
    expires_at: Mapped[datetime] = mapped_column(UTCDateTime())
    revoked_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    replaced_by_id: Mapped[int | None] = mapped_column(foreign_key("refresh_tokens.id"))
    user_agent: Mapped[str | None] = mapped_column(String(255))

    def __repr__(self) -> str:  # jamais l'empreinte dans les logs
        return f"<RefreshToken id={self.id} user_id={self.user_id} family={self.family_id}>"


RESET_CODE_MAX_ATTEMPTS = 5


class PasswordResetCode(IdMixin, TimestampMixin, Base):
    """Code à 6 chiffres envoyé par SMS pour réinitialiser un mot de passe.

    Seule son empreinte HMAC-SHA256 (clé secrète du serveur) est stockée : avec seulement
    un million de codes possibles, une simple empreinte se retrouverait en une seconde si la
    base fuitait ; sans la clé, c'est impossible.
    Un code est utilisable une seule fois, pendant 10 minutes, avec 5 essais au plus.
    """

    __tablename__ = "password_reset_codes"
    __table_args__ = (
        CheckConstraint(f"CHAR_LENGTH(code_hash) = {TOKEN_HASH_LENGTH}", name="code_hash_length"),
        CheckConstraint("expires_at > created_at", name="expires_after_creation"),
        CheckConstraint(f"attempts BETWEEN 0 AND {RESET_CODE_MAX_ATTEMPTS}", name="attempts_range"),
        # Un code n'est pas à la fois utilisé et invalidé.
        CheckConstraint("used_at IS NULL OR invalidated_at IS NULL", name="single_outcome"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)
    code_hash: Mapped[str] = mapped_column(CHAR(TOKEN_HASH_LENGTH))
    expires_at: Mapped[datetime] = mapped_column(UTCDateTime())
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0, server_default="0")
    used_at: Mapped[datetime | None] = mapped_column(UTCDateTime())  # réinitialisation réussie
    # Remplacé par un nouveau code, ou trop d'essais faux.
    invalidated_at: Mapped[datetime | None] = mapped_column(UTCDateTime())

    def __repr__(self) -> str:  # jamais l'empreinte dans les logs
        return f"<PasswordResetCode id={self.id} user_id={self.user_id}>"


class TwoFactorSecret(IdMixin, TimestampMixin, Base):
    """Double authentification d'un membre de l'équipe (B11.3, maquette A11).

    Le secret TOTP est CHIFFRÉ (AES-256-GCM, clé `TWO_FACTOR_KEY`) : il faut pouvoir le relire
    pour vérifier un code, donc une simple empreinte ne suffit pas. `enabled_at` NULL :
    activation commencée (QR code affiché) mais pas encore confirmée par un premier code.
    `last_used_step` : dernier pas de 30 s accepté, pour qu'un code ne serve jamais deux fois.
    """

    __tablename__ = "two_factor_secrets"
    __table_args__ = (
        CheckConstraint("last_used_step IS NULL OR last_used_step >= 0", name="step_positive"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"), unique=True)
    secret_encrypted: Mapped[str] = mapped_column(String(255))
    enabled_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    last_used_step: Mapped[int | None] = mapped_column(BigInteger)

    def __repr__(self) -> str:  # jamais le secret dans les logs
        return f"<TwoFactorSecret user_id={self.user_id} enabled={self.enabled_at is not None}>"


BACKUP_CODES = 10


class TwoFactorBackupCode(IdMixin, TimestampMixin, Base):
    """Code de secours (téléphone perdu) : 10 à l'activation, chacun utilisable une seule fois.

    Seule l'empreinte HMAC-SHA256 est stockée (comme les codes SMS). Régénérer la liste
    invalide les anciens codes (gardés pour l'historique, jamais supprimés).
    """

    __tablename__ = "two_factor_backup_codes"
    __table_args__ = (
        CheckConstraint(f"CHAR_LENGTH(code_hash) = {TOKEN_HASH_LENGTH}", name="code_hash_length"),
        CheckConstraint("used_at IS NULL OR invalidated_at IS NULL", name="single_outcome"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)
    code_hash: Mapped[str] = mapped_column(CHAR(TOKEN_HASH_LENGTH))
    used_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    invalidated_at: Mapped[datetime | None] = mapped_column(UTCDateTime())

    def __repr__(self) -> str:
        return f"<TwoFactorBackupCode id={self.id} user_id={self.user_id}>"
