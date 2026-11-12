"""Limites de tentatives de l'authentification (validées le 12/11/2026).

Toutes au même endroit pour pouvoir les ajuster. Les clés distinguent l'action, le type
(numéro ou adresse IP) et la valeur : « login:phone:+242061112233 », « forgot:ip:196.44.0.1 ».
"""

from app.core.rate_limit import Limit
from app.core.request_context import RequestContext

MINUTES = 60
HOUR = 3600

# Connexion : 5 ÉCHECS par numéro (deviner un mot de passe), 20 TENTATIVES par IP.
LOGIN_FAILURES_PER_PHONE = Limit(5, 15 * MINUTES)
LOGIN_ATTEMPTS_PER_IP = Limit(20, 15 * MINUTES)
# Mot de passe oublié : chaque code part par SMS, et un SMS coûte de l'argent.
FORGOT_PER_PHONE = Limit(3, HOUR)
FORGOT_PER_IP = Limit(10, HOUR)
# Réinitialisation : en plus des 5 essais par code.
RESET_ATTEMPTS_PER_IP = Limit(10, 15 * MINUTES)
# Inscription : pas de création massive de comptes.
REGISTER_PER_IP = Limit(5, HOUR)


def ip_key(action: str, context: RequestContext) -> str:
    return f"{action}:ip:{context.ip or 'inconnue'}"


def phone_key(action: str, phone: str) -> str:
    return f"{action}:phone:{phone}"
