// Fluidité de l'écran Consommation (F7) sur le téléphone : graphiques fl_chart (barres de l'année,
// du mois, de la semaine), calendrier de la vue Jour et courbe de l'onglet Direct (simulation).
//
// Aux jalons seulement, jamais en CI (pas de téléphone dans GitHub Actions). En profile, base
// DÉDIÉE `elecpay_e2e` remise à zéro par le script :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/consumption_perf_test.dart `
//       -Driver test_driver/consumption_perf_driver.dart
// Résultats : build/perf_conso.json (moyenne, 90e et 99e centiles, pire image, images hors budget
// de 16,7 ms), à lire avec ceux de build/perf_flou.json (glass_perf_test.dart).
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bills_test.dart' show login;
import 'glass_perf_test.dart' show summarize;
import 'support/itel_app.dart';

void main() {
  // Images réelles, au rythme de l'écran (sinon le test avance sans vraie mesure).
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final report = <String, Object>{};

  Future<void> measure(String key, Future<void> Function() action) async {
    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await action();
    // Les temps arrivent par paquets : laisser passer les derniers.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    report[key] = summarize(frames);
    binding.reportData = report;
  }

  Future<void> wait(WidgetTester tester, int milliseconds) =>
      tester.pump(Duration(milliseconds: milliseconds));

  testWidgets('Consommation : onglets, défilement, Direct', (tester) async {
    await login(tester);
    await tapOn(tester, find.text('Conso').last);
    await waitFor(tester, find.byKey(const Key('conso.chart')));
    await shot(tester, 'f7-1-mois');

    // 1. Changements d'onglet : chaque graphique se construit (barres, calendrier), 3 tours.
    await measure('conso_onglets', () async {
      for (var round = 0; round < 3; round++) {
        for (final tab in ['year', 'month', 'week', 'day', 'month']) {
          await tester.tap(find.byKey(Key('conso.tab.$tab')));
          await wait(tester, 1200);
        }
      }
    });
    await shot(tester, 'f7-2-apres-onglets');

    // 2. Défilement de la vue Mois (barres fl_chart + liste « Semaine par semaine »).
    final list = find.byKey(const Key('conso.list'));
    await measure('conso_defilement_mois', () async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -500), 1800);
        await wait(tester, 900);
        await tester.fling(list, const Offset(0, 500), 1800);
        await wait(tester, 900);
      }
    });

    // 3. Flèches : mois précédents (nouvelle série, nouvelles barres animées).
    await measure('conso_fleches', () async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('conso.previous')));
        await wait(tester, 1200);
      }
    });

    // 4. Onglet Direct (base e2e en mode démo) : courbe et jauge animées toutes les 2 s, 20 s.
    await tester.tap(find.byKey(const Key('conso.tab.direct')));
    await waitFor(tester, find.byKey(const Key('conso.directChart')));
    await shot(tester, 'f7-3-direct');
    await measure('conso_direct_20s', () => wait(tester, 20000));
    await tester.tap(find.byKey(const Key('conso.tab.month')));
    await wait(tester, 1000);
  });
}
