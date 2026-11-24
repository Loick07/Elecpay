// « Effet verre » (F9.2) : temps d'image sur les VRAIS écrans, SANS puis AVEC le flou, réglé par
// l'interrupteur de l'écran Compte (comme le ferait l'utilisateur).
//
// Aux jalons seulement, jamais en CI. En profile, base DÉDIÉE `elecpay_e2e` recréée par le script :
//   .\tool\integration.ps1 -Device <téléphone> -Target integration_test/glass_screens_perf_test.dart `
//       -Driver test_driver/perf_driver.dart
// Résultats : build/perf_flou.json (moyenne, 90e et 99e centiles, pire image, images hors budget
// de 16,7 ms), par écran et par réglage.
import 'dart:ui' show FrameTiming, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'glass_perf_test.dart' show summarize;
import 'support/itel_app.dart';

void main() {
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final report = <String, Object>{};

  Future<void> measure(String key, Future<void> Function() action) async {
    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    report[key] = summarize(frames);
    binding.reportData = report;
  }

  Future<void> wait(WidgetTester tester, int ms) => tester.pump(Duration(milliseconds: ms));

  Future<void> setGlass(WidgetTester tester, {required bool on}) async {
    await tapOn(tester, find.text('Compte'));
    await waitFor(tester, find.byKey(const Key('account.list')));
    await tester.dragUntilVisible(
      find.byKey(const Key('account.glass')),
      find.byKey(const Key('account.list')),
      const Offset(0, -250),
    );
    await wait(tester, 400);
    final handle = tester.ensureSemantics();
    final now = tester
        .getSemantics(find.byKey(const Key('account.glass')))
        .getSemanticsData()
        .flagsCollection
        .isToggled;
    handle.dispose();
    if ((now == Tristate.isTrue) != on) await tapOn(tester, find.byKey(const Key('account.glass')));
    await wait(tester, 600);
  }

  testWidgets('accueil, feuille de paiement et Compte : sans puis avec le flou', (tester) async {
    await startApp(tester);
    await typeInto(tester, 0, '060000101');
    await typeInto(tester, 1, 'Demo2026!');
    await tapOn(tester, find.text('Se connecter'));
    await waitFor(tester, find.byKey(const Key('home.list')));

    for (final on in [false, true]) {
      final name = on ? 'flou' : 'sans_flou';
      await setGlass(tester, on: on);

      // 1. Compte : défilement (barre du bas en verre au-dessus de la liste).
      final account = find.byKey(const Key('account.list'));
      await measure('compte_defilement_$name', () async {
        for (var i = 0; i < 6; i++) {
          await tester.fling(account, const Offset(0, -400), 1500);
          await wait(tester, 800);
          await tester.fling(account, const Offset(0, 400), 1500);
          await wait(tester, 800);
        }
      });

      // 2. Accueil : défilement sous la barre du bas.
      await tapOn(tester, find.text('Accueil'));
      await waitFor(tester, find.byKey(const Key('home.list')));
      final home = find.byKey(const Key('home.list'));
      await measure('accueil_defilement_$name', () async {
        for (var i = 0; i < 6; i++) {
          await tester.fling(home, const Offset(0, -400), 1500);
          await wait(tester, 800);
          await tester.fling(home, const Offset(0, 400), 1500);
          await wait(tester, 800);
        }
      });

      // 3. Feuille de paiement (verre) ouverte puis fermée, 4 fois.
      await measure('feuille_paiement_$name', () async {
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.text('Payer').last);
          await wait(tester, 900);
          await androidBack(tester);
          await wait(tester, 700);
        }
      });
    }
    await setGlass(tester, on: false); // remis par défaut sur l'appareil
  });
}
