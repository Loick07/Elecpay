"""Tests des erreurs d'authentification (B3.1) : statut, code, message et en-têtes HTTP."""

import pytest
from fastapi import APIRouter

from app.core.errors import TooManyAttemptsError
from app.modules.auth.errors import (
    AccountDisabledError,
    InsufficientRoleError,
    InvalidCredentialsError,
    NotAuthenticatedError,
    PhoneAlreadyUsedError,
    RefreshTokenReusedError,
    ResetCodeInvalidError,
    TokenExpiredError,
    TokenInvalidError,
)

CASES = [
    (InvalidCredentialsError(), 401, "INVALID_CREDENTIALS"),
    (AccountDisabledError(), 403, "ACCOUNT_DISABLED"),
    (NotAuthenticatedError(), 401, "NOT_AUTHENTICATED"),
    (TokenExpiredError(), 401, "TOKEN_EXPIRED"),
    (TokenInvalidError(), 401, "TOKEN_INVALID"),
    (RefreshTokenReusedError(), 401, "REFRESH_TOKEN_REUSED"),
    (InsufficientRoleError(), 403, "FORBIDDEN"),
    (PhoneAlreadyUsedError(), 409, "PHONE_ALREADY_USED"),
    (ResetCodeInvalidError(), 400, "RESET_CODE_INVALID"),
    (TooManyAttemptsError(90), 429, "TOO_MANY_ATTEMPTS"),
]


@pytest.fixture
def raising_client(app, client):
    router = APIRouter()
    for index, (error, _, _) in enumerate(CASES):

        def raise_it(error=error):
            raise error

        router.add_api_route(f"/boom/auth/{index}", raise_it)
    app.include_router(router, prefix="/api/v1")
    return client


@pytest.mark.parametrize(("index", "case"), list(enumerate(CASES)))
def test_auth_error_is_rendered_in_the_common_format(raising_client, index, case):
    _, status_code, code = case
    response = raising_client.get(f"/api/v1/boom/auth/{index}")
    assert response.status_code == status_code
    body = response.json()
    assert body["error"]["code"] == code
    assert body["error"]["message"]


def test_missing_or_bad_token_errors_carry_the_bearer_challenge(raising_client):
    """Jeton absent, expiré, invalide ou réutilisé : la norme HTTP demande WWW-Authenticate."""
    for index, (error, _, _) in enumerate(CASES):
        response = raising_client.get(f"/api/v1/boom/auth/{index}")
        if isinstance(error, NotAuthenticatedError):
            assert response.headers["www-authenticate"] == "Bearer"
        else:  # ex. mauvais mot de passe à la connexion : pas une affaire de jeton
            assert "www-authenticate" not in response.headers


def test_too_many_attempts_says_when_to_retry(raising_client):
    index = next(i for i, (e, _, _) in enumerate(CASES) if isinstance(e, TooManyAttemptsError))
    response = raising_client.get(f"/api/v1/boom/auth/{index}")
    assert response.headers["retry-after"] == "90"
    assert response.json()["error"]["details"] == {"retry_after_seconds": 90}


def test_unknown_phone_and_wrong_password_look_identical():
    """Anti-énumération : un seul type d'erreur pour les deux cas."""
    unknown_phone, wrong_password = InvalidCredentialsError(), InvalidCredentialsError()
    assert (unknown_phone.code, unknown_phone.message) == (
        wrong_password.code,
        wrong_password.message,
    )
