"""Registre de tous les modèles.

Alembic importe ce module pour que chaque table soit connue de `Base.metadata`
(sinon `--autogenerate` ne la verrait pas). Chaque nouveau module de modèles
doit être importé ici.
"""

from app.db.base import Base
from app.modules.audit.models import AuditLog
from app.modules.auth.models import PasswordResetCode, RefreshToken
from app.modules.bills.models import Bill, BillLine
from app.modules.consumption.models import MeterReading
from app.modules.households.models import Household, HouseholdMember
from app.modules.meters.models import Meter
from app.modules.notifications.models import Notification
from app.modules.payments.models import PaymentTransaction
from app.modules.receipts.models import Receipt
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User

__all__ = [
    "AuditLog",
    "Base",
    "Bill",
    "BillLine",
    "Household",
    "HouseholdMember",
    "Meter",
    "MeterReading",
    "Notification",
    "PasswordResetCode",
    "PaymentTransaction",
    "Receipt",
    "RefreshToken",
    "Tariff",
    "User",
]
