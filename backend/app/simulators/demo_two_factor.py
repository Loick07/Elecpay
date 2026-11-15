"""Double authentification des comptes de DÉMO (B11.3, option validée par Loick le 14/11/2026).

La 2FA est obligatoire pour admin et super admin : sans elle, le back-office de démo serait
fermé. Les comptes de démo admin et super admin reçoivent donc une 2FA DÉJÀ ACTIVE, avec un
secret fixe et public (il est imprimé par `scripts.seed` et écrit ici) : on l'ajoute une fois
dans son application d'authentification. Un secret connu de tous n'est acceptable QUE pour des
données de démonstration : `scripts.seed` refuse de tourner en production.
"""

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core import totp
from app.core.config import Settings
from app.core.secret_box import encrypt
from app.modules.auth.models import TwoFactorSecret
from app.modules.auth.two_factor import REQUIRED_ROLES
from app.modules.users.models import User

# 32 caractères base32 (20 octets). Public : DÉMO UNIQUEMENT.
DEMO_TOTP_SECRET = "ELECPAYDEMO2FASECRETPOURLESTESTS"  # noqa: S105 — public, démo, voulu
DEMO_TOTP_LABEL = "Comptes de démo ElecPay"


def enable_demo_two_factor(session: Session, settings: Settings) -> list[User]:
    """Active la 2FA (secret de démo) des comptes admin et super admin. Pas de commit."""
    members = session.scalars(
        select(User).where(User.role.in_(REQUIRED_ROLES)).order_by(User.id)
    ).all()
    now = datetime.now(UTC)
    for member in members:
        session.add(
            TwoFactorSecret(
                user_id=member.id,
                secret_encrypted=encrypt(DEMO_TOTP_SECRET, settings.two_factor_cipher_key),
                enabled_at=now,
            )
        )
    session.flush()
    return list(members)


def demo_provisioning_uri() -> str:
    return totp.provisioning_uri(DEMO_TOTP_SECRET, DEMO_TOTP_LABEL, issuer="ElecPay démo")
