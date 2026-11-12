"""Tests du mode navigateur du back-office (B3.7) : cookies httpOnly + protection CSRF."""

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy import func, select

from app.core.config import Settings
from app.core.security import hash_password
from app.db.session import get_db
from app.main import create_app
from app.modules.auth.cookies import ACCESS_COOKIE, CSRF_COOKIE, CSRF_HEADER, REFRESH_COOKIE
from app.modules.auth.models import RefreshToken
from app.modules.users.models import UserRole
from tests.factories import make_user

PASSWORD = "Demo2026!"
ADMIN_PHONE = "+242060000002"
WEB_LOGIN = "/api/v1/auth/web/login"
WEB_REFRESH = "/api/v1/auth/web/refresh"
WEB_LOGOUT = "/api/v1/auth/web/logout"


@pytest.fixture
def web(app):
    """Navigateur simulé en HTTPS (un cookie Secure n'est jamais renvoyé en HTTP)."""
    with TestClient(app, base_url="https://testserver", raise_server_exceptions=False) as client:
        yield client


@pytest.fixture
def admin(db_session):
    return make_user(
        db_session, phone=ADMIN_PHONE, role=UserRole.ADMIN, password_hash=hash_password(PASSWORD)
    )


def web_login(web, phone=ADMIN_PHONE, password=PASSWORD):
    return web.post(WEB_LOGIN, json={"phone": phone, "password": password})


def csrf(web):
    return {CSRF_HEADER: web.cookies.get(CSRF_COOKIE)}


def set_cookies(response) -> dict[str, str]:
    """{nom: en-tête Set-Cookie complet} (en minuscules pour comparer les attributs)."""
    return {
        header.split("=", 1)[0]: header.lower()
        for header in response.headers.get_list("set-cookie")
    }


def code(response):
    return response.json()["error"]["code"]


# --- Connexion ----------------------------------------------------------------------


def test_team_login_sets_three_cookies_and_returns_no_token(web, admin):
    response = web_login(web)
    assert response.status_code == 200
    body = response.json()
    assert body["user"]["role"] == "admin"
    assert "access_token" not in body and "refresh_token" not in body

    cookies = set_cookies(response)
    assert set(cookies) == {ACCESS_COOKIE, REFRESH_COOKIE, CSRF_COOKIE}
    for header in cookies.values():
        assert "secure" in header and "samesite=strict" in header
    assert "httponly" in cookies[ACCESS_COOKIE] and "path=/api/v1" in cookies[ACCESS_COOKIE]
    assert "httponly" in cookies[REFRESH_COOKIE]
    assert "path=/api/v1/auth/web" in cookies[REFRESH_COOKIE]  # jamais envoyé ailleurs
    assert "httponly" not in cookies[CSRF_COOKIE]  # lisible par le JavaScript, voulu


@pytest.mark.parametrize("role", [UserRole.SUPPORT, UserRole.ADMIN, UserRole.SUPER_ADMIN])
def test_every_team_role_can_use_the_back_office(web, db_session, role):
    make_user(db_session, phone="+242060000009", role=role, password_hash=hash_password(PASSWORD))
    assert web_login(web, phone="+242060000009").status_code == 200


def test_clients_are_refused_and_get_no_session(web, db_session):
    client_user = make_user(
        db_session, phone="+242060000101", password_hash=hash_password(PASSWORD)
    )
    response = web_login(web, phone="+242060000101")
    assert response.status_code == 403
    assert code(response) == "FORBIDDEN"
    assert "réservé à l'équipe" in response.json()["error"]["message"]
    assert set_cookies(response) == {}
    sessions = db_session.scalar(
        select(func.count()).select_from(RefreshToken).where(RefreshToken.user_id == client_user.id)
    )
    assert sessions == 0


def test_client_with_wrong_password_learns_nothing(web, db_session):
    make_user(db_session, phone="+242060000101", password_hash=hash_password(PASSWORD))
    assert (
        code(web_login(web, phone="+242060000101", password="Mauvais2026")) == "INVALID_CREDENTIALS"
    )


def test_wrong_password(web, admin):
    response = web_login(web, password="Mauvais2026")
    assert response.status_code == 401
    assert set_cookies(response) == {}


def test_web_and_mobile_logins_share_the_failure_counter(web, admin):
    for _ in range(5):
        web_login(web, password="Mauvais2026")
    mobile = web.post("/api/v1/auth/login", json={"phone": ADMIN_PHONE, "password": PASSWORD})
    assert mobile.status_code == 429  # on ne contourne pas la limite en changeant de chemin


# --- Requêtes avec le cookie --------------------------------------------------------


def test_reading_with_the_cookie_needs_no_csrf(web, admin):
    web_login(web)
    response = web.get("/api/v1/me")  # aucun en-tête Authorization : le cookie suffit
    assert response.status_code == 200
    assert response.json()["phone"] == ADMIN_PHONE


@pytest.mark.parametrize("header", [None, "mauvais-jeton"])
def test_modifying_with_the_cookie_requires_the_csrf_token(web, admin, header):
    web_login(web)
    headers = {CSRF_HEADER: header} if header else {}
    response = web.patch("/api/v1/me", json={"full_name": "Admin Démo"}, headers=headers)
    assert response.status_code == 403
    assert code(response) == "CSRF_INVALID"


def test_modifying_with_the_right_csrf_token(web, admin):
    web_login(web)
    response = web.patch("/api/v1/me", json={"full_name": "Admin Démo"}, headers=csrf(web))
    assert response.status_code == 200
    assert response.json()["full_name"] == "Admin Démo"


def test_mobile_bearer_requests_need_no_csrf(web, admin):
    """L'application mobile (en-tête Authorization) n'est pas concernée par le CSRF."""
    token = web.post(
        "/api/v1/auth/login", json={"phone": ADMIN_PHONE, "password": PASSWORD}
    ).json()["access_token"]
    response = web.patch(
        "/api/v1/me",
        json={"full_name": "Admin Mobile"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200


def test_no_cookie_no_header(web):
    response = web.get("/api/v1/me")
    assert response.status_code == 401
    assert code(response) == "NOT_AUTHENTICATED"


# --- Rafraîchissement ---------------------------------------------------------------


def test_refresh_renews_all_cookies(web, admin):
    web_login(web)
    old_access, old_csrf = web.cookies.get(ACCESS_COOKIE), web.cookies.get(CSRF_COOKIE)
    response = web.post(WEB_REFRESH, headers=csrf(web))
    assert response.status_code == 200
    assert web.cookies.get(ACCESS_COOKIE) != old_access
    assert web.cookies.get(CSRF_COOKIE) != old_csrf
    assert web.get("/api/v1/me").status_code == 200


def test_refresh_requires_the_csrf_token(web, admin):
    web_login(web)
    response = web.post(WEB_REFRESH)
    assert response.status_code == 403
    assert code(response) == "CSRF_INVALID"


def test_refresh_without_session(web):
    web.cookies.set(CSRF_COOKIE, "abc", domain="testserver.local", path="/")
    response = web.post(WEB_REFRESH, headers={CSRF_HEADER: "abc"})
    assert response.status_code == 401


def test_replayed_refresh_cookie_closes_the_session(web, admin):
    web_login(web)
    stolen = web.cookies.get(REFRESH_COOKIE, path="/api/v1/auth/web")
    web.post(WEB_REFRESH, headers=csrf(web))  # l'administrateur rafraîchit normalement

    with TestClient(web.app, base_url="https://testserver") as thief:
        thief.cookies.set(
            REFRESH_COOKIE, stolen, domain="testserver.local", path="/api/v1/auth/web"
        )
        thief.cookies.set(CSRF_COOKIE, "x", domain="testserver.local", path="/")
        response = thief.post(WEB_REFRESH, headers={CSRF_HEADER: "x"})
    assert response.status_code == 401
    assert code(response) == "REFRESH_TOKEN_REUSED"
    assert web.post(WEB_REFRESH, headers=csrf(web)).status_code == 401  # session fermée


# --- Déconnexion --------------------------------------------------------------------


def test_logout_revokes_the_session_and_clears_the_cookies(web, admin, db_session):
    web_login(web)
    response = web.post(WEB_LOGOUT, headers=csrf(web))
    assert response.status_code == 204
    cleared = set_cookies(response)
    assert set(cleared) == {ACCESS_COOKIE, REFRESH_COOKIE, CSRF_COOKIE}
    assert all("max-age=0" in header for header in cleared.values())
    assert web.get("/api/v1/me").status_code == 401
    active = db_session.scalar(
        select(func.count())
        .select_from(RefreshToken)
        .where(RefreshToken.user_id == admin.id, RefreshToken.revoked_at.is_(None))
    )
    assert active == 0


def test_logout_requires_the_csrf_token(web, admin):
    """Sinon, n'importe quel site pourrait déconnecter un administrateur à son insu."""
    web_login(web)
    assert web.post(WEB_LOGOUT).status_code == 403
    assert web.get("/api/v1/me").status_code == 200


# --- Configuration ------------------------------------------------------------------


def test_cookies_without_secure_when_configured(test_settings, db_session, admin):
    insecure = create_app(test_settings.model_copy(update={"auth_cookie_secure": False}))
    insecure.dependency_overrides[get_db] = lambda: db_session
    with TestClient(insecure) as client:  # HTTP simple
        response = web_login(client)
        assert all("secure" not in h for h in set_cookies(response).values())
        assert client.get("/api/v1/me").status_code == 200


def test_production_refuses_insecure_cookies():
    with pytest.raises(ValidationError, match="AUTH_COOKIE_SECURE"):
        Settings(
            _env_file=None,
            database_url="mysql+pymysql://u:p@h/db",
            jwt_secret="x" * 48,
            app_env="production",
            auth_cookie_secure=False,
        )


def test_cors_allows_the_csrf_header(client):
    response = client.options(
        "/api/v1/me",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "PATCH",
            "Access-Control-Request-Headers": "X-CSRF-Token",
        },
    )
    assert response.status_code == 200
    assert "x-csrf-token" in response.headers["access-control-allow-headers"].lower()
