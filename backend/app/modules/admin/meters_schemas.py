"""Schémas de l'écran Compteurs du back-office (A4 : liste et panneau de détail).

Énergies en Wh entiers (jamais de float) ; l'affichage en kWh se fait côté écran.
"""

from datetime import date, datetime
from enum import StrEnum
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

from app.core.validation import clean_text
from app.modules.bills.models import BillStatus
from app.modules.consumption.models import AnomalyStatus
from app.modules.meters.models import MeterStatus


class TodayStatus(StrEnum):
    """État du compteur ce jour-là (heure de Brazzaville)."""

    RECEIVED = "received"  # relevé de minuit reçu, normal
    ANOMALY = "anomaly"  # relevé reçu mais en anomalie (index en baisse)
    MISSING = "missing"  # compteur actif et rattaché, mais aucun relevé ce matin
    INACTIVE = "inactive"  # compteur suspendu, résilié ou détaché : aucun relevé attendu


class MeterCounters(BaseModel):
    """Compteurs du haut de l'écran (filtres ignorés)."""

    attached: int = Field(description="Compteurs rattachés à un foyer")
    received_today: int = Field(description="Relevés reçus ce matin (anomalies comprises)")
    missing_today: int
    open_anomalies: int = Field(
        description="Anomalies pas encore traitées par l'équipe, des 30 derniers jours"
    )
    control_requested: int = Field(description="Relevés de contrôle demandés, en attente")
    inactive: int


class AdminMeterRow(BaseModel):
    id: int
    reference: str = Field(description="N° de branchement E²C")
    label: str | None
    customer_number: str | None
    e2c_center: str | None
    status: MeterStatus
    household_id: int | None = Field(description="NULL : compteur détaché")
    household_name: str | None
    district: str | None
    owner_name: str | None
    today_status: TodayStatus
    today_index_wh: int | None
    last_reading_at: datetime | None
    open_anomalies: int


class AdminMeterList(BaseModel):
    items: list[AdminMeterRow]
    total: int
    page: int
    size: int
    day: date = Field(description="Journée affichée (heure de Brazzaville)")
    counters: MeterCounters


class ReadingLine(BaseModel):
    id: int
    read_at: datetime
    index_wh: int
    consumption_wh: int = Field(description="Consommation depuis le relevé valide précédent")
    is_estimated: bool
    is_anomaly: bool
    anomaly_reason: str | None
    anomaly_status: AnomalyStatus | None


class AnomalyLine(BaseModel):
    reading_id: int
    read_at: datetime
    index_wh: int = Field(description="Index lu (en baisse)")
    previous_index_wh: int | None = Field(description="Dernier index valide avant ce relevé")
    reason: str
    status: AnomalyStatus | None = Field(description="NULL : à traiter")
    handled_by: str | None
    handled_at: datetime | None
    note: str | None


class HouseholdBrief(BaseModel):
    id: int
    name: str
    district: str | None
    city: str
    owner_id: int
    owner_name: str


class LastBill(BaseModel):
    id: int
    reference: str
    period_label: str
    amount_total: int = Field(description="FCFA")
    status: BillStatus = Field(description="Statut affiché (en retard si échéance dépassée)")
    due_date: date


class AdminMeterDetail(BaseModel):
    id: int
    reference: str
    label: str | None
    customer_number: str | None
    contract_number: str | None
    e2c_center: str | None
    subscribed_power_va: int | None
    status: MeterStatus
    installed_at: date | None
    household: HouseholdBrief | None = Field(description="NULL : compteur détaché")
    day: date
    today_status: TodayStatus
    yesterday: ReadingLine | None = Field(description="Relevé de la veille (minuit)")
    today: ReadingLine | None = Field(description="Relevé de ce matin (minuit)")
    explanation: str = Field(description="Phrase d'explication pour l'équipe")
    last_bill: LastBill | None
    anomalies: list[AnomalyLine] = Field(
        description="Anomalies non classées, plus récentes d'abord"
    )
    recent_readings: list[ReadingLine] = Field(description="14 derniers relevés")


Note = Annotated[str, AfterValidator(lambda raw: clean_text(raw, max_length=255, min_length=5))]


class ControlRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    note: Note | None = Field(default=None, examples=["Index à vérifier sur place"])


class DismissRequest(BaseModel):
    """Note obligatoire : pourquoi l'anomalie ne mérite pas de suite."""

    model_config = ConfigDict(extra="forbid")

    note: Note = Field(examples=["Erreur de lecture ponctuelle, relevé suivant normal"])


class AnomalyHandled(BaseModel):
    reading_id: int
    meter_id: int
    status: AnomalyStatus
    handled_at: datetime


class DetachRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    reason: Note = Field(examples=["Déménagement du titulaire"])


class AttachRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    household_id: int = Field(gt=0)
    reason: Note = Field(examples=["Compteur rattaché par erreur à un autre foyer"])


class MeterLink(BaseModel):
    meter_id: int
    household_id: int | None
    unpaid_bills: int = Field(
        description="Factures à payer de ce compteur (elles suivent le compteur)"
    )
