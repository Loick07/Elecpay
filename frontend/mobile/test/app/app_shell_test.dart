import 'package:elecpay/app/router.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/fake_auth_backend.dart';

/// L'application connectée (session enregistrée), ouverte sur `location`.
Future<void> openApp(WidgetTester tester, String location) async {
  await AppHarness(stored: SessionHarness.tokens(1)).start(tester);
  await tester.pumpAndSettle();
  AppHarness.containerOf(tester).read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

void main() {
  test('les 4 onglets ont leur route', () {
    final shell = appRoutes().whereType<ShellRoute>().single;
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
