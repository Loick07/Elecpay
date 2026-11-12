"""Tests de la configuration (aucune base de données nécessaire)."""

import pytest
from pydantic import ValidationError

from app.core.config import Settings

DB_URL = "mysql+pymysql://u:p@127.0.0.1:3307/db"
STRONG_SECRET = "x" * 48


@pytest.fixture(autouse=True)
def clean_environment(monkeypatch):
    """Chaque test part d'un environnement vide (la CI, elle, définit APP_ENV, DATABASE_URL…)."""
    for name in Settings.model_fields:
        monkeypatch.delenv(name.upper(), raising=False)


def make_settings(**overrides) -> Settings:
    """Construit une configuration sans lire le .env du développeur."""
    values = {"database_url": DB_URL, "jwt_secret": "change-me"} | overrides
    return Settings(_env_file=None, **values)


def test_default_values():
    settings = make_settings()
    assert settings.app_env == "development"
    assert settings.access_token_minutes == 15
    assert settings.refresh_token_days == 30
    assert settings.payment_provider == "simulated"
    assert settings.demo_mode is True
    assert settings.cors_origins == []
    assert settings.billing_period_months == 2  # bimestriel, comme E²C
    assert (settings.bill_issue_delay_days, settings.bill_due_delay_days) == (3, 15)


def test_billing_period_is_read_from_environment(monkeypatch):
    monkeypatch.setenv("BILLING_PERIOD_MONTHS", "3")
    assert make_settings().billing_period_months == 3


@pytest.mark.parametrize("months", [0, 5, 7, 24])
def test_billing_period_must_divide_the_year(months):
    with pytest.raises(ValidationError, match="billing_period_months"):
        make_settings(billing_period_months=months)


@pytest.mark.parametrize(
    ("field", "value"), [("bill_issue_delay_days", -1), ("bill_due_delay_days", 0)]
)
def test_bill_delays_are_bounded(field, value):
    with pytest.raises(ValidationError, match=field):
        make_settings(**{field: value})


def test_reads_environment_variables(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", DB_URL)
    monkeypatch.setenv("JWT_SECRET", "change-me")
    monkeypatch.setenv("DEMO_MODE", "false")
    monkeypatch.setenv("ACCESS_TOKEN_MINUTES", "10")
    monkeypatch.setenv("CORS_ORIGINS", "http://localhost:3000, https://admin.elecpay.cg")

    settings = Settings(_env_file=None)

    assert settings.demo_mode is False
    assert settings.access_token_minutes == 10
    assert settings.cors_origins == ["http://localhost:3000", "https://admin.elecpay.cg"]


def test_database_url_is_required(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    with pytest.raises(ValidationError, match="database_url"):
        Settings(_env_file=None, jwt_secret="change-me")


def test_jwt_secret_is_never_displayed():
    settings = make_settings(jwt_secret="super-secret-value")
    assert "super-secret-value" not in repr(settings)
    assert settings.jwt_secret.get_secret_value() == "super-secret-value"


@pytest.mark.parametrize("value", ["oui-peut-etre", "2"])
def test_invalid_boolean_is_rejected(value):
    with pytest.raises(ValidationError, match="demo_mode"):
        make_settings(demo_mode=value)


@pytest.mark.parametrize("minutes", [0, 61])
def test_access_token_duration_is_bounded(minutes):
    with pytest.raises(ValidationError, match="access_token_minutes"):
        make_settings(access_token_minutes=minutes)


def test_unknown_payment_provider_is_rejected():
    with pytest.raises(ValidationError, match="payment_provider"):
        make_settings(payment_provider="orange")


def test_wildcard_cors_origin_is_rejected():
    with pytest.raises(ValidationError, match="CORS strict"):
        make_settings(cors_origins="*")


@pytest.mark.parametrize("secret", ["change-me", "short-secret"])
def test_production_rejects_weak_jwt_secret(secret):
    with pytest.raises(ValidationError, match="JWT_SECRET"):
        make_settings(app_env="production", jwt_secret=secret)


def test_production_with_simulation_requires_demo_mode():
    with pytest.raises(ValidationError, match="DEMO_MODE"):
        make_settings(app_env="production", jwt_secret=STRONG_SECRET, demo_mode=False)


def test_valid_production_configuration():
    settings = make_settings(app_env="production", jwt_secret=STRONG_SECRET, demo_mode=True)
    assert settings.is_production is True


def test_weak_secret_is_tolerated_in_development():
    assert make_settings(jwt_secret="change-me").is_production is False
