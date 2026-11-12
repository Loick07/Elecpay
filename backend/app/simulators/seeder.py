"""Remplit une base VIDE avec les données de démonstration (utilisé par `scripts.seed`).

Assemble les simulateurs : relevés (B2.2) → factures (B2.3) → paiements (B2.4) → base.
Respecte le cycle de vie imposé par les triggers (B1) : chaque transaction est insérée
« en attente » puis passe à son statut final ; les reçus suivent les paiements réussis.

Déterministe : même date du jour + même graine → exactement la même base.
Ne valide pas la transaction (pas de commit) : c'est à l'appelant de le faire.
"""

from collections import Counter
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, timedelta
from typing import Any

from sqlalchemy import func, insert, select
from sqlalchemy.orm import Session

from app.core.calendar import add_months
from app.core.money import format_fcfa
from app.core.security import hash_password
from app.core.timezone import local_midnight_utc
from app.modules.audit.models import AuditLog
from app.modules.bills.models import Bill, BillStatus
from app.modules.bills.notifications import bill_issued_notification, bill_overdue_notification
from app.modules.bills.periods import BillingSettings
from app.modules.bills.service import generate_bill
from app.modules.households.models import Household, HouseholdMember, MemberRole, MemberStatus
from app.modules.meters.models import Meter
from app.modules.notifications.models import NotificationType
from app.modules.notifications.service import insert_notifications, notification_row
from app.modules.payments.models import PaymentProvider, PaymentTransaction, TransactionStatus
from app.modules.receipts.models import Receipt
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User
from app.simulators.bills import generate_bills
from app.simulators.demo_dataset import CLIENTS, DEMO_PASSWORD, E2C_CENTERS, TEAM, DemoPerson
from app.simulators.payments import BillOutcome, Payer, SimulatedAttempt, simulate_payments
from app.simulators.persistence import anomaly_notification, insert_readings
from app.simulators.readings import PROFILES, generate_readings

HISTORY_MONTHS = 18
DEFAULT_SEED = 2026
RECENT_EVENTS = timedelta(days=45)  # échecs et anomalies récents → notifications


class SeedError(RuntimeError):
    """Le remplissage est impossible (base non vide, configuration invalide…)."""


@dataclass
class SeedReport:
    first_day: date
    last_day: date
    counts: Counter = field(default_factory=Counter)
    accounts: list[tuple[str, str, str]] = field(default_factory=list)  # (rôle, nom, téléphone)
    seconds: float = 0.0


def history_start(today: date, period_months: int, months_back: int = HISTORY_MONTHS) -> date:
    """Début d'une période de facturation située au moins `months_back` mois avant `today`."""
    current_start = date(today.year, (today.month - 1) // period_months * period_months + 1, 1)
    periods_back = -(-months_back // period_months)  # arrondi au supérieur
    return add_months(current_start, -periods_back * period_months)


def meter_seed(seed: int, meter_number: int) -> int:
    return seed * 1_000 + meter_number


class _Seeder:
    def __init__(self, session: Session, today: date, settings: BillingSettings, seed: int):
        self.session = session
        self.today = today
        self.settings = settings
        self.seed = seed
        self.now = local_midnight_utc(today)  # l'histoire s'arrête à minuit ce matin
        self.first_day = history_start(today, settings.billing_period_months)
        self.report = SeedReport(self.first_day, today - timedelta(days=1))
        self.users: dict[str, User] = {}
        self.successes: list[tuple[SimulatedAttempt, PaymentTransaction]] = []
        self.notifications: list[dict[str, Any]] = []

    # --- Étapes ---------------------------------------------------------------------

    def run(self) -> SeedReport:
        if self.session.scalar(select(func.count()).select_from(User)):
            raise SeedError("La base n'est pas vide : lancez d'abord `python -m scripts.reset_db`.")
        self.tariff = self._tariff()
        for person in (*TEAM, *CLIENTS):
            self._user(person)
        meter_number = 0
        for person in CLIENTS:
            for demo_household in person.households:
                household = self._household(person, demo_household)
                delegate = self._members(household, demo_household)
                for demo_meter in demo_household.meters:
                    meter_number += 1
                    self._meter_history(person, household, demo_meter, delegate, meter_number)
        self._receipts()
        self._announcement()
        self.report.counts["notifications"] += insert_notifications(
            self.session, self.notifications
        )
        self._audit()
        return self.report

    def _tariff(self) -> Tariff:
        tariff = Tariff(
            code="BT_DOMESTIQUE",
            label="Basse tension domestique (hypothèse, à vérifier)",
            price_per_kwh_milli=49_080,
            fixed_fee_per_month=2_550,
            vat_rate_bp=1_800,
            additional_tax_rate_bp=500,
            audiovisual_fee=1_000,
            stamp_fee=0,
            valid_from=self.first_day,
            is_assumption=True,
            source_note="Facture E²C BT juillet-août 2026 ; voir docs/FACTURE_E2C.md",
        )
        self.session.add(tariff)
        self.session.flush()
        self.report.counts["tariffs"] += 1
        return tariff

    def _user(self, person: DemoPerson) -> None:
        user = User(
            phone=person.phone,
            full_name=person.full_name,
            email=person.email,
            password_hash=hash_password(DEMO_PASSWORD),
            role=person.role,
            last_login_at=self.now - timedelta(days=1 + len(self.users) % 9, hours=3),
        )
        self.session.add(user)
        self.session.flush()
        self.users[person.key] = user
        self.report.counts["users"] += 1
        self.report.accounts.append((person.role.value, person.full_name, person.phone))

    def _household(self, person: DemoPerson, demo) -> Household:
        household = Household(
            name=demo.name,
            district=demo.district,
            city=demo.city,
            address=demo.address,
            owner_id=self.users[person.key].id,
        )
        self.session.add(household)
        self.session.flush()
        self.report.counts["households"] += 1
        return household

    def _members(self, household: Household, demo) -> Payer | None:
        delegate = None
        for member_key, role in demo.members:
            member = self.users[member_key]
            self.session.add(
                HouseholdMember(
                    household_id=household.id,
                    user_id=member.id,
                    role=role,
                    status=MemberStatus.ACTIVE,
                    invited_by=household.owner_id,
                )
            )
            self.report.counts["members"] += 1
            role_label = "payeur délégué" if role is MemberRole.PAYER else "lecteur"
            self.notifications.append(
                notification_row(
                    member.id,
                    NotificationType.INVITATION_RECEIVED,
                    "Invitation acceptée",
                    f"Vous êtes {role_label} du foyer « {household.name} ».",
                    {"household_id": household.id},
                    at=local_midnight_utc(self.first_day) + timedelta(hours=10),
                    read=True,
                )
            )
            if role is MemberRole.PAYER and delegate is None:
                delegate = Payer(member_key, member.phone)
        self.session.flush()
        return delegate

    def _meter_history(self, person, household, demo_meter, delegate, number) -> None:
        owner = self.users[person.key]
        meter = Meter(
            household_id=household.id,
            reference=demo_meter.reference,
            label=demo_meter.label,
            contract_number=demo_meter.contract_number,
            customer_number=demo_meter.customer_number,
            e2c_center=E2C_CENTERS[household.city],
            subscribed_power_va=demo_meter.power_va,
            installed_at=date(2015 + number % 9, 1 + number % 12, 1 + number % 27),
        )
        self.session.add(meter)
        self.session.flush()
        self.report.counts["meters"] += 1

        readings = generate_readings(
            PROFILES[demo_meter.profile],
            self.first_day,
            self.report.last_day,
            start_index_wh=1_500_000 + number * 1_234_567,
            seed=meter_seed(self.seed, number),
        )
        self.report.counts["readings"] += insert_readings(self.session, meter.id, readings)
        for reading in readings:
            if reading.is_anomaly and reading.read_at >= self.now - RECENT_EVENTS:
                self.notifications.append(
                    anomaly_notification(owner.id, meter.id, meter.reference, reading.read_at)
                )

        bills = generate_bills(
            readings,
            self.tariff,
            period_months=self.settings.billing_period_months,
            issue_delay_days=self.settings.bill_issue_delay_days,
            due_delay_days=self.settings.bill_due_delay_days,
            as_of=self.today,
            billed_power_va=demo_meter.power_va,
        )
        stories = simulate_payments(
            bills,
            owner=Payer(person.key, owner.phone),
            delegate=delegate,
            as_of=self.now,
            seed=meter_seed(self.seed, number),
        )
        for story in stories:
            self._bill_with_payments(meter, owner, story)

    def _bill_with_payments(self, meter: Meter, owner: User, story) -> None:
        # La facture est émise par le service unique ; le scénario de paiement a été écrit
        # à partir du simulateur : les deux doivent tomber d'accord au franc près.
        bill = generate_bill(
            self.session,
            meter,
            story.bill.period_start,
            today=self.today,
            settings=self.settings,
        ).bill
        if bill.amount_total != story.bill.computation.amount_total:
            raise SeedError(
                f"Facture {bill.reference} : {bill.amount_total} FCFA émis, "
                f"{story.bill.computation.amount_total} FCFA attendus par le scénario"
            )
        self.report.counts["bill_lines"] += len(story.bill.computation.lines)

        for attempt in story.attempts:
            self._transaction(bill, attempt)

        if story.outcome is BillOutcome.PAID:
            bill.status, bill.paid_at = BillStatus.PAID, story.paid_at
        elif story.outcome is BillOutcome.OVERDUE:
            bill.status = BillStatus.OVERDUE
            self.notifications.append(bill_overdue_notification(owner.id, bill))
        else:
            self.notifications.append(bill_issued_notification(owner.id, bill))
        self.session.flush()
        self.report.counts[f"bills_{bill.status.value}"] += 1

    def _transaction(self, bill: Bill, attempt: SimulatedAttempt) -> None:
        payer = self.users[attempt.payer_key]
        transaction = PaymentTransaction(
            bill_id=bill.id,
            payer_id=payer.id,
            provider=PaymentProvider.SIMULATED,
            phone_number=attempt.phone_number,
            amount=attempt.amount,
            idempotency_key=attempt.idempotency_key,
            initiated_at=attempt.initiated_at,
            expires_at=attempt.expires_at,
            created_at=attempt.initiated_at,
            updated_at=attempt.initiated_at,
        )
        self.session.add(transaction)
        self.session.flush()  # naît « en attente », comme une vraie transaction
        transaction.status = attempt.status
        transaction.confirmed_at = attempt.confirmed_at
        transaction.provider_ref = attempt.provider_ref
        transaction.failure_reason = attempt.failure_reason
        self.session.flush()
        self.report.counts[f"transactions_{attempt.status.value}"] += 1

        if attempt.status is TransactionStatus.SUCCEEDED:
            self.successes.append((attempt, transaction))
        elif attempt.finished_at >= self.now - RECENT_EVENTS:
            self.notifications.append(
                notification_row(
                    payer.id,
                    NotificationType.PAYMENT_FAILED,
                    "Paiement non abouti",
                    f"Le paiement de {format_fcfa(attempt.amount)} n'a pas abouti : "
                    f"{attempt.failure_reason}. Vous pouvez réessayer.",
                    {"bill_id": bill.id, "transaction_id": transaction.id},
                    at=attempt.finished_at,
                )
            )

    def _receipts(self) -> None:
        """Reçus numérotés dans l'ordre chronologique, par année : EP-2026-000001…"""
        chronological = sorted(self.successes, key=lambda item: item[0].confirmed_at)
        per_year: Counter = Counter()
        rows = []
        for attempt, transaction in chronological:
            confirmed = attempt.confirmed_at
            per_year[confirmed.year] += 1
            rows.append(
                {
                    "transaction_id": transaction.id,
                    "number": f"EP-{confirmed.year}-{per_year[confirmed.year]:06d}",
                    "issued_at": confirmed,
                    "verification_code": attempt.receipt_verification_code,
                }
            )
        if rows:
            self.session.execute(insert(Receipt), rows)
        self.report.counts["receipts"] += len(rows)
        for attempt, transaction in chronological[-20:]:
            self.notifications.append(
                notification_row(
                    self.users[attempt.payer_key].id,
                    NotificationType.PAYMENT_SUCCEEDED,
                    "Paiement réussi",
                    f"Paiement de {format_fcfa(attempt.amount)} confirmé. Reçu disponible.",
                    {"bill_id": transaction.bill_id, "transaction_id": transaction.id},
                    at=attempt.confirmed_at,
                    read=True,
                )
            )

    def _announcement(self) -> None:
        for person in CLIENTS:
            self.notifications.append(
                notification_row(
                    self.users[person.key].id,
                    NotificationType.ANNOUNCEMENT,
                    "Bienvenue sur ElecPay",
                    "Vous utilisez la version de démonstration : consommations, factures et "
                    "paiements sont simulés.",
                    None,
                    at=self.now - timedelta(days=2, hours=-9),
                )
            )

    def _audit(self) -> None:
        self.session.add(
            AuditLog(
                actor_id=None,
                action="demo.seed",
                entity_type="database",
                after_json=dict(sorted(self.report.counts.items())),
                created_at=datetime.now(UTC),
            )
        )
        self.session.flush()


def seed_demo(
    session: Session, *, today: date, settings: BillingSettings, seed: int = DEFAULT_SEED
) -> SeedReport:
    """Remplit une base vide. Lève `SeedError` si la base contient déjà des utilisateurs."""
    return _Seeder(session, today, settings, seed).run()
