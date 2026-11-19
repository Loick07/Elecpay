import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/features/bills/bills_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/openapi.dart';

/// Rend les espaces insécables visibles (« · »).
String visible(String s) => s.replaceAll('\u00A0', '·');

BillSummary bill(
  int id, {
  String status = BillStatuses.unpaid,
  String start = '2026-09-01',
  String end = '2026-10-31',
  int daysOverdue = 0,
  String? paidAt,
}) => BillSummary.fromJson({
  ...FakeHomeBackend.bill(id, household: 1, meter: 11, status: status),
  'period_start': start,
  'period_end': end,
  'consumption_kwh': 417.4,
  'days_overdue': daysOverdue,
  'paid_at': paidAt,
});

void main() {
  test('onglets dans l’ordre de la maquette, filtres du contrat', () {
    expect(BillsFilter.values.map((f) => f.label), ['Toutes', 'À payer', 'Payées', 'En retard']);
    final filters = OpenApi.load().enumValues('BillFilter');
    for (final f in BillsFilter.values) {
      if (f.status != null) expect(filters, contains(f.status), reason: f.label);
    }
  });

  test('groupes par PÉRIODE (maquette), dans l’ordre reçu', () {
    final groups = groupBillsByPeriod([
      bill(1),
      bill(2),
      bill(3, start: '2026-07-01', end: '2026-08-31'),
    ]);
    expect(groups.map((g) => g.title), ['Septembre – octobre 2026', 'Juillet – août 2026']);
    expect(groups.first.bills.map((b) => b.id), [1, 2]);
    expect(groupBillsByPeriod([]), isEmpty);
  });

  test('ligne secondaire selon le statut (maquette)', () {
    expect(visible(billRowSubtitle(bill(1))), '417,4·kWh · échéance le 18 nov.');
    expect(
      billRowSubtitle(bill(1, status: BillStatuses.paid, paidAt: '2026-09-10T09:00:00Z')),
      'Payée le 10 sept.',
    );
    expect(
      visible(billRowSubtitle(bill(1, status: BillStatuses.overdue, daysOverdue: 3))),
      '417,4·kWh · en retard de 3 jours',
    );
    expect(
      visible(billRowSubtitle(bill(1, status: BillStatuses.overdue, daysOverdue: 1))),
      '417,4·kWh · en retard de 1 jour',
    );
    expect(
      visible(billRowSubtitle(bill(1, status: BillStatuses.pendingPayment))),
      '417,4·kWh · paiement en cours',
    );
    expect(billRowSubtitle(bill(1, status: BillStatuses.cancelled)), 'Annulée');
  });

  test('reste à payer : titre et détail', () {
    expect(outstandingTitle(2), 'Reste à payer · 2 foyers');
    expect(outstandingTitle(1), 'Reste à payer');
    const two = Outstanding(amount: 57238, count: 2, overdueAmount: 0, overdueCount: 0);
    expect(outstandingDetail(two, firstDue: DateTime(2026, 11, 18)), '2 factures avant le 18 nov.');
    expect(outstandingDetail(two), '2 factures');
    const late = Outstanding(amount: 57238, count: 2, overdueAmount: 25818, overdueCount: 1);
    expect(outstandingDetail(late), '2 factures, dont 1 en retard');
    const none = Outstanding(amount: 0, count: 0, overdueAmount: 0, overdueCount: 0);
    expect(outstandingDetail(none), 'Tout est payé');
  });

  test('états vides : texte de la maquette pour « En retard »', () {
    expect(emptyBills(BillsFilter.overdue, 2), (
      title: 'Aucune facture en retard',
      message: 'Vos deux foyers sont à jour. Nous vous prévenons 5 jours avant chaque échéance.',
    ));
    expect(emptyBills(BillsFilter.toPay, 1).message, startsWith('Votre foyer est à jour.'));
    expect(emptyBills(BillsFilter.toPay, 3).message, startsWith('Vos 3 foyers sont à jour.'));
    expect(emptyBills(BillsFilter.all, 1).title, 'Aucune facture');
    expect(emptyBills(BillsFilter.paid, 1).title, 'Aucune facture payée');
  });

  group('lignes E²C (maquette de l’écran 7)', () {
    final detail = BillDetail.fromJson(FakeHomeBackend.billDetail(101));

    test('sous-textes des 6 lignes', () {
      expect(detail.lines.map(billLineDetail).map((s) => s == null ? null : visible(s)), [
        '417,4·kWh × 49,08·FCFA',
        '2·mois × 2·550·FCFA',
        '18·% du hors taxes',
        '5·% de la TVA',
        'Montant fixe, sans TVA',
        null,
      ]);
    });

    test('« Total hors taxes » après le droit à la consommation', () {
      expect(subtotalAfter(detail.lines), 1);
      expect(subtotalAfter([]), isNull);
    });

    test('la somme des lignes vaut le total (règle du backend)', () {
      expect(detail.lines.fold<int>(0, (s, l) => s + l.amount), detail.amountTotal);
    });

    test('chaque type de ligne du contrat a une règle (sinon : pas de sous-texte)', () {
      final kinds = OpenApi.load().enumValues('BillLineKind').toSet();
      expect(kinds, {
        BillLineKinds.energy,
        BillLineKinds.fixedFee,
        BillLineKinds.audiovisualFee,
        BillLineKinds.vat,
        BillLineKinds.additionalTax,
        BillLineKinds.stamp,
        BillLineKinds.other,
      });
    });
  });
}
