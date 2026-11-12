"""Facture au format PDF (B6.5), à partir du détail `BillDetail` (le même que l'écran 7).

Fonction pure : aucune base de données, aucune horloge (la date de génération est passée).
Mise en page reprise de la facture E²C (lignes, index, totaux), aux couleurs de la charte.
Le PDF n'est JAMAIS présenté comme une facture officielle : seule la facture E²C fait foi,
et un bandeau « Mode démo » s'affiche tant que les données sont simulées.

Polices : Helvetica intégrée au PDF (latin-1). Les quelques caractères hors latin-1
(tirets longs, apostrophes typographiques…) sont remplacés par leur équivalent simple.
"""

from datetime import date, datetime, timedelta
from decimal import Decimal

from fpdf import FPDF
from fpdf.enums import Align, XPos, YPos

from app.core.money import format_fcfa
from app.core.timezone import CONGO_TZ
from app.modules.bills.calculator import MILLI, WH_PER_KWH
from app.modules.bills.models import BillSource, BillStatus
from app.modules.bills.schemas import BillDetail, BillLinePublic

# Couleurs de la charte (frontend/design/tokens.json)
NAVY = (5, 13, 26)  # bg #050D1A
VOLT = (245, 166, 35)  # jaune #F5A623
CURRENT = (30, 136, 229)  # bleu #1E88E5
ERROR = (239, 68, 68)  # #EF4444
MUTED = (90, 98, 112)
RULE = (214, 218, 225)
SOFT = (246, 247, 249)

FONT = "Helvetica"
PAGE_WIDTH = 210
MARGIN = 15
CONTENT = PAGE_WIDTH - 2 * MARGIN  # 180 mm

_REPLACEMENTS = {
    "–": "-",
    "—": "-",
    "’": "'",
    "‘": "'",
    "“": '"',
    "”": '"',
    "…": "...",
    " ": " ",  # espace fine insécable
}

STATUS_LABELS = {
    BillStatus.UNPAID: "À payer",
    BillStatus.OVERDUE: "En retard",
    BillStatus.PENDING_PAYMENT: "Paiement en cours",
    BillStatus.PAID: "Payée",
    BillStatus.CANCELLED: "ANNULÉE",
}


TOTAL_LABELS = {BillStatus.PAID: "TOTAL PAYÉ", BillStatus.CANCELLED: "TOTAL ANNULÉ"}


def latin1(text: str) -> str:
    """Texte affichable par les polices intégrées du PDF (latin-1)."""
    for char, replacement in _REPLACEMENTS.items():
        text = text.replace(char, replacement)
    return text.encode("latin-1", "replace").decode("latin-1")


def fr_number(milli: int, *, max_decimals: int = 3) -> str:
    """Millièmes → nombre à la française, sans zéros inutiles : 571 000 → « 571 »,
    49 080 → « 49,08 », 14 854 482 → « 14 854,482 »."""
    value = Decimal(milli) / MILLI
    text = f"{value:,.{max_decimals}f}".rstrip("0").rstrip(".")
    return text.replace(",", " ").replace(".", ",")


def fr_percent(rate_bp: int) -> str:
    return fr_number(rate_bp * 10, max_decimals=2) + " %"  # 1 800 bp → « 18 % »


def kwh_text(wh: int) -> str:
    """Wh → « 14 854,482 kWh »."""
    return fr_number(wh * MILLI // WH_PER_KWH) + " kWh"  # Wh = millièmes de kWh


def local(instant: datetime) -> datetime:
    return instant.astimezone(CONGO_TZ)


def bill_filename(bill: BillDetail) -> str:
    return f"facture-{bill.reference}.pdf"


class _BillPdf(FPDF):
    def __init__(self, footer_text: str) -> None:
        super().__init__(orientation="portrait", unit="mm", format="A4")
        self.footer_text = footer_text
        self.set_margins(MARGIN, MARGIN, MARGIN)
        self.set_auto_page_break(auto=True, margin=22)

    def footer(self) -> None:
        self.set_y(-16)
        self.set_draw_color(*RULE)
        self.line(MARGIN, self.get_y(), PAGE_WIDTH - MARGIN, self.get_y())
        self.set_font(FONT, size=7.5)
        self.set_text_color(*MUTED)
        self.multi_cell(
            CONTENT - 20, 3.6, latin1(self.footer_text), new_x=XPos.RIGHT, new_y=YPos.TOP
        )
        self.cell(20, 3.6, f"Page {self.page_no()}/{{nb}}", align=Align.R)


def render_bill_pdf(bill: BillDetail, *, generated_at: datetime, demo_mode: bool) -> bytes:
    """Le PDF de la facture, en octets. `generated_at` : instant UTC de la génération."""
    generated = local(generated_at)
    pdf = _BillPdf(
        f"Généré par ElecPay le {generated:%d/%m/%Y à %H:%M} (heure de Brazzaville). "
        "Copie d'information : seule la facture E²C fait foi."
    )
    pdf.set_title(latin1(f"Facture {bill.reference}"))
    pdf.set_author("ElecPay")
    pdf.set_subject(latin1(f"Facture d'électricité {bill.period_label}"))
    pdf.set_creation_date(generated_at)
    pdf.add_page()
    if bill.status is BillStatus.CANCELLED:
        _watermark(pdf, "ANNULÉE")  # dessiné d'abord : le texte reste lisible par-dessus

    _header(pdf, bill)
    if demo_mode or bill.source is BillSource.SIMULATED:
        _banner(
            pdf,
            "MODE DÉMO - données simulées. Ce document n'est pas une facture E²C.",
            fill=VOLT,
            color=NAVY,
        )
    if bill.status is BillStatus.CANCELLED:
        cancelled = f" le {local(bill.cancelled_at):%d/%m/%Y}" if bill.cancelled_at else ""
        _banner(
            pdf,
            f"FACTURE ANNULÉE{cancelled}. Motif : {bill.cancelled_reason or '-'}",
            fill=ERROR,
            color=(255, 255, 255),
        )
    _parties(pdf, bill)
    _indexes(pdf, bill)
    _lines_table(pdf, bill.lines)
    _totals(pdf, bill)
    _notes(pdf, bill)
    return bytes(pdf.output())


# --- Blocs ----------------------------------------------------------------------------------


def _header(pdf: FPDF, bill: BillDetail) -> None:
    pdf.set_fill_color(*NAVY)
    pdf.rect(0, 0, PAGE_WIDTH, 30, style="F")
    pdf.set_xy(MARGIN, 9)
    pdf.set_font(FONT, "B", 22)
    pdf.set_text_color(*VOLT)
    pdf.cell(60, 10, "ElecPay")
    pdf.set_font(FONT, "B", 13)
    pdf.set_text_color(255, 255, 255)
    pdf.set_xy(MARGIN + 60, 8)
    pdf.cell(CONTENT - 60, 7, latin1("Facture d'électricité"), align=Align.R)
    pdf.set_font(FONT, size=10)
    pdf.set_xy(MARGIN + 60, 15)
    pdf.cell(CONTENT - 60, 6, latin1(f"{bill.period_label}  ·  N° {bill.reference}"), align=Align.R)
    pdf.set_y(36)


def _banner(pdf: FPDF, text: str, *, fill: tuple, color: tuple) -> None:
    pdf.set_fill_color(*fill)
    pdf.set_text_color(*color)
    pdf.set_font(FONT, "B", 9)
    pdf.multi_cell(CONTENT, 6, latin1(text), fill=True, align=Align.C, padding=(1.5, 3))
    pdf.ln(3)


def _section_title(pdf: FPDF, title: str, width: float) -> None:
    pdf.set_font(FONT, "B", 9)
    pdf.set_text_color(*CURRENT)
    pdf.cell(width, 6, latin1(title.upper()), new_x=XPos.LEFT, new_y=YPos.NEXT)


def _key_values(pdf: FPDF, x: float, width: float, rows: list[tuple[str, str]]) -> None:
    for label, value in rows:
        pdf.set_x(x)
        pdf.set_font(FONT, size=9)
        pdf.set_text_color(*MUTED)
        pdf.cell(width * 0.45, 5.2, latin1(label))
        pdf.set_font(FONT, "B", 9)
        pdf.set_text_color(*NAVY)
        pdf.cell(width * 0.55, 5.2, latin1(value), new_x=XPos.LMARGIN, new_y=YPos.NEXT)


def _parties(pdf: FPDF, bill: BillDetail) -> None:
    top, half = pdf.get_y(), CONTENT / 2 - 4
    power = bill.billed_power_va
    subscriber = [
        ("Foyer", bill.household_name),
        ("Compteur", bill.meter_label or "-"),
        ("N° Branchement", bill.meter_reference),
        ("N° Police", bill.meter_contract_number or "-"),
        ("N° Client", bill.meter_customer_number or "-"),
        ("Centre E²C", bill.e2c_center or "-"),
        ("Puissance facturée", f"{fr_number(power)} kVA" if power else "-"),
    ]
    status = STATUS_LABELS[bill.status]
    if bill.status is BillStatus.PAID and bill.paid_at:
        status = f"Payée le {local(bill.paid_at):%d/%m/%Y}"
    elif bill.status is BillStatus.OVERDUE and bill.days_overdue:
        status = f"En retard ({bill.days_overdue} j)"
    invoice = [
        ("N° de facture", bill.reference),
        ("Période", f"du {bill.period_start:%d/%m/%Y} au {bill.period_end:%d/%m/%Y}"),
        ("Durée", f"{bill.months_count} mois"),
        ("Émise le", f"{local(bill.issued_at):%d/%m/%Y}"),
        ("Échéance", f"{bill.due_date:%d/%m/%Y}"),
        ("Statut", status),
    ]
    pdf.set_xy(MARGIN, top)
    _section_title(pdf, "Abonné", half)
    _key_values(pdf, MARGIN, half, subscriber)
    left_bottom = pdf.get_y()
    pdf.set_xy(MARGIN + half + 8, top)
    _section_title(pdf, "Facture", half)
    _key_values(pdf, MARGIN + half + 8, half, invoice)
    pdf.set_y(max(left_bottom, pdf.get_y()) + 4)


def _indexes(pdf: FPDF, bill: BillDetail) -> None:
    _section_title(pdf, "Relevés du compteur", CONTENT)
    third = CONTENT / 3
    top = pdf.get_y()
    pdf.set_fill_color(*SOFT)
    pdf.rect(MARGIN, top, CONTENT, 15, style="F")
    cells = [
        (f"Ancien index ({bill.period_start:%d/%m/%Y})", kwh_text(bill.previous_index_wh)),
        (f"Nouvel index ({_day_after(bill):%d/%m/%Y})", kwh_text(bill.current_index_wh)),
        ("Consommation", kwh_text(bill.consumption_wh)),
    ]
    for position, (label, value) in enumerate(cells):
        x = MARGIN + position * third
        pdf.set_xy(x + 3, top + 2)
        pdf.set_font(FONT, size=8)
        pdf.set_text_color(*MUTED)
        pdf.cell(third - 6, 4.5, latin1(label))
        pdf.set_xy(x + 3, top + 7)
        pdf.set_font(FONT, "B", 11)
        pdf.set_text_color(*NAVY)
        pdf.cell(third - 6, 6, latin1(value))
    pdf.set_y(top + 15 + 5)


def _day_after(bill: BillDetail) -> date:
    """Le nouvel index est relevé à minuit au début du lendemain du dernier jour."""
    return bill.period_end + timedelta(days=1)


COLUMNS = (("Désignation", 64, Align.L), ("Quantité", 26, Align.R), ("Prix unitaire", 28, Align.R),
           ("Taux", 18, Align.R), ("Base", 22, Align.R), ("Montant", 22, Align.R))  # fmt: skip


def _lines_table(pdf: FPDF, lines: list[BillLinePublic]) -> None:
    _section_title(pdf, "Détail de la facture", CONTENT)
    pdf.set_fill_color(*NAVY)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font(FONT, "B", 8.5)
    pdf.c_margin = 2  # marge intérieure des cellules (mm)
    for title, width, align in COLUMNS:
        pdf.cell(width, 7, latin1(title), fill=True, align=align)
    pdf.ln()
    pdf.set_draw_color(*RULE)
    for line in lines:
        quantity = (
            f"{fr_number(line.quantity_milli)} {line.unit}"
            if line.quantity_milli is not None
            else ""
        )
        price = (
            fr_number(line.unit_price_milli, max_decimals=3)
            if line.unit_price_milli is not None
            else ""
        )
        values = (
            line.label,
            quantity,
            price,
            fr_percent(line.rate_bp) if line.rate_bp is not None else "",
            fr_number(line.base_amount * MILLI) if line.base_amount is not None else "",
            fr_number(line.amount * MILLI),
        )
        pdf.set_text_color(*NAVY)
        last = len(COLUMNS) - 1
        for column, ((_, width, align), value) in enumerate(zip(COLUMNS, values, strict=True)):
            pdf.set_font(FONT, "B" if column == last else "", 9)  # montant en gras
            pdf.cell(width, 7, latin1(value), border="B", align=align)
        pdf.ln()
    pdf.ln(3)


def _totals(pdf: FPDF, bill: BillDetail) -> None:
    label_width, value_width = 52, 34
    x = PAGE_WIDTH - MARGIN - label_width - value_width
    rows = (
        ("Total hors taxes", bill.amount_ht),
        ("TVA et centimes additionnels", bill.amount_tax),
        ("Redevances (RAV, timbre)", bill.amount_fees),
    )
    for label, amount in rows:
        pdf.set_x(x)
        pdf.set_font(FONT, size=9)
        pdf.set_text_color(*MUTED)
        pdf.cell(label_width, 6, latin1(label))
        pdf.set_text_color(*NAVY)
        pdf.cell(value_width, 6, latin1(format_fcfa(amount)), align=Align.R)
        pdf.ln()
    pdf.set_x(x)
    pdf.set_fill_color(*NAVY)
    pdf.set_text_color(*VOLT)
    pdf.set_font(FONT, "B", 11)
    pdf.cell(label_width, 9, latin1(TOTAL_LABELS.get(bill.status, "NET À PAYER")), fill=True)
    pdf.cell(value_width, 9, latin1(format_fcfa(bill.amount_total)), fill=True, align=Align.R)
    pdf.ln(13)


def _notes(pdf: FPDF, bill: BillDetail) -> None:
    notes = []
    previous = bill.previous_bill
    if previous is not None:
        change = (
            f" ({'+' if previous.consumption_change_wh >= 0 else ''}"
            f"{str(previous.consumption_change_percent).replace('.', ',')} % de consommation)"
            if previous.consumption_change_percent is not None
            else ""
        )
        notes.append(
            f"Facture précédente ({previous.period_label}) : "
            f"{kwh_text(previous.consumption_wh)}, {format_fcfa(previous.amount_total)}{change}."
        )
    tariff = bill.tariff
    notes.append(
        f"Tarif appliqué : {tariff.label} ({tariff.code}), "
        f"{fr_number(tariff.price_per_kwh_milli)} FCFA/kWh."
        + (" Valeurs à confirmer sur de vraies factures E²C." if tariff.is_assumption else "")
    )
    notes.append("Montants en FCFA, tronqués au franc à chaque ligne comme sur la facture E²C.")
    _section_title(pdf, "À savoir", CONTENT)
    pdf.set_font(FONT, size=8.5)
    pdf.set_text_color(*MUTED)
    for note in notes:
        pdf.multi_cell(CONTENT, 4.6, latin1("- " + note), new_x=XPos.LMARGIN, new_y=YPos.NEXT)


def _watermark(pdf: FPDF, text: str) -> None:
    pdf.set_font(FONT, "B", 70)
    pdf.set_text_color(250, 205, 205)
    with pdf.rotation(35, x=PAGE_WIDTH / 2, y=160):
        pdf.text(38, 175, latin1(text))
