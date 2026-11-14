"""Envoi des annonces de l'équipe (maquette A9, B10.7).

`send_announcement` est l'UNIQUE endroit qui envoie une annonce : il calcule les destinataires
au moment de l'envoi (une annonce programmée vise donc la situation du jour d'envoi), crée une
notification `announcement` par personne (par `insert_notifications`) et note la date et le
nombre de destinataires. Appelé par la route d'envoi immédiat et par
`scripts.send_announcements` (programmées, toutes les minutes). Pas de commit.

Destinataires (comptes actifs seulement, chacun une seule fois) :
- all      : tous les clients ;
- overdue  : titulaires et payeurs délégués actifs des foyers ayant une facture en retard ;
- district : titulaires et membres actifs (payeurs, lecteurs) des foyers du quartier ;
- client   : le client choisi.
"""

from collections.abc import Sequence
from datetime import date, datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.modules.announcements.models import Announcement, AnnouncementStatus, Audience
from app.modules.audit.service import record
from app.modules.bills.models import Bill
from app.modules.bills.queries import is_overdue
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.notifications.models import Notification, NotificationType
from app.modules.notifications.service import insert_notifications, notification_row
from app.modules.users.models import User, UserRole


def same_district(district: str):
    """Comparaison de quartier sans tenir compte des majuscules ni des espaces autour."""
    return func.lower(func.trim(Household.district)) == district.strip().lower()


def audience_user_ids(
    session: Session,
    audience: Audience,
    *,
    today: date,
    district: str | None = None,
    target_user_id: int | None = None,
) -> list[int]:
    match audience:
        case Audience.ALL:
            candidates = select(User.id).where(User.role == UserRole.CLIENT)
        case Audience.CLIENT:
            candidates = select(User.id).where(
                User.id == target_user_id, User.role == UserRole.CLIENT
            )
        case Audience.OVERDUE:
            households = (
                select(Meter.household_id)
                .join(Bill, Bill.meter_id == Meter.id)
                .where(is_overdue(today), Meter.household_id.is_not(None))
            )
            candidates = _owners_and_members(households, roles=(MemberRole.PAYER,))
        case Audience.DISTRICT:
            households = select(Household.id).where(same_district(district or ""))
            candidates = _owners_and_members(households, roles=tuple(MemberRole))
    return list(
        session.scalars(
            select(User.id)
            .where(User.id.in_(candidates), User.is_active.is_(True))
            .order_by(User.id)
        )
    )


def _owners_and_members(households, *, roles: Sequence[MemberRole]):
    owners = select(Household.owner_id).where(Household.id.in_(households))
    members = select(HouseholdMember.user_id).where(
        HouseholdMember.household_id.in_(households),
        HouseholdMember.role.in_(roles),
        HouseholdMember.status == MemberStatus.ACTIVE,
    )
    return owners.union(members)


def send_announcement(session: Session, announcement: Announcement, *, now: datetime) -> int:
    """Envoie l'annonce maintenant. Renvoie le nombre de notifications créées. Pas de commit."""
    recipients = audience_user_ids(
        session,
        announcement.audience,
        today=local_date(now),
        district=announcement.district,
        target_user_id=announcement.target_user_id,
    )
    sent = insert_notifications(
        session,
        [
            notification_row(
                user_id,
                NotificationType.ANNOUNCEMENT,
                announcement.title,
                announcement.body,
                {"announcement_id": announcement.id},
                at=now,
            )
            for user_id in recipients
        ],
    )
    announcement.status = AnnouncementStatus.SENT
    announcement.sent_at = now
    announcement.recipients = sent
    session.flush()
    record(
        session,
        action="announcement.sent",
        entity_type="announcement",
        entity_id=announcement.id,
        actor_id=None,  # envoi par la plateforme (immédiat ou à l'heure programmée)
        after={"recipients": sent, "audience": announcement.audience.value},
    )
    return sent


def send_due_announcements(session: Session, *, now: datetime) -> list[Announcement]:
    """Envoie les annonces programmées dont l'heure est venue, une par une (commit chacune).

    `SKIP LOCKED` : deux exécutions simultanées ne prennent jamais la même annonce.
    """
    sent = []
    while True:
        announcement = session.scalars(
            select(Announcement)
            .where(
                Announcement.status == AnnouncementStatus.SCHEDULED,
                Announcement.scheduled_at <= now,
            )
            .order_by(Announcement.scheduled_at, Announcement.id)
            .limit(1)
            .with_for_update(skip_locked=True)
        ).first()
        if announcement is None:
            return sent
        send_announcement(session, announcement, now=now)
        session.commit()
        sent.append(announcement)


def read_counts(session: Session, announcement_ids: Sequence[int]) -> dict[int, tuple[int, int]]:
    """Pour chaque annonce : (notifications créées, notifications lues)."""
    if not announcement_ids:
        return {}
    key = Notification.data_json["announcement_id"].as_integer()
    rows = session.execute(
        select(key, func.count(), func.count(Notification.read_at))
        .where(Notification.type == NotificationType.ANNOUNCEMENT, key.in_(announcement_ids))
        .group_by(key)
    ).all()
    return {announcement_id: (total, read) for announcement_id, total, read in rows}
