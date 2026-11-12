"""Table `meters` : compteurs E²C rattachés (ou non) à un foyer."""

from datetime import date
from enum import StrEnum

from sqlalchemy import CheckConstraint, Date, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin
from app.db.types import enum_type, foreign_key


class MeterType(StrEnum):
    POSTPAID = "postpaid"  # facturé après consommation (le prépayé viendra plus tard)


class MeterStatus(StrEnum):
    ACTIVE = "active"
    SUSPENDED = "suspended"  # coupure temporaire
    TERMINATED = "terminated"  # contrat résilié


class Meter(IdMixin, TimestampMixin, Base):
    __tablename__ = "meters"
    __table_args__ = (
        CheckConstraint("CHAR_LENGTH(TRIM(reference)) > 0", name="reference_not_blank"),
        CheckConstraint("subscribed_power_va > 0", name="subscribed_power_positive"),
    )

    # Correspondance avec la facture E²C (voir backend/docs/FACTURE_E2C.md) :
    #   N° Branchement → reference · N° Police → contract_number · N° Client → customer_number
    #   Centre E²C → e2c_center. La « référence paiement par téléphone » se déduit
    #   de customer_number + reference : elle n'est pas stockée.

    # NULL = compteur détaché de tout foyer (un admin peut rattacher / détacher).
    household_id: Mapped[int | None] = mapped_column(foreign_key("households.id"), index=True)
    reference: Mapped[str] = mapped_column(String(32), unique=True)  # N° Branchement E²C
    label: Mapped[str | None] = mapped_column(String(60))  # nom choisi par l'abonné (« Boutique »)
    type: Mapped[MeterType] = mapped_column(
        enum_type(MeterType, "type"), default=MeterType.POSTPAID
    )
    contract_number: Mapped[str | None] = mapped_column(String(32))  # N° Police
    customer_number: Mapped[str | None] = mapped_column(String(32), index=True)  # N° Client
    e2c_center: Mapped[str | None] = mapped_column(String(60))  # ex. POINTE-NOIRE
    # Puissance souscrite en VA (entier) : 2,2 kVA → 2200. Jamais de float.
    subscribed_power_va: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[MeterStatus] = mapped_column(
        enum_type(MeterStatus, "status"), default=MeterStatus.ACTIVE
    )
    installed_at: Mapped[date | None] = mapped_column(Date)
