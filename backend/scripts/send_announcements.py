"""Envoie les annonces programmées dont l'heure est venue (maquette admin A9).

Usage, depuis backend/ :
    python -m scripts.send_announcements

À planifier toutes les minutes en production (décision B10). Idempotent : une annonce envoyée
ne l'est jamais deux fois, même si deux exécutions se chevauchent.
"""

import sys

import app.db.models  # noqa: F401 — enregistre TOUTES les tables (clés étrangères des insertions)
from app.db.base import utcnow
from app.db.session import get_sessionmaker
from app.modules.announcements.service import send_due_announcements


def main() -> int:
    with get_sessionmaker()() as session:
        sent = send_due_announcements(session, now=utcnow())
    print(f"Annonces programmées envoyées : {len(sent)}")
    for announcement in sent:
        print(f"  n° {announcement.id:<6} {announcement.recipients:>6} destinataire(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
