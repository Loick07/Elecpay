"""Reçu au format PDF (B8.3), à partir de `ReceiptPublic` (le même que l'écran 10).

Fonction pure : aucune base de données, aucune horloge. Même style que la facture PDF.
Un QR code mène à la vérification publique du reçu (`RECEIPT_VERIFY_URL/<code>`) ; il est
dessiné en carrés vectoriels (net à toute taille, aucune image). Bandeau « Mode démo »
tant que le paiement est simulé : aucun débit réel n'a eu lieu.
"""

from datetime import datetime

import segno
from fpdf import FPDF
from fpdf.enums import Align, XPos, YPos

from app.core.money import format_fcfa
from app.modules.bills.pdf import (
    CONTENT,
    CURRENT,
    FONT,
    MARGIN,
    MUTED,
    NAVY,
    PAGE_WIDTH,
    SOFT,
    VOLT,
    ElecPayPdf,
    latin1,
    local,
)
from app.modules.receipts.schemas import ReceiptPublic
from app.modules.receipts.service import normalize_verification_code

SUCCESS = (34, 197, 94)  # #22C55E (charte)
QR_SIZE = 38  # mm


def verification_url(base_url: str, verification_code: str) -> str:
    """Adresse imprimée dans le QR code : base + code sans tirets (« …/verify/8F3K2Q9M7XHT »)."""
    return f"{base_url.rstrip('/')}/{normalize_verification_code(verification_code)}"


def receipt_filename(receipt: ReceiptPublic) -> str:
    return f"recu-{receipt.number}.pdf"


def render_receipt_pdf(
    receipt: ReceiptPublic, *, verify_base_url: str, generated_at: datetime, demo_mode: bool
) -> bytes:
    generated = local(generated_at)
    pdf = ElecPayPdf(
        f"Généré par ElecPay le {generated:%d/%m/%Y à %H:%M} (heure de Brazzaville). "
        "Ce reçu atteste le paiement de la facture indiquée."
    )
    pdf.set_title(latin1(f"Reçu {receipt.number}"))
    pdf.set_author("ElecPay")
    pdf.set_subject(latin1(f"Reçu de paiement {receipt.bill_period_label}"))
    pdf.set_creation_date(generated_at)
    pdf.add_page()

    _header(pdf, receipt)
    if demo_mode or receipt.source == "simulated":
        _banner(pdf, "MODE DÉMO - paiement simulé : aucun débit réel n'a eu lieu.")
    _amount(pdf, receipt)
    _details(pdf, receipt)
    _verification(pdf, receipt, verification_url(verify_base_url, receipt.verification_code))
    return bytes(pdf.output())


# --- Blocs ------------------------------------------------------------------------------------


def _header(pdf: FPDF, receipt: ReceiptPublic) -> None:
    pdf.set_fill_color(*NAVY)
    pdf.rect(0, 0, PAGE_WIDTH, 30, style="F")
    pdf.set_xy(MARGIN, 9)
    pdf.set_font(FONT, "B", 22)
    pdf.set_text_color(*VOLT)
    pdf.cell(60, 10, "ElecPay")
    pdf.set_font(FONT, "B", 13)
    pdf.set_text_color(255, 255, 255)
    pdf.set_xy(MARGIN + 60, 8)
    pdf.cell(CONTENT - 60, 7, latin1("Reçu de paiement"), align=Align.R)
    pdf.set_font(FONT, size=10)
    pdf.set_xy(MARGIN + 60, 15)
    pdf.cell(CONTENT - 60, 6, latin1(f"N° {receipt.number}"), align=Align.R)
    pdf.set_y(36)


def _banner(pdf: FPDF, text: str) -> None:
    pdf.set_fill_color(*VOLT)
    pdf.set_text_color(*NAVY)
    pdf.set_font(FONT, "B", 9)
    pdf.multi_cell(CONTENT, 6, latin1(text), fill=True, align=Align.C, padding=(1.5, 3))
    pdf.ln(4)


def _amount(pdf: FPDF, receipt: ReceiptPublic) -> None:
    pdf.set_font(FONT, "B", 12)
    pdf.set_text_color(*SUCCESS)
    pdf.cell(
        CONTENT, 7, latin1("Paiement réussi"), align=Align.C, new_x=XPos.LMARGIN, new_y=YPos.NEXT
    )
    pdf.set_font(FONT, size=9)
    pdf.set_text_color(*MUTED)
    pdf.cell(CONTENT, 5, latin1("Montant payé"), align=Align.C, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font(FONT, "B", 26)
    pdf.set_text_color(*NAVY)
    pdf.cell(
        CONTENT,
        13,
        latin1(format_fcfa(receipt.amount)),
        align=Align.C,
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )
    pdf.ln(4)


def _details(pdf: FPDF, receipt: ReceiptPublic) -> None:
    household = receipt.household_name or "-"
    rows = [
        ("Reçu", receipt.number),
        ("Date", f"{local(receipt.issued_at):%d/%m/%Y à %H:%M}"),
        ("Facture", f"{receipt.bill_period_label} · N° {receipt.bill_reference}"),
        ("Foyer", f"{household} · compteur {receipt.meter_reference}"),
        ("Payé par", receipt.payer_name),
        ("Moyen", f"{receipt.operator_label} · {receipt.phone_number}"),
        ("Transaction", receipt.transaction_reference),
    ]
    top = pdf.get_y()
    pdf.set_fill_color(*SOFT)
    pdf.rect(MARGIN, top, CONTENT, 7 * len(rows) + 4, style="F")
    pdf.set_y(top + 2)
    for label, value in rows:
        pdf.set_x(MARGIN + 4)
        pdf.set_font(FONT, size=9.5)
        pdf.set_text_color(*MUTED)
        pdf.cell(38, 7, latin1(label))
        pdf.set_font(FONT, "B", 9.5)
        pdf.set_text_color(*NAVY)
        pdf.cell(CONTENT - 46, 7, latin1(value), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_y(top + 7 * len(rows) + 10)


def _verification(pdf: FPDF, receipt: ReceiptPublic, url: str) -> None:
    top = pdf.get_y()
    _draw_qr(pdf, url, x=MARGIN, y=top, size=QR_SIZE)
    # Colonne de texte à droite du QR code : chaque ligne repart de `x` (après un texte sur
    # plusieurs lignes, fpdf2 revient sinon à la marge gauche… par-dessus le QR code).
    x = MARGIN + QR_SIZE + 8
    width = CONTENT - QR_SIZE - 8

    def line(text: str, height: float, *, font=(FONT, "", 9), color=MUTED) -> None:
        pdf.set_x(x)
        pdf.set_font(*font)
        pdf.set_text_color(*color)
        pdf.multi_cell(width, height, latin1(text), new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.set_y(top + 2)
    line("VÉRIFIER CE REÇU", 6, font=(FONT, "B", 9), color=CURRENT)
    line(
        "Scannez le QR code, ou saisissez le code ci-dessous sur la page de vérification "
        "ElecPay, pour confirmer que ce reçu est authentique.",
        4.8,
    )
    pdf.ln(1)
    line(receipt.verification_code, 9, font=("Courier", "B", 16), color=NAVY)
    line(url, 4, font=(FONT, "", 7.5))
    pdf.set_y(max(pdf.get_y(), top + QR_SIZE) + 4)


def _draw_qr(pdf: FPDF, data: str, *, x: float, y: float, size: float) -> None:
    """QR code (correction d'erreurs moyenne) en carrés pleins, avec sa marge blanche."""
    qr = segno.make(data, error="m", micro=False)
    rows = list(qr.matrix_iter(border=4))
    module = size / len(rows)
    pdf.set_fill_color(255, 255, 255)
    pdf.rect(x, y, size, size, style="F")
    pdf.set_fill_color(*NAVY)
    for row_index, row in enumerate(rows):
        for column_index, dark in enumerate(row):
            if dark:
                pdf.rect(x + column_index * module, y + row_index * module, module, module, "F")
