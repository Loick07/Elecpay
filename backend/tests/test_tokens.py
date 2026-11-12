"""Tests des jetons (B3.2) : jeton d'accès JWT et jeton de rafraîchissement opaque."""

import base64
import json
import re
from datetime import UTC, datetime, timedelta

import jwt
import pytest

from app.modules.auth.errors import TokenExpiredError, TokenInvalidError
from app.modules.auth.tokens import (
    ALGORITHM,
    ISSUER,
    create_access_token,
    decode_access_token,
    hash_refresh_token,
    new_refresh_token,
)

# 64 octets : assez long aussi pour le test qui signe en HS512 (faux algorithme).
SECRET = "un-secret-de-test-suffisamment-long-pour-hs256-et-hs512-01234567"


def make(user_id=42, role="client", minutes=15, now=None):
    return create_access_token(user_id, role, secret=SECRET, minutes=minutes, now=now)


def valid_payload(**overrides):
    now = datetime.now(UTC)
    payload = {
        "sub": "42",
        "role": "client",
        "type": "access",
        "jti": "abc",
        "iss": ISSUER,
        "iat": now,
        "exp": now + timedelta(minutes=15),
    }
    payload.update(overrides)
    return {k: v for k, v in payload.items() if v is not None}


# --- Jeton d'accès valide -----------------------------------------------------------


def test_round_trip():
    token, expires_at = make(user_id=7, role="admin")
    claims = decode_access_token(token, secret=SECRET)
    assert (claims.user_id, claims.role) == (7, "admin")
    assert claims.expires_at == expires_at
    assert claims.expires_at - claims.issued_at == timedelta(minutes=15)
    assert re.fullmatch(r"[0-9a-f]{32}", claims.token_id)


def test_each_token_is_unique():
    assert make()[0] != make()[0]  # identifiant jti différent


def test_token_never_contains_a_password_or_phone():
    token, _ = make()
    payload = jwt.decode(token, SECRET, algorithms=[ALGORITHM], issuer=ISSUER)
    assert set(payload) == {"sub", "role", "type", "jti", "iss", "iat", "exp"}


# --- Refus --------------------------------------------------------------------------


def test_expired_token_is_refused_as_expired():
    token, _ = make(now=datetime.now(UTC) - timedelta(minutes=16))
    with pytest.raises(TokenExpiredError):
        decode_access_token(token, secret=SECRET)


def test_wrong_secret_is_refused():
    token, _ = make()
    with pytest.raises(TokenInvalidError):
        decode_access_token(token, secret=SECRET + "x")


def test_tampered_payload_is_refused():
    """Changer le rôle à la main (client → super_admin) casse la signature."""
    header, payload, signature = make()[0].split(".")
    data = json.loads(base64.urlsafe_b64decode(payload + "=="))
    data["role"] = "super_admin"
    forged = base64.urlsafe_b64encode(json.dumps(data).encode()).decode().rstrip("=")
    with pytest.raises(TokenInvalidError):
        decode_access_token(f"{header}.{forged}.{signature}", secret=SECRET)


def test_alg_none_attack_is_refused():
    unsigned = jwt.encode(valid_payload(role="super_admin"), key=None, algorithm="none")
    with pytest.raises(TokenInvalidError):
        decode_access_token(unsigned, secret=SECRET)


def test_other_algorithm_is_refused_even_with_the_right_secret():
    other = jwt.encode(valid_payload(), SECRET, algorithm="HS512")
    with pytest.raises(TokenInvalidError):
        decode_access_token(other, secret=SECRET)


@pytest.mark.parametrize(
    "overrides",
    [
        {"type": "refresh"},  # un autre type de jeton
        {"type": None},
        {"iss": "autre-application"},
        {"sub": "pas-un-nombre"},
        {"role": None},
        {"jti": None},
        {"exp": None},
    ],
)
def test_malformed_claims_are_refused(overrides):
    token = jwt.encode(valid_payload(**overrides), SECRET, algorithm=ALGORITHM)
    with pytest.raises(TokenInvalidError):
        decode_access_token(token, secret=SECRET)


@pytest.mark.parametrize("garbage", ["", "abc", "a.b.c", "Bearer xyz", new_refresh_token()])
def test_garbage_is_refused(garbage):
    with pytest.raises(TokenInvalidError):
        decode_access_token(garbage, secret=SECRET)


# --- Jeton de rafraîchissement ------------------------------------------------------


def test_refresh_token_is_long_random_and_url_safe():
    tokens = {new_refresh_token() for _ in range(1_000)}
    assert len(tokens) == 1_000
    assert all(re.fullmatch(r"[A-Za-z0-9_-]{64}", t) for t in tokens)


def test_refresh_token_hash_is_a_stable_sha256():
    token = new_refresh_token()
    assert hash_refresh_token(token) == hash_refresh_token(token)
    assert re.fullmatch(r"[0-9a-f]{64}", hash_refresh_token(token))
    assert token not in hash_refresh_token(token)
