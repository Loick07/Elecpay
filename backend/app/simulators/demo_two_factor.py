"""Double authentification des comptes de DÉMO (B11.3, option validée par Loick le 14/11/2026).

La 2FA est obligatoire pour admin et super admin : sans elle, le back-office de démo serait
fermé. Les comptes de démo admin et super admin reçoivent donc une 2FA DÉJÀ ACTIVE, avec un
secret fixe et public (il est imprimé par `scripts.seed` et écrit ici) : on l'ajoute une fois
dans son application d'authentification. Un secret connu de tous n'est acceptable QUE pour des
données de démonstration locales : en production (et dès que DEMO_SEED_PASSWORD est donné),
`scripts.seed` tire au hasard un secret par membre (M1.1, app/simulators/seed_policy.py).
"""

from collections.abc import Callable
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


def enable_team_two_factor(
    session: Session, settings: Settings, secret_for: Callable[[User], str]
) -> list[tuple[User, str]]:
    """Active la 2FA des comptes admin et super admin, avec le secret donné par `secret_for`
    (secret de démo, ou tiré au hasard pour chacun : M1.1). Secrets chiffrés en base.
    Renvoie (membre, secret en clair) pour l'affichage UNIQUE par `scripts.seed`. Pas de commit."""
    members = session.scalars(
        select(User).where(User.role.in_(REQUIRED_ROLES)).order_by(User.id)
    ).all()
    now = datetime.now(UTC)
    secured = []
    for member in members:
        secret = secret_for(member)
        session.add(
            TwoFactorSecret(
                user_id=member.id,
                secret_encrypted=encrypt(secret, settings.two_factor_cipher_key),
                enabled_at=now,
            )
        )
        secured.append((member, secret))
    session.flush()
    return secured


def enable_demo_two_factor(session: Session, settings: Settings) -> list[User]:
    """Active la 2FA (secret PUBLIC de démo) des comptes admin et super admin. Pas de commit."""
    secured = enable_team_two_factor(session, settings, lambda _member: DEMO_TOTP_SECRET)
    return [member for member, _ in secured]


def demo_provisioning_uri() -> str:
    return totp.provisioning_uri(DEMO_TOTP_SECRET, DEMO_TOTP_LABEL, issuer="ElecPay démo")
