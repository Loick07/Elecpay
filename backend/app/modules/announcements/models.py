"""Tables `announcements` (annonces de l'équipe) et `alert_settings` (alertes automatiques).

Maquette admin A9. Une annonce devient, à son envoi, une notification `announcement` par
destinataire (créée par `insert_notifications`, toujours envoyée : l'abonné ne peut pas la
couper). Le taux de lecture se lit sur ces notifications.

Garanties assurées PAR LA BASE :
- la cible est complète : un quartier pour « district », un client pour « client », rien de
  plus pour « all » et « overdue » ;
- une annonce envoyée a sa date d'envoi et son nombre de destinataires ; une annonce
  annulée a sa date d'annulation ; une annonce programmée a sa date prévue.
"""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import Boolean, CheckConstraint, Integer, String, UniqueConstraint, true
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import enum_type, foreign_key


class Audience(StrEnum):
    ALL = "all"  # tous les clients actifs
    OVERDUE = "overdue"  # titulaires et payeurs délégués des foyers ayant une facture en retard
    DISTRICT = "district"  # tous les membres actifs des foyers d'un quartier
    CLIENT = "client"  # un client précis


class AnnouncementStatus(StrEnum):
    SCHEDULED = "scheduled"  # programmée, pas encore envoyée
    SENT = "sent"
    CANCELLED = "cancelled"  # programmée puis annulée (jamais envoyée)


class Announcement(IdMixin, TimestampMixin, Base):
    __tablename__ = "announcements"
    __table_args__ = (
        CheckConstraint("CHAR_LENGTH(TRIM(title)) > 0", name="title_not_blank"),
        CheckConstraint("CHAR_LENGTH(TRIM(body)) > 0", name="body_not_blank"),
        CheckConstraint(
            "(audience = 'district' AND district IS NOT NULL AND target_user_id IS NULL)"
            " OR (audience = 'client' AND target_user_id IS NOT NULL AND district IS NULL)"
            " OR (audience IN ('all', 'overdue') AND district IS NULL AND target_user_id IS NULL)",
            name="audience_is_complete",
        ),
        CheckConstraint(
            "(status = 'scheduled' AND scheduled_at IS NOT NULL AND sent_at IS NULL"
            " AND recipients IS NULL AND cancelled_at IS NULL)"
            " OR (status = 'sent' AND sent_at IS NOT NULL AND recipients IS NOT NULL"
            " AND cancelled_at IS NULL)"
            " OR (status = 'cancelled' AND cancelled_at IS NOT NULL AND sent_at IS NULL"
            " AND recipients IS NULL)",
            name="status_is_complete",
        ),
        CheckConstraint("recipients IS NULL OR recipients >= 0", name="recipients_not_negative"),
    )

    title: Mapped[str] = mapped_column(String(120))
    body: Mapped[str] = mapped_column(String(500))
    audience: Mapped[Audience] = mapped_column(enum_type(Audience, "audience"))
    district: Mapped[str | None] = mapped_column(String(80))
    target_user_id: Mapped[int | None] = mapped_column(foreign_key("users.id"))
    status: Mapped[AnnouncementStatus] = mapped_column(
        enum_type(AnnouncementStatus, "status"), index=True
    )
    scheduled_at: Mapped[datetime | None] = mapped_column(UTCDateTime())  # NULL : envoi immédiat
    sent_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    recipients: Mapped[int | None] = mapped_column(Integer)  # nombre de notifications créées
    cancelled_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    created_by: Mapped[int] = mapped_column(foreign_key("users.id"))


class AlertSettings(IdMixin, TimestampMixin, Base):
    """Interrupteurs GÉNÉRAUX des alertes automatiques (A9), pour toute la plateforme.

    Une seule ligne (scope = « global », unique) ; pas de ligne = tout activé. Couper une
    alerte n'arrête que les notifications : une facture échue passe quand même « en retard ».
    Les choix de chaque abonné (écran 14) s'appliquent en plus.
    """

    __tablename__ = "alert_settings"
    # MySQL refuse un CHECK sur la colonne auto-incrémentée : l'unicité passe par `scope`.
    __table_args__ = (
        UniqueConstraint("scope"),
        CheckConstraint("scope = 'global'", name="single_row"),
    )

    scope: Mapped[str] = mapped_column(String(16), default="global", server_default="global")
    due_soon: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    overdue: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    high_consumption: Mapped[bool] = mapped_column(Boolean, default=True, server_default=true())
    updated_by: Mapped[int | None] = mapped_column(foreign_key("users.id"))
