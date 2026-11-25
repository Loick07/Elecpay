"""Mise en ligne de démonstration par ngrok (M1.2) : modèle de configuration et garde-fou du script.

- `deploy/ngrok.env.example` : aucun secret, l'adresse ngrok de Loick, et une fois les secrets tirés
  par `public.ps1 -Step preparer`, une configuration de PRODUCTION acceptée par l'API ;
- `deploy/public.ps1 -Step config` : refuse toute autre base que `elecpay_public` de ce PC, une
  configuration qui n'est pas de production, ou un secret vide (sans rien toucher).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

from app.core.config import BACKEND_DIR, Settings

DEPLOY = BACKEND_DIR / "deploy"
DOMAIN = "https://omnivore-pardon-sixth.ngrok-free.dev"
SECRET_KEYS = ("JWT_SECRET", "TWO_FACTOR_KEY", "PAYMENT_WEBHOOK_SECRET", "DEMO_SEED_PASSWORD")
PUBLIC_DB = "mysql+pymysql://elecpay_public:motdepasse-de-test@127.0.0.1:3307/elecpay_public?charset=utf8mb4"


def read_env(path: Path) -> dict[str, str]:
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        text = line.strip()
        if text and not text.startswith("#") and "=" in text:
            key, value = text.split("=", 1)
            values[key.strip()] = value.strip()
    return values


def filled_example() -> dict[str, str]:
    """Le modèle tel que `preparer` le remplit (ici avec des secrets de test)."""
    values = read_env(DEPLOY / "ngrok.env.example")
    values["DATABASE_URL"] = PUBLIC_DB
    for index, key in enumerate(SECRET_KEYS):
        values[key] = f"secret-de-test-{index}-" + "s" * 40
    values["DEMO_SEED_PASSWORD"] = "ElecPay-test-2026"
    return values


def test_the_example_holds_no_secret():
    values = read_env(DEPLOY / "ngrok.env.example")
    for key in (*SECRET_KEYS, "DATABASE_URL"):
        assert values[key] == "", f"{key} doit rester vide dans le modèle (tiré sur le PC)"


def test_the_example_points_at_the_ngrok_domain():
    values = read_env(DEPLOY / "ngrok.env.example")
    assert values["RECEIPT_VERIFY_URL"] == f"{DOMAIN}/api/v1/receipts/verify"
    assert values["CORS_ORIGINS"] == DOMAIN
    assert values["TRUSTED_PROXIES"] == "127.0.0.1/32,::1/128"  # l'agent ngrok, sur ce PC
    assert (values["APP_ENV"], values["DEMO_MODE"]) == ("production", "true")


def test_once_filled_it_is_a_valid_production_configuration():
    values = filled_example()
    settings = Settings(_env_file=None, **{key.lower(): value for key, value in values.items()})
    assert settings.is_production
    assert settings.receipt_verify_url == f"{DOMAIN}/api/v1/receipts/verify"
    assert settings.cors_origins == [DOMAIN]
    assert [str(network) for network in settings.trusted_networks] == ["127.0.0.1/32", "::1/128"]
    assert settings.auth_cookie_secure and settings.team_2fa_required


def test_the_real_configuration_file_is_ignored_by_git():
    git = shutil.which("git")
    assert git, "git introuvable"
    ignored = subprocess.run(  # noqa: S603 (git du système, chemins fixes du projet)
        [git, "check-ignore", "deploy/ngrok.env", "deploy/sauvegardes/x.sql"],
        capture_output=True,
        text=True,
        cwd=BACKEND_DIR,
        check=False,
    )
    # Code 0 dès qu'UN chemin est ignoré : on vérifie les deux, un par un.
    assert ignored.returncode == 0
    assert ignored.stdout.split() == ["deploy/ngrok.env", "deploy/sauvegardes/x.sql"]


# --- Garde-fou de public.ps1 (lancé pour de vrai, étape « config » : rien n'est modifié) -------


def find_powershell() -> str | None:
    for exe in ("powershell", "pwsh"):
        if found := shutil.which(exe):
            return found
    return None


SHELL = find_powershell()
needs_powershell = pytest.mark.skipif(SHELL is None, reason="PowerShell introuvable")


def run_config(tmp_path: Path, values: dict[str, str] | None) -> subprocess.CompletedProcess:
    env_file = tmp_path / "ngrok.env"
    if values is not None:
        env_file.write_text("\n".join(f"{k}={v}" for k, v in values.items()), encoding="utf-8")
    return subprocess.run(  # noqa: S603 (PowerShell du système, script du projet)
        [
            SHELL,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(DEPLOY / "public.ps1"),
            "-Step",
            "config",
            "-EnvFile",
            str(env_file),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


@needs_powershell
@pytest.mark.parametrize(
    ("change", "why"),
    [
        ({"DATABASE_URL": PUBLIC_DB.replace("/elecpay_public?", "/elecpay?")}, "base de démo"),
        ({"DATABASE_URL": PUBLIC_DB.replace("/elecpay_public?", "/elecpay_e2e?")}, "base e2e"),
        ({"DATABASE_URL": PUBLIC_DB.replace("127.0.0.1", "10.0.0.5")}, "autre machine"),
        ({"DATABASE_URL": PUBLIC_DB + "/../elecpay"}, "chemin après le nom"),
        ({"APP_ENV": "development"}, "pas en production"),
        ({"DEMO_MODE": "false"}, "sans mode démo"),
        ({"DEMO_SEED_PASSWORD": ""}, "mot de passe vide"),
        ({"JWT_SECRET": ""}, "secret vide"),
    ],
)
def test_public_script_refuses(tmp_path, change, why):
    result = run_config(tmp_path, {**filled_example(), **change})
    assert result.returncode != 0, why
    assert "Refus" in result.stdout + result.stderr, why


@needs_powershell
def test_public_script_refuses_without_configuration(tmp_path):
    result = run_config(tmp_path, None)
    assert result.returncode != 0
    assert "preparer" in result.stdout + result.stderr


@needs_powershell
def test_public_script_accepts_the_filled_example(tmp_path):
    result = run_config(tmp_path, filled_example())
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Configuration valide" in result.stdout
    assert DOMAIN in result.stdout
    for key in SECRET_KEYS:  # aucun secret affiché
        assert filled_example()[key] not in result.stdout + result.stderr
