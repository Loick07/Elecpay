"""Récapitulatif de paiement par e-mail (B11.4), reçu PDF joint.

`enqueue_receipt_emails` est appelé au succès d'un paiement, dans la MÊME transaction SQL (par
`apply_provider_update`, juste après le reçu) : il ne fait qu'ajouter des lignes à la file, il ne
contacte aucun service. Le paiement ne dépend donc jamais de l'e-mail.

Destinataires (choix validés par Loick) : la personne qui a payé, et AUSSI le titulaire du foyer
quand c'est un payeur délégué qui paie. Seulement si l'adresse est VÉRIFIÉE, le compte actif et
l'interrupteur « Recevoir mes reçus par e-mail » allumé.

`send_pending_emails` (commande `scripts.send_emails`, toutes les minutes) construit chaque
message à l'envoi (reçu PDF généré à ce moment-là) et retente en cas de panne : 1 min, 5 min,
15 min, 1 h, 3 h, puis abandon (statut `failed` ; à montrer aux admins en B11.5).
"""

from collections import Counter
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.money import format_fcfa
from app.core.validation import mask_email
from app.integrations.email.base import Attachment, EmailMessage, EmailSender, EmailSendError
from app.modules.bills.models import Bill
from app.modules.bills.pdf import local
from app.modules.emails.models import EmailKind, EmailStatus, OutboxEmail
from app.modules.households.models import Household
from app.modules.meters.models import Meter
from app.modules.notifications.service import preferences_of
from app.modules.payments.models import PaymentTransaction
from app.modules.receipts.models import Receipt
from app.modules.receipts.pdf import receipt_filename, render_receipt_pdf, verification_url
from app.modules.receipts.queries import receipt_public
from app.modules.users.models import User

RETRY_DELAYS = (
    timedelta(minutes=1),
    timedelta(minutes=5),
    timedelta(minutes=15),
    timedelta(hours=1),
    timedelta(hours=3),
)
MAX_ATTEMPTS = len(RETRY_DELAYS) + 1


def _owner_id(session: Session, bill: Bill) -> int | None:
    return session.scalar(
        select(Household.owner_id)
        .join(Meter, Meter.household_id == Household.id)
        .where(Meter.id == bill.meter_id)
    )


def enqueue_receipt_emails(
    session: Session, transaction: PaymentTransaction, bill: Bill, receipt: Receipt, *, now
) -> int:
    """Met en file le récapitulatif pour le payeur et le titulaire. Pas de commit."""
    candidates = [transaction.payer_id]
    owner_id = _owner_id(session, bill)
    if owner_id is not None and owner_id != transaction.payer_id:
        candidates.append(owner_id)
    preferences = preferences_of(session, candidates)
    queued = 0
    for user in session.scalars(select(User).where(User.id.in_(candidates))):
        wanted = (
            user.is_active
            and user.email
            and user.email_verified_at is not None
            and preferences[user.id]["email_receipts"]
        )
        if not wanted:
            continue
        session.add(
            OutboxEmail(
                user_id=user.id,
                to_email=user.email,
                kind=EmailKind.PAYMENT_RECEIPT,
                receipt_id=receipt.id,
                status=EmailStatus.PENDING,
                next_attempt_at=now,
            )
        )
        queued += 1
    session.flush()
    return queued


def receipt_email(
    session: Session, row: OutboxEmail, settings: Settings, *, now: datetime
) -> EmailMessage:
    """Le message tel qu'il part : texte + reçu PDF joint (généré maintenant)."""
    recipient = session.get(User, row.user_id)
    receipt = receipt_public(session, session.get(Receipt, row.receipt_id), recipient)
    paid_at = local(receipt.issued_at)
    demo = settings.demo_mode or receipt.source == "simulated"
    check_url = verification_url(settings.receipt_verify_url, receipt.verification_code)
    place = f" ({receipt.household_name})" if receipt.household_name else ""
    if receipt.is_mine:
        opening = "Votre paiement a bien été reçu. Merci !"
    else:
        opening = (
            f"{receipt.payer_name} a payé la facture de votre foyer"
            f"{f' « {receipt.household_name} »' if receipt.household_name else ''}."
        )
    lines = [
        f"Bonjour {recipient.full_name},",
        "",
        opening,
        "",
    ]
    if demo:
        lines += ["MODE DÉMO : paiement simulé, aucun débit réel n'a eu lieu.", ""]
    lines += [
        f"Montant : {format_fcfa(receipt.amount)}",
        f"Date : {paid_at:%d/%m/%Y à %H:%M} (heure de Brazzaville)",
        f"Facture : {receipt.bill_period_label}, compteur {receipt.meter_reference}{place}",
        f"Payé par : {receipt.payer_name}, {receipt.operator_label} {receipt.phone_number}",
        f"Reçu n° {receipt.number}, code de vérification {receipt.verification_code}",
        f"Vérifier ce reçu : {check_url}",
        "",
        "Le reçu PDF est joint à ce message.",
        "",
        "Vous recevez cet e-mail car « Recevoir mes reçus par e-mail » est activé dans "
        "l'application ElecPay (Compte > Notifications).",
        "",
        "L'équipe ElecPay",
    ]
    pdf = render_receipt_pdf(
        receipt,
        verify_base_url=settings.receipt_verify_url,
        generated_at=now,
        demo_mode=settings.demo_mode,
    )
    return EmailMessage(
        to=row.to_email,
        subject=(
            f"{'[DÉMO] ' if demo else ''}Paiement reçu : {format_fcfa(receipt.amount)}, "
            f"facture {receipt.bill_period_label}"
        ),
        text="\n".join(lines),
        attachments=(Attachment(receipt_filename(receipt), "application/pdf", pdf),),
    )


def send_pending_emails(
    session: Session, sender: EmailSender, settings: Settings, *, now: datetime, limit: int = 100
) -> Counter:
    """Envoie les e-mails dont l'heure est venue, un par un (commit chacun). `SKIP LOCKED` :
    deux exécutions simultanées ne prennent jamais le même e-mail."""
    counts: Counter = Counter()
    for _ in range(limit):
        row = session.scalars(
            select(OutboxEmail)
            .where(OutboxEmail.status == EmailStatus.PENDING, OutboxEmail.next_attempt_at <= now)
            .order_by(OutboxEmail.next_attempt_at, OutboxEmail.id)
            .limit(1)
            .with_for_update(skip_locked=True)
        ).first()
        if row is None:
            break
        row.attempts += 1
        try:
            sender.send(receipt_email(session, row, settings, now=now))
        except EmailSendError:
            if row.attempts >= MAX_ATTEMPTS:
                row.status = EmailStatus.FAILED
                counts["failed"] += 1
            else:
                row.next_attempt_at = now + RETRY_DELAYS[row.attempts - 1]
                counts["retry"] += 1
            row.last_error = (
                f"Envoi impossible vers {mask_email(row.to_email)} (essai {row.attempts})"
            )
        else:
            row.status = EmailStatus.SENT
            row.sent_at = now
            row.last_error = None
            counts["sent"] += 1
        session.commit()
    return counts
