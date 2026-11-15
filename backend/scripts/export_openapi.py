"""Exporte le contrat d'API dans `backend/openapi.json` (référence du mobile et du back-office).

Usage, depuis backend/ :
    python -m scripts.export_openapi

À relancer après toute modification d'une route ou d'un schéma : le test
`tests/test_openapi_contract.py` échoue tant que le fichier n'est pas à jour. Le contenu ne
dépend d'aucun réglage (clés triées, même résultat sur toutes les machines).
"""

import json
import sys
from pathlib import Path

from app.main import create_app

CONTRACT = Path(__file__).resolve().parents[1] / "openapi.json"


def contract_text() -> str:
    schema = create_app().openapi()
    return json.dumps(schema, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> int:
    text = contract_text()
    CONTRACT.write_text(text, encoding="utf-8", newline="\n")
    schema = json.loads(text)
    operations = sum(len(methods) for methods in schema["paths"].values())
    print(f"Contrat écrit : {CONTRACT.name} ({len(schema['paths'])} chemins, {operations} routes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
