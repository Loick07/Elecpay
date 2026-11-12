"""Outils pour tester les contraintes de la base."""

from collections.abc import Iterator
from contextlib import contextmanager

import pytest
from sqlalchemy.exc import DataError, IntegrityError, OperationalError
from sqlalchemy.orm import Session

# Selon PyMySQL, MySQL signale :
# - unicité, clé étrangère, NOT NULL      → IntegrityError
# - contrainte CHECK (erreur 3819)        → OperationalError
# - valeur trop longue pour la colonne    → DataError (mode strict)
DB_REJECTIONS = (IntegrityError, OperationalError, DataError)


@contextmanager
def expect_db_rejection(session: Session, constraint: str | None = None) -> Iterator[None]:
    """Vérifie que la BASE refuse ce qui est écrit dans le bloc.

    Le bloc est exécuté dans un point de sauvegarde : après le refus, la session
    reste utilisable pour la suite du test.

        with expect_db_rejection(db_session, "uq_users_phone"):
            db_session.add(User(phone=numero_deja_pris, ...))

    `constraint` : nom de la contrainte attendue dans le message d'erreur de MySQL.
    """
    savepoint = session.begin_nested()
    with pytest.raises(DB_REJECTIONS) as error:
        yield
        session.flush()
    savepoint.rollback()
    if constraint is not None:
        message = str(error.value.orig)
        assert constraint in message, f"Contrainte {constraint!r} attendue, MySQL dit : {message}"
