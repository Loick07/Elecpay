"""Tests des briques de colonnes (app/db/types.py) sur une vraie table MySQL jetable."""

from enum import StrEnum

import pytest
from sqlalchemy import MetaData, String, select, text
from sqlalchemy.exc import StatementError
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.db.base import NAMING_CONVENTION, IdMixin
from app.db.types import StrictBigInteger, enum_type, foreign_key, non_negative
from tests.db_helpers import expect_db_rejection


class Color(StrEnum):
    RED = "red"
    GREEN = "green"
    DARK_BLUE = "dark_blue"


class SampleBase(DeclarativeBase):
    # Métadonnées séparées : ces tables d'essai n'apparaîtront jamais dans les migrations.
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


class Parent(IdMixin, SampleBase):
    __tablename__ = "zz_parent_b1"
    label: Mapped[str] = mapped_column(String(20))


class Child(IdMixin, SampleBase):
    __tablename__ = "zz_child_b1"
    __table_args__ = (non_negative("amount"),)

    parent_id: Mapped[int] = mapped_column(foreign_key("zz_parent_b1.id"))
    color: Mapped[Color] = mapped_column(enum_type(Color, "color"))
    amount: Mapped[int] = mapped_column(StrictBigInteger())


@pytest.fixture(scope="module")
def sample_tables(test_engine):
    SampleBase.metadata.drop_all(test_engine)
    SampleBase.metadata.create_all(test_engine)
    yield
    SampleBase.metadata.drop_all(test_engine)


@pytest.fixture
def session(sample_tables, db_session):
    return db_session


@pytest.fixture
def parent(session):
    row = Parent(label="p")
    session.add(row)
    session.flush()
    return row


# --- Structure générée --------------------------------------------------------------


def test_enum_is_a_varchar_with_named_check_constraint():
    column = Child.__table__.c.color
    assert column.type.native_enum is False
    assert column.type.length == len("dark_blue")
    check_names = {
        c.name for c in Child.__table__.constraints if c.__class__.__name__ == "CheckConstraint"
    }
    assert "ck_zz_child_b1_color" in check_names
    assert "ck_zz_child_b1_amount_non_negative" in check_names


def test_foreign_key_restricts_delete_by_default():
    (fk,) = Child.__table__.c.parent_id.foreign_keys
    assert fk.ondelete == "RESTRICT"
    assert fk.constraint.name == "fk_zz_child_b1_parent_id_zz_parent_b1"


def test_foreign_key_on_delete_can_be_chosen_explicitly():
    assert foreign_key("x.id", ondelete="CASCADE").ondelete == "CASCADE"


# --- Énumérations -------------------------------------------------------------------


def test_enum_value_is_stored_as_its_text(session, parent):
    session.add(Child(parent_id=parent.id, color=Color.DARK_BLUE, amount=10))
    session.flush()
    raw = session.execute(text("SELECT color FROM zz_child_b1")).scalar_one()
    assert raw == "dark_blue"
    assert session.scalars(select(Child)).one().color is Color.DARK_BLUE


def test_unknown_enum_value_is_refused_by_python(session, parent):
    session.add(Child(parent_id=parent.id, color="purple", amount=10))
    with pytest.raises(StatementError):
        session.flush()
    session.rollback()


def test_unknown_enum_value_is_refused_by_mysql(session, parent):
    # SQL brut : on contourne Python pour prouver que la BASE elle-même refuse.
    with expect_db_rejection(session, "ck_zz_child_b1_color"):
        session.execute(
            text("INSERT INTO zz_child_b1 (parent_id, color, amount) VALUES (:p, 'purple', 1)"),
            {"p": parent.id},
        )


# --- Entiers stricts et positifs ----------------------------------------------------


@pytest.mark.parametrize("value", [12.5, 12.0, True])
def test_strict_integer_refuses_non_int(value):
    with pytest.raises(TypeError, match="Entier attendu"):
        StrictBigInteger().process_bind_param(value, None)


def test_strict_integer_refuses_decimal():
    from decimal import Decimal

    with pytest.raises(TypeError, match="Decimal"):
        StrictBigInteger().process_bind_param(Decimal("12"), None)


def test_strict_integer_accepts_large_amounts(session, parent):
    big = 9_000_000_000_000  # au-delà d'un INT 32 bits : il faut bien un BIGINT
    session.add(Child(parent_id=parent.id, color=Color.RED, amount=big))
    session.flush()
    assert session.scalars(select(Child.amount)).one() == big


def test_float_amount_is_refused_before_reaching_mysql(session, parent):
    session.add(Child(parent_id=parent.id, color=Color.RED, amount=99.9))
    with pytest.raises(StatementError, match="Entier attendu"):
        session.flush()
    session.rollback()


def test_negative_amount_is_refused_by_mysql(session, parent):
    with expect_db_rejection(session, "ck_zz_child_b1_amount_non_negative"):
        session.add(Child(parent_id=parent.id, color=Color.RED, amount=-1))


def test_zero_amount_is_accepted(session, parent):
    session.add(Child(parent_id=parent.id, color=Color.GREEN, amount=0))
    session.flush()


# --- Clés étrangères ----------------------------------------------------------------


def test_reference_to_missing_row_is_refused(session):
    with expect_db_rejection(session, "fk_zz_child_b1_parent_id_zz_parent_b1"):
        session.add(Child(parent_id=999_999, color=Color.RED, amount=1))


def test_referenced_row_cannot_be_deleted(session, parent):
    session.add(Child(parent_id=parent.id, color=Color.RED, amount=1))
    session.flush()
    with expect_db_rejection(session, "fk_zz_child_b1_parent_id_zz_parent_b1"):
        session.execute(text("DELETE FROM zz_parent_b1 WHERE id = :id"), {"id": parent.id})


# --- L'outil de test lui-même -------------------------------------------------------


def test_session_is_still_usable_after_a_rejection(session, parent):
    with expect_db_rejection(session):
        session.add(Child(parent_id=parent.id, color=Color.RED, amount=-5))
    session.add(Child(parent_id=parent.id, color=Color.RED, amount=5))
    session.flush()
    assert session.scalars(select(Child.amount)).all() == [5]


def test_helper_fails_when_database_accepts(session, parent):
    with pytest.raises(pytest.fail.Exception), expect_db_rejection(session):
        session.add(Child(parent_id=parent.id, color=Color.RED, amount=5))


def test_helper_fails_on_wrong_constraint_name(session, parent):
    with (
        pytest.raises(AssertionError, match="uq_inexistante"),
        expect_db_rejection(session, "uq_inexistante"),
    ):
        session.add(Child(parent_id=parent.id, color=Color.RED, amount=-5))
