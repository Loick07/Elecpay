"""Schémas d'API de l'authentification (ce qui entre et ce qui sort)."""

from datetime import datetime
from typing import Literal

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


# --- Double authentification de l'équipe (B11.3) ------------------------------------------


class TwoFactorChallenge(BaseModel):
    """Mot de passe correct, mais un code est demandé (membre de l'équipe avec la 2FA)."""

    two_factor_required: Literal[True] = True
    challenge_token: str = Field(description="À renvoyer avec le code ; valable 5 minutes")
    expires_at: datetime
    methods: list[str] = Field(default=["totp", "backup_code"])


class TwoFactorLoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    challenge_token: str = Field(min_length=20, max_length=1000)
    code: str = Field(
        min_length=6,
        max_length=12,
        description="6 chiffres de l'application, ou un code de secours « ABCD-EFGH »",
        examples=["123456"],
    )


class TwoFactorStatus(BaseModel):
    enabled: bool
    pending_setup: bool = Field(description="QR code affiché, premier code pas encore saisi")
    required: bool = Field(description="Obligatoire pour mon rôle (admin, super admin)")
    enabled_at: datetime | None
    backup_codes_left: int


class TwoFactorSetupResponse(BaseModel):
    secret: str = Field(description="À saisir à la main si le QR code ne peut pas être scanné")
    otpauth_uri: str = Field(description="Contenu du QR code (Google Authenticator, etc.)")
    qr_svg: str = Field(description="QR code prêt à afficher (SVG)")


class TwoFactorCodeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    code: str = Field(pattern=r"^[0-9]{6}$", examples=["123456"])


class TwoFactorDisableRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    password: str = Field(min_length=1, max_length=128)
    code: str = Field(pattern=r"^[0-9]{6}$")


class BackupCodesResponse(BaseModel):
    backup_codes: list[str] = Field(
        description="À noter et garder en lieu sûr : montrés UNE seule fois, un usage chacun"
    )
