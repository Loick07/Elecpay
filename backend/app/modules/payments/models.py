"""Table `payment_transactions` : paiements Mobile Money des factures.

Cycle de vie : en_attente → reussie | echouee | expiree. Seul le prestataire (webhook)
fait passer à `reussie` ; un administrateur ne peut jamais forcer un paiement.

Garanties assurées PAR LA BASE (contraintes + triggers MySQL) :
- une seule transaction `en_attente` par facture (verrou de paiement) ;
- une seule transaction `reussie` par facture (jamais de double paiement) ;
- même clé d'idempotence → impossible de créer une deuxième transaction ;
- montant = montant total de la facture (jamais choisi par le client) ;
- une transaction naît `en_attente`, et une fois terminée elle ne change plus ;
- une transaction n'est jamais supprimée.
"""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import BigInteger, CheckConstraint, Computed, Index, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import StrictBigInteger, enum_type, foreign_key
from app.modules.users.models import PHONE_LENGTH, PHONE_PATTERN


class PaymentProvider(StrEnum):
    SIMULATED = "simulated"  # mode démo
    MTN = "mtn"  # MTN Mobile Money (à brancher)
    AIRTEL = "airtel"  # Airtel Money (à brancher)


class TransactionStatus(StrEnum):
    PENDING = "en_attente"
    SUCCEEDED = "reussie"
    FAILED = "echouee"
    EXPIRED = "expiree"


class PaymentTransaction(IdMixin, TimestampMixin, Base):
    __tablename__ = "payment_transactions"
    __table_args__ = (
        UniqueConstraint("idempotency_key"),
        # Une même référence prestataire ne peut pas confirmer deux transactions.
        UniqueConstraint("provider", "provider_ref"),
        UniqueConstraint("pending_bill_id"),  # verrou : 1 seule transaction en attente
        UniqueConstraint("succeeded_bill_id"),  # jamais deux paiements réussis
        Index("ix_payment_transactions_status_initiated_at", "status", "initiated_at"),
        CheckConstraint("amount > 0", name="amount_positive"),
        CheckConstraint(f"REGEXP_LIKE(phone_number, '{PHONE_PATTERN}', 'c')", name="phone_format"),
        CheckConstraint("CHAR_LENGTH(TRIM(idempotency_key)) > 0", name="idempotency_key_not_blank"),
        CheckConstraint("expires_at > initiated_at", name="expires_after_initiation"),
        CheckConstraint("confirmed_at >= initiated_at", name="confirmed_after_initiation"),
        # Réussie ⇔ date de confirmation + référence du prestataire.
        CheckConstraint(
            "(status = 'reussie' AND confirmed_at IS NOT NULL AND provider_ref IS NOT NULL)"
            " OR (status <> 'reussie' AND confirmed_at IS NULL)",
            name="success_is_confirmed",
        ),
        # Échouée ou expirée ⇔ motif.
        CheckConstraint(
            "(status IN ('echouee', 'expiree') AND failure_reason IS NOT NULL"
            " AND CHAR_LENGTH(TRIM(failure_reason)) > 0)"
            " OR (status IN ('en_attente', 'reussie') AND failure_reason IS NULL)",
            name="failure_has_reason",
        ),
    )

    bill_id: Mapped[int] = mapped_column(foreign_key("bills.id"), index=True)
    # Qui paie : le titulaire ou un payeur délégué du foyer (vérifié par le service).
    payer_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)
    provider: Mapped[PaymentProvider] = mapped_column(enum_type(PaymentProvider, "provider"))
    phone_number: Mapped[str] = mapped_column(String(PHONE_LENGTH))  # numéro Mobile Money débité
    amount: Mapped[int] = mapped_column(StrictBigInteger())  # FCFA = total de la facture
    status: Mapped[TransactionStatus] = mapped_column(
        enum_type(TransactionStatus, "status"), default=TransactionStatus.PENDING
    )
    idempotency_key: Mapped[str] = mapped_column(String(64))
    provider_ref: Mapped[str | None] = mapped_column(String(64))
    failure_reason: Mapped[str | None] = mapped_column(String(255))
    initiated_at: Mapped[datetime] = mapped_column(UTCDateTime())
    confirmed_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    expires_at: Mapped[datetime] = mapped_column(UTCDateTime())

    # Colonnes calculées par MySQL, uniquement pour les deux verrous ci-dessus.
    pending_bill_id: Mapped[int | None] = mapped_column(
        BigInteger, Computed("CASE WHEN status = 'en_attente' THEN bill_id END", persisted=True)
    )
    succeeded_bill_id: Mapped[int | None] = mapped_column(
        BigInteger, Computed("CASE WHEN status = 'reussie' THEN bill_id END", persisted=True)
    )
