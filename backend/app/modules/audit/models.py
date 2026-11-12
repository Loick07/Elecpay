"""Table `audit_logs` : journal des actions sensibles (qui a fait quoi, quand, sur quoi).

Garantie assurée PAR LA BASE (triggers MySQL) : une ligne d'audit n'est JAMAIS modifiée
ni supprimée, même par un super administrateur.
Règle pour les services : jamais de mot de passe, de jeton ou de hash dans before/after.
"""

from datetime import datetime
from typing import Any

from sqlalchemy import JSON, BigInteger, CheckConstraint, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, UTCDateTime, utcnow
from app.db.types import foreign_key

# Action au format « domaine.verbe » : bill.cancel, user.role_change, payment.recheck…
# « [.] » plutôt que « \. » : MySQL supprimerait l'antislash dans une chaîne SQL.
ACTION_PATTERN = "^[a-z_]+[.][a-z_]+$"


class AuditLog(IdMixin, Base):
    """Pas de `updated_at` : une ligne d'audit est écrite une fois, puis jamais touchée."""

    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_logs_entity_type_entity_id", "entity_type", "entity_id"),
        Index("ix_audit_logs_actor_id_created_at", "actor_id", "created_at"),
        Index("ix_audit_logs_created_at", "created_at"),
        CheckConstraint(f"REGEXP_LIKE(action, '{ACTION_PATTERN}', 'c')", name="action_format"),
        CheckConstraint("CHAR_LENGTH(TRIM(entity_type)) > 0", name="entity_type_not_blank"),
    )

    # NULL = action du système (webhook du prestataire, tâche planifiée…).
    actor_id: Mapped[int | None] = mapped_column(foreign_key("users.id"))
    action: Mapped[str] = mapped_column(String(64))
    entity_type: Mapped[str] = mapped_column(String(64))  # ex. bill, user, payment_transaction
    entity_id: Mapped[int | None] = mapped_column(BigInteger)
    # none_as_null : Python None → SQL NULL (sinon SQLAlchemy écrirait le texte JSON « null »).
    before_json: Mapped[dict[str, Any] | None] = mapped_column(JSON(none_as_null=True))
    after_json: Mapped[dict[str, Any] | None] = mapped_column(JSON(none_as_null=True))
    ip: Mapped[str | None] = mapped_column(String(45))  # IPv4 ou IPv6
    user_agent: Mapped[str | None] = mapped_column(String(255))  # navigateur / app (écran A10)
    created_at: Mapped[datetime] = mapped_column(
        UTCDateTime(), default=utcnow, nullable=False, sort_order=100
    )
