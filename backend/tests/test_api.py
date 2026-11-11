"""Tests de l'API : /health, format commun des erreurs, CORS, documentation."""

import pytest
from fastapi import APIRouter, FastAPI
from pydantic import BaseModel
from sqlalchemy import text

from app.core.errors import AppError
from app.db.session import build_engine, build_sessionmaker, get_db
from tests.conftest import TEST_CORS_ORIGIN as ALLOWED_ORIGIN
from tests.conftest import transactional_session


def assert_error_format(body: dict, code: str) -> None:
    assert set(body) == {"error"}
    assert set(body["error"]) == {"code", "message", "details"}
    assert body["error"]["code"] == code
    assert isinstance(body["error"]["message"], str) and body["error"]["message"]


# --- /health ----------------------------------------------------------------------


def test_health_ok(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok", "demo_mode": True}


def test_health_reports_unreachable_database(app, client):
    dead_engine = build_engine("mysql+pymysql://elecpay:elecpay@127.0.0.1:1/elecpay_test")
    dead_session = build_sessionmaker(dead_engine)()
    app.dependency_overrides[get_db] = lambda: dead_session

    response = client.get("/api/v1/health")

    dead_session.close()
    dead_engine.dispose()
    assert response.status_code == 503
    assert response.json() == {"status": "degraded", "database": "error", "demo_mode": True}


# --- Format des erreurs -------------------------------------------------------------


class Credentials(BaseModel):
    phone: str
    password: str
    age: int


@pytest.fixture
def app_with_test_routes(app: FastAPI) -> FastAPI:
    """Ajoute des routes qui provoquent chaque type d'erreur."""
    router = APIRouter()

    @router.get("/boom/app-error")
    def raise_app_error():
        raise AppError(
            "Cette facture est déjà payée.",
            code="BILL_ALREADY_PAID",
            status_code=409,
            details={"bill_id": 42},
        )

    @router.get("/boom/crash")
    def crash():
        raise RuntimeError("mot de passe base = s3cr3t ; SELECT * FROM users")

    @router.post("/boom/validation")
    def validate(payload: Credentials):
        return {"ok": True}

    app.include_router(router, prefix="/api/v1")
    return app


def test_unknown_route_returns_404_in_common_format(client):
    response = client.get("/api/v1/route-inconnue")
    assert response.status_code == 404
    assert_error_format(response.json(), "NOT_FOUND")


def test_wrong_method_returns_405_in_common_format(client):
    response = client.post("/api/v1/health")
    assert response.status_code == 405
    assert_error_format(response.json(), "METHOD_NOT_ALLOWED")


def test_app_error_keeps_code_status_and_details(app_with_test_routes, client):
    response = client.get("/api/v1/boom/app-error")
    assert response.status_code == 409
    body = response.json()
    assert_error_format(body, "BILL_ALREADY_PAID")
    assert body["error"]["message"] == "Cette facture est déjà payée."
    assert body["error"]["details"] == {"bill_id": 42}


def test_app_error_defaults():
    error = AppError()
    assert (error.status_code, error.code, error.message) == (
        400,
        "BAD_REQUEST",
        "Requête invalide.",
    )


def test_validation_error_lists_fields(app_with_test_routes, client):
    response = client.post(
        "/api/v1/boom/validation", json={"phone": "+242060000000", "age": "vieux"}
    )
    assert response.status_code == 422
    body = response.json()
    assert_error_format(body, "VALIDATION_ERROR")
    fields = {f["field"] for f in body["error"]["details"]["fields"]}
    assert fields == {"body.password", "body.age"}


def test_validation_error_never_echoes_submitted_values(app_with_test_routes, client):
    response = client.post(
        "/api/v1/boom/validation",
        json={"phone": "+242060000000", "password": "MonMotDePasse!", "age": "MonMotDePasse!"},
    )
    assert response.status_code == 422
    assert "MonMotDePasse!" not in response.text


def test_unexpected_error_returns_generic_500(app_with_test_routes, client, caplog):
    response = client.get("/api/v1/boom/crash")
    assert response.status_code == 500
    assert_error_format(response.json(), "INTERNAL_ERROR")
    # Aucun détail technique pour le client…
    assert "s3cr3t" not in response.text
    assert "SELECT" not in response.text
    assert "Traceback" not in response.text
    # … mais l'erreur est bien journalisée côté serveur.
    assert "Erreur inattendue sur GET /api/v1/boom/crash" in caplog.text


# --- CORS ---------------------------------------------------------------------------


def preflight(client, origin: str):
    return client.options(
        "/api/v1/health",
        headers={"Origin": origin, "Access-Control-Request-Method": "GET"},
    )


def test_cors_allows_known_origin_with_credentials(client):
    response = preflight(client, ALLOWED_ORIGIN)
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == ALLOWED_ORIGIN
    assert response.headers["access-control-allow-credentials"] == "true"


def test_cors_rejects_unknown_origin(client):
    response = preflight(client, "http://pirate.example")
    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers


def test_cors_allows_idempotency_key_header(client):
    response = client.options(
        "/api/v1/health",
        headers={
            "Origin": ALLOWED_ORIGIN,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Idempotency-Key",
        },
    )
    assert response.status_code == 200
    assert "idempotency-key" in response.headers["access-control-allow-headers"].lower()


# --- Documentation ------------------------------------------------------------------


def test_docs_page_is_served(client):
    response = client.get("/docs")
    assert response.status_code == 200
    assert "swagger" in response.text.lower()


def test_openapi_documents_health_and_error_format(client):
    schema = client.get("/openapi.json").json()
    assert "/api/v1/health" in schema["paths"]
    assert "ErrorResponse" in schema["components"]["schemas"]


# --- Isolation des tests ------------------------------------------------------------


def test_transactional_session_rolls_back_commits(test_engine):
    with test_engine.begin() as conn:
        conn.execute(text("CREATE TABLE IF NOT EXISTS zz_isolation_b0 (v INT)"))
        conn.execute(text("DELETE FROM zz_isolation_b0"))
    try:
        with transactional_session(test_engine) as session:
            session.execute(text("INSERT INTO zz_isolation_b0 (v) VALUES (1)"))
            session.commit()  # comme le ferait un service
            assert session.execute(text("SELECT COUNT(*) FROM zz_isolation_b0")).scalar() == 1

        with test_engine.connect() as conn:
            count = conn.execute(text("SELECT COUNT(*) FROM zz_isolation_b0")).scalar()
        assert count == 0
    finally:
        with test_engine.begin() as conn:
            conn.execute(text("DROP TABLE zz_isolation_b0"))
