"""Tables `refresh_tokens` (sessions de 30 jours) et `password_reset_codes` (codes SMS)."""

from datetime import datetime

from sqlalchemy import CheckConstraint, SmallInteger, String
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
