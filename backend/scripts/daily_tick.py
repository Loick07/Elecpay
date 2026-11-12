"""Relevé quotidien de démonstration : ajoute les relevés du jour, émet les factures
arrivées à échéance d'émission et passe en retard les factures impayées échues.

Usage, depuis backend/ :
    python -m scripts.daily_tick                      # aujourd'hui (heure de Brazzaville)
    python -m scripts.daily_tick --today 2026-11-20   # simuler une date (rattrape les jours)

À lancer une fois par jour (à la main, ou par une tâche planifiée). Idempotent.
Refuse de tourner si les données ne sont pas simulées (BILLING_SOURCE / DEMO_MODE).
"""

import argparse
import sys
from datetime import UTC, date, datetime

from app.core.config import Settings, get_settings
from app.core.timezone import local_date
from app.db.session import get_sessionmaker
from app.simulators.daily import TickReport, run_daily_tick


def refusal_reason(settings: Settings) -> str | None:
    """Raison de refuser, ou None. On ne fabrique jamais de relevés hors du mode simulé."""
    if settings.is_production:
        return "Refusé : APP_ENV=production."
    if settings.billing_source != "simulated" or not settings.demo_mode:
        return "Refusé : relevés simulés uniquement (BILLING_SOURCE=simulated et DEMO_MODE=true)."
    return None


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Relevé quotidien de démonstration ElecPay")
    parser.add_argument(
        "--today",
        type=date.fromisoformat,
        default=local_date(datetime.now(UTC)),
        help="date du jour simulée (AAAA-MM-JJ), par défaut aujourd'hui à Brazzaville",
    )
    return parser.parse_args(argv)


def print_report(report: TickReport) -> None:
    counts = report.counts
    print(f"Relevé quotidien du {report.today:%d/%m/%Y} :")
    print(f"  relevés ajoutés     {counts['readings']:>5}  (anomalies : {counts['anomalies']})")
    print(f"  factures émises     {counts['bills']:>5}")
    print(f"  passées en retard   {counts['overdue']:>5}")
    print(f"  notifications       {counts['notifications']:>5}")
    for message in report.skipped:
        print(f"  ⚠ {message}")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    settings = get_settings()
    reason = refusal_reason(settings)
    if reason:
        print(reason, file=sys.stderr)
        return 1
    with get_sessionmaker()() as session:
        report = run_daily_tick(session, today=args.today, settings=settings)
        session.commit()
    print_report(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
