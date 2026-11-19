import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/core/models/payments.dart';
import 'package:elecpay/features/home/home_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/openapi.dart';

final api = OpenApi.load();

BillSummary bill(
  int id, {
  String status = BillStatuses.unpaid,
  DateTime? due,
  int household = 1,
  String householdName = 'Maison Mpita',
  int meter = 10,
  bool canPay = true,
  DateTime? issued,
}) => BillSummary.fromJson(api.sample('BillSummary')).copyWith(
  id: id,
  status: status,
  dueDate: due ?? DateTime(2026, 11, 18),
  periodStart: DateTime(2026, 9),
  householdId: household,
  householdName: householdName,
  meterId: meter,
  canPay: canPay,
  issuedAt: issued ?? DateTime.utc(2026, 11, 3),
);

HouseholdSummary household(int id, [String name = 'Foyer']) =>
    HouseholdSummary.fromJson(api.sample('HouseholdSummary')).copyWith(id: id, name: name);

MeterDetail meter(int id, {String status = 'active'}) =>
    MeterDetail.fromJson(api.sample('MeterDetail')).copyWith(id: id, status: status);

PaymentPublic payment(int id, {String status = TransactionStatuses.succeeded, DateTime? at}) =>
    PaymentPublic.fromJson(api.sample('PaymentPublic'))
        .copyWith(id: id, status: status, confirmedAt: at ?? DateTime.utc(2026, 9, 10));

void main() {
  group('facture la plus urgente', () {
    test('tout payé ou annulé : aucune', () {
      expect(
        mostUrgentBill([
          bill(1, status: BillStatuses.paid),
          bill(2, status: BillStatuses.cancelled),
        ]),
        isNull,
      );
      expect(mostUrgentBill([]), isNull);
    });

    test('une facture en retard passe AVANT une impayée à échéance plus proche', () {
      final urgent = mostUrgentBill([
        bill(1, due: DateTime(2026, 11, 20)),
        bill(2, status: BillStatuses.overdue, due: DateTime(2026, 10, 1)),
      ]);
      expect(urgent!.id, 2);
    });

    test('plusieurs en retard : la plus ancienne échéance', () {
      final urgent = mostUrgentBill([
        bill(1, status: BillStatuses.overdue, due: DateTime(2026, 10, 15)),
        bill(2, status: BillStatuses.overdue, due: DateTime(2026, 9, 15)),
      ]);
      expect(urgent!.id, 2);
    });

    test('aucune en retard : l’échéance la plus proche (paiement en cours compris)', () {
      final urgent = mostUrgentBill([
        bill(1, due: DateTime(2026, 12, 3)),
        bill(2, status: BillStatuses.pendingPayment, due: DateTime(2026, 11, 18)),
      ]);
      expect(urgent!.id, 2);
    });

    test('statut inconnu (ajouté plus tard par l’API) : ignoré, pas de plantage', () {
      expect(mostUrgentBill([bill(1, status: 'nouveau_statut')]), isNull);
    });
  });

  group('action de la carte', () {
    test('payable : « Payer »', () {
      expect(urgentBillAction(bill(1)), UrgentBillAction.pay);
    });

    test('paiement en cours : « Paiement en cours » au lieu de Payer', () {
      final pending = bill(1, status: BillStatuses.pendingPayment, canPay: false);
      expect(urgentBillAction(pending), UrgentBillAction.paymentInProgress);
    });

    test('simple lecteur du foyer (can_pay faux) : ni l’un ni l’autre', () {
      expect(urgentBillAction(bill(1, canPay: false)), UrgentBillAction.none);
    });
  });

  group('foyer affiché', () {
    final foyers = [household(1, 'Maison Mpita'), household(2, 'Boutique Tié-Tié')];

    test('par défaut : celui de la facture la plus urgente', () {
      final toPay = [bill(1), bill(2, status: BillStatuses.overdue, household: 2)];
      expect(defaultHouseholdId(foyers, toPay), 2);
    });

    test('rien à payer : le premier foyer ; aucun foyer : aucun', () {
      expect(defaultHouseholdId(foyers, []), 1);
      expect(defaultHouseholdId([], [bill(1)]), isNull);
    });

    test('le choix gardé passe avant le défaut, s’il existe encore', () {
      final toPay = [bill(1, status: BillStatuses.overdue, household: 2)];
      expect(effectiveHouseholdId(saved: 1, households: foyers, toPay: toPay), 1);
      expect(effectiveHouseholdId(saved: 99, households: foyers, toPay: toPay), 2);
      expect(effectiveHouseholdId(saved: null, households: foyers, toPay: toPay), 2);
    });
  });

  group('rappel des retards dans les AUTRES foyers', () {
    test('« 1 facture en retard dans Boutique Tié-Tié » (pas le foyer affiché)', () {
      final toPay = [
        bill(1, status: BillStatuses.overdue),
        bill(2, status: BillStatuses.overdue, household: 2, householdName: 'Boutique Tié-Tié'),
        bill(3, household: 2, householdName: 'Boutique Tié-Tié'), // impayée, pas en retard
      ];
      expect(overdueElsewhere(toPay, 1), [
        (householdId: 2, householdName: 'Boutique Tié-Tié', count: 1),
      ]);
    });

    test('plusieurs retards dans un foyer : comptés ; aucun ailleurs : liste vide', () {
      final toPay = [
        bill(1, status: BillStatuses.overdue, household: 2, householdName: 'Boutique'),
        bill(2, status: BillStatuses.overdue, household: 2, householdName: 'Boutique'),
      ];
      expect(overdueElsewhere(toPay, 1).single.count, 2);
      expect(overdueElsewhere(toPay, 2), isEmpty);
    });
  });

  group('compteur de la carte du mois', () {
    test('celui de la facture urgente s’il est dans le foyer affiché', () {
      expect(consumptionMeterId(urgent: bill(1, meter: 11), meters: [meter(10), meter(11)]), 11);
    });

    test('sinon le premier compteur actif ; aucun compteur : aucun', () {
      final meters = [meter(10, status: 'suspended'), meter(11)];
      expect(consumptionMeterId(urgent: bill(1, meter: 99), meters: meters), 11);
      expect(consumptionMeterId(urgent: null, meters: [meter(10, status: 'terminated')]), 10);
      expect(consumptionMeterId(urgent: null, meters: []), isNull);
    });
  });

  group('activité récente', () {
    test('paiements réussis + factures émises, du plus récent, 3 au plus', () {
      final items = recentActivity(
        payments: [payment(1, at: DateTime.utc(2026, 9, 10))],
        bills: [
          bill(1, issued: DateTime.utc(2026, 11, 3)),
          bill(2, issued: DateTime.utc(2026, 9, 3)),
          bill(3, issued: DateTime.utc(2026, 7, 3)),
        ],
      );
      expect(items.map((i) => (i.runtimeType, i.at)), [
        (BillIssuedActivity, DateTime.utc(2026, 11, 3)),
        (PaymentActivity, DateTime.utc(2026, 9, 10)),
        (BillIssuedActivity, DateTime.utc(2026, 9, 3)),
      ]);
    });

    test('un paiement échoué ou une facture annulée n’apparaissent pas', () {
      final items = recentActivity(
        payments: [payment(1, status: TransactionStatuses.failed)],
        bills: [bill(1, status: BillStatuses.cancelled)],
      );
      expect(items, isEmpty);
    });

    test('paiement sans date de confirmation : sa date de demande', () {
      final p = payment(1).copyWith(confirmedAt: null, initiatedAt: DateTime.utc(2026, 9, 9));
      expect(PaymentActivity(p).at, DateTime.utc(2026, 9, 9));
    });
  });
}
