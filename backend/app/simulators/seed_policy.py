"""Mot de passe et double authentification des comptes créés par `scripts.seed` (M1.1).

Le mot de passe « Demo2026! » et le secret 2FA de démo sont PUBLICS (dépôt, documentation) : ils ne
servent qu'en développement. Dès que la base est joignable par d'autres (production, API exposée
par ngrok), le seed exige un mot de passe choisi sur le serveur et tire au hasard un secret 2FA par
membre de l'équipe :

- production : `DEMO_MODE=true` obligatoire (des données de démo ne vont jamais dans une vraie
  production) ; `DEMO_SEED_PASSWORD` obligatoire, ni vide, ni « Demo2026! » (quelle que soit
  l'écriture), et conforme aux règles d'inscription ; secrets 2FA tirés au hasard ;
- développement / tests : sans `DEMO_SEED_PASSWORD`, rien ne change (mot de passe et secret
  publics, utilisés par les tests et la base `elecpay_e2e`) ; avec, mêmes règles qu'en production.
"""

from dataclasses import dataclass, field

from app.core import totp
from app.core.config import Settings
from app.core.validation import check_password_strength
from app.simulators.demo_dataset import DEMO_PASSWORD
from app.simulators.demo_two_factor import DEMO_TOTP_SECRET


class SeedRefusedError(RuntimeError):
    """Le seed refuse de tourner avec cette configuration (message pour l'opérateur)."""


@dataclass(frozen=True)
class SeedCredentials:
    """Ce que le seed donne aux comptes. `repr` ne montre jamais le mot de passe."""

    password: str = field(repr=False)
    # True : mot de passe et secret 2FA publics (développement seulement).
    public: bool

    def totp_secret(self) -> str:
        """Secret 2FA d'UN membre de l'équipe : le secret public, ou un nouveau tiré au hasard."""
        return DEMO_TOTP_SECRET if self.public else totp.new_secret()


def _is_public_password(raw: str) -> bool:
    return raw.strip().casefold() == DEMO_PASSWORD.casefold()


def _checked(raw: str) -> str:
    if not raw.strip():
        raise SeedRefusedError(
            "Refusé : DEMO_SEED_PASSWORD est vide. Choisir un mot de passe sur le serveur "
            "(8 caractères minimum, au moins une lettre et un chiffre)."
        )
    if _is_public_password(raw):
        raise SeedRefusedError(
            f"Refusé : « {DEMO_PASSWORD} » est public (dépôt, documentation). Choisir un autre "
            "mot de passe dans DEMO_SEED_PASSWORD."
        )
    try:
        return check_password_strength(raw)
    except ValueError as error:
        raise SeedRefusedError(f"Refusé : DEMO_SEED_PASSWORD trop faible ({error}).") from error


def seed_credentials(settings: Settings) -> SeedCredentials:
    """Mot de passe et mode 2FA du seed pour cette configuration, ou `SeedRefusedError`."""
    raw = settings.demo_seed_password.get_secret_value()
    if settings.is_production:
        if not settings.demo_mode:
            raise SeedRefusedError(
                "Refusé : APP_ENV=production sans DEMO_MODE=true. Des données de démo ne vont "
                "jamais dans une vraie production."
            )
        return SeedCredentials(password=_checked(raw), public=False)
    if raw:
        return SeedCredentials(password=_checked(raw), public=False)
    return SeedCredentials(password=DEMO_PASSWORD, public=True)
