"""Phrases lisibles pour le journal (« Activité récente de l'équipe », A1 ; journal, A10).

Chaque action d'écriture du back-office ajoute ici son libellé (B10.3 → B10.9). Une action
inconnue s'affiche par son code : rien ne disparaît du fil, même sans libellé.
"""

ACTION_LABELS: dict[str, str] = {
    # Back-office (complété sous-étape par sous-étape)
    "user.deactivate": "a désactivé un compte",
    "user.reactivate": "a réactivé un compte",
    "user.send_reset_code": "a envoyé un code de réinitialisation",
    "meter.anomaly_control": "a demandé un relevé de contrôle",
    "meter.anomaly_dismiss": "a classé une anomalie sans suite",
    "meter.attach": "a rattaché un compteur",
    "meter.detach": "a détaché un compteur",
    "bill.cancel": "a annulé une facture",
    "bill.reissue": "a réémis une facture",
    "payment.recheck": "a relancé la vérification d'une transaction",
    "dispute.open": "a ouvert un litige",
    "dispute.resolve": "a clos un litige",
    "announcement.create": "a créé une annonce",
    "announcement.cancel": "a annulé une annonce programmée",
    "announcement.sent": "annonce envoyée",
    "alerts.settings": "a changé les alertes automatiques",
    "team.invite": "a invité un membre de l'équipe",
    "team.role": "a changé un rôle",
    "tariff.create": "a créé un tarif",
    "admin.export": "a exporté des données",
    # Actions des abonnés et du système (journal A10)
    "user.profile_update": "a modifié son profil",
    "user.password_reset": "a réinitialisé son mot de passe",
    "user.password_change": "a changé son mot de passe",
    "household.create": "a créé un foyer",
    "household.update": "a modifié un foyer",
    "meter.add": "a ajouté un compteur",
    "meter.rename": "a renommé un compteur",
    "payment.initiate": "a lancé un paiement",
    "payment.succeeded": "paiement confirmé par l'opérateur",
    "payment.failed": "paiement refusé par l'opérateur",
    "payment.expired": "paiement expiré (code PIN non saisi)",
    "payment.amount_mismatch": "montant annoncé différent (à rapprocher)",
    "payment.provider_conflict": "réponse contradictoire de l'opérateur (à rapprocher)",
    "payment.bill_not_payable": "paiement reçu sur une facture annulée (à régulariser)",
    "demo.seed": "a créé les données de démonstration",
}


def action_label(action: str) -> str:
    return ACTION_LABELS.get(action, action)
