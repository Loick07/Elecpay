"""Tests des alertes quotidiennes (B9.3) : échéance proche, rappels de retard, consommation
inhabituelle, et leur lancement (`run_daily_alerts`, relevé quotidien, `scripts.daily_alerts`)."""

from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.core.timezone import local_midnight_utc
from app.modules.bills.models import BillStatus
from app.modules.households.models import MemberRole, MemberStatus
from app.modules.notifications.daily_alerts import run_daily_alerts
from app.modules.notifications.models import (
    Notification,
    NotificationPreference,
    NotificationType,
)
from scripts.daily_alerts import parse_args
from tests.factories import (
    make_bill,
    make_household,
    make_member,
    make_meter,
    make_reading,
    make_user,
)

DUE = date(2026, 11, 20)  # vendredi


@pytest.fixture
def family(db_session):
    owner, payer, viewer = make_user(db_session), make_user(db_session), make_user(db_session)
    home = make_household(db_session, owner, name="Maison Mpita")
    make_member(db_session, home, payer, role=MemberRole.PAYER, status=MemberStatus.ACTIVE)
    make_member(db_session, home, viewer, role=MemberRole.VIEWER, status=MemberStatus.ACTIVE)
    meter = make_meter(db_session, home)
    bill = make_bill(
        db_session,
        meter,
        period_start=date(2026, 9, 1),
        period_end=date(2026, 10, 31),
        due_date=DUE,
    )
    return {
        "owner": owner,
        "payer": payer,
        "viewer": viewer,
        "home": home,
        "meter": meter,
        "bill": bill,
    }


def run(session, today):
    return run_daily_alerts(session, today=today)


def notices(session, user, kind):
    return session.scalars(
        select(Notification)
        .where(Notification.user_id == user.id, Notification.type == kind)
        .order_by(Notification.created_at)
    ).all()


def prefer(session, user, **values):
    defaults = {"due_soon": True, "payments": True, "high_consumption": False}
    session.add(NotificationPreference(user_id=user.id, **(defaults | values)))
    session.flush()


# --- Échéance proche --------------------------------------------------------------------------


def test_nothing_six_days_before(db_session, family):
    assert run(db_session, DUE - timedelta(days=6))["due_soon"] == 0


def test_five_days_before_to_those_who_can_pay(db_session, family):
    counts = run(db_session, DUE - timedelta(days=5))
    assert counts["due_soon"] == 2  # titulaire + payeur délégué, pas le lecteur
    for person in ("owner", "payer"):
        (notice,) = notices(db_session, family[person], NotificationType.BILL_DUE_SOON)
        assert notice.title == "Échéance dans 5 jours"
        assert notice.body == "Maison Mpita : 40 384 FCFA à payer avant le 20/11/2026."
        assert notice.data_json == {"bill_id": family["bill"].id, "stage": "before"}
        assert notice.created_at == local_midnight_utc(DUE - timedelta(days=5)) + timedelta(hours=8)
    assert notices(db_session, family["viewer"], NotificationType.BILL_DUE_SOON) == []


def test_then_on_the_due_day_and_never_twice(db_session, family):
    for day in range(5, -1, -1):  # J-5, J-4… jusqu'au jour J, chaque jour relancé deux fois
        run(db_session, DUE - timedelta(days=day))
        run(db_session, DUE - timedelta(days=day))
    titles = [n.title for n in notices(db_session, family["owner"], NotificationType.BILL_DUE_SOON)]
    assert titles == ["Échéance dans 5 jours", "Échéance aujourd'hui"]
    last = notices(db_session, family["owner"], NotificationType.BILL_DUE_SOON)[-1]
    assert last.body == "Maison Mpita : 40 384 FCFA à payer aujourd'hui."


def test_a_late_run_says_how_many_days_are_left(db_session, family):
    run(db_session, DUE - timedelta(days=2))  # le relevé n'a pas tourné avant
    (notice,) = notices(db_session, family["owner"], NotificationType.BILL_DUE_SOON)
    assert notice.title == "Échéance dans 2 jours"


@pytest.mark.parametrize(
    "changes",
    [
        {"status": BillStatus.PAID, "paid_at": datetime(2026, 11, 10, tzinfo=UTC)},
        {"status": BillStatus.PENDING_PAYMENT},
        {
            "status": BillStatus.CANCELLED,
            "cancelled_at": datetime(2026, 11, 10, tzinfo=UTC),
            "cancelled_reason": "Facture émise par erreur",
        },
    ],
    ids=["payee", "paiement-en-cours", "annulee"],
)
def test_no_reminder_for_a_bill_that_is_not_to_pay(db_session, family, changes):
    for name, value in changes.items():
        setattr(family["bill"], name, value)
    db_session.flush()
    assert run(db_session, DUE - timedelta(days=5))["due_soon"] == 0


def test_the_due_soon_switch_is_respected(db_session, family):
    prefer(db_session, family["payer"], due_soon=False)
    assert run(db_session, DUE - timedelta(days=5))["due_soon"] == 1
    assert notices(db_session, family["payer"], NotificationType.BILL_DUE_SOON) == []


def test_a_detached_meter_reminds_nobody(db_session, family):
    family["meter"].household_id = None
    db_session.flush()
    assert run(db_session, DUE - timedelta(days=5))["due_soon"] == 0


# --- Retard : le lendemain, puis tous les 7 jours ------------------------------------------


def test_overdue_the_day_after_then_every_seven_days(db_session, family):
    owner = family["owner"]
    first = run(db_session, DUE + timedelta(days=1))
    assert (first["overdue"], first["overdue_notices"]) == (1, 2)  # titulaire + payeur délégué
    for day in range(2, 8):
        assert run(db_session, DUE + timedelta(days=day))["overdue_reminders"] == 0
    assert run(db_session, DUE + timedelta(days=8))["overdue_reminders"] == 2
    for day in range(9, 15):
        assert run(db_session, DUE + timedelta(days=day))["overdue_reminders"] == 0
    assert run(db_session, DUE + timedelta(days=15))["overdue_reminders"] == 2

    titles = [n.title for n in notices(db_session, owner, NotificationType.BILL_OVERDUE)]
    assert titles == [
        "Facture en retard",
        "Rappel : facture en retard",
        "Rappel : facture en retard",
    ]
    last = notices(db_session, owner, NotificationType.BILL_OVERDUE)[-1]
    assert (
        last.body == "Maison Mpita : 40 384 FCFA, en retard de 15 jours (échéance du 20/11/2026)."
    )
    assert notices(db_session, family["viewer"], NotificationType.BILL_OVERDUE) == []


def test_no_more_reminders_once_paid(db_session, family):
    run(db_session, DUE + timedelta(days=1))
    family["bill"].status = BillStatus.PAID
    family["bill"].paid_at = datetime(2026, 11, 25, tzinfo=UTC)
    db_session.flush()
    assert run(db_session, DUE + timedelta(days=8))["overdue_reminders"] == 0


def test_overdue_reminders_ignore_the_switches(db_session, family):
    """« Facture en retard » n'est pas désactivable (décision B9)."""
    prefer(db_session, family["owner"], due_soon=False, payments=False)
    run(db_session, DUE + timedelta(days=1))
    assert run(db_session, DUE + timedelta(days=8))["overdue_reminders"] == 2


# --- Consommation inhabituelle -------------------------------------------------------------

TODAY = date(2026, 11, 12)  # on teste la journée du 11/11, relevée à minuit le 12


def consumption(session, meter, *, history, yesterday, **yesterday_flags):
    """`history` : Wh des journées précédentes (la plus ancienne d'abord), puis hier."""
    index = 1_000_000
    days = [*history, yesterday]
    first_day = TODAY - timedelta(days=len(days))
    for offset, wh in enumerate(days):
        index += wh
        flags = yesterday_flags if offset == len(days) - 1 else {}
        make_reading(
            session,
            meter,
            read_at=local_midnight_utc(first_day + timedelta(days=offset + 1)),
            index_wh=index,
            consumption_wh=wh,
            **flags,
        )


def test_off_by_default(db_session, family):
    consumption(db_session, family["meter"], history=[10_000] * 30, yesterday=14_000)
    assert run(db_session, TODAY)["high_consumption"] == 0


def test_a_day_above_average_once_switched_on(db_session, family):
    prefer(db_session, family["owner"], high_consumption=True)
    prefer(db_session, family["viewer"], high_consumption=True)
    consumption(db_session, family["meter"], history=[10_000] * 30, yesterday=14_000)
    assert run(db_session, TODAY)["high_consumption"] == 2  # titulaire et lecteur (activé)
    (notice,) = notices(db_session, family["owner"], NotificationType.HIGH_CONSUMPTION)
    assert notice.title == "Consommation inhabituelle"
    assert notice.body == "Maison Mpita : 14,0 kWh le 11/11, 40 % au-dessus de votre moyenne."
    assert notice.data_json == {
        "meter_id": family["meter"].id,
        "household_id": family["home"].id,
        "day": "2026-11-11",
    }
    assert notices(db_session, family["payer"], NotificationType.HIGH_CONSUMPTION) == []
    assert run(db_session, TODAY)["high_consumption"] == 0  # pas deux fois la même journée


@pytest.mark.parametrize(
    ("history", "yesterday", "flags"),
    [
        ([10_000] * 30, 13_000, {}),  # exactement + 30 % : pas « au-dessus »
        ([10_000] * 30, 12_000, {}),
        ([10_000] * 6, 20_000, {}),  # moins de 7 journées de référence
        ([10_000] * 30, 20_000, {"is_estimated": True}),  # journée estimée
        ([10_000] * 30, 20_000, {"is_anomaly": True, "anomaly_reason": "Index en baisse"}),
        ([0] * 30, 5_000, {}),  # moyenne nulle
    ],
    ids=["egal-30", "sous-30", "trop-peu", "estimee", "anomalie", "moyenne-nulle"],
)
def test_no_alert(db_session, family, history, yesterday, flags):
    prefer(db_session, family["owner"], high_consumption=True)
    consumption(db_session, family["meter"], history=history, yesterday=yesterday, **flags)
    assert run(db_session, TODAY)["high_consumption"] == 0


def test_only_the_last_thirty_days_count(db_session, family):
    """Une vieille journée très forte (il y a 40 jours) ne gonfle pas la moyenne."""
    prefer(db_session, family["owner"], high_consumption=True)
    consumption(
        db_session, family["meter"], history=[90_000] * 10 + [10_000] * 30, yesterday=14_000
    )
    assert run(db_session, TODAY)["high_consumption"] == 1


# --- Lancement ------------------------------------------------------------------------------------


def test_everything_in_one_call(db_session, family):
    counts = run(db_session, DUE - timedelta(days=5))
    assert set(counts) >= {
        "overdue",
        "overdue_notices",
        "overdue_reminders",
        "due_soon",
        "high_consumption",
        "notifications",
    }
    assert counts["notifications"] == counts["due_soon"] == 2


def test_command_arguments():
    assert parse_args(["--today", "2026-11-20"]).today == date(2026, 11, 20)
