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
    )

    meter_id: Mapped[int] = mapped_column(foreign_key("meters.id"))
    read_at: Mapped[datetime] = mapped_column(UTCDateTime())
    index_wh: Mapped[int] = mapped_column(StrictBigInteger())
    consumption_wh: Mapped[int] = mapped_column(StrictBigInteger())
    source: Mapped[ReadingSource] = mapped_column(enum_type(ReadingSource, "source"))
    is_estimated: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
    is_anomaly: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
    anomaly_reason: Mapped[str | None] = mapped_column(String(255))
