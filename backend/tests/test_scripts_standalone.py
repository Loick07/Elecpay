"""Chaque commande `python -m scripts.…` doit connaître TOUTES les tables quand elle tourne seule.

Bug trouvé en conditions réelles (B9.3) : `scripts.daily_alerts`, lancé seul, n'avait pas importé
le modèle `User` ; SQLAlchemy ne trouvait pas la table `users` au moment d'insérer une
notification (clé étrangère) et la commande plantait. Les tests ne le voyaient pas, car eux
importent toute l'application. Ici, chaque commande est importée dans un processus neuf.
"""

import subprocess
import sys
from pathlib import Path

import pytest

import app.db.models  # noqa: F401
from app.db.base import Base

BACKEND = Path(__file__).resolve().parents[1]
COMMANDS = sorted(
    path.stem for path in (BACKEND / "scripts").glob("*.py") if path.stem != "__init__"
)
CHECK = (
    "import importlib, sys; importlib.import_module('scripts.' + sys.argv[1]); "
    "from app.db.base import Base; print(','.join(sorted(Base.metadata.tables)))"
)


def test_every_command_is_checked():
    assert {"daily_alerts", "daily_tick", "check_pending_payments", "seed"} <= set(COMMANDS)


@pytest.mark.parametrize("command", COMMANDS)
def test_a_command_alone_knows_every_table(command):
    result = subprocess.run(  # noqa: S603 (interpréteur du projet, module du projet)
        [sys.executable, "-c", CHECK, command],
        cwd=BACKEND,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert set(result.stdout.strip().split(",")) == set(Base.metadata.tables)
