// Temps d'image (build et raster) du Catalogue sur le téléphone, AVEC puis SANS flou.
//
// Aux jalons seulement, jamais en CI (pas de téléphone dans GitHub Actions). En profile :
//   flutter drive --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/glass_perf_test.dart -d <téléphone>
// Résultats : build/perf_flou.json (moyenne, 90e et 99e centiles, pire image, nombre d'images).
//
// Les temps viennent du moteur (FrameTiming, comme DevTools), relevés par addTimingsCallback :
// pas besoin du service de débogage Dart (watchPerformance s'y connecte pour le ramasse-miettes,
// ce qui échoue en débogage sans fil).
import 'package:elecpay/app/app.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Résumé d'une série d'images, en millisecondes.
Map<String, Object> summarize(List<FrameTiming> frames) {
  Map<String, double> stats(List<double> values) {
    final sorted = [...values]..sort();
    double percentile(double p) => sorted[((sorted.length - 1) * p).round()];
    double round(double v) => (v * 100).round() / 100;
    return {
      'moyenne': round(values.reduce((a, b) => a + b) / values.length),
      'p90': round(percentile(0.90)),
      'p99': round(percentile(0.99)),
      'pire': round(sorted.last),
    };
  }

  double ms(Duration d) => d.inMicroseconds / 1000;
  final build = frames.map((f) => ms(f.buildDuration)).toList();
  final raster = frames.map((f) => ms(f.rasterDuration)).toList();
  // Budget d'une image à 60 Hz : 16,7 ms (build ou raster au-delà : image manquée).
  final missed = frames
      .where((f) => ms(f.buildDuration) > 16.7 || ms(f.rasterDuration) > 16.7)
      .length;
  return {
    'images': frames.length,
    'build_ms': stats(build),
    'raster_ms': stats(raster),
    'images_hors_budget_16_7ms': missed,
  };
}

/// Attente FIXE (pas pumpAndSettle : le Catalogue montre un bouton « en chargement » dont
/// l'animation ne s'arrête jamais).
Future<void> settle(WidgetTester tester, int milliseconds) =>
    tester.pump(Duration(milliseconds: milliseconds));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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

  for (final mode in [GlassMode.blur, GlassMode.opaque]) {
    final name = mode == GlassMode.blur ? 'flou' : 'sans_flou';

    testWidgets('Catalogue : défilement et feuille ($name)', (tester) async {
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(AppConfig.fromEnvironment())],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const ElecPayApp()),
      );
      await tester.pump(const Duration(seconds: 3)); // splash
      container.read(glassModeProvider.notifier).set(mode);
      container.read(routerProvider).go('/catalogue');
      await tester.pump(const Duration(seconds: 2));
      final list = find.byType(Scrollable).first;

      // 1. Défilement de tout le Catalogue (la barre du bas en verre est en fin de liste).
      await measure('defilement_$name', () async {
        for (var round = 0; round < 2; round++) {
          for (var i = 0; i < 8; i++) {
            await tester.fling(list, const Offset(0, -500), 1800);
            await settle(tester, 900);
          }
          for (var i = 0; i < 8; i++) {
            await tester.fling(list, const Offset(0, 500), 1800);
            await settle(tester, 900);
          }
        }
      });

      // 2. Ouverture et fermeture de la feuille de paiement (verre), 4 fois.
      final open = find.text('Ouvrir la feuille de paiement');
      await tester.scrollUntilVisible(open, 300, scrollable: list);
      await settle(tester, 900);
      await measure('feuille_$name', () async {
        for (var i = 0; i < 4; i++) {
          await tester.tap(open);
          await settle(tester, 700);
          Navigator.of(tester.element(open)).pop();
          await settle(tester, 700);
        }
      });
    });
  }
}
