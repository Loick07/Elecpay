"""Erreurs des foyers, membres et compteurs.

Règle de confidentialité : un foyer ou un compteur auquel on n'a pas accès répond 404
(« introuvable »), exactement comme s'il n'existait pas. On ne révèle jamais l'existence
du foyer d'un autre. Le 403 est réservé à un membre qui voit le foyer mais n'a pas le droit
d'y faire l'action demandée.
"""

from fastapi import status

from app.core.errors import AppError


class HouseholdNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "HOUSEHOLD_NOT_FOUND"
    message = "Foyer introuvable."


class MeterNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "METER_NOT_FOUND"
    message = "Compteur introuvable."


class HouseholdLimitError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "HOUSEHOLD_LIMIT_REACHED"
    message = "Nombre maximal de foyers atteint pour ce compte."


class HouseholdPermissionError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "HOUSEHOLD_FORBIDDEN"
    message = "Seul le propriétaire du foyer peut faire cette action."


# --- Membres et invitations -----------------------------------------------------------


class InviteeNotFoundError(AppError):
    """Numéro sans compte ElecPay actif (un compte désactivé répond pareil : rien n'est révélé)."""

    status_code = status.HTTP_404_NOT_FOUND
    code = "INVITEE_NOT_FOUND"
    message = "Ce numéro n'a pas encore de compte ElecPay : demandez-lui d'installer l'application."


class InvalidInviteeError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "INVALID_INVITEE"
    message = "Cette personne ne peut pas être invitée dans ce foyer."


class AlreadyMemberError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "ALREADY_MEMBER"
    message = "Cette personne est déjà membre du foyer ou a déjà une invitation en attente."


class MemberLimitError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "MEMBER_LIMIT_REACHED"
    message = "Nombre maximal de membres atteint pour ce foyer."


class MemberNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "MEMBER_NOT_FOUND"
    message = "Membre introuvable dans ce foyer."


class InvitationNotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "INVITATION_NOT_FOUND"
    message = "Invitation introuvable ou déjà traitée."


class OwnerCannotLeaveError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "OWNER_CANNOT_LEAVE"
    message = "Le propriétaire ne peut pas quitter son propre foyer."
