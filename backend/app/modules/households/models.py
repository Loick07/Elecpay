"""Tables `households` (foyers) et `household_members` (membres invités d'un foyer)."""

from enum import StrEnum

from sqlalchemy import CheckConstraint, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin
from app.db.types import enum_type, foreign_key


class Household(IdMixin, TimestampMixin, Base):
    """Un foyer = un logement, avec un seul propriétaire (`owner_id`, seule source de vérité).

    Le propriétaire n'apparaît PAS dans `household_members` : cette table ne contient
    que les autres personnes (payeurs délégués, lecteurs).
    """

    __tablename__ = "households"
    __table_args__ = (
        CheckConstraint("CHAR_LENGTH(TRIM(name)) > 0", name="name_not_blank"),
        CheckConstraint("CHAR_LENGTH(TRIM(city)) > 0", name="city_not_blank"),
    )

    name: Mapped[str] = mapped_column(String(80))  # ex. « Maison de maman »
    address: Mapped[str | None] = mapped_column(String(255))
    district: Mapped[str | None] = mapped_column(String(80))  # quartier (annonces ciblées, A9)
    city: Mapped[str] = mapped_column(String(80))  # ex. Pointe-Noire, Brazzaville
    owner_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)


class MemberRole(StrEnum):
    PAYER = "payer"  # payeur délégué : voit et paie les factures du foyer
    VIEWER = "viewer"  # lecture seule


class MemberStatus(StrEnum):
    INVITED = "invited"  # invitation envoyée, pas encore acceptée
    ACTIVE = "active"
    REVOKED = "revoked"  # retiré ou invitation annulée (la ligne est gardée pour l'historique)


class HouseholdMember(IdMixin, TimestampMixin, Base):
    __tablename__ = "household_members"
    __table_args__ = (UniqueConstraint("household_id", "user_id"),)

    household_id: Mapped[int] = mapped_column(foreign_key("households.id"))
    user_id: Mapped[int] = mapped_column(foreign_key("users.id"), index=True)
    role: Mapped[MemberRole] = mapped_column(enum_type(MemberRole, "role"))
    status: Mapped[MemberStatus] = mapped_column(
        enum_type(MemberStatus, "status"), default=MemberStatus.INVITED
    )
    invited_by: Mapped[int] = mapped_column(foreign_key("users.id"))
