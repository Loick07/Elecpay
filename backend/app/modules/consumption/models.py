"""Table `meter_readings` : relevés d'index des compteurs (un par jour en simulation)."""

from datetime import datetime
from enum import StrEnum

from sqlalchemy import Boolean, CheckConstraint, String, UniqueConstraint, false
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin, UTCDateTime
from app.db.types import StrictBigInteger, enum_type, foreign_key, non_negative


class ReadingSource(StrEnum):
    SIMULATED = "simulated"  # généré par le simulateur (mode démo)
    MANUAL = "manual"  # saisi par un agent / un administrateur
    E2C = "e2c"  # reçu d'E²C (quand l'intégration existera)


class AnomalyStatus(StrEnum):
    """Traitement d'un relevé en anomalie par l'équipe (B10.4, maquette A4). NULL = ouverte."""

    CONTROL_REQUESTED = "control_requested"  # relevé de contrôle demandé (à E²C demain)
    DISMISSED = "dismissed"  # classée sans suite (le relevé reste exclu des factures)


class MeterReading(IdMixin, TimestampMixin, Base):
    """Un relevé : l'index du compteur à un instant donné.

    Énergie en Wh (entiers) : 571 kWh = 571 000 Wh. Jamais de float.
    `consumption_wh` = index − index du relevé précédent. Si l'index a baissé
    (impossible pour un vrai compteur), le relevé est gardé mais marqué en anomalie.
    """

    __tablename__ = "meter_readings"
    __table_args__ = (
        # Un seul relevé par compteur et par instant ; sert aussi d'index (meter_id, read_at).
        UniqueConstraint("meter_id", "read_at"),
        non_negative("index_wh"),
        non_negative("consumption_wh"),
        # Une anomalie a toujours un motif, et un motif n'existe que pour une anomalie.
        # « IS NOT NULL » est indispensable : sinon CHAR_LENGTH(NULL) donne NULL, et MySQL
        # considère qu'un CHECK qui vaut NULL est respecté.
        CheckConstraint(
            "(is_anomaly = 0 AND anomaly_reason IS NULL)"
            " OR (is_anomaly = 1 AND anomaly_reason IS NOT NULL"
            " AND CHAR_LENGTH(TRIM(anomaly_reason)) > 0)",
            name="anomaly_has_reason",
        ),
        # Un traitement n'existe que sur une anomalie, avec son auteur et sa date (B10.4).
        CheckConstraint(
            "anomaly_status IS NULL OR is_anomaly = 1", name="anomaly_status_needs_anomaly"
        ),
        CheckConstraint(
            "(anomaly_status IS NULL AND anomaly_handled_by IS NULL AND anomaly_handled_at IS NULL)"
            " OR (anomaly_status IS NOT NULL AND anomaly_handled_by IS NOT NULL"
            " AND anomaly_handled_at IS NOT NULL)",
            name="anomaly_handling_complete",
        ),
    )

    meter_id: Mapped[int] = mapped_column(foreign_key("meters.id"))
    read_at: Mapped[datetime] = mapped_column(UTCDateTime())
    index_wh: Mapped[int] = mapped_column(StrictBigInteger())
    consumption_wh: Mapped[int] = mapped_column(StrictBigInteger())
    source: Mapped[ReadingSource] = mapped_column(enum_type(ReadingSource, "source"))
    is_estimated: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
    is_anomaly: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
    anomaly_reason: Mapped[str | None] = mapped_column(String(255))
    # Traitement par l'équipe (B10.4). NULL = anomalie ouverte (ou pas d'anomalie).
    anomaly_status: Mapped[AnomalyStatus | None] = mapped_column(
        enum_type(AnomalyStatus, "anomaly_status")
    )
    anomaly_handled_by: Mapped[int | None] = mapped_column(foreign_key("users.id"))
    anomaly_handled_at: Mapped[datetime | None] = mapped_column(UTCDateTime())
    anomaly_note: Mapped[str | None] = mapped_column(String(255))
