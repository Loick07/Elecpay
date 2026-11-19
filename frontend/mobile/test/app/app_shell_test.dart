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
    // Factures (F5) n'a plus de page d'attente : Conso (F7) en garde une.
    await openApp(tester, AppTab.consumption.path);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Conso : bientôt'), findsOneWidget);
    expect(find.text('Cet écran arrive à l’étape F7 du plan.'), findsOneWidget);
  });

  testWidgets('toucher un onglet change d’écran, l’onglet suit', (tester) async {
    await openApp(tester, AppTab.home.path);
    await tester.tap(find.text('Conso').last);
    await tester.pumpAndSettle();
    expect(find.text('Conso : bientôt'), findsOneWidget);
    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.current, AppTab.consumption);
  });

  testWidgets('Payer central, factures illisibles : un message, aucun paiement envoyé', (
    tester,
  ) async {
    // Le faux backend de connexion n'a pas de factures : Payer ne peut rien proposer (F6, D6.1 ;
    // les cas avec des factures sont dans test/features/payments/payment_entry_test.dart).
    final harness = AppHarness(stored: SessionHarness.tokens(1));
    await harness.start(tester);
    await tester.pumpAndSettle();
    AppHarness.containerOf(tester).read(routerProvider).go(AppTab.home.path);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de charger vos factures. Réessayez.'), findsOneWidget);
    expect(harness.backend.server.requests.where((r) => r.path == '/payments'), isEmpty);
  });

  testWidgets('le contenu passe sous la barre (barre flottante en verre)', (tester) async {
    await openApp(tester, AppTab.home.path);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.extendBody, isTrue);
  });
}
