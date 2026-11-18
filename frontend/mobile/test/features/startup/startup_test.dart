import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/core/widgets/demo_badge.dart';
import 'package:elecpay/features/startup/splash_screen.dart';
import 'package:elecpay/features/startup/startup_decision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_auth_backend.dart';
import '../../support/fake_health.dart';

String location(WidgetTester tester) =>
    AppHarness.containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void main() {
  group('décision du splash (2 s au plus)', () {
    Future<StartupDecision> decide({required bool session, required FakeHealthService health}) {
      final h = AppHarness(stored: session ? SessionHarness.tokens(1) : null, health: health);
      final container = ProviderContainer(overrides: h.overrides);
      addTearDown(container.dispose);
      return decideStart(session: container.read(sessionManagerProvider), health: health);
    }

    test('session + API injoignable → ACCUEIL (cache + bannière), sans attendre l’API', () async {
      final health = unreachableApi();
      expect(await decide(session: true, health: health), isA<GoHome>());
      expect(health.calls, 0, reason: 'l’API n’est même pas interrogée');
    });

    test('session + API muette → accueil aussitôt', () async {
      expect(await decide(session: true, health: silentApi()), isA<GoHome>());
    });

    test('sans session, API joignable → connexion', () async {
      expect(await decide(session: false, health: demoApi()), isA<GoLogin>());
    });

    test('sans session, API injoignable → bloc « Hors connexion »', () async {
      final decision = await decide(session: false, health: unreachableApi());
      expect(decision, isA<ShowUnreachable>());
    });

    test('sans session, base en panne (503) → « momentanément indisponible »', () async {
      final health = FakeHealthService(const ApiReachable(demoMode: true, databaseOk: false));
      expect(await decide(session: false, health: health), isA<ShowUnavailable>());
    });

    testWidgets('sans session, API muette → au bout de 2 s : injoignable', (tester) async {
      StartupDecision? decision;
      final h = AppHarness(health: silentApi());
      final container = ProviderContainer(overrides: h.overrides);
      addTearDown(container.dispose);
      decideStart(
        session: container.read(sessionManagerProvider),
        health: h.health,
      ).then((d) => decision = d).ignore();
      await tester.pump(const Duration(milliseconds: 1999));
      expect(decision, isNull);
      await tester.pump(const Duration(milliseconds: 2));
      expect(decision, isA<ShowUnreachable>());
    });
  });

  group('splash dans l’application', () {
    testWidgets('textes de la maquette et badge Mode démo', (tester) async {
      final h = AppHarness(
        health: silentApi()..answer = const ApiReachable(demoMode: true, databaseOk: true),
      );
      await h.start(tester);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('ElecPay'), findsOneWidget);
      expect(
        find.text('Votre électricité, vos factures et vos paiements au même endroit.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('session + API injoignable : l’ACCUEIL, pas le bloc « Hors connexion »', (
      tester,
    ) async {
      final h = AppHarness(stored: SessionHarness.tokens(1), health: unreachableApi());
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(location(tester), Routes.home);
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('Hors connexion'), findsNothing);
    });

    testWidgets('sans session + API injoignable : bloc « Hors connexion », puis Réessayer', (
      tester,
    ) async {
      final h = AppHarness(health: unreachableApi());
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(location(tester), Routes.splash);
      expect(find.text('Hors connexion'), findsOneWidget);

      h.health.answer = const ApiReachable(demoMode: true, databaseOk: true);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(location(tester), Routes.login);
    });

    testWidgets('sans session + API joignable : la connexion', (tester) async {
      final h = AppHarness();
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(location(tester), Routes.login);
    });

    testWidgets('sans session + API muette : bloc « Hors connexion » au bout de 2 s', (
      tester,
    ) async {
      final h = AppHarness(health: silentApi());
      await h.start(tester);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('Hors connexion'), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.text('Hors connexion'), findsOneWidget);
      expect(location(tester), Routes.splash);
    });

    testWidgets('badge Mode démo seulement si l’API le dit', (tester) async {
      final h = AppHarness(
        health: FakeHealthService(const ApiReachable(demoMode: false, databaseOk: false)),
      );
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsNothing);
      expect(find.text('Service indisponible'), findsOneWidget);
    });
  });
}
