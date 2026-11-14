"""Schémas du tableau de bord du back-office (A1, `GET /admin/stats`). Montants : FCFA entiers."""

from datetime import date, datetime

from pydantic import BaseModel, Field

from app.modules.bills.models import BillStatus
from app.modules.users.models import UserRole


class Collected(BaseModel):
    """« Encaissé en novembre » : paiements réussis confirmés depuis le 1er du mois."""

    amount: int
    payments: int
    previous_month_same_point: int = Field(
        description="Encaissé le mois précédent, du 1er au même moment (même durée écoulée)"
    )
    change_percent: float | None = Field(description="None si rien le mois précédent")


class UnpaidBills(BaseModel):
    """« Factures impayées » : à payer, en retard ou en cours de paiement."""

    count: int
    amount: int
    overdue_count: int


class FailureRate(BaseModel):
    """« Paiements non aboutis (7 jours) » : échoués + expirés / paiements terminés."""

    rate_percent: float | None = Field(description="None si aucun paiement terminé")
    finished: int
    not_completed: int
    previous_rate_percent: float | None = Field(description="Les 7 jours d'avant")
    change_points: float | None


class PendingTransactions(BaseModel):
    count: int
    older_than_10_minutes: int


class DailyCollection(BaseModel):
    day: date
    amount: int
    payments: int


class Collections30Days(BaseModel):
    total: int
    payments: int
    days: list[DailyCollection] = Field(description="30 journées, la plus ancienne d'abord")


class StatusCount(BaseModel):
    status: BillStatus
    count: int
    percent: float


class LatestBills(BaseModel):
    """« Factures d'octobre par statut » : la dernière période facturée."""

    period_start: date | None
    period_label: str | None = Field(examples=["Sept.-Oct. 2026"])
    issued: int
    issued_on: date | None
    by_status: list[StatusCount]


class WatchItem(BaseModel):
    """Un point « À surveiller », avec de quoi ouvrir le bon écran."""

    kind: str = Field(
        description="stuck_payment, repeated_failures, reading_anomalies, long_overdue"
    )
    title: str
    detail: str
    entity_type: str | None = Field(examples=["payment_transaction", "user", "meter", "bill"])
    entity_id: int | None


class TeamActivity(BaseModel):
    at: datetime
    actor_id: int
    actor_name: str
    actor_role: UserRole
    action: str
    label: str = Field(examples=["a annulé une facture"])
    entity_type: str
    entity_id: int | None


class AdminStats(BaseModel):
    generated_at: datetime
    demo: bool = Field(description="Données simulées (mode démo)")
    month_label: str = Field(examples=["Novembre 2026"])
    collected_this_month: Collected
    unpaid_bills: UnpaidBills
    failure_rate_7_days: FailureRate
    pending_transactions: PendingTransactions
    collections_30_days: Collections30Days
    latest_bills: LatestBills
    watchlist: list[WatchItem]
    team_activity: list[TeamActivity]
