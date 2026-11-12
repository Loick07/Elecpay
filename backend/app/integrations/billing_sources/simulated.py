"""Source E²C simulée (mode démo).

Ce qu'elle sait vérifier, honnêtement :
- Les compteurs du jeu de démo : connus avec leur couple exact (branchement, client) ;
  un mauvais N° client est refusé.
- Un autre compteur : la simulation ne peut pas connaître le vrai N° client, elle accepte donc
  tout couple bien formé, avec des caractéristiques STABLES (même branchement → même compteur).
  Exception voulue : un branchement qui finit par « 0000 » est « introuvable », pour tester et
  montrer ce cas.
Avec la vraie API E²C, c'est E²C qui vérifiera le couple.
"""

import hashlib
from functools import cache

from app.integrations.billing_sources.base import (
    E2CMeterInfo,
    display_reference,
    normalize_customer_number,
    normalize_reference,
)
from app.modules.meters.models import MeterType
from app.simulators.demo_dataset import CLIENTS, E2C_CENTERS

NOT_FOUND_SUFFIX = "0000"
SIMULATED_POWERS_VA = (2_200, 3_000, 4_400, 6_000, 9_000)
SIMULATED_CENTERS = ("POINTE-NOIRE", "BRAZZAVILLE", "DOLISIE")


@cache
def demo_registry() -> dict[str, E2CMeterInfo]:
    """Les compteurs du jeu de démo, indexés par N° de branchement (chiffres seuls)."""
    registry = {}
    for person in CLIENTS:
        for household in person.households:
            for meter in household.meters:
                registry[normalize_reference(meter.reference)] = E2CMeterInfo(
                    reference=meter.reference,
                    customer_number=normalize_customer_number(meter.customer_number),
                    contract_number=meter.contract_number,
                    e2c_center=E2C_CENTERS[household.city],
                    subscribed_power_va=meter.power_va,
                    meter_type=MeterType.POSTPAID,
                )
    return registry


class SimulatedBillingSource:
    def lookup_meter(self, reference: str, customer_number: str) -> E2CMeterInfo | None:
        known = demo_registry().get(reference)
        if known is not None:
            return known if known.customer_number == customer_number else None
        if reference.endswith(NOT_FOUND_SUFFIX):
            return None
        return self._generated(reference, customer_number)

    @staticmethod
    def _generated(reference: str, customer_number: str) -> E2CMeterInfo:
        """Caractéristiques déduites du numéro : toujours les mêmes pour le même compteur."""
        seed = int(hashlib.sha256(reference.encode()).hexdigest(), 16)
        return E2CMeterInfo(
            reference=display_reference(reference),
            customer_number=customer_number,
            contract_number=f"{reference[-7:]}K",
            e2c_center=SIMULATED_CENTERS[seed % len(SIMULATED_CENTERS)],
            subscribed_power_va=SIMULATED_POWERS_VA[(seed // 7) % len(SIMULATED_POWERS_VA)],
            meter_type=MeterType.POSTPAID,
        )
