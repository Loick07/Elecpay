"""Routes du back-office (`/api/v1/admin`). Chaque route se déclare avec `admin_route`.

Les écrans arrivent sous-étape par sous-étape (B10.2 → B10.9) ; ce routeur les rassemble.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.modules.admin.announcements_router import router as announcements_router
from app.modules.admin.bills_router import router as bills_router
from app.modules.admin.journal_router import router as journal_router
from app.modules.admin.meters_router import router as meters_router
from app.modules.admin.permissions import (
    CAPABILITIES,
    Permission,
    admin_route,
    allows,
    roles_for,
)
from app.modules.admin.schemas import CapabilityPublic, MyPermissions
from app.modules.admin.settings_router import router as settings_router
from app.modules.admin.stats import AdminStatsService
from app.modules.admin.stats_schemas import AdminStats
from app.modules.admin.transactions_router import router as transactions_router
from app.modules.admin.users_router import router as users_router
from app.modules.auth.dependencies import current_user
from app.modules.users.models import User

router = APIRouter(prefix="/admin", tags=["Back-office"])
router.include_router(users_router)
router.include_router(meters_router)
router.include_router(bills_router)
router.include_router(transactions_router)
router.include_router(announcements_router)
router.include_router(journal_router)
router.include_router(settings_router)


@admin_route(
    router,
    "GET",
    "/stats",
    Permission.STAFF,
    response_model=AdminStats,
    summary="Tableau de bord (A1) : indicateurs, encaissements 30 jours, points à surveiller",
    description="Encaissé du mois (comparé au mois précédent au même moment), factures "
    "impayées, taux de paiements non aboutis sur 7 jours, transactions en attente, "
    "encaissements jour par jour, dernière période facturée par statut, points « À "
    "surveiller », activité récente de l'équipe. Heure de Brazzaville ; FCFA entiers.",
)
def admin_stats(
    db: Session = Depends(get_db), settings: Settings = Depends(get_settings)
) -> AdminStats:
    return AdminStatsService(db, demo=settings.demo_mode).stats()


@admin_route(
    router,
    "GET",
    "/permissions",
    Permission.STAFF,
    response_model=MyPermissions,
    summary="Mes droits dans le back-office (matrice de l'onglet « Permissions », A11)",
    description="Pour afficher ou masquer les boutons. Le serveur contrôle de toute façon "
    "chaque route (403 sinon). « Marquer une transaction comme réussie » : jamais.",
)
def my_permissions(user: User = Depends(current_user)) -> MyPermissions:
    return MyPermissions(
        role=user.role,
        levels=[level for level in Permission if allows(user.role, level)],
        capabilities=[
            CapabilityPublic(
                key=capability.key,
                label=capability.label,
                roles=sorted(roles_for(capability.permission)),
                allowed=allows(user.role, capability.permission),
            )
            for capability in CAPABILITIES
        ],
    )
