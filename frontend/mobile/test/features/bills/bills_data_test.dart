import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/features/bills/bills_data.dart';
import 'package:elecpay/features/bills/bills_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';

ProviderContainer containerFor(FakeHomeBackend backend) {
  final container = ProviderContainer(retry: noAutomaticRetry, overrides: backend.overrides());
  addTearDown(container.dispose);
  return container;
}

/// Lit un fournisseur en l'écoutant (Riverpod 3 met en pause ce que personne n'écoute).
Future<T> listenRead<T>(ProviderContainer c, ProviderListenable<Future<T>> p) async {
  final sub = c.listen(p, (_, _) {});
  try {
    return await sub.read();
  } finally {
    sub.close();
  }
}

List<Map<String, Object?>> manyPaid(int n) => [
  for (var i = 1; i <= n; i++)
    FakeHomeBackend.bill(1000 + i, household: 1, meter: 11, status: BillStatuses.paid),
];

void main() {
  test('chaque onglet envoie son filtre ; « Toutes » n’en envoie aucun', () async {
    final backend = FakeHomeBackend();
    final c = containerFor(backend);
    for (final filter in BillsFilter.values) {
      await listenRead(c, billsProvider(filter).future);
    }
    final statuses = backend.requestsTo('/bills').map((r) => r.queryParameters['status']).toList();
    expect(statuses, [null, 'to_pay', 'paid', 'overdue']);
    expect(backend.requestsTo('/bills').map((r) => r.queryParameters['size']).toSet(), {20});
  });

  test('pages de 20 au défilement, sans doublon, jusqu’à la fin', () async {
    final backend = FakeHomeBackend()..paidBills = manyPaid(45);
    final c = containerFor(backend);
    final sub = c.listen(billsProvider(BillsFilter.paid), (_, _) {});
    addTearDown(sub.close);
    await c.read(billsProvider(BillsFilter.paid).future);
    final notifier = c.read(billsProvider(BillsFilter.paid).notifier);
    await notifier.loadMore();
    await notifier.loadMore();
    await notifier.loadMore(); // plus rien : aucune requête
    final view = c.read(billsProvider(BillsFilter.paid)).value!;
    expect(view.items, hasLength(45));
    expect(view.hasMore, isFalse);
    expect(backend.requestsTo('/bills').map((r) => r.queryParameters['page']), [1, 2, 3]);
  });

  test('page suivante en échec : l’erreur est gardée, la liste reste', () async {
    final backend = FakeHomeBackend()..paidBills = manyPaid(25);
    final c = containerFor(backend);
    final sub = c.listen(billsProvider(BillsFilter.paid), (_, _) {});
    addTearDown(sub.close);
    await c.read(billsProvider(BillsFilter.paid).future);
    backend.down.add('/bills');
    await c.read(billsProvider(BillsFilter.paid).notifier).loadMore();
    final view = c.read(billsProvider(BillsFilter.paid)).value!;
    expect(view.items, hasLength(20));
    expect(view.moreFailure, isNotNull);
    backend.down.clear();
    await c.read(billsProvider(BillsFilter.paid).notifier).loadMore();
    expect(c.read(billsProvider(BillsFilter.paid)).value!.items, hasLength(25));
  });

  test('pastilles des onglets : toutes, à payer, payées, en retard', () async {
    final backend = FakeHomeBackend()
      ..latestBills = [
        for (final b in [...FakeHomeBackend().toPay, ...manyPaid(3)]) b,
      ]
      ..paidBills = manyPaid(3);
    final counts = await listenRead(containerFor(backend), billCountsProvider.future);
    expect(counts, {
      BillsFilter.all: 5,
      BillsFilter.toPay: 2,
      BillsFilter.paid: 3,
      BillsFilter.overdue: 1,
    });
  });

  test('détail : lu, et gardé pour le mode hors ligne', () async {
    final backend = FakeHomeBackend();
    final detail = await listenRead(containerFor(backend), billDetailProvider(101).future);
    expect(detail.data.lines, hasLength(6));
    expect(detail, isA<FreshData<BillDetail>>());
    backend.down.add('/bills');
    final offline = await listenRead(containerFor(backend), billDetailProvider(101).future);
    expect(offline, isA<CachedData<BillDetail>>());
  });

  test('détail d’une facture d’un autre foyer : 404 (jamais masqué par le cache)', () async {
    final backend = FakeHomeBackend();
    expect(
      () => listenRead(containerFor(backend), billDetailProvider(999).future),
      throwsA(anything),
    );
  });

  test('liste hors ligne : lue dans le cache et signalée', () async {
    final backend = FakeHomeBackend();
    await listenRead(containerFor(backend), billsProvider(BillsFilter.all).future);
    backend.down.add('/bills');
    final view = await listenRead(containerFor(backend), billsProvider(BillsFilter.all).future);
    expect(view.offline, isNotNull);
    expect(view.items, isNotEmpty);
  });
}
