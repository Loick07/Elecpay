"""Briques de colonnes réutilisées par toutes les tables d'ElecPay.

- `enum_type(...)`      : valeurs fixes (rôle, statut…) → VARCHAR + contrainte CHECK en base.
- `StrictBigInteger`    : entier 64 bits qui refuse float / Decimal / bool (montants FCFA, Wh).
- `non_negative(...)`   : contrainte CHECK « colonne >= 0 ».
- `foreign_key(...)`    : clé étrangère qui interdit par défaut de supprimer la ligne référencée.
"""

from enum import StrEnum
from typing import Literal

from sqlalchemy import BigInteger, CheckConstraint, Dialect, Enum, ForeignKey
from sqlalchemy.types import TypeDecorator

# --- Valeurs fixes ------------------------------------------------------------------


def enum_type(enum_class: type[StrEnum], name: str) -> Enum:
    """Type SQLAlchemy pour une énumération Python.

    En base : une colonne VARCHAR et une contrainte CHECK `ck_<table>_<name>` qui refuse
    toute valeur hors de l'énumération (plus simple à faire évoluer qu'un ENUM MySQL).
    En Python : une valeur inconnue est refusée avant même d'atteindre la base.
    """
    values = [member.value for member in enum_class]
    return Enum(
        enum_class,
        name=name,  # nom de la contrainte CHECK (préfixé par la convention de nommage)
        native_enum=False,  # VARCHAR, pas ENUM MySQL
        create_constraint=True,  # contrainte CHECK en base
        validate_strings=True,  # refuse côté Python une chaîne inconnue
        length=max(len(v) for v in values),
        values_callable=lambda enum: [member.value for member in enum],  # stocke la valeur
    )


# --- Entiers stricts (montants FCFA, énergie en Wh) ---------------------------------


class StrictBigInteger(TypeDecorator[int]):
    """BIGINT qui n'accepte que des `int`.

    Règle ElecPay : jamais de float pour un montant. `12.5`, `Decimal("12")` ou `True`
    sont refusés à l'écriture, au lieu d'être arrondis ou convertis en silence.
    """

    impl = BigInteger
    cache_ok = True

    def process_bind_param(self, value: object, dialect: Dialect) -> int | None:
        if value is None:
            return None
        if isinstance(value, bool) or not isinstance(value, int):
            raise TypeError(f"Entier attendu (FCFA ou Wh), reçu {type(value).__name__} : {value!r}")
        return value


def non_negative(column: str) -> CheckConstraint:
    """Contrainte CHECK `ck_<table>_<column>_non_negative` : la colonne ne peut pas être < 0."""
    return CheckConstraint(f"{column} >= 0", name=f"{column}_non_negative")


# --- Clés étrangères ----------------------------------------------------------------

OnDelete = Literal["RESTRICT", "CASCADE", "SET NULL"]


def foreign_key(target: str, *, ondelete: OnDelete = "RESTRICT") -> ForeignKey:
    """Clé étrangère vers `table.colonne`.

    Par défaut RESTRICT : impossible de supprimer une ligne encore référencée
    (ex. un compteur qui a des factures). On ne choisit CASCADE ou SET NULL
    qu'explicitement, table par table, quand c'est justifié.
    """
    return ForeignKey(target, ondelete=ondelete, onupdate="RESTRICT")
