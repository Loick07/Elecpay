import '../../core/format/formats.dart';
import '../../core/models/bills.dart';

// Règles des écrans 6 et 7, sans réseau ni affichage : testées une à une
// (test/features/bills/bills_rules_test.dart). Guide : backend/docs/FACTURES.md.

/// Onglets de « Mes factures », dans l'ordre de la maquette.
enum BillsFilter {
  all('Toutes', null),
  toPay('À payer', BillFilters.toPay),
  paid('Payées', BillFilters.paid),
  overdue('En retard', BillFilters.overdue);

  const BillsFilter(this.label, this.status);

  final String label;

  /// Paramètre `status` de `GET /bills` (`null` : toutes sauf les annulées).
  final String? status;
}

/// Un groupe de la liste : une PÉRIODE de facturation (maquette : « Septembre – octobre 2026 »,
/// guide FACTURES.md : grouper par `period_start`).
typedef BillGroup = ({String title, List<BillSummary> bills});

/// Factures groupées par période, dans l'ordre reçu (l'API trie la période la plus récente d'abord).
List<BillGroup> groupBillsByPeriod(Iterable<BillSummary> bills) {
  final groups = <BillGroup>[];
  DateTime? currentStart;
  DateTime? currentEnd;
  for (final bill in bills) {
    if (bill.periodStart != currentStart || bill.periodEnd != currentEnd) {
      currentStart = bill.periodStart;
      currentEnd = bill.periodEnd;
      groups.add((title: formatBillPeriodGroup(bill.periodStart, bill.periodEnd), bills: []));
    }
    groups.last.bills.add(bill);
  }
  return groups;
}

/// Ligne secondaire d'une facture (maquette) : « 417,4 kWh · échéance le 18 nov. », « Payée le
/// 10 sept. », « 417,4 kWh · en retard de 3 jours », « Annulée ».
String billRowSubtitle(BillSummary bill) => switch (bill.status) {
  BillStatuses.paid when bill.paidAt != null =>
    'Payée le ${formatDayMonth(toBrazzaville(bill.paidAt!))}',
  BillStatuses.paid => 'Payée',
  BillStatuses.cancelled => 'Annulée',
  BillStatuses.overdue =>
    '${formatKwh(bill.consumptionKwh)} · en retard de ${bill.daysOverdue} '
        'jour${bill.daysOverdue > 1 ? 's' : ''}',
  BillStatuses.pendingPayment => '${formatKwh(bill.consumptionKwh)} · paiement en cours',
  _ => '${formatKwh(bill.consumptionKwh)} · échéance le ${formatDayMonth(bill.dueDate)}',
};

/// Titre de la carte « Reste à payer » : « Reste à payer · 2 foyers » (un seul foyer : sans).
String outstandingTitle(int householdCount) =>
    householdCount > 1 ? 'Reste à payer · $householdCount foyers' : 'Reste à payer';

/// Côté droit de la carte « Reste à payer » : « 2 factures avant le 18 nov. », « dont 1 en
/// retard », ou « Tout est payé ». `firstDue` : échéance la plus proche des factures à payer.
String outstandingDetail(Outstanding o, {DateTime? firstDue}) {
  if (o.count == 0) return 'Tout est payé';
  final bills = '${o.count} facture${o.count > 1 ? 's' : ''}';
  if (o.overdueCount > 0) return '$bills, dont ${o.overdueCount} en retard';
  return firstDue == null ? bills : '$bills avant le ${formatDayMonth(firstDue)}';
}

/// État vide d'un onglet (titre, phrase). Maquette : « Aucune facture en retard » / « Vos deux
/// foyers sont à jour. Nous vous prévenons 5 jours avant chaque échéance. »
({String title, String message}) emptyBills(BillsFilter filter, int householdCount) {
  final upToDate = switch (householdCount) {
    0 || 1 => 'Votre foyer est à jour.',
    2 => 'Vos deux foyers sont à jour.',
    _ => 'Vos $householdCount foyers sont à jour.',
  };
  const warned = 'Nous vous prévenons 5 jours avant chaque échéance.';
  return switch (filter) {
    BillsFilter.all => (
      title: 'Aucune facture',
      message: 'Vos factures E²C apparaîtront ici dès leur émission.',
    ),
    BillsFilter.toPay => (title: 'Rien à payer', message: '$upToDate $warned'),
    BillsFilter.paid => (
      title: 'Aucune facture payée',
      message: 'Vos factures payées apparaîtront ici, avec leur reçu.',
    ),
    BillsFilter.overdue => (title: 'Aucune facture en retard', message: '$upToDate $warned'),
  };
}

/// Sous-texte d'une ligne du détail (maquette de l'écran 7), selon la ligne E²C :
/// « 417,4 kWh × 49,08 FCFA », « 2 mois × 2 550 FCFA », « 18 % du hors taxes », « 5 % de la TVA »,
/// « Montant fixe, sans TVA ». `null` : rien sous le libellé.
String? billLineDetail(BillLinePublic line) {
  String? quantityTimesPrice() {
    final quantity = line.quantity;
    final price = line.unitPrice;
    if (quantity == null || price == null) return null;
    final unit = line.unit;
    final q = unit == null || unit.isEmpty
        ? formatDecimal(quantity, maxDecimals: 3)
        : (unit == 'kWh'
              ? formatKwh(quantity)
              : '${formatDecimal(quantity, maxDecimals: 3)}$unitSpace$unit');
    return '$q × ${formatDecimal(price)}${unitSpace}FCFA';
  }

  return switch (line.kind) {
    BillLineKinds.energy || BillLineKinds.fixedFee => quantityTimesPrice(),
    BillLineKinds.vat when line.ratePercent != null =>
      '${formatPercent(line.ratePercent!)} du hors taxes',
    BillLineKinds.additionalTax when line.ratePercent != null =>
      '${formatPercent(line.ratePercent!)} de la TVA',
    BillLineKinds.audiovisualFee => 'Montant fixe, sans TVA',
    _ => null,
  };
}

/// Après quelle ligne insérer « Total hors taxes » (maquette : après le droit à la consommation,
/// avant la TVA) : l'indice de la dernière ligne hors taxes, ou `null` s'il n'y en a pas.
int? subtotalAfter(List<BillLinePublic> lines) {
  int? last;
  for (final (i, line) in lines.indexed) {
    if (line.kind == BillLineKinds.energy || line.kind == BillLineKinds.fixedFee) last = i;
  }
  return last;
}
