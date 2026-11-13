"""Émission des reçus (B8.1) : `issue_receipt` est l'UNIQUE endroit qui crée un reçu.

Il est appelé au seul endroit où un paiement devient réussi (`apply_provider_update`), dans la
même transaction SQL : un paiement confirmé a toujours son reçu, et inversement (la base refuse
un reçu pour un paiement qui n'est pas réussi). Le seed de démo crée les reçus de l'historique.

- numéro `EP-AAAA-NNNNNN` : séquence par année d'émission (heure de Brazzaville), qui continue
  après les numéros existants ; émissions simultanées mises en file par un verrou sur le dernier
  numéro de l'année (comme les numéros de facture) ;
- code de vérification : 12 caractères tirés avec `secrets` (imprévisibles), dans un alphabet
  sans caractères qu'on confond (ni 0/O, ni 1/I/L) ; affiché par groupes de 4 ;
- date d'émission = date de confirmation du paiement.
Idempotent : un deuxième appel pour la même transaction renvoie le reçu existant.
"""

import secrets

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timezone import local_date
from app.modules.payments.models import PaymentTransaction, TransactionStatus
from app.modules.receipts.models import VERIFICATION_CODE_LENGTH, Receipt

# Lettres et chiffres sans ambiguïté à la lecture ou à la saisie (pas de 0 O 1 I L).
VERIFICATION_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
MAX_SEQUENCE = 999_999
CODE_ATTEMPTS = 5  # nouveaux tirages si un code existe déjà (31¹² possibilités : improbable)


class ReceiptNumbersExhaustedError(RuntimeError):
    """Plus de 999 999 reçus dans l'année : à traiter avant que cela n'arrive."""


def new_verification_code() -> str:
    return "".join(
        secrets.choice(VERIFICATION_CODE_ALPHABET) for _ in range(VERIFICATION_CODE_LENGTH)
    )


def format_verification_code(code: str) -> str:
    """« 8F3K2Q9M7XHT » → « 8F3K-2Q9M-7XHT » (affichage)."""
    return "-".join(code[i : i + 4] for i in range(0, len(code), 4))


def normalize_verification_code(raw: str) -> str:
    """Ce que tape ou scanne quelqu'un → code stocké : sans tirets ni espaces, en majuscules."""
    return "".join(char for char in raw.upper() if char.isalnum())


def receipt_number(year: int, sequence: int) -> str:
    return f"EP-{year}-{sequence:06d}"


def issue_receipt(session: Session, transaction: PaymentTransaction) -> Receipt:
    """Le reçu du paiement réussi `transaction` (créé s'il n'existe pas). Pas de commit."""
    existing = session.scalars(
        select(Receipt).where(Receipt.transaction_id == transaction.id)
    ).first()
    if existing is not None:
        return existing
    if transaction.status is not TransactionStatus.SUCCEEDED or transaction.confirmed_at is None:
        raise ValueError("Un reçu n'existe que pour un paiement réussi")

    issued_at = transaction.confirmed_at
    receipt = Receipt(
        transaction_id=transaction.id,
        number=_next_number(session, local_date(issued_at).year),
        issued_at=issued_at,
        verification_code=_unused_code(session),
    )
    session.add(receipt)
    session.flush()
    return receipt


def _next_number(session: Session, year: int) -> str:
    """Numéro suivant de l'année, en verrouillant le dernier (lecture verrouillante)."""
    latest = session.scalars(
        select(Receipt.number)
        .where(Receipt.number.between(receipt_number(year, 1), receipt_number(year, MAX_SEQUENCE)))
        .order_by(Receipt.number.desc())
        .limit(1)
        .with_for_update()
    ).first()
    sequence = int(latest.rsplit("-", 1)[1]) + 1 if latest else 1
    if sequence > MAX_SEQUENCE:
        raise ReceiptNumbersExhaustedError(f"Plus de numéro de reçu disponible pour {year}")
    return receipt_number(year, sequence)


def _unused_code(session: Session) -> str:
    for _ in range(CODE_ATTEMPTS):
        code = new_verification_code()
        taken = session.scalar(select(Receipt.id).where(Receipt.verification_code == code))
        if taken is None:
            return code
    raise RuntimeError("Impossible de tirer un code de vérification libre")
