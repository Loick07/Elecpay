"""Routes du compte connecté (/me)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import ErrorResponse
from app.core.request_context import RequestContext, request_context
from app.db.session import get_db
from app.integrations.sms.base import SmsSender
from app.integrations.sms.factory import get_sms_sender
from app.modules.auth.dependencies import current_user
from app.modules.auth.passwords import PasswordService
from app.modules.auth.router import token_response
from app.modules.auth.schemas import ChangePasswordRequest, TokenResponse
from app.modules.users.models import User
from app.modules.users.schemas import UpdateProfileRequest, UserPublic
from app.modules.users.service import UserService

router = APIRouter(tags=["Mon compte"])

AUTH_ERRORS = {
    401: {"model": ErrorResponse, "description": "Jeton absent, expiré ou invalide"},
    403: {"model": ErrorResponse, "description": "Compte désactivé"},
}


@router.get("/me", response_model=UserPublic, summary="Mon profil", responses=AUTH_ERRORS)
def read_me(user: User = Depends(current_user)) -> User:
    return user


@router.patch(
    "/me",
    response_model=UserPublic,
    summary="Modifier mon nom ou mon e-mail",
    responses=AUTH_ERRORS | {409: {"model": ErrorResponse, "description": "E-mail déjà utilisé"}},
)
def update_me(
    data: UpdateProfileRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    context: RequestContext = Depends(request_context),
) -> User:
    return UserService(db).update_profile(user, data, context)


@router.post(
    "/me/password",
    response_model=TokenResponse,
    summary="Changer mon mot de passe",
    description="Les autres appareils sont déconnectés ; cet appareil reçoit de nouveaux jetons.",
    responses=AUTH_ERRORS
    | {400: {"model": ErrorResponse, "description": "Mot de passe actuel incorrect"}},
)
def change_my_password(
    data: ChangePasswordRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
    sms: SmsSender = Depends(get_sms_sender),
    context: RequestContext = Depends(request_context),
) -> TokenResponse:
    issued = PasswordService(db, settings, sms).change(
        user, data.current_password, data.new_password, context
    )
    return token_response(issued, settings)
