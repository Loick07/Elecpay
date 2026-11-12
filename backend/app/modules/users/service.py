"""Service du compte : modification du profil. Ne connaît pas HTTP."""

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.request_context import RequestContext
from app.modules.audit.service import record
from app.modules.auth.errors import EmailAlreadyUsedError
from app.modules.users.models import User
from app.modules.users.schemas import UpdateProfileRequest

EDITABLE_FIELDS = ("full_name", "email")


class UserService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def update_profile(
        self, user: User, data: UpdateProfileRequest, context: RequestContext | None = None
    ) -> User:
        """Modifie le nom et/ou l'e-mail. Le téléphone (identifiant de connexion) ne se change
        pas ici : il faudra le vérifier par SMS."""
        changes = {
            field: getattr(data, field)
            for field in data.model_fields_set & set(EDITABLE_FIELDS)
            if getattr(data, field) != getattr(user, field)
        }
        if not changes:
            return user
        new_email = changes.get("email")
        if (
            new_email is not None
            and self.session.scalars(
                select(User.id).where(User.email == new_email, User.id != user.id)
            ).first()
        ):
            raise EmailAlreadyUsedError()

        before = {field: getattr(user, field) for field in changes}
        for field, value in changes.items():
            setattr(user, field, value)
        try:
            self.session.flush()
        except IntegrityError as error:  # e-mail pris entre-temps par quelqu'un d'autre
            self.session.rollback()
            raise EmailAlreadyUsedError() from error
        record(
            self.session,
            action="user.profile_update",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            context=context,
            before=before,
            after=changes,
        )
        self.session.commit()
        return user
