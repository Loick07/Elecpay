"""Schémas d'API des utilisateurs."""

from datetime import datetime
from typing import Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core.validation import Email, FullName
from app.modules.users.models import UserRole


class UserPublic(BaseModel):
    """Profil renvoyé par l'API. Jamais d'empreinte de mot de passe."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    phone: str
    email: str | None
    role: UserRole
    is_active: bool
    last_login_at: datetime | None
    created_at: datetime


class UpdateProfileRequest(BaseModel):
    """Champs modifiables. Un champ absent n'est pas modifié ; `"email": null` retire l'e-mail."""

    model_config = ConfigDict(extra="forbid")  # ex. "role" ou "phone" : refusés

    full_name: FullName | None = Field(default=None, examples=["Grâce Ngoma"])
    email: Email | None = Field(default=None, examples=["grace.ngoma@example.com"])

    @model_validator(mode="after")
    def something_to_change(self) -> Self:
        if not self.model_fields_set:
            raise ValueError("Indiquez au moins un champ à modifier (full_name, email)")
        if "full_name" in self.model_fields_set and self.full_name is None:
            raise ValueError("Le nom ne peut pas être vide")
        return self
