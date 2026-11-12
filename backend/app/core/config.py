"""Configuration de l'API, lue depuis les variables d'environnement et le fichier `.env`.

Toute la configuration passe par `get_settings()` : aucun autre module ne lit `os.environ`.
Les valeurs sont validées au démarrage ; une configuration invalide empêche l'API de démarrer.
"""

from functools import lru_cache
from pathlib import Path
from typing import Annotated, Literal, Self

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

# backend/.env, quel que soit le dossier depuis lequel on lance l'API.
BACKEND_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = BACKEND_DIR / ".env"

INSECURE_JWT_SECRETS = {"", "change-me", "secret", "changeme"}
MIN_JWT_SECRET_LENGTH = 32

API_PREFIX = "/api/v1"  # préfixe de toutes les routes (versionnées)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",  # une variable inconnue dans le .env n'empêche pas le démarrage
    )

    app_env: Literal["development", "test", "production"] = "development"

    # Base de données
    database_url: str
    test_database_url: str | None = None

    # Authentification
    jwt_secret: SecretStr  # SecretStr : jamais affiché en clair dans les logs ou les erreurs
    access_token_minutes: int = Field(default=15, ge=1, le=60)
    refresh_token_days: int = Field(default=30, ge=1, le=90)
    # Cookies du back-office envoyés uniquement en HTTPS. À désactiver seulement pour un
    # développement en HTTP qui ne passe pas par localhost.
    auth_cookie_secure: bool = True

    # Intégrations (seuls les simulateurs existent pour l'instant)
    payment_provider: Literal["simulated"] = "simulated"
    billing_source: Literal["simulated"] = "simulated"
    demo_mode: bool = True

    # Facturation (voir backend/docs/FACTURE_E2C.md). E²C facture tous les 2 mois, périodes
    # calées sur le calendrier (janvier-février, mars-avril…). Délais : hypothèses à vérifier.
    billing_period_months: int = 2  # 1, 2, 3, 4, 6 ou 12 (doit diviser 12)
    bill_issue_delay_days: int = Field(default=3, ge=0, le=30)  # émission après fin de période
    bill_due_delay_days: int = Field(default=15, ge=1, le=90)  # échéance après émission

    # CORS : origines autorisées, séparées par des virgules dans le .env
    cors_origins: Annotated[list[str], NoDecode] = Field(default_factory=list)

    @field_validator("cors_origins", mode="before")
    @classmethod
    def split_cors_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @field_validator("billing_period_months")
    @classmethod
    def period_divides_the_year(cls, value: int) -> int:
        if value < 1 or 12 % value != 0:
            raise ValueError("doit valoir 1, 2, 3, 4, 6 ou 12 (périodes calées sur l'année)")
        return value

    @field_validator("cors_origins")
    @classmethod
    def forbid_wildcard_origin(cls, value: list[str]) -> list[str]:
        if "*" in value:
            raise ValueError("CORS strict : l'origine '*' est interdite, lister les origines")
        return value

    @model_validator(mode="after")
    def check_production_safety(self) -> Self:
        if self.app_env != "production":
            return self
        if not self.auth_cookie_secure:
            raise ValueError("AUTH_COOKIE_SECURE doit rester à true en production (HTTPS)")
        secret = self.jwt_secret.get_secret_value()
        if secret.lower() in INSECURE_JWT_SECRETS or len(secret) < MIN_JWT_SECRET_LENGTH:
            raise ValueError(
                f"JWT_SECRET doit faire au moins {MIN_JWT_SECRET_LENGTH} caractères aléatoires "
                "en production"
            )
        uses_simulation = "simulated" in (self.payment_provider, self.billing_source)
        if uses_simulation and not self.demo_mode:
            raise ValueError(
                "Des sources simulées sont actives : DEMO_MODE doit rester à true "
                "(une donnée simulée ne doit jamais passer pour réelle)"
            )
        return self

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    """Configuration unique de l'application (lue une seule fois, puis mise en cache)."""
    return Settings()  # type: ignore[call-arg]  # les valeurs viennent de l'environnement
