"""Annonces et alertes automatiques dans le back-office (B10.7, maquette A9).

Lecture (support, admin, super admin) : annonces envoyées ou programmées avec leur taux de
lecture, aperçu du nombre de destinataires, quartiers connus, état des alertes automatiques.
Écriture (admin, super admin), chaque action au journal : envoyer ou programmer une annonce,
annuler une annonce programmée, activer / couper une alerte automatique pour toute la
plateforme. L'envoi lui-même : `announcements.service.send_announcement`.
"""

from collections.abc import Callable
from datetime import datetime, timedelta

from fastapi import status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.request_context import RequestContext
from app.core.timezone import local_date
from app.db.base import utcnow
from app.modules.admin.announcements_schemas import (
    AlertSettingsPublic,
    AlertSettingsUpdate,
    AnnouncementCreate,
    AnnouncementList,
    AnnouncementRow,
    AudiencePreview,
    DistrictLine,
)
from app.modules.admin.audit import record_admin_action
from app.modules.announcements.alerts import GLOBAL, alert_switches
from app.modules.announcements.models import (
    AlertSettings,
    Announcement,
    AnnouncementStatus,
    Audience,
)
from app.modules.announcements.service import (
    audience_user_ids,
    read_counts,
    send_announcement,
)
from app.modules.households.models import Household
from app.modules.users.models import User, UserRole

MIN_DELAY = timedelta(minutes=5)  # programmer au moins 5 minutes à l'avance
MAX_DELAY = timedelta(days=90)


class AnnouncementNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "ANNOUNCEMENT_NOT_FOUND"
    message = "Annonce introuvable."


class AnnouncementRefusedError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "ANNOUNCEMENT_REFUSED"
    message = "Annonce impossible."


class AnnouncementActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "ANNOUNCEMENT_ACTION_REFUSED"
    message = "Action impossible sur cette annonce."


class AdminAnnouncements:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Lecture ------------------------------------------------------------------------------

    def list(self, params: PageParams) -> AnnouncementList:
        total = self.session.scalar(select(func.count()).select_from(Announcement))
        rows = self.session.execute(
            select(Announcement, User)
            .join(User, User.id == Announcement.created_by)
            .order_by(Announcement.created_at.desc(), Announcement.id.desc())
            .limit(params.size)
            .offset(params.offset)
        ).all()
        counts = read_counts(self.session, [announcement.id for announcement, _ in rows])
        return AnnouncementList(
            items=[self._row(announcement, author, counts) for announcement, author in rows],
            total=total,
            page=params.page,
            size=params.size,
        )

    def preview(
        self, audience: Audience, district: str | None, user_id: int | None
    ) -> AudiencePreview:
        self._check_target(audience, district, user_id)
        recipients = audience_user_ids(
            self.session,
            audience,
            today=local_date(self.now()),
            district=district,
            target_user_id=user_id,
        )
        return AudiencePreview(
            audience=audience,
            label=self._label(audience, district, user_id),
            recipients=len(recipients),
        )

    def districts(self) -> list[DistrictLine]:
        name = func.trim(Household.district)
        rows = self.session.execute(
            select(func.min(name), func.count())
            .where(Household.district.is_not(None), func.char_length(name) > 0)
            .group_by(func.lower(name))
            .order_by(func.lower(name))
        ).all()
        return [DistrictLine(district=district, households=count) for district, count in rows]

    def alert_settings(self) -> AlertSettingsPublic:
        row = self._settings_row()
        switches = alert_switches(self.session)
        author = self.session.get(User, row.updated_by) if row and row.updated_by else None
        return AlertSettingsPublic(
            due_soon=switches.due_soon,
            overdue=switches.overdue,
            high_consumption=switches.high_consumption,
            updated_at=row.updated_at if row else None,
            updated_by=author.full_name if author else None,
        )

    # --- Écriture -----------------------------------------------------------------------------

    def create(
        self, actor: User, data: AnnouncementCreate, context: RequestContext
    ) -> AnnouncementRow:
        self._check_target(data.audience, data.district, data.user_id)
        now = self.now()
        if data.scheduled_at is not None:
            if data.scheduled_at < now + MIN_DELAY:
                raise AnnouncementRefusedError(
                    "Programmez l'annonce au moins 5 minutes à l'avance (ou envoyez-la maintenant)."
                )
            if data.scheduled_at > now + MAX_DELAY:
                raise AnnouncementRefusedError("Programmation limitée à 90 jours.")
        elif not self.preview(data.audience, data.district, data.user_id).recipients:
            raise AnnouncementRefusedError("Aucun destinataire pour cette cible aujourd'hui.")
        announcement = Announcement(
            title=data.title,
            body=data.body,
            audience=data.audience,
            district=data.district,
            target_user_id=data.user_id,
            status=AnnouncementStatus.SCHEDULED,
            scheduled_at=data.scheduled_at or now,
            created_by=actor.id,
        )
        self.session.add(announcement)
        self.session.flush()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="announcement.create",
            entity_type="announcement",
            entity_id=announcement.id,
            after={
                "title": data.title,
                "audience": data.audience.value,
                "district": data.district,
                "user_id": data.user_id,
                "scheduled_at": data.scheduled_at.isoformat() if data.scheduled_at else None,
            },
        )
        if data.scheduled_at is None:
            announcement.scheduled_at = None  # envoi immédiat : jamais programmée
            send_announcement(self.session, announcement, now=now)
        self.session.commit()
        return self._row(
            announcement,
            actor,
            read_counts(self.session, [announcement.id]),
        )

    def cancel(self, actor: User, announcement_id: int, context: RequestContext) -> AnnouncementRow:
        announcement = self.session.scalars(
            select(Announcement).where(Announcement.id == announcement_id).with_for_update()
        ).first()
        if announcement is None:
            raise AnnouncementNotFoundError()
        if announcement.status is not AnnouncementStatus.SCHEDULED:
            raise AnnouncementActionError(
                "Seule une annonce programmée, pas encore envoyée, peut être annulée."
            )
        announcement.status = AnnouncementStatus.CANCELLED
        announcement.cancelled_at = self.now()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="announcement.cancel",
            entity_type="announcement",
            entity_id=announcement.id,
            before={"status": AnnouncementStatus.SCHEDULED.value},
            after={"status": AnnouncementStatus.CANCELLED.value},
        )
        self.session.commit()
        author = self.session.get(User, announcement.created_by)
        return self._row(announcement, author, {})

    def update_alert_settings(
        self, actor: User, data: AlertSettingsUpdate, context: RequestContext
    ) -> AlertSettingsPublic:
        before = alert_switches(self.session)
        row = self._settings_row(lock=True)
        if row is None:
            row = AlertSettings(scope=GLOBAL)
            self.session.add(row)
        row.due_soon, row.overdue = data.due_soon, data.overdue
        row.high_consumption = data.high_consumption
        row.updated_by = actor.id
        self.session.flush()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="alerts.settings",
            entity_type="alert_settings",
            entity_id=row.id,
            before={
                "due_soon": before.due_soon,
                "overdue": before.overdue,
                "high_consumption": before.high_consumption,
            },
            after=data.model_dump(),
        )
        self.session.commit()
        return self.alert_settings()

    # --- Outils -------------------------------------------------------------------------------

    def _settings_row(self, *, lock: bool = False) -> AlertSettings | None:
        query = select(AlertSettings).where(AlertSettings.scope == GLOBAL)
        if lock:
            query = query.with_for_update()
        return self.session.scalars(query).first()

    def _check_target(self, audience: Audience, district: str | None, user_id: int | None) -> None:
        if audience is Audience.DISTRICT and not (district and district.strip()):
            raise AnnouncementRefusedError("Choisissez un quartier.")
        if audience is Audience.CLIENT:
            client = self.session.get(User, user_id) if user_id else None
            if client is None or client.role is not UserRole.CLIENT:
                raise AnnouncementRefusedError("Client introuvable.")
            if not client.is_active:
                raise AnnouncementRefusedError("Ce compte est désactivé.")

    def _label(self, audience: Audience, district: str | None, user_id: int | None) -> str:
        match audience:
            case Audience.ALL:
                return "Tous les clients"
            case Audience.OVERDUE:
                return "Clients avec une facture en retard"
            case Audience.DISTRICT:
                return f"Quartier {district}"
            case Audience.CLIENT:
                client = self.session.get(User, user_id)
                return f"Client : {client.full_name}" if client else "Client"

    def _row(
        self,
        announcement: Announcement,
        author: User,
        counts: dict[int, tuple[int, int]],
    ) -> AnnouncementRow:
        sent = announcement.status is AnnouncementStatus.SENT
        total, read = counts.get(announcement.id, (0, 0))
        return AnnouncementRow(
            id=announcement.id,
            title=announcement.title,
            body=announcement.body,
            audience=announcement.audience,
            audience_label=self._label(
                announcement.audience, announcement.district, announcement.target_user_id
            ),
            district=announcement.district,
            user_id=announcement.target_user_id,
            status=announcement.status,
            scheduled_at=announcement.scheduled_at,
            sent_at=announcement.sent_at,
            cancelled_at=announcement.cancelled_at,
            recipients=announcement.recipients,
            read=read if sent else None,
            read_rate_percent=round(read * 100 / total, 1) if sent and total else None,
            created_by=author.full_name,
            created_at=announcement.created_at,
        )
