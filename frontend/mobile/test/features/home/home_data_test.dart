import 'package:dio/dio.dart';
import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/features/home/home_data.dart';
import 'package:elecpay/features/home/home_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';

ProviderContainer containerFor(FakeHomeBackend backend, {MemoryHouseholdChoiceStore? choices}) {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: backend.overrides(choices: choices),
  );
  addTearDown(container.dispose);
  return container;
}

/// La carte (lecture) est-elle en échec ? Elle est ÉCOUTÉE pendant la lecture, comme à l'écran
/// (Riverpod 3 met en pause un fournisseur que personne n'écoute).
Future<bool> fails(ProviderContainer c, ProviderListenable<Future<Object?>> card) async {
  final subscription = c.listen(card, (_, _) {});
  try {
    await subscription.read();
    return false;
  } on Object {
    return true;
  } finally {
    subscription.close();
  }
}

/// Toutes les cartes de l'accueil, avec leur nom.
final cards = <String, ProviderListenable<Future<Object?>>>{
  'compte (Bonjour)': homeUserProvider.future,
  'sélecteur de foyer': householdsProvider.future,
  'facture urgente': urgentBillProvider.future,
  'mois en cours': monthConsumptionProvider.future,
  'activité récente': recentActivityProvider.future,
  'cloche': unreadCountProvider.future,
};

void main() {
  group('tout répond', () {
    test('foyer affiché par défaut : celui de la facture la plus urgente (en retard)', () async {
      final c = containerFor(FakeHomeBackend());
      expect(await c.read(shownHouseholdIdProvider.future), 2);
      final card = await c.read(urgentBillProvider.future);
      expect(card.urgent!.id, 201);
      expect(card.urgent!.status, BillStatuses.overdue);
      expect(card.action, UrgentBillAction.pay);
      expect(card.elsewhere, isEmpty, reason: 'rien en retard dans Maison Mpita');
    });

    test('foyer choisi et gardé : sa facture, et le rappel du retard ailleurs', () async {
      final choices = MemoryHouseholdChoiceStore();
      final c = containerFor(FakeHomeBackend(), choices: choices);
      await c.read(savedHouseholdProvider.notifier).choose(1);
      expect(choices.saved, 1, reason: 'gardé d’un lancement à l’autre');
      final card = await c.read(urgentBillProvider.future);
      expect(card.urgent!.id, 101);
      expect(card.elsewhere, [(householdId: 2, householdName: 'Boutique Tié-Tié', count: 1)]);
    });

    test(
      'paiement en cours sur la facture urgente : « Paiement en cours » au lieu de Payer',
      () async {
        final backend = FakeHomeBackend()
          ..toPay = [
            FakeHomeBackend.bill(101, household: 1, meter: 11, status: BillStatuses.pendingPayment),
          ];
        final card = await containerFor(backend).read(urgentBillProvider.future);
        expect(card.action, UrgentBillAction.paymentInProgress);
      },
    );

    test('tout payé : pas de facture urgente (carte « tout est payé »)', () async {
      final card = await containerFor(FakeHomeBackend()..toPay = [])
          .read(urgentBillProvider.future);
      expect(card.urgent, isNull);
    });

    test('carte du mois : le compteur de la facture urgente, 12 derniers jours par jour', () async {
      final backend = FakeHomeBackend();
      final c = containerFor(backend, choices: MemoryHouseholdChoiceStore(1));
      final month = await c.read(monthConsumptionProvider.future);
      expect(month!.summary.data.meterId, 11);
      final series = backend.requestsTo('/meters/11/consumption').single.queryParameters;
      expect(series['granularity'], 'day');
      final from = DateTime.parse(series['from'] as String);
      final to = DateTime.parse(series['to'] as String);
      expect(to.difference(from).inDays, homeChartDays - 1);
    });

    test('compte neuf (aucun foyer) : aucune carte du mois, sans erreur', () async {
      final backend = FakeHomeBackend()
        ..households = []
        ..toPay = [];
      final c = containerFor(backend);
      expect(await c.read(shownHouseholdIdProvider.future), isNull);
      expect(await c.read(monthConsumptionProvider.future), isNull);
    });

    test('foyer sans compteur : aucune carte du mois, sans erreur', () async {
      final backend = FakeHomeBackend()..meters = {1: [], 2: []};
      expect(await containerFor(backend).read(monthConsumptionProvider.future), isNull);
    });

    test('lectures envoyées : à payer (100), activité (3 paiements réussis, 3 factures)', () async {
      final backend = FakeHomeBackend();
      final c = containerFor(backend);
      await c.read(urgentBillProvider.future);
      final activity = await c.read(recentActivityProvider.future);
      final bills = backend.requestsTo('/bills').map((r) => r.queryParameters).toList();
      expect(bills, contains(equals({'status': 'to_pay', 'size': toPayPageSize})));
      expect(bills, contains(equals({'size': homeActivityCount})));
      expect(backend.requestsTo('/payments').single.queryParameters, {
        'status': 'reussie',
        'size': homeActivityCount,
      });
      expect(activity.items, hasLength(2));
      expect(activity.offline, isNull);
    });
  });

  group('chaque carte se charge et échoue SÉPARÉMENT', () {
    // Route coupée → cartes qui en dépendent (en échec) ; TOUTES les autres s'affichent.
    final cases = <String, Set<String>>{
      '/bills': {'facture urgente', 'activité récente'},
      '/households': {'sélecteur de foyer', 'mois en cours'},
      '/meters': {'mois en cours'},
      '/households/1/meters': {'mois en cours'},
      '/payments': {'activité récente'},
      '/notifications': {'cloche'},
      '/me': {'compte (Bonjour)'},
    };
    for (final MapEntry(key: route, value: failing) in cases.entries) {
      test('$route injoignable : seules « ${failing.join(' », « ')} » échouent', () async {
        final backend = FakeHomeBackend()..down.add(route);
        final c = containerFor(backend, choices: MemoryHouseholdChoiceStore(1));
        for (final MapEntry(key: name, value: card) in cards.entries) {
          expect(await fails(c, card), failing.contains(name), reason: name);
        }
      });
    }

    test(
      'carte en échec : échec IMMÉDIAT, une seule requête (aucune relance automatique)',
      () async {
        final backend = FakeHomeBackend()..down.add('/notifications');
        final c = containerFor(backend);
        final clock = Stopwatch()..start();
        expect(await fails(c, unreadCountProvider.future), isTrue);
        expect(clock.elapsed, lessThan(const Duration(seconds: 1)));
        await Future<void>.delayed(const Duration(seconds: 1));
        expect(backend.requestsTo('/notifications/unread-count'), hasLength(1));
      },
    );

    test('foyers illisibles : la carte urgente montre la plus urgente, tous foyers', () async {
      final c = containerFor(FakeHomeBackend()..down.add('/households'));
      expect((await c.read(urgentBillProvider.future)).urgent!.id, 201);
    });

    test('factures illisibles : le foyer affiché retombe sur le premier', () async {
      final c = containerFor(FakeHomeBackend()..down.add('/bills'));
      expect(await c.read(shownHouseholdIdProvider.future), 1);
    });
  });

  test('paiement : sa période vient de SES dates (contrat), aucune lecture de facture', () async {
    final backend = FakeHomeBackend();
    final activity = await containerFor(backend).read(recentActivityProvider.future);
    final paid = activity.items.whereType<PaymentActivity>().single.payment;
    expect((paid.billPeriodStart, paid.billPeriodEnd), (DateTime(2026, 7), DateTime(2026, 8, 31)));
    expect(backend.requestsTo('/bills/90'), isEmpty);
  });

  group('hors ligne', () {
    test('activité : donnée du cache signalée (« Hors connexion… »)', () async {
      final backend = FakeHomeBackend();
      await containerFor(backend).read(recentActivityProvider.future);
      backend.down.add('/payments');
      final activity = await containerFor(backend).read(recentActivityProvider.future);
      expect(activity.items, isNotEmpty);
      expect(activity.offline, isA<CachedData<Object?>>());
    });
  });

  group('cloche', () {
    test('se relit à la demande (retour sur l’application, accueil), sans interrogation', () async {
      final backend = FakeHomeBackend();
      final c = containerFor(backend);
      expect(await c.read(unreadCountProvider.future), 3);
      backend.unread = 0;
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(backend.requestsTo('/notifications/unread-count'), hasLength(1), reason: 'aucune');
      await c.read(unreadCountProvider.notifier).refresh();
      expect(c.read(unreadCountProvider).value, 0);
    });

    test('relecture en échec : la dernière valeur connue reste affichée', () async {
      final backend = FakeHomeBackend();
      final c = containerFor(backend);
      await c.read(unreadCountProvider.future);
      backend.forced['/notifications/unread-count'] = const FailReply(DioExceptionType.unknown);
      await c.read(unreadCountProvider.notifier).refresh();
      expect(c.read(unreadCountProvider).value, 3);
    });
  });
}
