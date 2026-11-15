"""Le contrat d'API exporté (`backend/openapi.json`) est toujours à jour (B11.6).

C'est la référence de l'application mobile et du back-office : une route ou un schéma modifié
sans réexporter le contrat fait échouer ce test.
"""

import json

from scripts.export_openapi import CONTRACT, contract_text


def test_the_exported_contract_is_up_to_date():
    assert CONTRACT.exists(), "Lancer : python -m scripts.export_openapi"
    assert CONTRACT.read_text(encoding="utf-8") == contract_text(), (
        "backend/openapi.json n'est plus à jour : lancer « python -m scripts.export_openapi »"
    )


def test_the_contract_does_not_depend_on_the_settings(test_settings):
    from app.main import create_app

    production_like = test_settings.model_copy(update={"demo_mode": False, "log_format": "json"})
    other = json.dumps(create_app(production_like).openapi(), sort_keys=True, ensure_ascii=False)
    assert json.loads(other) == json.loads(contract_text())


def test_every_route_documents_its_errors_in_the_common_format():
    schema = json.loads(contract_text())
    assert "ErrorResponse" in schema["components"]["schemas"]
    for path, operations in schema["paths"].items():
        for method, operation in operations.items():
            assert operation.get("summary"), f"{method.upper()} {path} : résumé manquant"
            assert "422" in operation["responses"] or method == "get", f"{method} {path}"
