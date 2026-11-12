"""Écriture dans le journal d'audit (table `audit_logs`, jamais modifiée ni supprimée).

Règle : ne jamais y mettre de mot de passe, de jeton, de code ou d'empreinte.
"""

from typing import Any

from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.db.base import utcnow
from app.modules.audit.models import AuditLog

FORBIDDEN_KEYS = {"password", "password_hash", "token", "refresh_token", "access_token", "code"}


def record(
    session: Session,
    *,
    action: str,
    entity_type: str,
    entity_id: int | None,
    actor_id: int | None,
    context: RequestContext | None = None,
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
) -> AuditLog:
    """Ajoute une ligne d'audit (sans valider : elle part avec la transaction de l'action)."""
    for state in (before, after):
        if state and FORBIDDEN_KEYS & set(state):
            raise ValueError("Donnée secrète interdite dans le journal d'audit")
    log = AuditLog(
        actor_id=actor_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        before_json=before,
        after_json=after,
        ip=context.ip if context else None,
        user_agent=context.user_agent if context else None,
        created_at=utcnow(),
    )
    session.add(log)
    return log
