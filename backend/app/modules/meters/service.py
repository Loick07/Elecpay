"""Service des compteurs : lister, ajouter (vérifié chez E²C), consulter, renommer.

Ne connaît pas HTTP. Les caractéristiques d'un compteur (police, centre, puissance) viennent
TOUJOURS de la source E²C, jamais de la saisie de l'abonné.
"""

from collections.abc import Callable
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.core.timezone import local_date
from app.db.base import utcnow
from app.integrations.billing_sources.base import BillingSource
from app.integrations.consumption_sources.base import ConsumptionSource
from app.modules.audit.service import record
from app.modules.households.access import HouseholdAccess, household_access, meter_access
from app.modules.meters.errors import (
    E2CMeterNotFoundError,
    MeterAlreadyLinkedError,
    MeterLimitError,
)
from app.modules.meters.models import Meter, MeterStatus
from app.modules.meters.schemas import (
    HistoryImportPublic,
    MeterAddRequest,
    MeterAddResponse,
    MeterDetail,
    MeterUpdate,
)
from app.modules.users.models import User

MAX_METERS_PER_HOUSEHOLD = 5


def meter_detail(meter: Meter, access: HouseholdAccess) -> MeterDetail:
    return MeterDetail(
        id=meter.id,
        household_id=meter.household_id,
        reference=meter.reference,
        label=meter.label,
        type=meter.type,
        status=meter.status,
        contract_number=meter.contract_number,
        customer_number=meter.customer_number,
        e2c_center=meter.e2c_center,
        subscribed_power_va=meter.subscribed_power_va,
        installed_at=meter.installed_at,
        my_role=access.role,
        can_manage=access.can_manage,
        created_at=meter.created_at,
    )


class MeterService:
    def __init__(self, session: Session, today: Callable[[], date] | None = None) -> None:
        self.session = session
        self.today = today or (lambda: local_date(utcnow()))

    def list_for_household(self, user: User, household_id: int) -> list[MeterDetail]:
        access = household_access(self.session, user, household_id)
        meters = self.session.scalars(
            select(Meter).where(Meter.household_id == household_id).order_by(Meter.id)
        ).all()
        return [meter_detail(meter, access) for meter in meters]

    def add(
        self,
        user: User,
        household_id: int,
        data: MeterAddRequest,
        billing: BillingSource,
        consumption: ConsumptionSource,
        context: RequestContext | None = None,
    ) -> MeterAddResponse:
        access = household_access(self.session, user, household_id)
        access.require_manage()
        info = billing.lookup_meter(data.reference, data.customer_number)
        if info is None:
            raise E2CMeterNotFoundError()

        existing = self.session.scalars(
            select(Meter).where(Meter.reference == info.reference).with_for_update()
        ).first()
        if existing is not None and existing.household_id is not None:
            raise MeterAlreadyLinkedError()
        count = self.session.scalar(
            select(func.count()).select_from(Meter).where(Meter.household_id == household_id)
        )
        if count >= MAX_METERS_PER_HOUSEHOLD:
            raise MeterLimitError(f"Un foyer compte au plus {MAX_METERS_PER_HOUSEHOLD} compteurs.")

        if existing is None:
            meter = Meter(reference=info.reference)
            self.session.add(meter)
        else:  # compteur détaché par l'administration : on le rattache, son historique reste
            meter = existing
        meter.household_id = household_id
        meter.label = data.label
        meter.type = info.meter_type
        meter.status = MeterStatus.ACTIVE
        meter.contract_number = info.contract_number
        meter.customer_number = info.customer_number
        meter.e2c_center = info.e2c_center
        meter.subscribed_power_va = info.subscribed_power_va
        self.session.flush()

        if existing is None:
            imported = consumption.import_history(self.session, meter, today=self.today())
            history = HistoryImportPublic(
                readings=imported.readings, bills=imported.bills, source=imported.source
            )
        else:
            history = HistoryImportPublic(readings=0, bills=0, source="existing")
        record(
            self.session,
            action="meter.add",
            entity_type="meter",
            entity_id=meter.id,
            actor_id=user.id,
            context=context,
            after={
                "household_id": household_id,
                "reference": meter.reference,
                "reattached": existing is not None,
                "history_source": history.source,
            },
        )
        self.session.commit()
        return MeterAddResponse(meter=meter_detail(meter, access), history=history)

    def detail(self, user: User, meter_id: int) -> MeterDetail:
        meter, access = meter_access(self.session, user, meter_id)
        return meter_detail(meter, access)

    def rename(
        self, user: User, meter_id: int, data: MeterUpdate, context: RequestContext | None = None
    ) -> MeterDetail:
        meter, access = meter_access(self.session, user, meter_id)
        access.require_manage()
        if data.label != meter.label:
            record(
                self.session,
                action="meter.rename",
                entity_type="meter",
                entity_id=meter.id,
                actor_id=user.id,
                context=context,
                before={"label": meter.label},
                after={"label": data.label},
            )
            meter.label = data.label
            self.session.commit()
        return meter_detail(meter, access)
