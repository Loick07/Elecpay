"""Critères de l'étape B4 (backend/PLAN.md), testés à travers l'API.

- « Un utilisateur ne voit que les foyers dont il est membre (test d'accès croisé obligatoire). »
- « Payeur délégué : peut voir et payer les factures du foyer, pas le modifier. »
- « Ajout de compteur : vérifié via BillingSource. »
+ le parcours de la démo : Christelle, sa maison, son compteur, et son fils Davy qui paie.
Chaque cas est aussi testé en détail dans test_households_api.py, test_members_api.py,
test_meters_api.py et test_household_access.py.
"""

from datetime import date

import pytest
from sqlalchemy import func, select

from app.integrations.billing_sources.factory import get_billing_source
from app.integrations.billing_sources.simulated import SimulatedBillingSource
from app.integrations.sms.factory import get_sms_sender
from app.integrations.sms.simulated import SimulatedSmsSender
from app.modules.bills.models import Bill, BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.meters.service import MeterService
from tests.factories import make_household, make_member, make_meter, make_tariff, make_user

TODAY = date(2026, 11, 12)


@pytest.fixture(autouse=True)
def demo_context(app, db_session, monkeypatch):
    app.dependency_overrides[get_sms_sender] = lambda: SimulatedSmsSender()
    make_tariff(db_session, code="BT_DOMESTIQUE", valid_from=date(2025, 1, 1))
    original = MeterService.__init__
    monkeypatch.setattr(
        MeterService,
        "__init__",
        lambda self, session, today=None: original(self, session, today=lambda: TODAY),
    )


# --- Critère 1 : accès croisé -------------------------------------------------------


def test_criterion_cross_access(client, auth_headers, db_session):
    arnaud, rodrigue = make_user(db_session), make_user(db_session)
    rodrigues_home = make_household(db_session, rodrigue)
    meter = make_meter(db_session, rodrigues_home)
    member = make_member(
        db_session, rodrigues_home, make_user(db_session), status=MemberStatus.ACTIVE
    )
    headers = auth_headers(arnaud)
    base = f"/api/v1/households/{rodrigues_home.id}"

    assert client.get("/api/v1/households", headers=headers).json() == []
    for response in (
        client.get(base, headers=headers),
        client.patch(base, json={"name": "Piraté"}, headers=headers),
        client.get(f"{base}/members", headers=headers),
        client.post(
            f"{base}/members", json={"phone": arnaud.phone, "role": "payer"}, headers=headers
        ),
        client.delete(f"{base}/members/{member.id}", headers=headers),
        client.get(f"{base}/meters", headers=headers),
        client.post(
            f"{base}/meters",
            json={"reference": "0018095408", "customer_number": "0758340H"},
            headers=headers,
        ),
        client.get(f"/api/v1/meters/{meter.id}", headers=headers),
        client.patch(f"/api/v1/meters/{meter.id}", json={"label": "X"}, headers=headers),
    ):
        assert response.status_code == 404, response.request.url


# --- Critère 2 : le payeur délégué voit et peut payer, sans modifier ----------------


def test_criterion_delegated_payer_sees_but_does_not_modify(client, auth_headers, db_session):
    owner, payer = make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner)
    meter = make_meter(db_session, home)
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    headers = auth_headers(payer)
    base = f"/api/v1/households/{home.id}"

    seen = client.get(base, headers=headers).json()
    assert (seen["can_pay"], seen["can_manage"]) == (True, False)
    assert client.get(f"/api/v1/meters/{meter.id}", headers=headers).status_code == 200

    for response in (
        client.patch(base, json={"name": "Changé"}, headers=headers),
        client.post(
            f"{base}/members", json={"phone": owner.phone, "role": "viewer"}, headers=headers
        ),
        client.post(
            f"{base}/meters",
            json={"reference": "0018095408", "customer_number": "0758340H"},
            headers=headers,
        ),
        client.patch(f"/api/v1/meters/{meter.id}", json={"label": "Changé"}, headers=headers),
    ):
        assert response.status_code == 403
        assert response.json()["error"]["code"] == "HOUSEHOLD_FORBIDDEN"


# --- Critère 3 : l'ajout de compteur passe par BillingSource ------------------------


def test_criterion_meter_is_verified_through_billing_source(app, client, auth_headers, db_session):
    calls = []

    class RecordingSource(SimulatedBillingSource):
        def lookup_meter(self, reference, customer_number):
            calls.append((reference, customer_number))
            return super().lookup_meter(reference, customer_number)

    app.dependency_overrides[get_billing_source] = RecordingSource
    owner = make_user(db_session)
    home = make_household(db_session, owner)
    url = f"/api/v1/households/{home.id}/meters"

    refused = client.post(
        url,
        json={"reference": "0018 09 0000", "customer_number": "0758340H"},
        headers=auth_headers(owner),
    )
    accepted = client.post(
        url,
        json={"reference": "0018 09 5408", "customer_number": "0758340h"},
        headers=auth_headers(owner),
    )
    assert refused.status_code == 404 and accepted.status_code == 201
    assert calls == [("0018090000", "0758340H"), ("0018095408", "0758340H")]  # normalisés


# --- Le parcours de la démo ---------------------------------------------------------


def test_demo_journey_mother_and_son(client, auth_headers, db_session):
    """Christelle crée sa maison, ajoute son compteur, invite son fils Davy (à Paris) ;
    Davy accepte et peut payer la facture de sa mère."""
    christelle = make_user(db_session, full_name="Christelle Bouanga")
    davy = make_user(db_session, full_name="Davy Bouanga")
    mom, son = auth_headers(christelle), auth_headers(davy)

    home = client.post(
        "/api/v1/households",
        json={"name": "Maison de maman", "city": "Brazzaville", "district": "Bacongo"},
        headers=mom,
    ).json()
    added = client.post(
        f"/api/v1/households/{home['id']}/meters",
        json={"reference": "0018 09 5408", "customer_number": "0758340H", "label": "Maison"},
        headers=mom,
    ).json()
    assert added["history"]["source"] == "simulated"

    invitation = client.post(
        f"/api/v1/households/{home['id']}/members",
        json={"phone": davy.phone, "role": "payer"},
        headers=mom,
    ).json()
    (pending,) = client.get("/api/v1/invitations", headers=son).json()
    assert pending["invited_by"]["full_name"] == "Christelle Bouanga"

    joined = client.post(f"/api/v1/invitations/{invitation['id']}/accept", headers=son).json()
    assert (joined["name"], joined["my_role"], joined["can_pay"]) == (
        "Maison de maman",
        "payer",
        True,
    )
    assert [m["label"] for m in joined["meters"]] == ["Maison"]

    # La dernière facture du compteur attend un paiement (que Davy pourra faire en B7).
    to_pay = db_session.scalar(
        select(func.count())
        .select_from(Bill)
        .where(
            Bill.meter_id == added["meter"]["id"],
            Bill.status.in_([BillStatus.UNPAID, BillStatus.OVERDUE]),
        )
    )
    assert to_pay == 1
