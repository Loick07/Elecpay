"""Remet la base de développement à zéro (toutes les tables recréées, vides).

Usage, depuis backend/ :   python -m scripts.reset_db

Refuse de tourner en production : cette commande efface TOUTES les données.
"""

import sys

from sqlalchemy.engine import make_url

from app.core.config import Settings, get_settings
from app.db.migrations import rebuild_database


class ResetRefusedError(RuntimeError):
    """La remise à zéro est interdite dans cet environnement."""


def reset_database(settings: Settings) -> str:
    """Vide et recrée la base de `settings.database_url`. Renvoie le nom de la base."""
    if settings.is_production:
        raise ResetRefusedError(
            "Refusé : APP_ENV=production. On ne remet jamais à zéro la production."
        )
    database = make_url(settings.database_url).database or "?"
    rebuild_database(settings.database_url)
    return database


def main() -> int:
    try:
        database = reset_database(get_settings())
    except ResetRefusedError as refusal:
        print(refusal, file=sys.stderr)
        return 1
    print(f"Base « {database} » remise à zéro (tables et triggers recréés, aucune donnée).")
    print("Étape suivante : python -m scripts.seed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
