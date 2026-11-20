import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/models/consumption.dart';
import 'package:elecpay/features/consumption/consumption_data.dart';
import 'package:elecpay/features/consumption/consumption_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_home_backend.dart';

ProviderContainer containerFor(FakeHomeBackend backend) {
  final c = ProviderContainer(retry: noAutomaticRetry, overrides: backend.overrides());
  addTearDown(c.dispose);
  return c;
}

Future<T> listenRead<T>(ProviderContainer c, ProviderListenable<Future<T>> p) async {
  final sub = c.listen(p, (_, _) {});
  try {
    return await sub.read();
  } finally {
    sub.close();
  }
}

void main() {
  test('toutes les routes de consommation sont en cache (relevés journaliers)', () {
    for (final path in [
      '/meters/11/consumption',
      '/meters/11/consumption/summary',
      '/meters/11/consumption/days/2026-10-14',
    ]) {
      expect(isCacheable(path), isTrue, reason: path);
    }
  });

  group('compteur affiché', () {
    test('par défaut : celui de la carte du mois de l’accueil', () async {
      final c = containerFor(FakeHomeBackend());
      // Accueil : foyer de la facture en retard (Boutique, compteur 20).
      expect(await listenRead(c, consumptionMeterIdProvider.future), 20);
    });

    test('choisi sur l’écran : gardé', () async {
      final c = containerFor(FakeHomeBackend());
      final sub = c.listen(consumptionMeterIdProvider.future, (_, _) {});
      addTearDown(sub.close);
      c.read(chosenConsumptionMeterProvider.notifier).choose(10);
      expect(await c.read(consumptionMeterIdProvider.future), 10);
    });

    test('tous mes compteurs, avec leur foyer (sélecteur)', () async {
      final meters = await listenRead(containerFor(FakeHomeBackend()), allMetersProvider.future);
      expect(meters.map((m) => (m.meter.id, m.household.name)), [
        (10, 'Maison Mpita'),
        (11, 'Maison Mpita'),
        (20, 'Boutique Tié-Tié'),
      ]);
    });

    test('aucun foyer : aucun compteur, sans erreur', () async {
      final backend = FakeHomeBackend()
        ..households = []
        ..toPay = [];
      expect(await listenRead(containerFor(backend), consumptionMeterIdProvider.future), isNull);
    });
  });

  test('série du mois : granularité et plage envoyées, dates au format de l’API', () async {
    final backend = FakeHomeBackend();
    final cursor = ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10));
    final series = await listenRead(
      containerFor(backend),
      consumptionSeriesProvider(seriesKey(11, cursor.chartRange)).future,
    );
    expect(series.data.points, hasLength(31));
    expect(backend.requestsTo('/meters/11/consumption').single.queryParameters, {
      'granularity': 'day',
      'from': '2026-10-01',
      'to': '2026-10-31',
    });
  });

  test(
    'détail d’un jour ; jour non relevé : refus de l’API (404), pas de cache trompeur',
    () async {
      final backend = FakeHomeBackend();
      final c = containerFor(backend);
      final day = await listenRead(
        c,
        dayDetailProvider((meterId: 11, day: DateTime(2026, 10, 14))).future,
      );
      expect(day.data.consumptionWh, 9000);
      expect(day, isA<FreshData<DayDetail>>());
      await expectLater(
        listenRead(c, dayDetailProvider((meterId: 11, day: DateTime(2026, 11, 20))).future),
        throwsA(anything),
      );
    },
  );

  test('hors ligne : la série vient du cache, signalée', () async {
    final backend = FakeHomeBackend();
    final key = seriesKey(
      11,
      ConsumptionCursor.of(ConsumptionLevel.month, DateTime(2026, 10)).chartRange,
    );
    await listenRead(containerFor(backend), consumptionSeriesProvider(key).future);
    backend.down.add('/meters');
    final offline = await listenRead(containerFor(backend), consumptionSeriesProvider(key).future);
    expect(offline, isA<CachedData<ConsumptionSeries>>());
  });

  test('facture qui couvre un mois (lien de la vue Mois), sans filtre d’année', () async {
    final backend = FakeHomeBackend()
      ..latestBills = [
        {
          ...FakeHomeBackend.bill(101, household: 1, meter: 11),
          'period_start': '2026-09-01',
          'period_end': '2026-10-31',
        },
      ];
    final c = containerFor(backend);
    final oct = await listenRead(
      c,
      billForMonthProvider((meterId: 11, month: DateTime(2026, 10))).future,
    );
    expect(oct!.id, 101);
    final nov = await listenRead(
      c,
      billForMonthProvider((meterId: 11, month: DateTime(2026, 11))).future,
    );
    expect(nov, isNull);
    expect(backend.requestsTo('/bills').first.queryParameters.containsKey('year'), isFalse);
  });
}
