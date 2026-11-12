"""Remplit une base vide avec les données de démonstration (18 mois d'historique).

Usage, depuis backend/ :
    python -m scripts.reset_db && python -m scripts.seed
    python -m scripts.seed --today 2026-11-12      # rejouer une date précise
    python -m scripts.seed --seed 7                # autre jeu de hasard

Déterministe : même date + même graine → exactement la même base.
"""

import argparse
import sys
import time
from datetime import UTC, date, datetime

from app.core.config import get_settings
from app.core.timezone import local_date
from app.db.session import get_sessionmaker
from app.simulators.demo_dataset import DEMO_PASSWORD
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


def print_report(report: SeedReport, seconds: float) -> None:
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
    print(f"\nComptes de démo (mot de passe commun : {DEMO_PASSWORD}) :")
    for role, name, phone in report.accounts:
        print(f"  {phone}  {role:<12} {name}")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    settings = get_settings()
    if settings.is_production:
        print("Refusé : APP_ENV=production. Pas de données de démo en production.", file=sys.stderr)
        return 1
    started = time.perf_counter()
    try:
        with get_sessionmaker()() as session:
            report = seed_demo(session, today=args.today, settings=settings, seed=args.seed)
            session.commit()
    except SeedError as error:
        print(error, file=sys.stderr)
        return 1
    print_report(report, time.perf_counter() - started)
    return 0


if __name__ == "__main__":
    sys.exit(main())
