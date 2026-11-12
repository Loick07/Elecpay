"""Table `refresh_tokens` : jetons de rafraîchissement (sessions de 30 jours)."""

from datetime import datetime

from sqlalchemy import CheckConstraint, String
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
