"""Le seed est déterministe : même date + même graine → exactement la même base.

Fichier séparé de test_seed.py : deux seeds ne doivent pas être ouverts EN MÊME TEMPS
(MySQL ferait attendre le second sur les numéros de téléphone uniques du premier).
"""

from sqlalchemy import func, select

from app.modules.bills.models import Bill
from app.modules.receipts.models import Receipt
from app.simulators.seeder import seed_demo
from tests.conftest import transactional_session
from tests.factories import Billing
from tests.test_seed import TODAY


def snapshot(engine, seed=2026):
    with transactional_session(engine) as session:
        report = seed_demo(session, today=TODAY, settings=Billing(), seed=seed)
        return (
            report.counts,
            session.scalar(select(func.sum(Bill.amount_total))),
            tuple(session.scalars(select(Receipt.verification_code).order_by(Receipt.number))),
        )


def test_same_date_and_seed_give_the_same_database(test_engine):
    # Qu'une AUTRE graine donne d'autres données est déjà prouvé, bien plus vite, par les
    # tests des simulateurs (relevés, factures, paiements) : pas besoin de deux seeds de plus.
    assert snapshot(test_engine) == snapshot(test_engine)
