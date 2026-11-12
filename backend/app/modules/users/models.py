"""Table `users` : les comptes (clients, support, administrateurs)."""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import Boolean, CheckConstraint, String, true
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import enum_type

# Numéro congolais normalisé : +242 suivi de 9 chiffres (ex. +242061234567).
PHONE_LENGTH = 13
# « [+] » plutôt que « \+ » : MySQL supprimerait l'antislash dans une chaîne SQL.
PHONE_PATTERN = "^[+]242[0-9]{9}$"


class UserRole(StrEnum):
    """Rôle du COMPTE. « Payeur délégué » n'en fait pas partie : c'est un rôle dans un foyer."""

    CLIENT = "client"
    SUPPORT = "support"  # back-office en lecture seule
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"  # peut en plus changer les rôles


class User(IdMixin, TimestampMixin, Base):
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint(f"REGEXP_LIKE(phone, '{PHONE_PATTERN}', 'c')", name="phone_format"),
        CheckConstraint("CHAR_LENGTH(TRIM(full_name)) > 0", name="full_name_not_blank"),
    )

    phone: Mapped[str] = mapped_column(String(PHONE_LENGTH), unique=True)
    # Unicité insensible à la casse grâce à la collation utf8mb4_0900_ai_ci.
    # Plusieurs comptes peuvent ne pas avoir d'e-mail (NULL n'entre pas en conflit).
    email: Mapped[str | None] = mapped_column(String(254), unique=True)
    full_name: Mapped[str] = mapped_column(String(120))
    password_hash: Mapped[str] = mapped_column(String(255))  # hash Argon2, jamais le mot de passe
    role: Mapped[UserRole] = mapped_column(enum_type(UserRole, "role"), default=UserRole.CLIENT)
    # Un compte n'est jamais supprimé : il est désactivé.
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    last_login_at: Mapped[datetime | None] = mapped_column(UTCDateTime())

    def __repr__(self) -> str:  # jamais de hash ni de numéro complet dans les logs
        return f"<User id={self.id} role={self.role}>"
