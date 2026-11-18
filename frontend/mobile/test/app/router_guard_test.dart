import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_auth_backend.dart';
import '../support/fake_server.dart';

String location(WidgetTester tester) =>
    AppHarness.containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Future<void> go(WidgetTester tester, String path) async {
  AppHarness.containerOf(tester).read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  group('garde (fonction pure)', () {
    const active = SessionActive(42);
    const ended = SessionEnded(SessionEndReason.loggedOut);
    const expired = SessionEnded(SessionEndReason.expired);

    String? guardFor(String location, SessionState session, {bool notice = false}) =>
        guard(location: location, session: session, expiryNoticePending: notice);

    test('session pas encore lue : écrans protégés → splash ; connexion libre', () {
      expect(guardFor('/factures', const SessionUnknown()), Routes.splash);
      expect(guardFor(Routes.login, const SessionUnknown()), isNull);
    });

    test('connecté : plus d’écran de connexion', () {
      for (final page in Routes.auth) {
        expect(guardFor(page, active), Routes.home, reason: page);
      }
      expect(guardFor('/conso', active), isNull);
    });

    test('déconnecté : écrans protégés → connexion', () {
      for (final tab in AppTab.values) {
        expect(guardFor(tab.path, ended), Routes.login, reason: tab.path);
      }
      expect(guardFor(Routes.register, ended), isNull);
    });

    test('session expirée, feuille pas encore vue : on reste (l’écran est masqué)', () {
      expect(guardFor('/accueil', expired, notice: true), isNull);
      expect(guardFor('/accueil', expired), Routes.login);
    });

    test('pages de développement : jamais redirigées', () {
      for (final session in [const SessionUnknown(), active, ended]) {
        expect(guardFor('/diagnostic', session), isNull);
        expect(guardFor('/catalogue', session), isNull);
      }
    });
  });

  group('dans l’application', () {
    testWidgets('déconnecté : ouvrir un onglet mène à la connexion', (tester) async {
      final h = AppHarness();
      await h.start(tester);
      await tester.pumpAndSettle();
      await go(tester, '/factures');
      expect(location(tester), Routes.login);
    });

    testWidgets('connecté : la connexion mène à l’accueil', (tester) async {
      final h = AppHarness(stored: SessionHarness.tokens(1));
      await h.start(tester);
      await tester.pumpAndSettle();
      await go(tester, Routes.login);
      expect(location(tester), Routes.home);
    });

    testWidgets('déconnexion (onglet Compte) : connexion, jetons effacés, sans feuille', (
      tester,
    ) async {
      final h = AppHarness(stored: SessionHarness.tokens(1));
      await h.start(tester);
      await tester.pumpAndSettle();
      await go(tester, AppTab.account.path);
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      expect(location(tester), Routes.login);
      expect(h.tokens.tokens, isNull);
      expect(find.text('Session expirée'), findsNothing);
    });

    testWidgets('session EXPIRÉE pendant l’utilisation : feuille, puis la connexion', (
      tester,
    ) async {
      final h = AppHarness(stored: SessionHarness.tokens(1));
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(location(tester), Routes.home);

      // Le jeton est refusé et le rafraîchissement aussi : la session expire.
      h.backend
        ..expireAccessTokens()
        ..forced['/auth/refresh'] = JsonReply(
          401,
          apiError('REFRESH_TOKEN_REUSED', 'Session fermée par sécurité.'),
        );
      final api = AppHarness.containerOf(tester).read(authenticatedApiProvider);
      await tester.runAsync(() async {
        try {
          await api.getObject('/me', (json) => json);
        } on Object {
          // échec attendu : SessionExpired
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Votre session a expiré. Reconnectez-vous pour continuer.'), findsOneWidget);
      expect(location(tester), Routes.home, reason: 'l’écran reste, masqué par la feuille');

      await tester.tap(find.text('Se reconnecter'));
      await tester.pumpAndSettle();
      expect(location(tester), Routes.login);
      expect(find.text('Session expirée'), findsNothing);
    });

    testWidgets('API muette au rafraîchissement : la session reste (pas de feuille)', (
      tester,
    ) async {
      final h = AppHarness(stored: SessionHarness.tokens(1));
      await h.start(tester);
      await tester.pumpAndSettle();
      h.backend
        ..expireAccessTokens()
        ..forced['/auth/refresh'] = const FailReply(DioExceptionType.connectionError);
      final api = AppHarness.containerOf(tester).read(authenticatedApiProvider);
      await tester.runAsync(() async {
        try {
          await api.getObject('/me', (json) => json);
        } on Object {
          // hors ligne
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Session expirée'), findsNothing);
      expect(location(tester), Routes.home);
      expect(AppHarness.containerOf(tester).read(sessionStateProvider), const SessionActive(42));
    });
  });
}
