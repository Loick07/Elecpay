"""Qui peut faire quoi dans le back-office (matrice validée, maquettes admin A11).

Trois niveaux, contrôlés CÔTÉ SERVEUR sur chaque route `/admin` :

| Niveau        | Rôles                       | Exemples                                     |
|---------------|-----------------------------|----------------------------------------------|
| `staff`       | support, admin, super admin | consulter clients, factures, transactions    |
| `admin`       | admin, super admin          | journal, désactiver un compte, annuler       |
| `super_admin` | super admin                 | tarifs, rôles, inviter un membre             |

Une route se déclare avec `admin_route(router, "GET", "/…", Permission.STAFF, …)` : le contrôle
du rôle ET la mention `x-permission` du contrat OpenAPI viennent du même endroit, et un test
vérifie chaque route `/admin` pour chaque rôle. « Marquer une transaction comme réussie » :
JAMAIS, pour personne (aucune route ne le permet).
"""

from collections.abc import Callable
from dataclasses import dataclass
from enum import StrEnum
from typing import Any

from fastapi import APIRouter, Depends

from app.modules.auth.dependencies import require_role
from app.modules.users.models import UserRole


class Permission(StrEnum):
    STAFF = "staff"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"


ROLES: dict[Permission, frozenset[UserRole]] = {
    Permission.STAFF: frozenset({UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN}),
    Permission.ADMIN: frozenset({UserRole.ADMIN, UserRole.SUPER_ADMIN}),
    Permission.SUPER_ADMIN: frozenset({UserRole.SUPER_ADMIN}),
}
OPENAPI_KEY = "x-permission"


@dataclass(frozen=True, slots=True)
class Capability:
    """Une ligne de la matrice affichée dans l'onglet « Permissions » (A11)."""

    key: str
    label: str
    permission: Permission | None  # None : jamais, pour personne


CAPABILITIES: tuple[Capability, ...] = (
    Capability("view", "Consulter clients, factures, transactions", Permission.STAFF),
    Capability("view_audit_log", "Consulter le journal", Permission.ADMIN),
    Capability("toggle_account", "Désactiver / réactiver un compte", Permission.ADMIN),
    Capability("cancel_bill", "Annuler une facture (motif)", Permission.ADMIN),
    Capability(
        "recheck_transaction", "Relancer la vérification d'une transaction", Permission.ADMIN
    ),
    Capability("send_announcement", "Envoyer une annonce", Permission.ADMIN),
    Capability("edit_tariffs", "Modifier les tarifs", Permission.SUPER_ADMIN),
    Capability("manage_team", "Attribuer des rôles, inviter un membre", Permission.SUPER_ADMIN),
    Capability("force_payment_success", "Marquer une transaction comme réussie", None),
)


def roles_for(permission: Permission | None) -> frozenset[UserRole]:
    return ROLES[permission] if permission is not None else frozenset()


def allows(role: UserRole, permission: Permission | None) -> bool:
    return role in roles_for(permission)


def admin_route(
    router: APIRouter, method: str, path: str, permission: Permission, **options: Any
) -> Callable:
    """Décorateur de route du back-office : contrôle du rôle + mention dans le contrat.

    Le gardien est ajouté aux `dependencies` de la route : il s'exécute avant tout le reste
    (un client reçoit 403 même si sa requête est mal formée).
    """
    dependencies = [Depends(require_role(*ROLES[permission])), *options.pop("dependencies", [])]
    openapi_extra = {OPENAPI_KEY: permission.value} | options.pop("openapi_extra", {})
    return router.api_route(
        path,
        methods=[method],
        dependencies=dependencies,
        openapi_extra=openapi_extra,
        **options,
    )
