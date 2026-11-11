"""Tests du socle base de données : type UTC, mixins, session et vérification de la base."""

from datetime import UTC, datetime, timedelta, timezone

import pytest
from sqlalchemy import MetaData, String, UniqueConstraint, select
from sqlalchemy.dialects import mysql
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.db import session as db_session
from app.db.base import NAMING_CONVENTION, Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.session import build_engine, build_sessionmaker, database_is_reachable

MYSQL = mysql.dialect()


# --- Type UTCDateTime (sans base) -------------------------------------------------


def test_naive_datetime_is_refused():
    with pytest.raises(ValueError, match="sans fuseau"):
        UTCDateTime().process_bind_param(datetime(2026, 1, 1, 12, 0), MYSQL)


def test_aware_datetime_is_stored_as_utc():
    brazzaville = timezone(timedelta(hours=1))  # heure du Congo : UTC+1
    local_time = datetime(2026, 1, 1, 13, 0, tzinfo=brazzaville)
    stored = UTCDateTime().process_bind_param(local_time, MYSQL)
    assert stored == datetime(2026, 1, 1, 12, 0)
    assert stored.tzinfo is None


def test_value_read_from_database_is_utc_aware():
    value = UTCDateTime().process_result_value(datetime(2026, 1, 1, 12, 0), MYSQL)
    assert value == datetime(2026, 1, 1, 12, 0, tzinfo=UTC)


def test_none_passes_through():
    assert UTCDateTime().process_bind_param(None, MYSQL) is None
    assert UTCDateTime().process_result_value(None, MYSQL) is None


def test_base_uses_naming_convention():
    assert Base.metadata.naming_convention == NAMING_CONVENTION


# --- Mixins sur une vraie table MySQL --------------------------------------------


class SampleBase(DeclarativeBase):
    # Métadonnées séparées : cette table de test n'apparaîtra jamais dans les migrations.
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


class Sample(IdMixin, TimestampMixin, SampleBase):
    __tablename__ = "zz_sample_b0"
    __table_args__ = (UniqueConstraint("code"),)
    code: Mapped[str] = mapped_column(String(20))


@pytest.fixture
def sample_session(test_engine):
    SampleBase.metadata.create_all(test_engine)
    session = build_sessionmaker(test_engine)()
    yield session
    session.close()
    SampleBase.metadata.drop_all(test_engine)


def test_unique_constraint_name_follows_convention():
    names = {c.name for c in Sample.__table__.constraints}
    assert "uq_zz_sample_b0_code" in names


def test_mixins_fill_id_and_timestamps(sample_session):
    before = datetime.now(UTC)
    row = Sample(code="A")
    sample_session.add(row)
    sample_session.commit()

    loaded = sample_session.scalars(select(Sample).where(Sample.code == "A")).one()
    assert isinstance(loaded.id, int) and loaded.id > 0
    assert loaded.created_at.tzinfo == UTC
    assert before <= loaded.created_at <= datetime.now(UTC)
    # Deux lectures successives de l'horloge : quelques microsecondes d'écart au plus.
    assert timedelta(0) <= loaded.updated_at - loaded.created_at < timedelta(seconds=1)


def test_updated_at_changes_on_update(sample_session):
    row = Sample(code="B")
    sample_session.add(row)
    sample_session.commit()
    created_at = row.created_at

    row.code = "B2"
    sample_session.commit()
    sample_session.expire_all()

    reloaded = sample_session.get(Sample, row.id)
    assert reloaded.created_at == created_at
    assert reloaded.updated_at > created_at


def test_microseconds_are_preserved(sample_session):
    instant = datetime(2026, 3, 4, 5, 6, 7, 123456, tzinfo=UTC)
    row = Sample(code="C", created_at=instant, updated_at=instant)
    sample_session.add(row)
    sample_session.commit()
    sample_session.expire_all()

    assert sample_session.get(Sample, row.id).created_at == instant


# --- Session et disponibilité de la base -----------------------------------------


def test_database_is_reachable(test_engine):
    with build_sessionmaker(test_engine)() as session:
        assert database_is_reachable(session) is True


def test_unreachable_database_is_detected():
    engine = build_engine("mysql+pymysql://elecpay:elecpay@127.0.0.1:1/elecpay_test")
    with build_sessionmaker(engine)() as session:
        assert database_is_reachable(session) is False
    engine.dispose()


class FakeSession:
    def __init__(self):
        self.rolled_back = False
        self.closed = False

    def rollback(self):
        self.rolled_back = True

    def close(self):
        self.closed = True


@pytest.fixture
def fake_session(monkeypatch):
    fake = FakeSession()
    monkeypatch.setattr(db_session, "get_sessionmaker", lambda: lambda: fake)
    return fake


def test_get_db_closes_session(fake_session):
    dependency = db_session.get_db()
    assert next(dependency) is fake_session
    with pytest.raises(StopIteration):
        next(dependency)
    assert fake_session.closed is True
    assert fake_session.rolled_back is False


def test_get_db_rolls_back_on_error(fake_session):
    dependency = db_session.get_db()
    next(dependency)
    with pytest.raises(RuntimeError):
        dependency.throw(RuntimeError("erreur pendant la requête"))
    assert fake_session.rolled_back is True
    assert fake_session.closed is True
