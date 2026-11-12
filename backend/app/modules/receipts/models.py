"""Table `receipts` : reçus numériques des paiements réussis.

Garanties assurées PAR LA BASE :
- un seul reçu par transaction, et seulement pour une transaction `reussie` (trigger) ;
- numéro unique au format EP-AAAA-NNNNNN ; code de vérification unique ;
- un reçu n'est jamais supprimé ; seul son PDF peut être ajouté après coup (trigger).
"""

from datetime import datetime

from sqlalchemy import CheckConstraint, String, UniqueConstraint
from sqlalchemy.dialects.mysql import CHAR
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import foreign_key

RECEIPT_NUMBER_PATTERN = "^EP-[0-9]{4}-[0-9]{6}$"  # ex. EP-2026-000123
VERIFICATION_CODE_LENGTH = 12
VERIFICATION_CODE_PATTERN = f"^[A-Z0-9]{{{VERIFICATION_CODE_LENGTH}}}$"


class Receipt(IdMixin, TimestampMixin, Base):
    __tablename__ = "receipts"
    __table_args__ = (
        UniqueConstraint("transaction_id"),
        UniqueConstraint("number"),
        UniqueConstraint("verification_code"),
        CheckConstraint(
            f"REGEXP_LIKE(number, '{RECEIPT_NUMBER_PATTERN}', 'c')", name="number_format"
        ),
        CheckConstraint(
            f"REGEXP_LIKE(verification_code, '{VERIFICATION_CODE_PATTERN}', 'c')",
            name="verification_code_format",
        ),
    )

    transaction_id: Mapped[int] = mapped_column(foreign_key("payment_transactions.id"))
    number: Mapped[str] = mapped_column(String(20))
    issued_at: Mapped[datetime] = mapped_column(UTCDateTime())
    pdf_path: Mapped[str | None] = mapped_column(String(255))  # généré après l'émission
    # Code imprimé sur le reçu (et dans son QR code) pour la vérification publique.
    verification_code: Mapped[str] = mapped_column(CHAR(VERIFICATION_CODE_LENGTH))
