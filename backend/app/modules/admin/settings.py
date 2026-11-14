"""Paramètres et rôles du back-office (B10.9, maquette A11).

- Équipe (admin+ pour voir, super admin pour agir) : liste des membres ; inviter un membre
  (compte créé sans mot de passe utilisable : il le choisit lui-même avec un code reçu par
  SMS, que personne dans l'équipe ne voit) ; changer un rôle. Garde-fous : personne ne change
  son propre rôle ; il reste toujours au moins un super admin actif ; un compte client n'est
  jamais promu (un membre de l'équipe a son propre compte). Le rôle est relu en base à chaque
  requête : un changement prend effet immédiatement. Désactiver un membre : écran A3.
- Tarifs datés (toute l'équipe pour voir, super admin pour créer) : une nouvelle version d'un
  tarif EXISTANT, à partir de demain au plus tôt ; la version en cours se termine alors à cette
  date. Les factures déjà émises ne changent jamais (montants figés) ; le tarif d'une facture
  est celui en vigueur au premier jour de sa période.
- Intégrations (admin+) : état des simulateurs et des services branchés, sans aucun secret.
- 2FA : B11.
"""

import secrets
from collections.abc import Callable
from datetime import datetime

from fastapi import status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import AppError
from app.core.request_context import RequestContext
from app.core.security import hash_password
from app.core.timezone import local_date
from app.core.validation import mask_phone
from app.db.base import utcnow
from app.integrations.sms.base import SmsSender
from app.modules.admin.audit import STAFF_ROLES, record_admin_action
from app.modules.admin.settings_schemas import (
    Integration,
    IntegrationMode,
    IntegrationsStatus,
    RoleChange,
    TariffCreate,
    TariffRow,
    TeamInvite,
    TeamInvited,
    TeamMember,
)
from app.modules.auth.passwords import PasswordService
from app.modules.bills.models import Bill
from app.modules.tariffs.models import Tariff
from app.modules.users.models import User, UserRole

ROLE_LABELS = {
    UserRole.SUPPORT: "Support",
    UserRole.ADMIN: "Administrateur",
    UserRole.SUPER_ADMIN: "Super administrateur",
}


class TeamActionError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "TEAM_ACTION_REFUSED"
    message = "Action impossible sur ce membre de l'équipe."


class TeamMemberNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "TEAM_MEMBER_NOT_FOUND"
    message = "Membre de l'équipe introuvable."


class TariffRefusedError(AppError):
    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    code = "TARIFF_REFUSED"
    message = "Tarif refusé."


def invitation_sms(full_name: str, role: UserRole) -> str:
    return (
        f"ElecPay : bonjour {full_name}, vous êtes invité(e) dans l'équipe ElecPay "
        f"({ROLE_LABELS[role]}). Un code va suivre pour choisir votre mot de passe."
    )


class AdminSettings:
    def __init__(self, session: Session, now: Callable[[], datetime] = utcnow) -> None:
        self.session = session
        self.now = now

    # --- Équipe -------------------------------------------------------------------------------

    def team(self) -> list[TeamMember]:
        members = self.session.scalars(
            select(User)
            .where(User.role.in_(STAFF_ROLES))
            .order_by(User.is_active.desc(), User.full_name)
        ).all()
        return [self._member(member) for member in members]

    def invite(
        self,
        actor: User,
        data: TeamInvite,
        context: RequestContext,
        settings: Settings,
        sms: SmsSender,
    ) -> TeamInvited:
        role = UserRole(data.role.value)
        taken = self.session.scalars(
            select(User).where(
                or_(User.phone == data.phone, User.email == data.email)
                if data.email
                else User.phone == data.phone
            )
        ).first()
        if taken is not None:
            raise TeamActionError(
                "Ce numéro ou cet e-mail a déjà un compte ElecPay. Un membre de l'équipe "
                "utilise un compte à lui, distinct de tout compte client."
            )
        member = User(
            full_name=data.full_name,
            phone=data.phone,
            email=data.email,
            role=role,
            # Mot de passe aléatoire jamais communiqué : inutilisable, il sera remplacé.
            password_hash=hash_password(secrets.token_urlsafe(32)),
        )
        self.session.add(member)
        self.session.flush()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="team.invite",
            entity_type="user",
            entity_id=member.id,
            after={"role": role.value, "phone": mask_phone(member.phone)},
        )
        sms.send(member.phone, invitation_sms(member.full_name, role))
        # Code de choix du mot de passe : envoyé par SMS au membre, jamais renvoyé à l'équipe.
        PasswordService(self.session, settings, sms, self.now).request_reset(member.phone)
        self.session.commit()
        return TeamInvited(member=self._member(member), sms_sent_to=mask_phone(member.phone))

    def change_role(
        self, actor: User, member_id: int, data: RoleChange, context: RequestContext
    ) -> TeamMember:
        member = self.session.scalars(
            select(User).where(User.id == member_id).with_for_update()
        ).first()
        if member is None or member.role not in STAFF_ROLES:
            raise TeamMemberNotFoundError()
        if member.id == actor.id:
            raise TeamActionError("Vous ne pouvez pas changer votre propre rôle.")
        role = UserRole(data.role.value)
        if role is member.role:
            raise TeamActionError("Ce membre a déjà ce rôle.")
        if member.role is UserRole.SUPER_ADMIN and self._other_super_admins(member) == 0:
            raise TeamActionError("Il doit toujours rester au moins un super admin actif.")
        before = member.role
        member.role = role
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="team.role",
            entity_type="user",
            entity_id=member.id,
            before={"role": before.value},
            after={"role": role.value, "reason": data.reason},
        )
        self.session.commit()
        return self._member(member)

    # --- Tarifs -------------------------------------------------------------------------------

    def tariffs(self) -> list[TariffRow]:
        today = local_date(self.now())
        used = dict(
            self.session.execute(
                select(Bill.tariff_id, func.count()).group_by(Bill.tariff_id)
            ).all()
        )
        return [
            self._tariff(tariff, today, used.get(tariff.id, 0))
            for tariff in self.session.scalars(
                select(Tariff).order_by(Tariff.code, Tariff.valid_from.desc())
            )
        ]

    def create_tariff(
        self, actor: User, data: TariffCreate, context: RequestContext
    ) -> list[TariffRow]:
        today = local_date(self.now())
        if data.valid_from <= today:
            raise TariffRefusedError(
                "Un nouveau tarif démarre au plus tôt demain : les tarifs passés ne changent pas."
            )
        versions = self.session.scalars(
            select(Tariff)
            .where(Tariff.code == data.code)
            .order_by(Tariff.valid_from.desc())
            .with_for_update()
        ).all()
        if not versions:
            raise TariffRefusedError(
                "Code de tarif inconnu : seule une nouvelle version d'un tarif existant est "
                "possible (un compteur n'a pas encore de tarif propre)."
            )
        latest = versions[0]
        if data.valid_from <= latest.valid_from:
            raise TariffRefusedError(
                "La nouvelle version doit démarrer après la dernière "
                f"({latest.valid_from:%d/%m/%Y})."
            )
        closed = None
        if latest.valid_to is None or latest.valid_to > data.valid_from:
            closed = latest.valid_to
            latest.valid_to = data.valid_from  # d'abord fermer : jamais de chevauchement
            self.session.flush()
        tariff = Tariff(**data.model_dump())
        self.session.add(tariff)
        self.session.flush()
        record_admin_action(
            self.session,
            actor=actor,
            context=context,
            action="tariff.create",
            entity_type="tariff",
            entity_id=tariff.id,
            before={
                "previous_tariff_id": latest.id,
                "previous_valid_to": closed.isoformat() if closed else None,
            },
            # « code » est une clé refusée par le journal (codes secrets) : c'est ici le code
            # du tarif, noté sous un autre nom.
            after={"tariff_code": data.code} | data.model_dump(mode="json", exclude={"code"}),
        )
        self.session.commit()
        return self.tariffs()

    # --- Intégrations -------------------------------------------------------------------------

    @staticmethod
    def integrations(settings: Settings) -> IntegrationsStatus:
        payment_simulated = settings.payment_provider == "simulated"
        payment_mode = IntegrationMode.SIMULATED if payment_simulated else IntegrationMode.LIVE
        payment_detail = (
            "Simulateur ElecPay : aucun débit réel (scénarios par numéro de test)"
            if payment_simulated
            else "Branché"
        )
        billing_simulated = settings.billing_source == "simulated"
        return IntegrationsStatus(
            environment=settings.app_env,
            demo_mode=settings.demo_mode,
            integrations=[
                Integration(
                    key="mtn_momo", label="MTN MoMo", mode=payment_mode, detail=payment_detail
                ),
                Integration(
                    key="airtel_money",
                    label="Airtel Money",
                    mode=payment_mode,
                    detail=payment_detail,
                ),
                Integration(
                    key="e2c",
                    label="E²C (relevés et factures)",
                    mode=IntegrationMode.SIMULATED if billing_simulated else IntegrationMode.LIVE,
                    detail="Relevés et factures simulés (données de démonstration)"
                    if billing_simulated
                    else "Branché",
                ),
                Integration(
                    key="sms",
                    label="SMS",
                    mode=IntegrationMode.SIMULATED,
                    detail="Aucun SMS ne part : envoi seulement journalisé, numéro masqué",
                ),
                Integration(
                    key="push",
                    label="Notifications push",
                    mode=IntegrationMode.PHASE_2,
                    detail="Phase 2 (FCM) : notifications visibles dans l'application seulement",
                ),
            ],
            webhook_secret_configured=bool(settings.payment_webhook_secret.get_secret_value()),
            receipt_verify_url_is_https=settings.receipt_verify_url.startswith("https://"),
        )

    # --- Outils -------------------------------------------------------------------------------

    def _other_super_admins(self, member: User) -> int:
        return self.session.scalar(
            select(func.count())
            .select_from(User)
            .where(
                User.role == UserRole.SUPER_ADMIN,
                User.is_active.is_(True),
                User.id != member.id,
            )
        )

    @staticmethod
    def _member(member: User) -> TeamMember:
        return TeamMember(
            id=member.id,
            full_name=member.full_name,
            phone=member.phone,
            email=member.email,
            role=member.role,
            is_active=member.is_active,
            invited_at=member.created_at,
            last_login_at=member.last_login_at,
            invitation_pending=member.last_login_at is None,
            two_factor="not_available",
        )

    @staticmethod
    def _tariff(tariff: Tariff, today, bills: int) -> TariffRow:
        return TariffRow(
            id=tariff.id,
            code=tariff.code,
            label=tariff.label,
            price_per_kwh_milli=tariff.price_per_kwh_milli,
            fixed_fee_per_month=tariff.fixed_fee_per_month,
            vat_rate_bp=tariff.vat_rate_bp,
            additional_tax_rate_bp=tariff.additional_tax_rate_bp,
            audiovisual_fee=tariff.audiovisual_fee,
            stamp_fee=tariff.stamp_fee,
            valid_from=tariff.valid_from,
            valid_to=tariff.valid_to,
            is_assumption=tariff.is_assumption,
            source_note=tariff.source_note,
            in_force=tariff.valid_from <= today
            and (tariff.valid_to is None or today < tariff.valid_to),
            bills=bills,
        )
