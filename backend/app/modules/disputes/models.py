"""Table `payment_disputes` : litiges sur une transaction (maquette admin A8, B10.6).

Un litige s'ouvre quand un client affirme avoir été débité alors qu'ElecPay ne voit pas de
paiement réussi (ou l'inverse). C'est un DOSSIER de suivi pour l'équipe : il ne change jamais
le statut d'une transaction ni d'une facture. Seul le prestataire peut faire passer une
transaction à « réussie » ; la clôture d'un litige note seulement ce que l'opérateur a dit.

Garanties assurées PAR LA BASE :
- un seul litige ouvert par transaction ;
- un litige clos a toujours sa conclusion, son auteur, sa date et une note ;
- motif d'ouverture non vide.
"""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import BigInteger, CheckConstraint, Computed, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import enum_type, foreign_key


class DisputeStatus(StrEnum):
    OPEN = "open"
    CLOSED = "closed"


class DisputeResolution(StrEnum):
    """Ce que l'opérateur a confirmé à la clôture (enregistré, jamais appliqué au paiement)."""

    NO_DEBIT = "no_debit"  # aucun débit chez l'opérateur : rien n'a été pris au client
    REFUNDED = "refunded"  # débit remboursé au client par l'opérateur
    DEBIT_CONFIRMED = "debit_confirmed"  # débit réel : régularisation hors ElecPay, voir la note


class PaymentDispute(IdMixin, TimestampMixin, Base):
    __tablename__ = "payment_disputes"
    __table_args__ = (
        UniqueConstraint("open_transaction_id"),  # un seul litige ouvert par transaction
        CheckConstraint("CHAR_LENGTH(TRIM(reason)) >= 10", name="reason_long_enough"),
        CheckConstraint(
            "(status = 'open' AND resolution IS NULL AND resolved_by IS NULL"
            " AND resolved_at IS NULL AND resolution_note IS NULL)"
            " OR (status = 'closed' AND resolution IS NOT NULL AND resolved_by IS NOT NULL"
            " AND resolved_at IS NOT NULL AND resolution_note IS NOT NULL"
            " AND CHAR_LENGTH(TRIM(resolution_note)) >= 10)",
            name="closed_is_complete",
        ),
    )

    transaction_id: Mapped[int] = mapped_column(foreign_key("payment_transactions.id"), index=True)
    status: Mapped[DisputeStatus] = mapped_column(
        enum_type(DisputeStatus, "status"), default=DisputeStatus.OPEN
    )
    reason: Mapped[str] = mapped_column(String(255))  # ce que dit le client
    # Référence du SMS de débit reçu par le client (« ID de transaction » MoMo), si fournie.
    customer_reference: Mapped[str | None] = mapped_column(String(64))
    opened_by: Mapped[int] = mapped_column(foreign_key("users.id"))
    opened_at: Mapped[datetime] = mapped_column(UTCDateTime())
    resolution: Mapped[DisputeResolution | None] = mapped_column(
        enum_type(DisputeResolution, "resolution")
    )
    resolution_note: Mapped[str | None] = mapped_column(String(255))
    resolved_by: Mapped[int | None] = mapped_column(foreign_key("users.id"))
    resolved_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    # Colonne calculée par MySQL, uniquement pour le verrou « un seul litige ouvert ».
    open_transaction_id: Mapped[int | None] = mapped_column(
        BigInteger,
        Computed("CASE WHEN status = 'open' THEN transaction_id END", persisted=True),
    )
