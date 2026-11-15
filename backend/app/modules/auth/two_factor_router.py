"""Routes « Ma double authentification » (B11.3), réservées à l'équipe. Logique :
`TwoFactorService`. Volontairement HORS de `/admin` : un admin qui n'a pas encore activé sa
2FA (et à qui `/admin` répond 403) doit pouvoir l'activer."""

import segno
from fastapi import APIRouter, Depends, status
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.modules.auth.dependencies import require_role
from app.modules.auth.schemas import (
    BackupCodesResponse,
    TwoFactorCodeRequest,
    TwoFactorDisableRequest,
    TwoFactorSetupResponse,
    TwoFactorStatus,
)
from app.modules.auth.two_factor import TEAM_ROLES, TwoFactorService
from app.modules.users.models import User

router = APIRouter(prefix="/me/2fa", tags=["Double authentification (équipe)"])
team_member = require_role(*TEAM_ROLES)
CODE_ERRORS = {
    401: {"model": ErrorResponse, "description": "Code incorrect"},
    409: {"model": ErrorResponse, "description": "État incompatible (déjà active, pas active…)"},
}


def status_of(service: TwoFactorService, user: User) -> TwoFactorStatus:
    state = service.state(user)
    return TwoFactorStatus(
        enabled=state.enabled,
        pending_setup=state.pending_setup,
        required=state.required,
        enabled_at=state.enabled_at,
        backup_codes_left=state.backup_codes_left,
    )


@router.get("", response_model=TwoFactorStatus, summary="État de ma double authentification")
def my_two_factor(
    user: User = Depends(team_member),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> TwoFactorStatus:
    return status_of(TwoFactorService(db, settings), user)


@router.post(
    "/setup",
    response_model=TwoFactorSetupResponse,
    summary="Activer (1/2) : obtenir le QR code à scanner",
    description="Avec Google Authenticator, Microsoft Authenticator, Aegis… Rien n'est actif "
    "tant que le premier code n'a pas été confirmé (`/enable`). Recommencer remplace le QR code.",
    responses={409: CODE_ERRORS[409]},
)
def start_setup(
    user: User = Depends(team_member),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> TwoFactorSetupResponse:
    setup = TwoFactorService(db, settings).start_setup(user)
    qr_svg = segno.make(setup.otpauth_uri, error="m").svg_inline(scale=4, border=2)
    return TwoFactorSetupResponse(secret=setup.secret, otpauth_uri=setup.otpauth_uri, qr_svg=qr_svg)


@router.post(
    "/enable",
    response_model=BackupCodesResponse,
    summary="Activer (2/2) : confirmer avec un premier code",
    description="Renvoie 10 codes de secours, montrés UNE seule fois. Inscrit au journal.",
    responses=CODE_ERRORS,
)
def enable(
    data: TwoFactorCodeRequest,
    user: User = Depends(team_member),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> BackupCodesResponse:
    codes = TwoFactorService(db, settings).enable(user, data.code, context)
    return BackupCodesResponse(backup_codes=codes)


@router.post(
    "/backup-codes",
    response_model=BackupCodesResponse,
    summary="Nouveaux codes de secours (les anciens ne marchent plus)",
    responses=CODE_ERRORS,
)
def regenerate_backup_codes(
    data: TwoFactorCodeRequest,
    user: User = Depends(team_member),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> BackupCodesResponse:
    codes = TwoFactorService(db, settings).regenerate_backup_codes(user, data.code, context)
    return BackupCodesResponse(backup_codes=codes)


@router.post(
    "/disable",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Désactiver ma double authentification (support seulement)",
    description="Mot de passe + code. Impossible pour admin et super admin (obligatoire). "
    "Inscrit au journal.",
    responses=CODE_ERRORS
    | {403: {"model": ErrorResponse, "description": "Obligatoire pour mon rôle"}},
)
def disable(
    data: TwoFactorDisableRequest,
    user: User = Depends(team_member),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    context: RequestContext = Depends(request_context),
) -> Response:
    TwoFactorService(db, settings).disable(user, data.password, data.code, context)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
