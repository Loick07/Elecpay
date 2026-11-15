"""Briques de la double authentification (B11.3) : TOTP selon les valeurs officielles des RFC,
chiffrement des secrets, codes de secours."""

import base64

import pytest

from app.core import totp
from app.core.secret_box import decrypt, derive_key, encrypt
from app.modules.auth.two_factor import BACKUP_ALPHABET, new_backup_code, normalize_backup_code

# Secret des RFC 4226 / 6238 : « 12345678901234567890 » en ASCII.
RFC_SECRET = base64.b32encode(b"12345678901234567890").decode()


@pytest.mark.parametrize(
    ("counter", "code"),
    list(enumerate(
        ["755224", "287082", "359152", "969429", "338314",
         "254676", "287922", "162583", "399871", "520489"]
    )),
)  # fmt: skip
def test_hotp_rfc4226(counter, code):
    assert totp.hotp(RFC_SECRET, counter) == code


@pytest.mark.parametrize(
    ("unix", "code"),
    [
        (59, "94287082"),
        (1111111109, "07081804"),
        (1111111111, "14050471"),
        (1234567890, "89005924"),
        (2000000000, "69279037"),
        (20000000000, "65353130"),
    ],
)
def test_totp_rfc6238_sha1(unix, code):
    assert totp.hotp(RFC_SECRET, totp.time_step(unix), digits=8) == code


def test_matching_step_window_and_replay():
    secret = totp.new_secret()
    now = 1_800_000_000
    step = totp.time_step(now)
    assert totp.matching_step(secret, totp.hotp(secret, step), now) == step
    assert (
        totp.matching_step(secret, totp.hotp(secret, step - 1), now) == step - 1
    )  # 30 s de retard
    assert totp.matching_step(secret, totp.hotp(secret, step + 1), now) == step + 1
    assert totp.matching_step(secret, totp.hotp(secret, step - 2), now) is None
    # Déjà utilisé : refusé, même dans sa fenêtre de validité.
    assert totp.matching_step(secret, totp.hotp(secret, step), now, last_used_step=step) is None
    assert totp.matching_step(secret, "12345", now) is None
    assert totp.matching_step(secret, "abcdef", now) is None


def test_provisioning_uri():
    uri = totp.provisioning_uri("JBSWY3DPEHPK3PXP", "+242060000002")
    assert uri.startswith("otpauth://totp/ElecPay%3A%2B242060000002?")
    assert "secret=JBSWY3DPEHPK3PXP" in uri and "issuer=ElecPay" in uri


def test_new_secret_is_random_base32():
    first, second = totp.new_secret(), totp.new_secret()
    assert first != second and len(first) == 32
    totp.hotp(first, 0)  # décodable


def test_secret_box():
    key = derive_key("une-cle-de-test-suffisamment-longue", "totp")
    sealed = encrypt("JBSWY3DPEHPK3PXP", key)
    assert "JBSWY3DPEHPK3PXP" not in sealed and sealed.startswith("v1:")
    assert decrypt(sealed, key) == "JBSWY3DPEHPK3PXP"
    assert encrypt("JBSWY3DPEHPK3PXP", key) != sealed  # nonce aléatoire
    with pytest.raises(ValueError, match="illisible"):
        decrypt(sealed, derive_key("une-autre-cle-tout-aussi-longue-xx", "totp"))
    assert derive_key("même", "totp") != derive_key("même", "autre-usage")


def test_backup_codes():
    code = new_backup_code()
    assert len(code) == 9 and code[4] == "-"
    assert set(code.replace("-", "")) <= set(BACKUP_ALPHABET)
    assert normalize_backup_code(" abcd-efgh ") == "ABCDEFGH"
