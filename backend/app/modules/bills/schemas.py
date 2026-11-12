"""Schémas d'API des factures (écrans client 6 « Mes factures » et 7 « Détail »).

Montants en FCFA entiers ; énergie en Wh (valeur exacte) et kWh à 3 décimales (affichage).
`status` est le statut AFFICHÉ : une facture impayée dont l'échéance est dépassée apparaît
« overdue » dès le lendemain de l'échéance, sans attendre le relevé quotidien.
"""

from datetime import date, datetime
from enum import StrEnum

from pydantic import BaseModel, Field

from app.core.pagination import Page
from app.modules.bills.models import BillLineKind, BillSource, BillStatus
from app.modules.households.access import HouseholdRole


class BillFilter(StrEnum):
    """Filtres de l'écran « Mes factures » (sans filtre : toutes, sauf les annulées)."""

    TO_PAY = "to_pay"  # À payer : impayées, en retard, paiement en cours
    OVERDUE = "overdue"  # En retard
    PAID = "paid"  # Payées
    PENDING_PAYMENT = "pending_payment"  # Paiement en cours
    CANCELLED = "cancelled"  # Annulées (seulement si on les demande)


class BillSummary(BaseModel):
    id: int
    reference: str = Field(examples=["20260903000001"])
    meter_id: int
    meter_reference: str = Field(description="N° Branchement")
    meter_label: str | None
    household_id: int
    household_name: str
    period_start: date
    period_end: date = Field(description="Dernier jour de la période (inclus)")
    period_label: str = Field(examples=["Juil.-Août 2026"])
    months_count: int
    consumption_wh: int
    consumption_kwh: float
    amount_total: int = Field(description="FCFA")
    issued_at: datetime
    due_date: date
    status: BillStatus = Field(description="Statut affiché (retard calculé à la lecture)")
    days_overdue: int = Field(description="Jours de retard (0 si la facture n'est pas en retard)")
    paid_at: datetime | None
    my_role: HouseholdRole
    can_pay: bool = Field(description="Bouton « Payer » : facture à payer et droit de payer")
    source: BillSource = Field(description="« simulated » en mode démo : données simulées")


class BillLinePublic(BaseModel):
    """Une ligne de la facture, avec de quoi refaire le calcul à la main.

    Valeurs exactes en entiers (`*_milli`, `rate_bp`) ; `quantity`, `unit_price` et
    `rate_percent` sont les mêmes valeurs prêtes à afficher. `amount` : FCFA, tronqué.
    """

    position: int
    kind: BillLineKind
    label: str = Field(examples=["Montant consommation"])
    quantity_milli: int | None = Field(description="Millièmes d'unité (571 kWh → 571 000)")
    quantity: float | None = Field(examples=[571.0])
    unit: str | None = Field(examples=["kWh"])
    unit_price_milli: int | None = Field(description="Millièmes de FCFA (49,08 → 49 080)")
    unit_price: float | None = Field(examples=[49.08])
    rate_bp: int | None = Field(description="Points de base (18 % → 1 800)")
    rate_percent: float | None = Field(examples=[18.0])
    base_amount: int | None = Field(description="Assiette du taux, FCFA")
    amount: int


class TariffPublic(BaseModel):
    id: int
    code: str
    label: str
    price_per_kwh_milli: int
    is_assumption: bool = Field(description="Valeurs pas encore vérifiées sur de vraies factures")


class PreviousBillComparison(BaseModel):
    """Comparaison avec la facture précédente du même compteur (non annulée)."""

    bill_id: int
    reference: str
    period_label: str
    consumption_wh: int
    consumption_kwh: float
    amount_total: int
    consumption_change_wh: int
    consumption_change_percent: float | None = Field(description="None si la précédente vaut 0")
    amount_change: int
    amount_change_percent: float | None


class BillDetail(BillSummary):
    """Écran 7 « Détail de la facture »."""

    meter_contract_number: str | None = Field(description="N° Police")
    meter_customer_number: str | None = Field(description="N° Client")
    e2c_center: str | None
    previous_index_wh: int
    current_index_wh: int
    previous_index_kwh: float
    current_index_kwh: float
    billed_power_va: int | None
    amount_ht: int
    amount_tax: int = Field(description="TVA + centimes additionnels")
    amount_fees: int = Field(description="RAV + timbre (hors TVA)")
    lines: list[BillLinePublic]
    tariff: TariffPublic
    previous_bill: PreviousBillComparison | None = Field(description="None : première facture")
    cancelled_at: datetime | None
    cancelled_reason: str | None


class Outstanding(BaseModel):
    """« Reste à payer » : impayées, en retard et en cours de paiement (filtres de statut
    et d'année ignorés ; filtres de foyer et de compteur appliqués)."""

    amount: int = Field(description="FCFA")
    count: int
    overdue_amount: int
    overdue_count: int


class BillList(Page[BillSummary]):
    outstanding: Outstanding
