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
from app.modules.bills.models import BillLineKind, BillSource, BillStatus
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


class ElecPayPdf(FPDF):
    """Page A4 d'un document ElecPay (facture, reçu) : marges et pied de page communs."""

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
    """Le PDF de la facture, en octets. `generated_at` : instant UTC de la génération.

    Mise en page dans le genre de la facture BT d'E²C (grille d'identification, grand tableau de
    consommation, totaux à droite, coupon détachable), mais SOUS LE NOM D'ELECPAY : jamais
    l'en-tête, le logo ni les mentions légales d'E²C (ce document n'est pas une facture officielle).
    """
    generated = local(generated_at)
    pdf = ElecPayPdf(
        f"Généré par ElecPay le {generated:%d/%m/%Y à %H:%M} (heure de Brazzaville). "
        "Copie d'information : seule la facture E²C fait foi."
    )
    pdf.set_title(latin1(f"Facture {bill.reference}"))
    pdf.set_author("ElecPay")
    pdf.set_subject(latin1(f"Facture d'électricité {bill.period_label}"))
    pdf.set_creation_date(generated_at)
    pdf.add_page()
    pdf.set_line_width(0.2)
    if bill.status is BillStatus.CANCELLED:
        _watermark(pdf, "ANNULÉE")  # dessiné d'abord : le texte reste lisible par-dessus

    _header(pdf)
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
    _identification(pdf, bill)
    _consumption_table(pdf, bill)
    _payment_and_totals(pdf, bill)
    _situation(pdf, bill)
    _coupon(pdf, bill)
    return bytes(pdf.output())


# --- Outils de grille -------------------------------------------------------------------------

HEAD_FILL = (232, 235, 240)  # cases d'intitulé grisées, comme sur la facture E²C
STARS = "*****"  # devant le montant à payer, comme sur la facture E²C (rien ne s'ajoute devant)


def _grid_row(
    pdf: FPDF,
    cells: list[tuple[str, float]],
    *,
    height: float,
    head: bool = False,
    size: float = 9.5,
    bold: bool = False,
    align: Align = Align.L,
) -> None:
    """Une rangée de cases encadrées, à partir de la marge gauche."""
    pdf.set_x(MARGIN)
    pdf.set_draw_color(*NAVY)
    pdf.set_fill_color(*HEAD_FILL)
    pdf.set_text_color(*(MUTED if head else NAVY))
    pdf.set_font(FONT, "B" if head or bold else "", 8 if head else size)
    for text, width in cells:
        pdf.cell(width, height, latin1(text), border=1, fill=head, align=Align.C if head else align)
    pdf.ln(height)


def _head_cell(pdf: FPDF, x: float, y: float, width: float, height: float, text: str) -> None:
    """Case d'intitulé sur une ou deux lignes, centrée (en-tête du tableau de consommation)."""
    pdf.set_draw_color(*NAVY)
    pdf.set_fill_color(*HEAD_FILL)
    pdf.rect(x, y, width, height, style="DF")
    pdf.set_font(FONT, "B", 6.6)
    pdf.set_text_color(*MUTED)
    lines = text.split("\n")
    line_height = 3.3
    top = y + (height - line_height * len(lines)) / 2
    for index, line in enumerate(lines):
        pdf.set_xy(x, top + index * line_height)
        pdf.cell(width, line_height, latin1(line), align=Align.C)


def _line(bill: BillDetail, kind: BillLineKind) -> BillLinePublic | None:
    return next((line for line in bill.lines if line.kind is kind), None)


def _amount(bill: BillDetail, kind: BillLineKind) -> str:
    line = _line(bill, kind)
    return fr_number(line.amount * MILLI) if line is not None else "0"


def _power(bill: BillDetail) -> str:
    return f"{fr_number(bill.billed_power_va)} kVA" if bill.billed_power_va else "-"


def _status_text(bill: BillDetail) -> str:
    if bill.status is BillStatus.PAID and bill.paid_at:
        return f"Payée le {local(bill.paid_at):%d/%m/%Y}"
    if bill.status is BillStatus.OVERDUE and bill.days_overdue:
        return f"En retard ({bill.days_overdue} j)"
    return STATUS_LABELS[bill.status]


# --- Blocs ----------------------------------------------------------------------------------


def _header(pdf: FPDF) -> None:
    """En-tête ElecPay (jamais celui d'E²C) et titre « FACTURE BT », comme sur la facture E²C."""
    top = 10
    pdf.set_xy(MARGIN, top)
    pdf.set_font(FONT, "B", 20)
    pdf.set_text_color(*NAVY)
    pdf.cell(pdf.get_string_width("Elec"), 9, "Elec")
    pdf.set_text_color(*VOLT)
    pdf.cell(pdf.get_string_width("Pay") + 1, 9, "Pay")
    pdf.set_xy(MARGIN, top + 9)
    pdf.set_font(FONT, size=7.5)
    pdf.set_text_color(*MUTED)
    pdf.cell(100, 4, latin1("Suivi et paiement des factures d'électricité E²C"))
    pdf.set_xy(MARGIN + 80, top)
    pdf.set_font(FONT, "B", 18)
    pdf.set_text_color(*NAVY)
    pdf.cell(CONTENT - 80, 9, "FACTURE BT", align=Align.R)
    pdf.set_xy(MARGIN + 80, top + 9)
    pdf.set_font(FONT, size=7.5)
    pdf.set_text_color(*MUTED)
    pdf.cell(
        CONTENT - 80, 4, latin1("Copie ElecPay · seule la facture E²C fait foi"), align=Align.R
    )
    pdf.set_draw_color(*NAVY)
    pdf.set_line_width(0.5)
    pdf.line(MARGIN, top + 16, PAGE_WIDTH - MARGIN, top + 16)
    pdf.set_line_width(0.2)
    pdf.set_y(top + 20)


IDENT = (36.0, 64.0, 44.0, 36.0)  # 180 mm


def _identification(pdf: FPDF, bill: BillDetail) -> None:
    """Grille du haut de la facture E²C : centre, point de livraison, période, branchement…"""
    a, b, c, d = IDENT
    delivery = bill.meter_label or "Compteur"
    _grid_row(
        pdf,
        [("Centre E²C de", a), ("Point de livraison", b), ("Période", c), ("N° Branchement", d)],
        height=5.5,
        head=True,
    )
    _grid_row(
        pdf,
        [
            ((bill.e2c_center or "-").upper(), a),
            (f"{delivery} · {bill.household_name}", b),
            (bill.period_label, c),
            (bill.meter_reference, d),
        ],
        height=7,
    )
    _grid_row(
        pdf,
        [("N° Client", a), ("Numéro facture", b), ("Référence abonné", c + d)],
        height=5.5,
        head=True,
    )
    _grid_row(
        pdf,
        [
            (bill.meter_customer_number or "-", a),
            (bill.reference, b),
            (bill.household_name, c + d),
        ],
        height=7,
    )
    _grid_row(
        pdf,
        [("Période de consommation", a + b), ("Émise le", c), ("Échéance", d)],
        height=5.5,
        head=True,
    )
    _grid_row(
        pdf,
        [
            (
                f"du {bill.period_start:%d/%m/%Y} au {bill.period_end:%d/%m/%Y} "
                f"({bill.months_count} mois)",
                a + b,
            ),
            (f"{local(bill.issued_at):%d/%m/%Y}", c),
            (f"{bill.due_date:%d/%m/%Y}", d),
        ],
        height=7,
    )
    pdf.ln(4)


# Grand tableau de la facture E²C : 10 colonnes, 180 mm.
CONSUMPTION_COLUMNS = (
    ("N° POLICE", 20.0),
    ("Index\nancien", 19.0),
    ("Index\nnouveau", 19.0),
    ("Consommation\nà facturer", 19.0),
    ("Puissance\nsouscrite", 17.0),
    ("Nbre\nmois", 11.0),
    ("Puissance\nfacturée", 17.0),
    ("Consommation\ntotale", 19.0),
    ("Prix\nunitaire", 16.0),
    ("Montant\nconsommation", 23.0),
)


def _consumption_table(pdf: FPDF, bill: BillDetail) -> None:
    top = pdf.get_y()
    x = MARGIN
    for title, width in CONSUMPTION_COLUMNS:
        _head_cell(pdf, x, top, width, 9, title)
        x += width
    energy = _line(bill, BillLineKind.ENERGY)
    kwh = fr_number(bill.consumption_wh)  # Wh = millièmes de kWh
    values = (
        bill.meter_contract_number or "-",
        fr_number(bill.previous_index_wh),
        fr_number(bill.current_index_wh),
        kwh,
        _power(bill),
        str(bill.months_count),
        _power(bill),
        kwh,
        fr_number(energy.unit_price_milli) if energy and energy.unit_price_milli else "-",
        fr_number(energy.amount * MILLI) if energy else "0",
    )
    pdf.set_xy(MARGIN, top + 9)
    pdf.set_draw_color(*NAVY)
    pdf.set_text_color(*NAVY)
    last = len(CONSUMPTION_COLUMNS) - 1
    for index, ((_, width), value) in enumerate(zip(CONSUMPTION_COLUMNS, values, strict=True)):
        pdf.set_font(FONT, "B" if index == last else "", 8.5)
        align = Align.L if index == 0 else Align.R
        pdf.cell(width, 8, latin1(value), border="LR", align=align)
    pdf.ln(8)
    # Zone basse du tableau (vide sur la facture E²C) : les index en clair, unités comprises.
    pdf.set_x(MARGIN)
    pdf.set_font(FONT, size=7.8)
    pdf.set_text_color(*MUTED)
    pdf.multi_cell(
        CONTENT,
        4.2,
        latin1(
            f"Ancien index : {kwh_text(bill.previous_index_wh)} (relevé le "
            f"{bill.period_start:%d/%m/%Y})  ·  Nouvel index : {kwh_text(bill.current_index_wh)} "
            f"(relevé le {_day_after(bill):%d/%m/%Y})  ·  Consommation : "
            f"{kwh_text(bill.consumption_wh)}. Prix unitaire en FCFA/kWh."
        ),
        border="LRB",
        align=Align.L,
        padding=(2, 2),
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )
    pdf.ln(4)


TOTALS_LABEL, TOTALS_VALUE = 44.0, 30.0  # bloc des totaux, à droite (74 mm)


def _payment_and_totals(pdf: FPDF, bill: BillDetail) -> None:
    top = pdf.get_y()
    left_width = CONTENT - TOTALS_LABEL - TOTALS_VALUE - 6
    # À gauche : la « référence de paiement » de la facture E²C, ici le paiement par ElecPay.
    pdf.set_xy(MARGIN, top)
    _boxed_title(pdf, "Référence de paiement de la facture", left_width)
    pdf.set_x(MARGIN)
    pdf.set_font(FONT, "B", 11)
    pdf.set_text_color(*NAVY)
    pdf.cell(left_width, 8, latin1(bill.reference), border="LR", align=Align.C)
    pdf.ln(8)
    pdf.set_x(MARGIN)
    pdf.set_font(FONT, size=8)
    pdf.set_text_color(*MUTED)
    pdf.multi_cell(
        left_width,
        4.2,
        latin1(
            "Payez par Mobile Money (MTN MoMo, Airtel Money) dans l'application ElecPay : "
            "le reçu est délivré dès la confirmation de l'opérateur."
        ),
        border="LRB",
        align=Align.L,
        padding=(1.5, 2),
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )
    pdf.ln(2)
    pdf.set_x(MARGIN)
    _boxed_title(pdf, "Statut de la facture", left_width)
    pdf.set_x(MARGIN)
    pdf.set_font(FONT, "B", 10)
    pdf.set_text_color(*(ERROR if bill.status is BillStatus.OVERDUE else NAVY))
    pdf.cell(left_width, 8, latin1(_status_text(bill)), border="LRB", align=Align.C)
    left_bottom = pdf.get_y() + 8

    # À droite : les totaux, dans l'ordre de la facture E²C.
    vat = _line(bill, BillLineKind.VAT)
    additional = _line(bill, BillLineKind.ADDITIONAL_TAX)
    rows = (
        ("Droit à la consommation", _amount(bill, BillLineKind.FIXED_FEE)),
        ("Total hors taxes", fr_number(bill.amount_ht * MILLI)),
        ("RAV (*)", _amount(bill, BillLineKind.AUDIOVISUAL_FEE)),
        (
            f"T.V.A. ({fr_percent(vat.rate_bp)})" if vat and vat.rate_bp else "T.V.A.",
            _amount(bill, BillLineKind.VAT),
        ),
        (
            f"C.A. ({fr_percent(additional.rate_bp)})"
            if additional and additional.rate_bp
            else "C.A.",
            _amount(bill, BillLineKind.ADDITIONAL_TAX),
        ),
        ("Timbre électronique", _amount(bill, BillLineKind.STAMP)),
    )
    x = PAGE_WIDTH - MARGIN - TOTALS_LABEL - TOTALS_VALUE
    y = top
    pdf.set_draw_color(*NAVY)
    for label, value in rows:
        pdf.set_xy(x, y)
        pdf.set_font(FONT, size=8.5)
        pdf.set_text_color(*MUTED)
        pdf.cell(TOTALS_LABEL, 6.5, latin1(label), border=1, align=Align.R)
        pdf.set_font(FONT, "B", 9)
        pdf.set_text_color(*NAVY)
        pdf.cell(TOTALS_VALUE, 6.5, latin1(value), border=1, align=Align.R)
        y += 6.5
    pdf.set_xy(x, y + 1.5)
    pdf.set_line_width(0.5)
    pdf.set_font(FONT, "B", 10)
    pdf.set_text_color(*NAVY)
    pdf.cell(TOTALS_LABEL, 10, latin1(TOTAL_LABELS.get(bill.status, "TOTAL À PAYER")), border=1)
    pdf.set_font(FONT, "B", 11)
    pdf.cell(TOTALS_VALUE, 10, latin1(f"{STARS}{fr_number(bill.amount_total * MILLI)}"),
             border=1, align=Align.R)  # fmt: skip
    pdf.set_line_width(0.2)
    pdf.set_xy(x, y + 12)
    pdf.set_font(FONT, size=7)
    pdf.set_text_color(*MUTED)
    pdf.cell(
        TOTALS_LABEL + TOTALS_VALUE,
        4,
        latin1(f"Soit {format_fcfa(bill.amount_total)}. (*) Redevance audiovisuelle."),
        align=Align.R,
    )
    pdf.set_y(max(left_bottom, y + 17) + 3)


def _boxed_title(pdf: FPDF, title: str, width: float) -> None:
    pdf.set_draw_color(*NAVY)
    pdf.set_fill_color(*HEAD_FILL)
    pdf.set_font(FONT, "B", 8)
    pdf.set_text_color(*MUTED)
    pdf.cell(width, 5.5, latin1(title), border=1, fill=True, align=Align.C)
    pdf.ln(5.5)


def _situation(pdf: FPDF, bill: BillDetail) -> None:
    """Bandeau « situation » de la facture E²C : ici la facture précédente et le tarif."""
    pdf.set_x(MARGIN)
    _boxed_title(pdf, latin1("Situation au ") + f"{bill.due_date:%d/%m/%Y}", CONTENT)
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
    else:
        notes.append("Première facture de ce compteur dans ElecPay.")
    tariff = bill.tariff
    notes.append(
        f"Tarif appliqué : {tariff.label} ({tariff.code}), "
        f"{fr_number(tariff.price_per_kwh_milli)} FCFA/kWh."
        + (" Valeurs à confirmer sur de vraies factures E²C." if tariff.is_assumption else "")
    )
    notes.append("Montants en FCFA, tronqués au franc à chaque ligne comme sur la facture E²C.")
    pdf.set_font(FONT, size=8)
    pdf.set_text_color(*NAVY)
    pdf.set_x(MARGIN)
    pdf.multi_cell(
        CONTENT,
        4.3,
        latin1("\n".join(f"- {note}" for note in notes)),
        border="LRB",
        align=Align.L,
        padding=(1.5, 2),
        new_x=XPos.LMARGIN,
        new_y=YPos.NEXT,
    )


COUPON_TOP = 226  # mm : le coupon reste en bas de page, comme sur la facture E²C
COUPON = (30.0, 32.0, 40.0, 46.0, 32.0)  # 180 mm


def _coupon(pdf: FPDF, bill: BillDetail) -> None:
    """Coupon détachable : les références de la facture et le montant, à garder avec le reçu."""
    top = max(COUPON_TOP, pdf.get_y() + 6)
    pdf.set_draw_color(*MUTED)
    pdf.set_dash_pattern(dash=1.5, gap=1.2)
    pdf.line(MARGIN, top, PAGE_WIDTH - MARGIN, top)
    pdf.set_dash_pattern()
    pdf.set_xy(MARGIN, top + 2)
    pdf.set_font(FONT, "B", 10)
    pdf.set_text_color(*NAVY)
    pdf.cell(60, 6, "ElecPay")
    pdf.set_font(FONT, "B", 10)
    pdf.cell(CONTENT - 60, 6, latin1("COUPON DÉTACHABLE FACTURE BT"), align=Align.R)
    pdf.set_y(top + 9)
    a, b, c, d, e = COUPON
    _grid_row(
        pdf,
        [("N° Client", a), ("N° Branchement", b), ("Numéro facture", c),
         ("Référence abonné", d), ("Période", e)],
        height=5.5,
        head=True,
    )  # fmt: skip
    _grid_row(
        pdf,
        [(bill.meter_customer_number or "-", a), (bill.meter_reference, b), (bill.reference, c),
         (bill.household_name, d), (bill.period_label, e)],
        height=7,
        size=9,
    )  # fmt: skip
    label = {BillStatus.PAID: "MONTANT PAYÉ", BillStatus.CANCELLED: "MONTANT ANNULÉ"}.get(
        bill.status, "MONTANT À PAYER"
    )
    pdf.set_x(MARGIN)
    pdf.set_font(FONT, size=8.5)
    pdf.set_text_color(*MUTED)
    pdf.cell(a + b + c, 9, latin1(f"Échéance : {bill.due_date:%d/%m/%Y}"), border=1)
    pdf.set_font(FONT, "B", 10)
    pdf.set_text_color(*NAVY)
    pdf.cell(d, 9, latin1(label), border=1, align=Align.C)
    pdf.set_font(FONT, "B", 11)
    pdf.cell(e, 9, latin1(f"{STARS}{fr_number(bill.amount_total * MILLI)}"), border=1,
             align=Align.R)  # fmt: skip
    pdf.ln(9)


def _day_after(bill: BillDetail) -> date:
    """Le nouvel index est relevé à minuit au début du lendemain du dernier jour."""
    return bill.period_end + timedelta(days=1)


def _banner(pdf: FPDF, text: str, *, fill: tuple, color: tuple) -> None:
    pdf.set_fill_color(*fill)
    pdf.set_text_color(*color)
    pdf.set_font(FONT, "B", 9)
    pdf.multi_cell(CONTENT, 6, latin1(text), fill=True, align=Align.C, padding=(1.5, 3))
    pdf.ln(3)


def _watermark(pdf: FPDF, text: str) -> None:
    pdf.set_font(FONT, "B", 70)
    pdf.set_text_color(250, 205, 205)
    with pdf.rotation(35, x=PAGE_WIDTH / 2, y=160):
        pdf.text(38, 175, latin1(text))
