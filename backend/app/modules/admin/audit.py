"""Journal des actions du back-office : chaque écriture d'un membre de l'équipe y laisse une ligne.

`record_admin_action` est le passage obligé des routes d'écriture `/admin` : il exige l'auteur
(un membre de l'équipe) et le contexte de la requête (IP, navigateur, affichés en A10). Le
journal refuse toute donnée secrète (mot de passe, jeton, code) et n'est jamais modifié.
Pas de commit : la ligne part avec l'action qu'elle décrit (les deux, ou aucune).
"""

from typing import Any

from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.modules.audit.models import AuditLog
from app.modules.audit.service import record
from app.modules.users.models import User, UserRole

STAFF_ROLES = frozenset({UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN})


def record_admin_action(
    session: Session,
    *,
    actor: User,
    context: RequestContext,
    action: str,
    entity_type: str,
    entity_id: int | None,
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
) -> AuditLog:
    if actor.role not in STAFF_ROLES:
        raise ValueError("Seul un membre de l'équipe agit dans le back-office")
    return record(
        session,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        actor_id=actor.id,
        context=context,
        before=before,
        after=after,
    )
