"""Tables des e-mails (B11.4) : `email_verification_codes` et `email_outbox`.

- Vérification de l'adresse : un code à 6 chiffres envoyé par e-mail (même principe que le
  code SMS du mot de passe oublié). Aucun reçu ne part vers une adresse non vérifiée : une faute
  de frappe enverrait sinon le nom, le montant et le reçu d'un client à un inconnu.
- File d'envoi : le paiement ne dépend JAMAIS de l'e-mail. Le récapitulatif est mis en file
  dans la même transaction que le succès, puis envoyé par `scripts.send_emails` (toutes les
  minutes) ; en cas de panne du service d'envoi, il est retenté plus tard.
"""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import CheckConstraint, SmallInteger, String, UniqueConstraint
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import enum_type, foreign_key

CODE_HASH_LENGTH = 64  # HMAC-SHA256 en hexadécimal
VERIFICATION_MAX_ATTEMPTS = 5
USERS_ID = "users.id"


class EmailVerificationCode(IdMixin, TimestampMixin, Base):
    """Code envoyé à une adresse précise : il ne vaut que pour CETTE adresse (si l'abonné change
    d'e-mail entre-temps, le code ne vérifie pas la nouvelle). Seule l'empreinte est stockée."""

    __tablename__ = "email_verification_codes"
    __table_args__ = (
        CheckConstraint(f"CHAR_LENGTH(code_hash) = {CODE_HASH_LENGTH}", name="code_hash_length"),
        CheckConstraint("expires_at > created_at", name="expires_after_creation"),
        CheckConstraint(
            f"attempts BETWEEN 0 AND {VERIFICATION_MAX_ATTEMPTS}", name="attempts_range"
        ),
        CheckConstraint("used_at IS NULL OR invalidated_at IS NULL", name="single_outcome"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key(USERS_ID), index=True)
    email: Mapped[str] = mapped_column(String(254))
    code_hash: Mapped[str] = mapped_column(CHAR(CODE_HASH_LENGTH))
    expires_at: Mapped[datetime] = mapped_column(UTCDateTime())
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0, server_default="0")
    used_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    invalidated_at: Mapped[datetime | None] = mapped_column(UTCDateTime())

    def __repr__(self) -> str:
        return f"<EmailVerificationCode id={self.id} user_id={self.user_id}>"


class EmailKind(StrEnum):
    PAYMENT_RECEIPT = "payment_receipt"  # « Paiement reçu », reçu PDF joint


class EmailStatus(StrEnum):
    PENDING = "pending"  # à envoyer (ou à retenter)
    SENT = "sent"
    FAILED = "failed"  # abandonné après plusieurs essais


class OutboxEmail(IdMixin, TimestampMixin, Base):
    """Un e-mail à envoyer. Le contenu est construit à l'envoi (rien de personnel stocké ici
    hormis l'adresse) ; le reçu PDF est généré à ce moment-là."""

    __tablename__ = "email_outbox"
    __table_args__ = (
        # Jamais deux fois le même récapitulatif à la même personne.
        UniqueConstraint("kind", "receipt_id", "user_id"),
        CheckConstraint(
            "(status = 'sent' AND sent_at IS NOT NULL) OR (status <> 'sent' AND sent_at IS NULL)",
            name="sent_has_date",
        ),
        CheckConstraint("attempts >= 0", name="attempts_positive"),
    )

    user_id: Mapped[int] = mapped_column(foreign_key(USERS_ID), index=True)
    to_email: Mapped[str] = mapped_column(String(254))  # adresse vérifiée au moment de la file
    kind: Mapped[EmailKind] = mapped_column(enum_type(EmailKind, "kind"))
    receipt_id: Mapped[int | None] = mapped_column(foreign_key("receipts.id"))
    status: Mapped[EmailStatus] = mapped_column(
        enum_type(EmailStatus, "status"), default=EmailStatus.PENDING, index=True
    )
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0, server_default="0")
    next_attempt_at: Mapped[datetime] = mapped_column(UTCDateTime())
    sent_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    last_error: Mapped[str | None] = mapped_column(String(255))  # message générique, sans donnée
