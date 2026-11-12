"""Table `tariffs` : tarifs E²C datés (voir backend/docs/FACTURE_E2C.md).

Structure reprise d'une vraie facture E²C (Basse Tension) :
    Montant consommation  = kWh × prix unitaire                     (tronqué au FCFA)
    Droit à consommation  = frais fixes mensuels × nombre de mois
    Total hors taxes      = consommation + droit à consommation
    TVA                   = HT × taux de TVA                         (tronqué)
    C.A.                  = TVA × taux des centimes additionnels     (tronqué)
    RAV                   = redevance audiovisuelle (montant fixe, hors base TVA)
    Timbre électronique   = montant fixe
    Total                 = HT + RAV + TVA + C.A. + timbre

Les taux sont en points de base (1 % = 100 bp ; 18 % = 1800).
"""

from datetime import date

from sqlalchemy import Boolean, CheckConstraint, Date, Integer, String, UniqueConstraint, true
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin
from app.db.types import StrictBigInteger, non_negative

MAX_RATE_BP = 10_000  # 100 %


def rate_between_0_and_100_percent(column: str) -> CheckConstraint:
    return CheckConstraint(f"{column} BETWEEN 0 AND {MAX_RATE_BP}", name=f"{column}_range")


class Tariff(IdMixin, TimestampMixin, Base):
    """Un tarif valable du `valid_from` (inclus) au `valid_to` (exclu, NULL = sans fin).

    Deux périodes d'un même `code` ne se chevauchent jamais (garanti par des triggers MySQL).
    """

    __tablename__ = "tariffs"
    __table_args__ = (
        UniqueConstraint("code", "valid_from"),
        CheckConstraint("CHAR_LENGTH(TRIM(code)) > 0", name="code_not_blank"),
        CheckConstraint("price_per_kwh_milli > 0", name="price_positive"),
        non_negative("fixed_fee_per_month"),
        non_negative("audiovisual_fee"),
        non_negative("stamp_fee"),
        rate_between_0_and_100_percent("vat_rate_bp"),
        rate_between_0_and_100_percent("additional_tax_rate_bp"),
        CheckConstraint("valid_to IS NULL OR valid_to > valid_from", name="valid_period"),
    )

    code: Mapped[str] = mapped_column(String(32))  # ex. BT_DOMESTIQUE
    label: Mapped[str] = mapped_column(String(120))
    # Prix du kWh en millièmes de FCFA : 49,08 FCFA/kWh → 49 080.
    price_per_kwh_milli: Mapped[int] = mapped_column(StrictBigInteger())
    # « Droit à la consommation » par mois, en FCFA.
    fixed_fee_per_month: Mapped[int] = mapped_column(StrictBigInteger())
    vat_rate_bp: Mapped[int] = mapped_column(Integer)  # TVA : 1800 = 18 %
    # Centimes additionnels, calculés SUR LA TVA : 500 = 5 % de la TVA.
    additional_tax_rate_bp: Mapped[int] = mapped_column(Integer)
    audiovisual_fee: Mapped[int] = mapped_column(StrictBigInteger())  # RAV, FCFA par facture
    stamp_fee: Mapped[int] = mapped_column(StrictBigInteger())  # timbre électronique, FCFA
    valid_from: Mapped[date] = mapped_column(Date)
    valid_to: Mapped[date | None] = mapped_column(Date)
    # Vrai tant que les valeurs n'ont pas été vérifiées sur plusieurs vraies factures E²C.
    is_assumption: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    source_note: Mapped[str | None] = mapped_column(String(255))  # d'où viennent ces valeurs
