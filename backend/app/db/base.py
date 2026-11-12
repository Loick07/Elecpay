"""Socle commun de tous les modèles SQLAlchemy : `Base`, type de date UTC et mixins."""

from datetime import UTC, datetime

from sqlalchemy import BigInteger, DateTime, Dialect, MetaData
from sqlalchemy.dialects import mysql
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.types import TypeDecorator, TypeEngine

# Noms de contraintes stables et prévisibles : indispensable pour qu'Alembic
# puisse générer, renommer et supprimer les contraintes de façon fiable.
NAMING_CONVENTION = {
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Classe mère de toutes les tables d'ElecPay."""

    metadata = MetaData(naming_convention=NAMING_CONVENTION)


def utcnow() -> datetime:
    """Instant présent, en UTC, avec fuseau horaire."""
    return datetime.now(UTC)


class UTCDateTime(TypeDecorator[datetime]):
    """Date-heure toujours en UTC.

    MySQL `DATETIME` ne stocke pas de fuseau horaire. Ce type :
    - refuse une date sans fuseau à l'écriture (impossible de savoir si elle est en UTC) ;
    - convertit en UTC puis stocke sans fuseau, à la microseconde près ;
    - rend à la lecture une date avec fuseau UTC (sérialisée en ISO 8601 par l'API).
    """

    impl = DateTime
    cache_ok = True

    def load_dialect_impl(self, dialect: Dialect) -> TypeEngine[datetime]:
        if dialect.name == "mysql":
            return dialect.type_descriptor(mysql.DATETIME(fsp=6))
        return dialect.type_descriptor(DateTime())

    def process_bind_param(self, value: datetime | None, dialect: Dialect) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            raise ValueError("Date sans fuseau horaire refusée : utiliser une date UTC (utcnow())")
        return value.astimezone(UTC).replace(tzinfo=None)

    def process_result_value(self, value: datetime | None, dialect: Dialect) -> datetime | None:
        if value is None:
            return None
        return value.replace(tzinfo=UTC)


class IdMixin:
    """Clé primaire entière auto-incrémentée (BIGINT)."""

    # sort_order : l'id vient toujours en premier dans la table.
    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, sort_order=-100
    )


class TimestampMixin:
    """Dates de création et de dernière modification, gérées automatiquement."""

    # sort_order : ces colonnes viennent toujours en dernier dans la table.
    created_at: Mapped[datetime] = mapped_column(
        UTCDateTime(), default=utcnow, nullable=False, sort_order=100
    )
    updated_at: Mapped[datetime] = mapped_column(
        UTCDateTime(), default=utcnow, onupdate=utcnow, nullable=False, sort_order=101
    )
