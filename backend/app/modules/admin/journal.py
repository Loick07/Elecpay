"""Journal d'activité du back-office (B10.8, maquette A10) : admin et super admin.

Toutes les lignes d'audit, de l'équipe comme du système et des abonnés, les plus récentes
d'abord, avec le détail avant / après et les métadonnées (IP, navigateur). LECTURE SEULE :
aucune route ne modifie ni ne supprime une ligne, et la base l'interdit de toute façon
(triggers `trg_audit_logs_no_update` / `trg_audit_logs_no_delete`). Le journal ne contient
jamais de secret (mot de passe, jeton, code) : `audit.service.record` les refuse.
"""

from datetime import date, timedelta

from fastapi import status
from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.core.pagination import PageParams
from app.core.timezone import local_midnight_utc
from app.modules.admin.activity import action_label
from app.modules.admin.audit import STAFF_ROLES
from app.modules.admin.journal_schemas import (
    ActorKind,
    DomainCount,
    JournalActor,
    JournalEntry,
    JournalPage,
)
from app.modules.audit.models import AuditLog
from app.modules.users.models import User, UserRole

# Premier mot de l'action (« bill » dans « bill.cancel ») → filtre « par type » de l'écran A10.
DOMAINS: dict[str, str] = {
    "user": "Comptes",
    "household": "Foyers",
    "meter": "Compteurs",
    "bill": "Factures",
    "payment": "Paiements",
    "dispute": "Litiges",
    "announcement": "Annonces",
    "alerts": "Alertes automatiques",
    "team": "Équipe",
    "tariff": "Tarifs",
    "admin": "Exports",
    "demo": "Démonstration",
}


class JournalDateRangeError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "JOURNAL_DATE_RANGE_INVALID"
    message = "La date de début doit précéder la date de fin."


def domain_of(action: str) -> str:
    return action.split(".", 1)[0]


class AdminJournal:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list(
        self,
        params: PageParams,
        *,
        domain: str | None = None,
        action: str | None = None,
        actor_kind: ActorKind | None = None,
        actor_id: int | None = None,
        entity_type: str | None = None,
        entity_id: int | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
    ) -> JournalPage:
        if date_from and date_to and date_from > date_to:
            raise JournalDateRangeError()
        query = self._filtered(
            domain, action, actor_kind, actor_id, entity_type, entity_id, date_from, date_to
        )
        total = self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = self.session.execute(
            query.order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
            .limit(params.size)
            .offset(params.offset)
        ).all()
        return JournalPage(
            items=[self._entry(log, actor) for log, actor in rows],
            total=total,
            page=params.page,
            size=params.size,
        )

    def domains(self) -> list[DomainCount]:
        """Les types présents dans le journal, avec leur nombre de lignes (filtres de l'écran)."""
        domain = func.substring_index(AuditLog.action, ".", 1)
        rows = self.session.execute(
            select(domain, func.count()).group_by(domain).order_by(domain)
        ).all()
        return [
            DomainCount(domain=name, label=DOMAINS.get(name, name), count=count)
            for name, count in rows
        ]

    # --- Outils -------------------------------------------------------------------------------

    @staticmethod
    def _filtered(
        domain: str | None,
        action: str | None,
        actor_kind: ActorKind | None,
        actor_id: int | None,
        entity_type: str | None,
        entity_id: int | None,
        date_from: date | None,
        date_to: date | None,
    ) -> Select:
        query = select(AuditLog, User).outerjoin(User, User.id == AuditLog.actor_id)
        if domain:
            query = query.where(AuditLog.action.like(f"{domain}.%"))
        if action:
            query = query.where(AuditLog.action == action)
        match actor_kind:
            case ActorKind.SYSTEM:
                query = query.where(AuditLog.actor_id.is_(None))
            case ActorKind.TEAM:
                query = query.where(User.role.in_(STAFF_ROLES))
            case ActorKind.CLIENT:
                query = query.where(User.role == UserRole.CLIENT)
        if actor_id is not None:
            query = query.where(AuditLog.actor_id == actor_id)
        if entity_type:
            query = query.where(AuditLog.entity_type == entity_type)
        if entity_id is not None:
            query = query.where(AuditLog.entity_id == entity_id)
        if date_from:
            query = query.where(AuditLog.created_at >= local_midnight_utc(date_from))
        if date_to:  # inclus : jusqu'à minuit le lendemain (heure de Brazzaville)
            query = query.where(
                AuditLog.created_at < local_midnight_utc(date_to + timedelta(days=1))
            )
        return query

    @staticmethod
    def _entry(log: AuditLog, actor: User | None) -> JournalEntry:
        domain = domain_of(log.action)
        return JournalEntry(
            id=log.id,
            at=log.created_at,
            action=log.action,
            label=action_label(log.action),
            domain=domain,
            domain_label=DOMAINS.get(domain, domain),
            actor=(
                JournalActor(id=actor.id, full_name=actor.full_name, role=actor.role)
                if actor
                else None
            ),
            entity_type=log.entity_type,
            entity_id=log.entity_id,
            before=log.before_json,
            after=log.after_json,
            ip=log.ip,
            user_agent=log.user_agent,
        )
