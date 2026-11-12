"""Tests de la validation des saisies (B3.1) : téléphone, mot de passe, e-mail, nom."""

import re

import pytest
from pydantic import BaseModel, ValidationError

from app.core.validation import (
    CongoPhone,
    Email,
    FullName,
    NewPassword,
    check_password_strength,
    mask_phone,
    normalize_congo_phone,
    normalize_email,
    normalize_full_name,
)
from app.modules.users.models import PHONE_PATTERN

# --- Téléphone ----------------------------------------------------------------------


@pytest.mark.parametrize(
    "raw",
    [
        "+242061234567",
        "242061234567",
        "00242061234567",
        "061234567",
        "06 123 45 67",
        "06.12.34.56.7",
        "06-123-45-67",
        "+242 (06) 123 45 67",
        "  061234567  ",
    ],
)
def test_every_common_way_of_writing_a_number_is_normalized(raw):
    assert normalize_congo_phone(raw) == "+242061234567"


@pytest.mark.parametrize(
    "raw", ["051234567", "041234567", "221234567"]
)  # Airtel, autre mobile, fixe
def test_valid_prefixes(raw):
    assert normalize_congo_phone(raw) == f"+242{raw}"


def test_normalized_number_matches_the_database_constraint():
    assert re.fullmatch(PHONE_PATTERN.replace("[+]", r"\+"), normalize_congo_phone("061234567"))


@pytest.mark.parametrize(
    ("raw", "reason"),
    [
        ("06123456", "9 chiffres"),  # trop court
        ("0612345678", "9 chiffres"),  # trop long
        ("+243061234567", "9 chiffres"),  # indicatif RDC
        ("+33612345678", "9 chiffres"),  # France
        ("071234567", "04, 05, 06 ou 22"),
        ("101234567", "04, 05, 06 ou 22"),
        ("06 12a 45 67", "seuls les chiffres"),
        ("", "9 chiffres"),
        ("++242061234567", "seuls les chiffres"),
    ],
)
def test_invalid_numbers_are_refused_with_a_clear_reason(raw, reason):
    with pytest.raises(ValueError, match=reason):
        normalize_congo_phone(raw)


def test_phone_is_masked_for_logs_and_back_office():
    assert mask_phone("+242061234567") == "+242 06 *** ** 67"
    assert mask_phone("bizarre") == "***"


# --- Mot de passe -------------------------------------------------------------------


@pytest.mark.parametrize("password", ["Demo2026!", "abcdefg1", "motdepasse 2026", "Ébène-9-Kwa"])
def test_acceptable_passwords(password):
    assert check_password_strength(password) == password


@pytest.mark.parametrize(
    ("password", "reason"),
    [
        ("abc1", "trop court"),
        ("abcdefgh", "au moins un chiffre"),
        ("12345678", "au moins une lettre"),
        ("a1" * 65, "trop long"),
        (" Demo2026", "espace"),
        ("Demo2026 ", "espace"),
    ],
)
def test_weak_passwords_are_refused(password, reason):
    with pytest.raises(ValueError, match=reason):
        check_password_strength(password)


# --- E-mail et nom ------------------------------------------------------------------


def test_email_is_lowercased_and_trimmed():
    assert normalize_email("  Grace.Ngoma@Example.COM ") == "grace.ngoma@example.com"


@pytest.mark.parametrize(
    "raw", ["sans-arobase", "a@b", "a@b.c", "a b@c.cg", "@example.com", "x@.cg"]
)
def test_invalid_emails_are_refused(raw):
    with pytest.raises(ValueError, match="e-mail"):
        normalize_email(raw)


def test_full_name_spaces_are_cleaned():
    assert normalize_full_name("  Grâce   Ngoma ") == "Grâce Ngoma"


@pytest.mark.parametrize(
    ("raw", "reason"), [("A", "trop court"), ("12 34", "lettres"), ("x" * 121, "trop long")]
)
def test_invalid_names_are_refused(raw, reason):
    with pytest.raises(ValueError, match=reason):
        normalize_full_name(raw)


# --- Utilisation dans un schéma Pydantic --------------------------------------------


class Form(BaseModel):
    phone: CongoPhone
    password: NewPassword
    email: Email | None = None
    full_name: FullName


def test_types_normalize_inside_a_schema():
    form = Form(
        phone="06 123 45 67", password="Demo2026!", email="A@Example.com", full_name=" Davy  B "
    )
    assert (form.phone, form.email, form.full_name) == ("+242061234567", "a@example.com", "Davy B")


def test_types_report_errors_per_field():
    with pytest.raises(ValidationError) as error:
        Form(phone="123", password="court", full_name="Davy")
    fields = {e["loc"][0] for e in error.value.errors()}
    assert fields == {"phone", "password"}
