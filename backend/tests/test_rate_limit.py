"""Tests de la limitation des tentatives (B3.6) : le limiteur, puis les routes protégées."""

import threading

import pytest

from app.core.errors import TooManyAttemptsError
from app.core.rate_limit import CLEANUP_EVERY, MAX_WINDOW_SECONDS, Limit, RateLimiter
from app.core.security import hash_password
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from tests.factories import make_user

PASSWORD = "Demo2026!"
PHONE = "+242061112233"


class FakeClock:
    def __init__(self):
        self.now = 1_000.0

    def __call__(self):
        return self.now

    def advance(self, seconds):
        self.now += seconds


@pytest.fixture
def clock():
    return FakeClock()


# --- Le limiteur --------------------------------------------------------------------


def test_allows_up_to_the_limit_then_refuses(clock):
    limiter, limit = RateLimiter(clock), Limit(3, 60)
    for _ in range(3):
        limiter.consume("k", limit)
    with pytest.raises(TooManyAttemptsError) as error:
        limiter.consume("k", limit)
    assert error.value.details == {"retry_after_seconds": 60}


def test_window_slides(clock):
    limiter, limit = RateLimiter(clock), Limit(2, 60)
    limiter.consume("k", limit)  # t = 0
    clock.advance(40)
    limiter.consume("k", limit)  # t = 40
    clock.advance(10)
    assert limiter.retry_after("k", limit) == 10  # le premier sort de la fenêtre à t = 60
    clock.advance(10)
    limiter.consume("k", limit)  # place libérée


def test_check_does_not_count_and_record_does(clock):
    limiter, limit = RateLimiter(clock), Limit(1, 60)
    for _ in range(5):
        limiter.check("k", limit)
    limiter.record("k", limit)
    with pytest.raises(TooManyAttemptsError):
        limiter.check("k", limit)


def test_reset_clears_a_key(clock):
    limiter, limit = RateLimiter(clock), Limit(1, 60)
    limiter.consume("k", limit)
    limiter.reset("k")
    limiter.consume("k", limit)


def test_keys_are_independent(clock):
    limiter, limit = RateLimiter(clock), Limit(1, 60)
    limiter.consume("login:phone:A", limit)
    limiter.consume("login:phone:B", limit)


def test_old_keys_are_forgotten(clock):
    limiter, limit = RateLimiter(clock), Limit(5, 60)
    limiter.consume("k", limit)
    clock.advance(61)
    assert limiter.retry_after("k", limit) is None
    assert len(limiter) == 0


def test_never_consulted_keys_are_cleaned_up_eventually(clock):
    limiter, limit = RateLimiter(clock), Limit(5, 60)
    limiter.consume("oublie", limit)
    clock.advance(MAX_WINDOW_SECONDS + 1)
    for i in range(CLEANUP_EVERY):  # d'autres numéros arrivent ; « oublie » n'est plus consulté
        limiter.record(f"k{i}", limit)
    assert "oublie" not in limiter._events
    assert len(limiter) == CLEANUP_EVERY  # les compteurs récents, eux, sont gardés


def test_concurrent_requests_cannot_exceed_the_limit():
    limiter, limit = RateLimiter(), Limit(10, 60)
    accepted = []

    def attempt():
        try:
            limiter.consume("k", limit)
            accepted.append(1)
        except TooManyAttemptsError:
            pass

    threads = [threading.Thread(target=attempt) for _ in range(50)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    assert len(accepted) == 10


# --- Routes protégées ---------------------------------------------------------------


@pytest.fixture
def limited_client(app, client, clock):
    """Client dont le limiteur suit une horloge qu'on avance à la main."""
    app.state.rate_limiter = RateLimiter(clock)
    return client


@pytest.fixture
def account(db_session):
    return make_user(db_session, phone=PHONE, password_hash=hash_password(PASSWORD))


def login(client, password=PASSWORD, phone=PHONE):
    return client.post("/api/v1/auth/login", json={"phone": phone, "password": password})


def assert_blocked(response, retry_after=None):
    assert response.status_code == 429
    assert response.json()["error"]["code"] == "TOO_MANY_ATTEMPTS"
    seconds = int(response.headers["retry-after"])
    assert response.json()["error"]["details"]["retry_after_seconds"] == seconds
    if retry_after is not None:
        assert seconds == retry_after


def test_five_wrong_passwords_lock_the_number_for_15_minutes(limited_client, account, clock):
    for _ in range(5):
        assert login(limited_client, password="Mauvais2026").status_code == 401
    assert_blocked(login(limited_client), retry_after=15 * 60)  # même avec le bon mot de passe
    clock.advance(15 * 60)
    assert login(limited_client).status_code == 200


def test_successful_login_clears_the_failures(limited_client, account):
    for _ in range(4):
        login(limited_client, password="Mauvais2026")
    assert login(limited_client).status_code == 200
    for _ in range(4):
        assert login(limited_client, password="Mauvais2026").status_code == 401  # pas 429


def test_unknown_numbers_are_limited_the_same_way(limited_client):
    for _ in range(5):
        assert login(limited_client, phone="069999999").status_code == 401
    assert_blocked(login(limited_client, phone="069999999"))


def test_one_ip_cannot_try_many_numbers(limited_client):
    for i in range(20):
        assert login(limited_client, phone=f"0690000{i:02d}").status_code == 401
    assert_blocked(login(limited_client, phone="069000099"))


def test_forgot_password_is_limited_per_number(limited_client, app, account, db_session):
    sender = SimulatedSmsSender()
    app.dependency_overrides[get_sms_sender] = lambda: sender
    make_user(db_session, phone="+242064445566")
    for _ in range(3):
        assert (
            limited_client.post("/api/v1/auth/password/forgot", json={"phone": PHONE}).status_code
            == 200
        )
    blocked = limited_client.post("/api/v1/auth/password/forgot", json={"phone": PHONE})
    assert_blocked(blocked)
    assert len(sender.outbox) == 3  # aucun SMS de plus (ils coûtent de l'argent)
    other = limited_client.post("/api/v1/auth/password/forgot", json={"phone": "+242064445566"})
    assert other.status_code == 200


def test_forgot_password_is_limited_per_ip(limited_client):
    for i in range(10):
        response = limited_client.post(
            "/api/v1/auth/password/forgot", json={"phone": f"0690000{i:02d}"}
        )
        assert response.status_code == 200
    assert_blocked(limited_client.post("/api/v1/auth/password/forgot", json={"phone": "069000099"}))


def test_reset_attempts_are_limited_per_ip(limited_client):
    data = {"phone": PHONE, "code": "123456", "new_password": "Nouveau2026"}
    for _ in range(10):
        assert limited_client.post("/api/v1/auth/password/reset", json=data).status_code == 400
    assert_blocked(limited_client.post("/api/v1/auth/password/reset", json=data))


def test_registration_is_limited_per_ip(limited_client, clock):
    def register(i):
        return limited_client.post(
            "/api/v1/auth/register",
            json={"full_name": f"Client {i}", "phone": f"0680000{i:02d}", "password": PASSWORD},
        )

    for i in range(5):
        assert register(i).status_code == 201
    assert_blocked(register(5))
    clock.advance(3600)
    assert register(6).status_code == 201


def test_refresh_and_me_are_not_limited(limited_client, account):
    tokens = login(limited_client).json()
    for _ in range(30):
        tokens = limited_client.post(
            "/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
        ).json()
    assert "access_token" in tokens
