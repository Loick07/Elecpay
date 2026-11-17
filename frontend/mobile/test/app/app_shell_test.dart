import 'package:elecpay/app/app.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_health.dart';
import '../support/itel_screen.dart';

Future<void> openApp(WidgetTester tester, String location) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: healthOverrides(demoApi()), child: const ElecPayApp()),
  );
  appRouter.go(location);
  await tester.pumpAndSettle();
  addTearDown(() => appRouter.go('/'));
}

void main() {
  test('les 4 onglets ont leur route', () {
    final shell = appRouter.configuration.routes.whereType<ShellRoute>().single;
    final paths = shell.routes.whereType<GoRoute>().map((r) => r.path);
    expect(paths, [for (final tab in AppTab.values) tab.path]);
  });

  testWidgets('écran principal : barre du bas, page d’attente avec son étape', (tester) async {
    await openApp(tester, AppTab.bills.path);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Factures : bientôt'), findsOneWidget);
    expect(find.text('Cet écran arrive à l’étape F5 du plan.'), findsOneWidget);
  });

  testWidgets('toucher un onglet change d’écran, l’onglet suit', (tester) async {
    await openApp(tester, AppTab.home.path);
    await tester.tap(find.text('Conso').last);
    await tester.pumpAndSettle();
    expect(find.text('Conso : bientôt'), findsOneWidget);
    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.current, AppTab.consumption);
  });

  testWidgets('Payer (avant F6) : un message, aucun paiement', (tester) async {
    await openApp(tester, AppTab.home.path);
    await tester.tap(find.text('Payer'));
    await tester.pump();
    expect(find.text('Le paiement arrive à l’étape F6.'), findsOneWidget);
  });

  testWidgets('le contenu passe sous la barre (barre flottante en verre)', (tester) async {
    await openApp(tester, AppTab.home.path);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.extendBody, isTrue);
  });
}
