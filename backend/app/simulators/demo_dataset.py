"""Jeu de données de démonstration : personnes, foyers et compteurs FICTIFS.

Aucune donnée réelle : noms inventés, numéros de la forme +242 06 000 0xxx, e-mails sur
le domaine réservé example.com, références de compteur inventées. Les foyers « Maison Mpita »
et « Boutique Tié-Tié » (avec Grâce Ngoma payeuse déléguée) reprennent les maquettes validées.
"""

from dataclasses import dataclass, field

from app.modules.households.models import MemberRole
from app.modules.users.models import UserRole
from app.simulators.readings import ProfileName

# Mot de passe de TOUS les comptes de démo (affiché sur l'écran de connexion en mode démo).
DEMO_PASSWORD = "Demo2026!"  # noqa: S105 — mot de passe public de démonstration, voulu


@dataclass(frozen=True)
class DemoMeter:
    reference: str  # N° Branchement (fictif)
    label: str
    profile: ProfileName
    power_va: int
    customer_number: str  # N° Client (fictif)
    contract_number: str  # N° Police (fictif)


@dataclass(frozen=True)
class DemoHousehold:
    name: str
    district: str
    city: str
    address: str
    meters: tuple[DemoMeter, ...]
    # Autres membres : (clé du client, rôle).
    members: tuple[tuple[str, MemberRole], ...] = ()


@dataclass(frozen=True)
class DemoPerson:
    key: str
    full_name: str
    phone: str
    role: UserRole = UserRole.CLIENT
    email: str | None = None
    households: tuple[DemoHousehold, ...] = field(default_factory=tuple)


E2C_CENTERS = {"Pointe-Noire": "POINTE-NOIRE", "Brazzaville": "BRAZZAVILLE", "Dolisie": "DOLISIE"}

TEAM = (
    DemoPerson(
        "superadmin",
        "Superviseur Démo",
        "+242060000001",
        UserRole.SUPER_ADMIN,
        "superadmin@example.com",
    ),
    DemoPerson(
        "admin", "Administrateur Démo", "+242060000002", UserRole.ADMIN, "admin@example.com"
    ),
    DemoPerson(
        "support", "Agent Support Démo", "+242060000003", UserRole.SUPPORT, "support@example.com"
    ),
)


def profile_for(reference: str, power_va: int | None) -> ProfileName:
    """Profil de consommation d'un compteur : celui du jeu de démo, sinon déduit de la puissance."""
    for person in CLIENTS:
        for household in person.households:
            for meter in household.meters:
                if meter.reference == reference:
                    return meter.profile
    if power_va is not None and power_va <= 3_000:
        return ProfileName.SMALL_HOUSEHOLD
    if power_va is not None and power_va >= 9_000:
        return ProfileName.SHOP
    return ProfileName.FAMILY


def _meter(reference, label, profile, power_va, number) -> DemoMeter:
    return DemoMeter(reference, label, profile, power_va, f"{number:07d}H", f"{number:07d}K")


FAMILY, SMALL, SHOP = ProfileName.FAMILY, ProfileName.SMALL_HOUSEHOLD, ProfileName.SHOP
PAYER, VIEWER = MemberRole.PAYER, MemberRole.VIEWER

CLIENTS = (
    DemoPerson(
        "arnaud",
        "Arnaud Mavoungou",
        "+242060000101",
        email="arnaud.mavoungou@example.com",
        households=(
            DemoHousehold(
                "Maison Mpita",
                "Mpita",
                "Pointe-Noire",
                "Rue Mboukou, n° 12",
                (_meter("0412-8833", "Maison", FAMILY, 6_000, 4128833),),
            ),
            DemoHousehold(
                "Boutique Tié-Tié",
                "Tié-Tié",
                "Pointe-Noire",
                "Avenue de l'Indépendance, n° 48",
                (_meter("0377-1209", "Boutique", SHOP, 9_000, 3771209),),
                members=(("grace", PAYER),),
            ),
        ),
    ),
    DemoPerson(
        "grace",
        "Grâce Ngoma",
        "+242060000102",
        households=(
            DemoHousehold(
                "Studio Loandjili",
                "Loandjili",
                "Pointe-Noire",
                "Rue des Manguiers, n° 5",
                (_meter("0398-4410", "Studio", SMALL, 3_000, 3984410),),
            ),
        ),
    ),
    DemoPerson(
        "christelle",
        "Christelle Bouanga",
        "+242060000103",
        households=(
            DemoHousehold(
                "Maison de maman",
                "Bacongo",
                "Brazzaville",
                "Rue Mayama, n° 30",
                (_meter("1105-2276", "Maison", FAMILY, 6_000, 11052276),),
                members=(("davy", PAYER),),  # le fils paie à distance
            ),
        ),
    ),
    DemoPerson(
        "davy",
        "Davy Bouanga",
        "+242060000104",
        email="davy.bouanga@example.com",
        households=(
            DemoHousehold(
                "Appartement Moungali",
                "Moungali",
                "Brazzaville",
                "Avenue de la Paix, n° 210",
                (_meter("1162-0981", "Appartement", SMALL, 3_000, 11620981),),
            ),
        ),
    ),
    DemoPerson(
        "patrick",
        "Patrick Loubaki",
        "+242060000105",
        households=(
            DemoHousehold(
                "Maison Poto-Poto",
                "Poto-Poto",
                "Brazzaville",
                "Rue Mbochis, n° 77",
                (_meter("1121-5530", "Maison", FAMILY, 4_400, 11215530),),
            ),
            DemoHousehold(
                "Atelier Ouenzé",
                "Ouenzé",
                "Brazzaville",
                "Avenue des Trois Martyrs, n° 9",
                (
                    _meter("1188-3012", "Atelier", SHOP, 9_000, 11883012),
                    _meter("1188-3013", "Entrepôt", SMALL, 3_000, 11883013),
                ),
            ),
        ),
    ),
    DemoPerson(
        "mireille",
        "Mireille Samba",
        "+242060000106",
        households=(
            DemoHousehold(
                "Maison Tchimbamba",
                "Tchimbamba",
                "Pointe-Noire",
                "Rue Loango, n° 3",
                (_meter("0421-7764", "Maison", FAMILY, 3_000, 4217764),),
            ),
        ),
    ),
    DemoPerson(
        "rodrigue",
        "Rodrigue Malonga",
        "+242060000107",
        households=(
            DemoHousehold(
                "Maison Talangaï",
                "Talangaï",
                "Brazzaville",
                "Rue Ndolo, n° 58",
                (_meter("1174-6620", "Maison", FAMILY, 6_000, 11746620),),
            ),
            DemoHousehold(
                "Kiosque Talangaï",
                "Talangaï",
                "Brazzaville",
                "Marché Total, stand 14",
                (_meter("1174-6688", "Kiosque", SHOP, 3_000, 11746688),),
            ),
        ),
    ),
    DemoPerson(
        "sandrine",
        "Sandrine Kimbembe",
        "+242060000108",
        households=(
            DemoHousehold(
                "Studio Makélékélé",
                "Makélékélé",
                "Brazzaville",
                "Rue Bangala, n° 21",
                (_meter("1133-0457", "Studio", SMALL, 2_200, 11330457),),
            ),
        ),
    ),
    DemoPerson(
        "herve",
        "Hervé Okemba",
        "+242060000109",
        households=(
            DemoHousehold(
                "Maison Mvoumvou",
                "Mvoumvou",
                "Pointe-Noire",
                "Avenue Moe Vangoula, n° 66",
                (_meter("0445-1288", "Maison", FAMILY, 6_000, 4451288),),
                members=(("mireille", VIEWER),),  # la sœur consulte
            ),
        ),
    ),
    DemoPerson(
        "nadege",
        "Nadège Tchicaya",
        "+242060000110",
        email="nadege.tchicaya@example.com",
        households=(
            DemoHousehold(
                "Boutique Lumumba",
                "Lumumba",
                "Pointe-Noire",
                "Avenue Lumumba, n° 102",
                (_meter("0433-9051", "Boutique", SHOP, 6_000, 4339051),),
            ),
            DemoHousehold(
                "Maison Ngoyo",
                "Ngoyo",
                "Pointe-Noire",
                "Rue de la Plage, n° 8",
                (_meter("0458-2214", "Maison", FAMILY, 4_400, 4582214),),
            ),
            DemoHousehold(
                "Maison du village",
                "Centre-ville",
                "Dolisie",
                "Quartier Bacongo, n° 4",
                (_meter("2201-0336", "Maison", SMALL, 2_200, 22010336),),
            ),
        ),
    ),
)
