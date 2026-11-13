"""Les tâches quotidiennes sur les factures et les alertes (B9.3), en un seul appel.

Utilisé par le relevé quotidien de démo (`scripts.daily_tick`) et, en production, par
`scripts.daily_alerts` (le relevé simulé, lui, est interdit en production). Dans l'ordre :
1. passage en retard des factures échues (premier avis de retard) ;
2. rappels de retard (tous les 7 jours) ;
3. rappels d'échéance (5 jours avant, puis le jour même) ;
4. consommation inhabituelle (journée d'hier).
Idempotent : relancé le même jour, rien n'est fait deux fois. Pas de commit.
"""

from collections import Counter
from datetime import date

from sqlalchemy.orm import Session

from app.modules.bills.reminders import send_due_soon_reminders, send_overdue_reminders
from app.modules.bills.service import mark_overdue_bills
from app.modules.consumption.alerts import send_high_consumption_alerts


def run_daily_alerts(session: Session, *, today: date) -> Counter:
    """Compteurs : factures passées en retard et notifications créées, par sorte."""
    counts: Counter = Counter()
    overdue = mark_overdue_bills(session, today=today)
    counts["overdue"] = len(overdue.bills)
    counts["overdue_notices"] = overdue.notifications
    counts["overdue_reminders"] = send_overdue_reminders(session, today=today)
    counts["due_soon"] = send_due_soon_reminders(session, today=today)
    counts["high_consumption"] = send_high_consumption_alerts(session, today=today)
    counts["notifications"] = (
        counts["overdue_notices"]
        + counts["overdue_reminders"]
        + counts["due_soon"]
        + counts["high_consumption"]
    )
    return counts
