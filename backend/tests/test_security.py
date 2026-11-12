"""Tests du hachage des mots de passe (Argon2id)."""

import pytest

from app.core.security import hash_password, needs_rehash, verify_password

PASSWORD = "Demo2026!"


def test_hash_is_argon2id_and_never_contains_the_password():
    password_hash = hash_password(PASSWORD)
    assert password_hash.startswith("$argon2id$")
    assert PASSWORD not in password_hash


def test_same_password_gives_different_hashes():
    assert hash_password(PASSWORD) != hash_password(PASSWORD)  # sel aléatoire


def test_correct_password_is_accepted():
    assert verify_password(PASSWORD, hash_password(PASSWORD)) is True


@pytest.mark.parametrize("attempt", ["demo2026!", "Demo2026", "", "Demo2026! "])
def test_wrong_password_is_refused(attempt):
    assert verify_password(attempt, hash_password(PASSWORD)) is False


@pytest.mark.parametrize("broken_hash", ["", "pas-un-hash", "$argon2id$v=19$tronqué"])
def test_invalid_hash_is_refused_without_crashing(broken_hash):
    assert verify_password(PASSWORD, broken_hash) is False


def test_empty_password_cannot_be_hashed():
    with pytest.raises(ValueError, match="vide"):
        hash_password("")


def test_fresh_hash_does_not_need_rehash():
    assert needs_rehash(hash_password(PASSWORD)) is False
