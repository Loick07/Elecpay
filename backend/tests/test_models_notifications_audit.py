"""Contraintes des tables `notifications` et `audit_logs` (B1.7)."""

from datetime import UTC, datetime

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.exc import StatementError

from app.modules.audit.models import AuditLog
from app.modules.notifications.models import Notification, NotificationType
from tests.db_helpers import expect_db_rejection
from tests.factories import make_audit_log, make_notification, make_user

# --- notifications ------------------------------------------------------------------


def test_notification_is_unread_by_default_and_keeps_its_data(db_session):
    notification = make_notification(db_session, data_json={"bill_id": 42, "amount": 40_384})
    db_session.expire(notification)
    assert notification.read_at is None
    assert notification.data_json == {"bill_id": 42, "amount": 40_384}


@pytest.mark.parametrize("kind", list(NotificationType))
def test_every_notification_type_is_accepted(db_session, kind):
    make_notification(db_session, type=kind)


def test_unknown_notification_type_is_refused(db_session):
    notification = make_notification(db_session)
    with expect_db_rejection(db_session, "ck_notifications_type"):
        db_session.execute(
            text("UPDATE notifications SET type = 'spam' WHERE id = :id"), {"id": notification.id}
        )


@pytest.mark.parametrize(
    ("column", "constraint"),
    [("title", "ck_notifications_title_not_blank"), ("body", "ck_notifications_body_not_blank")],
)
def test_title_and_body_cannot_be_blank(db_session, column, constraint):
    with expect_db_rejection(db_session, constraint):
        make_notification(db_session, **{column: "  "})


@pytest.mark.parametrize("data", [[1, 2, 3], "texte"])
def test_data_must_be_a_json_object(db_session, data):
    with expect_db_rejection(db_session, "ck_notifications_data_is_object"):
        make_notification(db_session, data_json=data)


def test_notification_without_data_is_allowed(db_session):
    notification = make_notification(db_session, data_json=None)
    stored = db_session.execute(
        text("SELECT data_json IS NULL FROM notifications WHERE id = :id"), {"id": notification.id}
    ).scalar_one()
    assert stored == 1  # un vrai NULL SQL, pas le texte JSON « null »


def test_audit_log_without_before_state_stores_sql_null(db_session):
    log = make_audit_log(db_session, before_json=None)  # ex. création : pas d'état « avant »
    stored = db_session.execute(
        text("SELECT before_json IS NULL FROM audit_logs WHERE id = :id"), {"id": log.id}
    ).scalar_one()
    assert stored == 1


def test_unread_count_for_the_badge(db_session):
    user = make_user(db_session)
    make_notification(db_session, user)
    make_notification(db_session, user)
    make_notification(db_session, user, read_at=datetime(2026, 9, 12, tzinfo=UTC))
    make_notification(db_session)  # quelqu'un d'autre
    unread = db_session.scalar(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == user.id, Notification.read_at.is_(None))
    )
    assert unread == 2


def test_notification_requires_existing_user(db_session):
    with expect_db_rejection(db_session, "fk_notifications_user_id_users"):
        make_notification(db_session, user_id=999_999)


# --- audit_logs ---------------------------------------------------------------------


def test_audit_log_records_who_did_what(db_session):
    admin = make_user(db_session)
    log = make_audit_log(db_session, admin)
    db_session.expire(log)
    assert log.actor_id == admin.id
    assert log.before_json == {"status": "unpaid"}
    assert log.after_json["status"] == "cancelled"
    assert log.user_agent == "Mozilla/5.0 (back-office ElecPay)"  # écran A10 : IP + navigateur
    assert log.created_at.tzinfo is not None


def test_system_action_has_no_actor(db_session):
    log = make_audit_log(db_session, actor=None, action="payment.confirm", ip=None)
    assert log.actor_id is None


def test_ipv6_address_fits(db_session):
    make_audit_log(db_session, ip="2001:0db8:85a3:0000:0000:8a2e:0370:7334")


@pytest.mark.parametrize("action", ["cancel", "Bill.Cancel", "bill-cancel", "bill.", ".cancel"])
def test_action_format_is_domain_dot_verb(db_session, action):
    with expect_db_rejection(db_session, "ck_audit_logs_action_format"):
        make_audit_log(db_session, action=action)


def test_entity_type_cannot_be_blank(db_session):
    with expect_db_rejection(db_session, "ck_audit_logs_entity_type_not_blank"):
        make_audit_log(db_session, entity_type=" ")


def test_audit_log_can_never_be_modified(db_session):
    log = make_audit_log(db_session)
    with expect_db_rejection(db_session, "audit_log_immutable"):
        db_session.execute(
            text("UPDATE audit_logs SET action = 'bill.view' WHERE id = :id"), {"id": log.id}
        )


def test_audit_log_can_never_be_deleted(db_session):
    log = make_audit_log(db_session)
    with expect_db_rejection(db_session, "audit_log_immutable"):
        db_session.execute(text("DELETE FROM audit_logs WHERE id = :id"), {"id": log.id})


def test_audit_log_cannot_be_emptied_in_bulk(db_session):
    make_audit_log(db_session)
    make_audit_log(db_session)
    with expect_db_rejection(db_session, "audit_log_immutable"):
        db_session.execute(text("DELETE FROM audit_logs"))
    assert db_session.scalar(select(func.count()).select_from(AuditLog)) == 2


def test_actor_with_audit_history_cannot_be_deleted(db_session):
    admin = make_user(db_session)
    make_audit_log(db_session, admin)
    with expect_db_rejection(db_session, "fk_audit_logs_actor_id_users"):
        db_session.execute(text("DELETE FROM users WHERE id = :id"), {"id": admin.id})


def test_audit_log_has_no_updated_at():
    assert "updated_at" not in AuditLog.__table__.c


def test_unknown_json_value_types_are_refused_by_python(db_session):
    with pytest.raises(StatementError):
        make_audit_log(db_session, after_json={"when": datetime(2026, 1, 1)})
    db_session.rollback()
