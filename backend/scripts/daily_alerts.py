"""Tâches quotidiennes sur les factures et les alertes (production comme démo).

Usage, depuis backend/ :
    python -m scripts.daily_alerts                      # aujourd'hui (heure de Brazzaville)
    python -m scripts.daily_alerts --today 2026-11-20   # simuler une date

À planifier une fois par jour (le matin). Passage en retard, rappels de retard et d'échéance,
consommation inhabituelle. Idempotent. En démo, `scripts.daily_tick` le fait déjà.
"""

import argparse
import sys
from datetime import UTC, date, datetime

import app.db.models  # noqa: F401 — enregistre TOUTES les tables (clés étrangères des insertions)
from app.core.timezone import local_date
from app.db.session import get_sessionmaker
from app.modules.notifications.daily_alerts import run_daily_alerts


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Alertes quotidiennes ElecPay")
    parser.add_argument(
        "--today",
        type=date.fromisoformat,
        default=local_date(datetime.now(UTC)),
        help="date du jour (AAAA-MM-JJ), par défaut aujourd'hui à Brazzaville",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    with get_sessionmaker()() as session:
        counts = run_daily_alerts(session, today=args.today)
        session.commit()
    print(f"Alertes du {args.today:%d/%m/%Y} :")
    print(f"  passées en retard        {counts['overdue']:>5}")
    print(f"  rappels de retard        {counts['overdue_reminders']:>5}")
    print(f"  rappels d'échéance       {counts['due_soon']:>5}")
    print(f"  consommation inhabituelle{counts['high_consumption']:>5}")
    print(f"  notifications créées     {counts['notifications']:>5}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
