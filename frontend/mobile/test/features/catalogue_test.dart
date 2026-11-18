import 'dart:io';

import 'package:elecpay/app/router.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:elecpay/core/widgets/hero_bill_card.dart';
import 'package:elecpay/features/catalogue/catalogue_screen.dart';
import 'package:elecpay/features/diagnostic/diagnostic_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/itel_screen.dart';

/// La liste de la page (les champs de saisie ont aussi leur propre zone qui défile).
final page = find.byType(Scrollable).first;

void main() {
  test('route /catalogue seulement avec la page Diagnostic (debug / profile)', () {
    expect(diagnosticsEnabled, isTrue, reason: 'les tests tournent en debug');
    final paths = appRoutes().whereType<GoRoute>().map((r) => r.path);
    expect(paths, containsAll(['/diagnostic', '/catalogue']));
  });

  test('porte la marque cherchée dans l’APK release (absente en release)', () {
    // Même contrôle que la page Diagnostic : apk_check vérifie que la marque est absente en release.
    final source = File('lib/features/catalogue/catalogue_screen.dart').readAsStringSync();
    expect(source, contains('identifier: diagnosticMarker'));
  });

  testWidgets('s’affiche sur l’itel ; interrupteurs hors ligne et sans flou', (tester) async {
    tester.view.physicalSize = itelPhysicalSize;
    tester.view.devicePixelRatio = itelPixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CatalogueScreen())));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Catalogue'), findsOneWidget);

    // Hors ligne : la bannière apparaît, la carte de facture désactive Payer.
    await tester.tap(find.text('En ligne'));
    await tester.pump();
    expect(find.textContaining('Hors connexion. Les données affichées datent du'), findsOneWidget);

    // Sans flou (interrupteur en haut de page).
    final container = ProviderScope.containerOf(tester.element(find.byType(CatalogueScreen)));
    await tester.tap(find.text('Effet verre (flou)'));
    await tester.pump();
    expect(container.read(glassModeProvider), GlassMode.opaque);

    // La liste ne construit que ce qui est à l'écran : on descend jusqu'à la carte de facture.
    await tester.scrollUntilVisible(find.byType(HeroBillCard), 300, scrollable: page);
    expect(tester.widget<HeroBillCard>(find.byType(HeroBillCard)).online, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('se parcourt jusqu’en bas sans erreur (tous les composants)', (tester) async {
    tester.view.physicalSize = itelPhysicalSize;
    tester.view.devicePixelRatio = itelPixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CatalogueScreen())));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Ouvrir les écrans principaux'),
      400,
      scrollable: page,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('interrupteur du verre : repasse au flou', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: CatalogueScreen())));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(CatalogueScreen)));
    container.read(glassModeProvider.notifier).set(GlassMode.opaque);
    await tester.pump();
    await tester.tap(find.text('Effet verre (flou)'));
    await tester.pump();
    expect(container.read(glassModeProvider), GlassMode.blur);
  });
}
