"""Configuration de l'API, lue depuis les variables d'environnement et le fichier `.env`.

Toute la configuration passe par `get_settings()` : aucun autre module ne lit `os.environ`.
Les valeurs sont validées au démarrage ; une configuration invalide empêche l'API de démarrer.
"""

from functools import lru_cache
from ipaddress import IPv4Network, IPv6Network, ip_network
from pathlib import Path
from typing import Annotated, Literal, Self
from urllib.parse import urlsplit

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

from app.core.secret_box import derive_key

# backend/.env, quel que soit le dossier depuis lequel on lance l'API.
BACKEND_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = BACKEND_DIR / ".env"

INSECURE_JWT_SECRETS = {"", "change-me", "secret", "changeme"}
MIN_JWT_SECRET_LENGTH = 32

API_PREFIX = "/api/v1"  # préfixe de toutes les routes (versionnées)
HTTPS = "https://"


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

    # Paiements Mobile Money
    # Secret partagé avec le prestataire pour signer ses webhooks (HMAC-SHA256). Vide : tout
    # webhook est refusé. Obligatoire (≥ 32 caractères) en production.
    payment_webhook_secret: SecretStr = SecretStr("")
    # Sans saisie du code PIN dans ce délai, la transaction expire (« PIN saisi » : jamais).
    payment_timeout_minutes: int = Field(default=10, ge=1, le=60)

    # Reçus : adresse de la vérification publique, imprimée dans le QR code du reçu PDF
    # (suivie de « /<code> »). Par défaut, la route de l'API ; une page web plus tard.
    receipt_verify_url: str = "http://127.0.0.1:8000/api/v1/receipts/verify"

    @field_validator("receipt_verify_url")
    @classmethod
    def verify_url_is_http(cls, value: str) -> str:
        if not value.startswith(("http://", HTTPS)):
            raise ValueError("doit commencer par http:// ou https://")
        return value.rstrip("/")

    # Facturation (voir backend/docs/FACTURE_E2C.md). E²C facture tous les 2 mois, périodes
    # calées sur le calendrier (janvier-février, mars-avril…). Délais : hypothèses à vérifier.
    billing_period_months: int = 2  # 1, 2, 3, 4, 6 ou 12 (doit diviser 12)
    bill_issue_delay_days: int = Field(default=3, ge=0, le=30)  # émission après fin de période
    bill_due_delay_days: int = Field(default=15, ge=1, le=90)  # échéance après émission

    # CORS : origines autorisées, séparées par des virgules dans le .env
    cors_origins: Annotated[list[str], NoDecode] = Field(default_factory=list)

    # Proxys inverses de confiance (IP ou réseau CIDR, séparés par des virgules), ex. le
    # répartiteur de charge de l'hébergeur. Seulement derrière eux, l'IP réelle du client est
    # lue dans X-Forwarded-For ; vide = l'en-tête est ignoré (personne ne peut usurper une IP).
    trusted_proxies: Annotated[list[str], NoDecode] = Field(default_factory=list)
    # Limite globale de requêtes par IP et par minute (en plus des limites de l'auth). 0 = aucune.
    rate_limit_per_minute: int = Field(default=300, ge=0, le=100_000)

    # Double authentification de l'équipe (B11.3). Clé de chiffrement des secrets TOTP en base :
    # obligatoire en production (≥ 32 caractères, différente de JWT_SECRET) ; dérivée de
    # JWT_SECRET si vide (développement, tests). 2FA obligatoire pour admin et super admin.
    two_factor_key: SecretStr = SecretStr("")
    team_2fa_required: bool = True

    # Journaux techniques (B11.2) : JSON en production, texte en développement si non précisé.
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"
    log_format: Literal["text", "json"] | None = None

    @field_validator("cors_origins", "trusted_proxies", mode="before")
    @classmethod
    def split_comma_list(cls, value: object) -> object:
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    @field_validator("trusted_proxies")
    @classmethod
    def proxies_are_networks(cls, value: list[str]) -> list[str]:
        for item in value:
            try:
                ip_network(item, strict=False)
            except ValueError as error:
                raise ValueError(f"proxy de confiance invalide : {item!r}") from error
        return value

    @field_validator("cors_origins")
    @classmethod
    def origins_are_bare(cls, value: list[str]) -> list[str]:
        """Une origine = schéma + hôte (+ port), sans chemin : « https://admin.elecpay.cg »."""
        for origin in value:
            if origin == "*":
                continue  # refusée avec un message dédié (forbid_wildcard_origin)
            parts = urlsplit(origin)
            if parts.scheme not in ("http", "https") or not parts.netloc or parts.path:
                raise ValueError(
                    f"origine CORS invalide : {origin!r} (ex. https://admin.elecpay.cg)"
                )
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
        if len(self.payment_webhook_secret.get_secret_value()) < MIN_JWT_SECRET_LENGTH:
            raise ValueError(
                f"PAYMENT_WEBHOOK_SECRET doit faire au moins {MIN_JWT_SECRET_LENGTH} caractères "
                "aléatoires en production"
            )
        if not self.receipt_verify_url.startswith(HTTPS):
            raise ValueError("RECEIPT_VERIFY_URL doit être en https:// en production")
        two_factor_key = self.two_factor_key.get_secret_value()
        if len(two_factor_key) < MIN_JWT_SECRET_LENGTH or two_factor_key == secret:
            raise ValueError(
                f"TWO_FACTOR_KEY doit faire au moins {MIN_JWT_SECRET_LENGTH} caractères "
                "aléatoires en production, et être différente de JWT_SECRET"
            )
        if not self.team_2fa_required:
            raise ValueError("TEAM_2FA_REQUIRED doit rester à true en production")
        if any(not origin.startswith(HTTPS) for origin in self.cors_origins):
            raise ValueError("CORS_ORIGINS : uniquement des origines en https:// en production")
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

    @property
    def two_factor_cipher_key(self) -> bytes:
        """Clé AES-256 des secrets TOTP (voir app/core/secret_box.py)."""
        material = self.two_factor_key.get_secret_value() or self.jwt_secret.get_secret_value()
        return derive_key(material, "totp")

    @property
    def trusted_networks(self) -> tuple[IPv4Network | IPv6Network, ...]:
        return tuple(ip_network(item, strict=False) for item in self.trusted_proxies)


@lru_cache
def get_settings() -> Settings:
    """Configuration unique de l'application (lue une seule fois, puis mise en cache)."""
    return Settings()  # type: ignore[call-arg]  # les valeurs viennent de l'environnement
