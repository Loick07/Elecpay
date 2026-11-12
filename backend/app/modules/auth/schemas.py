"""Schémas d'API de l'authentification (ce qui entre et ce qui sort)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.validation import (
    PASSWORD_MAX_LENGTH,
    CongoPhone,
    Email,
    FullName,
    NewPassword,
)
from app.modules.users.schemas import UserPublic


class RegisterRequest(BaseModel):
    # extra="forbid" : un champ inattendu (ex. "role": "admin") est refusé, jamais ignoré.
    model_config = ConfigDict(extra="forbid")

    full_name: FullName = Field(examples=["Grâce Ngoma"])
    phone: CongoPhone = Field(examples=["06 123 45 67"])
    email: Email | None = Field(default=None, examples=["grace.ngoma@example.com"])
    password: NewPassword = Field(examples=["Demo2026!"])


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: CongoPhone = Field(examples=["+242060000101"])
    # Pas de règle de force ici (l'ancien mot de passe peut être plus faible) ;
    # seulement une longueur maximale, pour ne pas hacher des textes géants.
    password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH, examples=["Demo2026!"])


# Nos jetons font 64 caractères. La limite est large pour qu'un mauvais jeton plausible
# (ex. un jeton d'accès JWT envoyé par erreur) reçoive un 401 clair, pas un 422 ;
# elle bloque seulement les envois géants.
REFRESH_TOKEN_MAX_LENGTH = 1_024


class RefreshRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    refresh_token: str = Field(min_length=1, max_length=REFRESH_TOKEN_MAX_LENGTH)


class ForgotPasswordRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: CongoPhone = Field(examples=["+242060000101"])


class ForgotPasswordResponse(BaseModel):
    message: str
    expires_in: int = Field(description="Durée de validité du code, en secondes")
    demo_code: str | None = Field(
        default=None,
        description="MODE DÉMO UNIQUEMENT : le code, affiché à l'écran au lieu d'un vrai SMS",
    )


class ResetPasswordRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: CongoPhone = Field(examples=["+242060000101"])
    code: str = Field(pattern=r"^[0-9]{6}$", examples=["048213"])
    new_password: NewPassword = Field(examples=["Nouveau2026!"])


class ChangePasswordRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    current_password: str = Field(min_length=1, max_length=PASSWORD_MAX_LENGTH)
    new_password: NewPassword


class LogoutAllResponse(BaseModel):
    revoked_sessions: int = Field(description="Nombre de sessions (appareils) déconnectées")


class WebSessionResponse(BaseModel):
    """Réponse du back-office : les jetons sont dans des cookies httpOnly, jamais dans le JSON."""

    access_expires_at: datetime
    refresh_expires_at: datetime
    user: UserPublic


class TokenResponse(BaseModel):
    """Réponse de connexion, d'inscription et de rafraîchissement."""

    token_type: str = "bearer"  # noqa: S105 — nom standard du type de jeton (RFC 6750)
    access_token: str
    access_expires_at: datetime
    expires_in: int = Field(description="Durée de validité du jeton d'accès, en secondes")
    refresh_token: str
    refresh_expires_at: datetime
    user: UserPublic
