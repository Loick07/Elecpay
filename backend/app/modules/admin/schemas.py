"""Schémas d'API communs du back-office."""

from pydantic import BaseModel, Field

from app.modules.admin.permissions import Permission
from app.modules.users.models import UserRole


class CapabilityPublic(BaseModel):
    key: str = Field(examples=["cancel_bill"])
    label: str = Field(examples=["Annuler une facture (motif)"])
    roles: list[UserRole] = Field(description="Rôles autorisés (vide : jamais, pour personne)")
    allowed: bool = Field(description="Le membre connecté peut-il le faire ?")


class MyPermissions(BaseModel):
    """Ce que le membre connecté peut faire : le back-office affiche ou masque ses boutons
    d'après `allowed` (le serveur contrôle de toute façon chaque route)."""

    role: UserRole
    levels: list[Permission] = Field(description="Niveaux accessibles : staff, admin, super_admin")
    capabilities: list[CapabilityPublic]
