"""Tables `bills` (factures) et `bill_lines` (lignes de facture).

Structure calquée sur une vraie facture E²C BT : voir backend/docs/FACTURE_E2C.md.

Garanties assurées PAR LA BASE (contraintes + triggers MySQL) :
- une facture n'est jamais supprimée ; ses lignes non plus ;
- le contenu d'une facture (période, index, montants…) ne change jamais : seul son statut évolue ;
- une facture payée ou annulée est entièrement figée ;
- total = HT + taxes + redevances ; consommation = nouvel index − ancien index.
"""

from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    CheckConstraint,
    Computed,
    Date,
    Index,
    Integer,
    SmallInteger,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import StrictBigInteger, enum_type, foreign_key, non_negative


class BillStatus(StrEnum):
    UNPAID = "unpaid"
    PENDING_PAYMENT = "pending_payment"  # un paiement Mobile Money est en cours
    PAID = "paid"
    OVERDUE = "overdue"  # échéance dépassée, toujours impayée
    CANCELLED = "cancelled"  # annulée (motif obligatoire) ; jamais supprimée


class BillSource(StrEnum):
    SIMULATED = "simulated"
    E2C = "e2c"


class Bill(IdMixin, TimestampMixin, Base):
    """Une facture pour un compteur et une période (bimestrielle chez E²C).

    La période est inclusive : du 1er juillet au 31 août.
    Montants en FCFA entiers ; énergie en Wh entiers.
    """

    __tablename__ = "bills"
    __table_args__ = (
        UniqueConstraint("reference"),
        # Une seule facture « active » (non annulée) par compteur et par période ;
        # une facture annulée libère la place pour sa facture corrigée.
        UniqueConstraint("meter_id", "active_period_start"),
        Index("ix_bills_meter_id_period_start", "meter_id", "period_start"),
        Index("ix_bills_status_due_date", "status", "due_date"),
        CheckConstraint("period_end >= period_start", name="period_order"),
        CheckConstraint("months_count BETWEEN 1 AND 12", name="months_count_range"),
        CheckConstraint("due_date >= period_end", name="due_after_period"),
        non_negative("previous_index_wh"),
        CheckConstraint("current_index_wh >= previous_index_wh", name="index_not_decreasing"),
        CheckConstraint(
            "consumption_wh = current_index_wh - previous_index_wh",
            name="consumption_matches_index",
        ),
        CheckConstraint("billed_power_va > 0", name="billed_power_positive"),
        non_negative("amount_ht"),
        non_negative("amount_tax"),
        non_negative("amount_fees"),
        CheckConstraint("amount_total = amount_ht + amount_tax + amount_fees", name="total_is_sum"),
        # Statut et dates cohérents. Les deux côtés sont écrits explicitement pour qu'aucune
        # valeur NULL ne fasse passer le contrôle (un CHECK qui vaut NULL est accepté par MySQL).
        CheckConstraint(
            "(status = 'paid' AND paid_at IS NOT NULL) OR (status <> 'paid' AND paid_at IS NULL)",
            name="paid_has_date",
        ),
        CheckConstraint(
            "(status = 'cancelled' AND cancelled_at IS NOT NULL AND cancelled_reason IS NOT NULL"
            " AND CHAR_LENGTH(TRIM(cancelled_reason)) >= 10)"  # motif ≥ 10 caractères (A6)
            " OR (status <> 'cancelled' AND cancelled_at IS NULL AND cancelled_reason IS NULL)",
            name="cancelled_has_reason",
        ),
    )

    meter_id: Mapped[int] = mapped_column(foreign_key("meters.id"))
    tariff_id: Mapped[int] = mapped_column(foreign_key("tariffs.id"), index=True)
    reference: Mapped[str] = mapped_column(String(32))  # numéro de facture

    period_start: Mapped[date] = mapped_column(Date)
    period_end: Mapped[date] = mapped_column(Date)  # inclus
    months_count: Mapped[int] = mapped_column(SmallInteger)  # 2 pour une facture bimestrielle
    # Colonne calculée par MySQL : la date de début, sauf si la facture est annulée (NULL).
    active_period_start: Mapped[date | None] = mapped_column(
        Date,
        Computed("CASE WHEN status <> 'cancelled' THEN period_start END", persisted=True),
    )

    # Valeurs figées au moment de la facturation (elles ne suivent pas le compteur ensuite).
    previous_index_wh: Mapped[int] = mapped_column(StrictBigInteger())
    current_index_wh: Mapped[int] = mapped_column(StrictBigInteger())
    consumption_wh: Mapped[int] = mapped_column(StrictBigInteger())
    billed_power_va: Mapped[int | None] = mapped_column(Integer)

    amount_ht: Mapped[int] = mapped_column(StrictBigInteger())  # consommation + droit à conso.
    amount_tax: Mapped[int] = mapped_column(StrictBigInteger())  # TVA + centimes additionnels
    amount_fees: Mapped[int] = mapped_column(StrictBigInteger())  # RAV + timbre (hors TVA)
    amount_total: Mapped[int] = mapped_column(StrictBigInteger())

    due_date: Mapped[date] = mapped_column(Date)
    status: Mapped[BillStatus] = mapped_column(
        enum_type(BillStatus, "status"), default=BillStatus.UNPAID
    )
    issued_at: Mapped[datetime] = mapped_column(UTCDateTime())
    paid_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    cancelled_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    cancelled_reason: Mapped[str | None] = mapped_column(String(255))
    source: Mapped[BillSource] = mapped_column(enum_type(BillSource, "source"))


class BillLineKind(StrEnum):
    """Les lignes d'une facture E²C, dans l'ordre où elles apparaissent."""

    ENERGY = "energy"  # Montant consommation : kWh × prix
    FIXED_FEE = "fixed_fee"  # Droit à la consommation
    AUDIOVISUAL_FEE = "audiovisual_fee"  # RAV
    VAT = "vat"  # T.V.A.
    ADDITIONAL_TAX = "additional_tax"  # C.A. (centimes additionnels, sur la TVA)
    STAMP = "stamp"  # Timbre électronique
    OTHER = "other"


class BillLine(IdMixin, TimestampMixin, Base):
    """Une ligne de facture, avec de quoi refaire le calcul à la main.

    - Ligne « quantité × prix » (énergie, droit à la consommation) :
      quantity_milli = quantité en millièmes d'unité (571 kWh → 571 000 ; 2 mois → 2 000),
      unit_price_milli = prix unitaire en millièmes de FCFA (49,08 → 49 080 ; 2 550 → 2 550 000).
    - Ligne « taux × base » (TVA, C.A.) : rate_bp (18 % → 1 800) et base_amount (FCFA).
    - Ligne forfaitaire (RAV, timbre) : seulement `amount`.
    `amount` est toujours le montant final en FCFA, tronqué.
    """

    __tablename__ = "bill_lines"
    __table_args__ = (
        UniqueConstraint("bill_id", "position"),
        CheckConstraint("position >= 1", name="position_positive"),
        CheckConstraint("CHAR_LENGTH(TRIM(label)) > 0", name="label_not_blank"),
        non_negative("amount"),
        non_negative("quantity_milli"),
        non_negative("unit_price_milli"),
        non_negative("base_amount"),
        CheckConstraint("rate_bp BETWEEN 0 AND 10000", name="rate_bp_range"),
        CheckConstraint(
            "(quantity_milli IS NULL AND unit_price_milli IS NULL AND unit IS NULL)"
            " OR (quantity_milli IS NOT NULL AND unit_price_milli IS NOT NULL"
            " AND unit IS NOT NULL)",
            name="quantity_price_unit_together",
        ),
        CheckConstraint(
            "(rate_bp IS NULL AND base_amount IS NULL)"
            " OR (rate_bp IS NOT NULL AND base_amount IS NOT NULL)",
            name="rate_and_base_together",
        ),
    )

    bill_id: Mapped[int] = mapped_column(foreign_key("bills.id"))
    position: Mapped[int] = mapped_column(SmallInteger)  # ordre d'affichage
    kind: Mapped[BillLineKind] = mapped_column(enum_type(BillLineKind, "kind"))
    label: Mapped[str] = mapped_column(String(120))  # ex. « Montant consommation »
    quantity_milli: Mapped[int | None] = mapped_column(StrictBigInteger())
    unit: Mapped[str | None] = mapped_column(String(16))  # « kWh », « mois »
    unit_price_milli: Mapped[int | None] = mapped_column(StrictBigInteger())
    rate_bp: Mapped[int | None] = mapped_column(Integer)
    base_amount: Mapped[int | None] = mapped_column(StrictBigInteger())
    amount: Mapped[int] = mapped_column(StrictBigInteger())
