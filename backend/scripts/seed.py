"""Remplit une base vide avec les données de démonstration (18 mois d'historique).

Usage, depuis backend/ :
    python -m scripts.reset_db && python -m scripts.seed
    python -m scripts.seed --today 2026-11-12      # rejouer une date précise
    python -m scripts.seed --seed 7                # autre jeu de hasard

Déterministe : même date + même graine → exactement la même base.

Mot de passe et 2FA des comptes (M1.1, règles : app/simulators/seed_policy.py) :
- développement, sans DEMO_SEED_PASSWORD : « Demo2026! » et le secret 2FA de démo, PUBLICS ;
- production (APP_ENV=production, DEMO_MODE=true obligatoire) ou DEMO_SEED_PASSWORD donné : le
  mot de passe choisi sur le serveur (jamais « Demo2026! », jamais affiché) et un secret 2FA tiré
  au hasard pour chaque admin et super admin, affiché UNE SEULE FOIS ici.
"""

import argparse
import sys
import time
from datetime import UTC, date, datetime

import app.db.models  # noqa: F401 — enregistre TOUTES les tables (clés étrangères des insertions)
from app.core import totp
from app.core.config import get_settings
from app.core.timezone import local_date
from app.db.session import get_sessionmaker
from app.simulators.demo_two_factor import (
    DEMO_TOTP_SECRET,
    demo_provisioning_uri,
    enable_team_two_factor,
)
from app.simulators.seed_policy import SeedCredentials, SeedRefusedError, seed_credentials
from app.simulators.seeder import DEFAULT_SEED, SeedError, SeedReport, seed_demo


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Données de démonstration ElecPay")
    parser.add_argument(
        "--today",
        type=date.fromisoformat,
        default=local_date(datetime.now(UTC)),
        help="date du jour simulée (AAAA-MM-JJ), par défaut aujourd'hui à Brazzaville",
    )
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="graine du hasard")
    return parser.parse_args(argv)


def print_report(report: SeedReport, seconds: float, credentials: SeedCredentials) -> None:
    counts = report.counts
    print(f"Données de démo créées en {seconds:.1f} s.")
    print(f"Historique : du {report.first_day:%d/%m/%Y} au {report.last_day:%d/%m/%Y}")
    for label, key in (
        ("Utilisateurs", "users"),
        ("Foyers", "households"),
        ("Membres invités", "members"),
        ("Compteurs", "meters"),
        ("Relevés", "readings"),
        ("Reçus", "receipts"),
        ("Notifications", "notifications"),
    ):
        print(f"  {label:<16} {counts[key]:>6}")
    bills = {k.removeprefix("bills_"): v for k, v in counts.items() if k.startswith("bills_")}
    payments = {
        k.removeprefix("transactions_"): v
        for k, v in counts.items()
        if k.startswith("transactions_")
    }
    print(f"  {'Factures':<16} {sum(bills.values()):>6}  {dict(sorted(bills.items()))}")
    print(f"  {'Transactions':<16} {sum(payments.values()):>6}  {dict(sorted(payments.items()))}")
    if credentials.public:
        print(f"\nComptes de démo (mot de passe commun, PUBLIC : {credentials.password}) :")
    else:
        print("\nComptes de démo (mot de passe : celui de DEMO_SEED_PASSWORD, non affiché) :")
    for role, name, phone in report.accounts:
        print(f"  {phone}  {role:<12} {name}")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    settings = get_settings()
    try:
        credentials = seed_credentials(settings)  # avant toute écriture en base
    except SeedRefusedError as refusal:
        print(refusal, file=sys.stderr)
        return 1
    started = time.perf_counter()
    try:
        with get_sessionmaker()() as session:
            report = seed_demo(
                session,
                today=args.today,
                settings=settings,
                seed=args.seed,
                password=credentials.password,
            )
            secured = enable_team_two_factor(
                session, settings, lambda _member: credentials.totp_secret()
            )
            session.commit()
    except SeedError as error:
        print(error, file=sys.stderr)
        return 1
    print_report(report, time.perf_counter() - started, credentials)
    print_two_factor(secured, credentials)
    return 0


def print_two_factor(secured, credentials: SeedCredentials) -> None:
    if credentials.public:
        print("\nDouble authentification (DÉMO) déjà activée pour :")
        for member, _ in secured:
            print(f"  {member.phone}  {member.role.value:<12} {member.full_name}")
        print(f"  Secret PUBLIC à ajouter UNE fois dans votre application : {DEMO_TOTP_SECRET}")
        print(f"  (ou ce lien en QR code : {demo_provisioning_uri()})")
        print("  Un seul ajout suffit : le même secret sert aux deux comptes de démo.")
        return
    print("\nDouble authentification déjà activée, UN secret tiré au hasard par compte.")
    print("AFFICHÉS UNE SEULE FOIS : les ajouter maintenant dans l'application d'authentification")
    print("(chiffrés en base ; perdus : un super admin réinitialise la 2FA du compte).")
    for member, secret in secured:
        print(f"  {member.phone}  {member.role.value:<12} {member.full_name}")
        print(f"    secret : {secret}")
        uri = totp.provisioning_uri(secret, member.phone, issuer="ElecPay")
        print(f"    lien (QR code) : {uri}")


if __name__ == "__main__":
    sys.exit(main())
