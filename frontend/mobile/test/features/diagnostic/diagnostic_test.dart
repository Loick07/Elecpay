import 'package:dio/dio.dart';
import 'package:elecpay/app/router.dart';
import 'package:elecpay/core/cache/cache_store.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/session/auth_interceptor.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/session/token_store.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:elecpay/features/diagnostic/diagnostic_access.dart';
import 'package:elecpay/features/diagnostic/diagnostic_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../tool/apk_check.dart' as apk_check;
import '../../support/app_harness.dart';
import '../../support/fake_auth_backend.dart';
import '../../support/fake_server.dart';
import '../../support/memory_cache_store.dart';

void main() {
  group('visible en debug et profile, JAMAIS en release', () {
    test('la règle est une constante liée au mode de compilation', () {
      expect(diagnosticsEnabled, !kReleaseMode);
      // Les tests tournent en debug : la page doit exister ici.
      expect(diagnosticsEnabled, isTrue);
    });

    test('route /diagnostic présente (version de développement)', () {
      final paths = appRoutes().whereType<GoRoute>().map((r) => r.path);
      expect(paths, contains('/diagnostic'));
    });

    test('la marque cherchée dans l’APK release est la même que celle de la page', () {
      expect(apk_check.diagnosticMarker, diagnosticMarker);
    });

    test('recherche d’octets de l’outil (utilisée sur le code compilé)', () {
      final marker = diagnosticMarker.codeUnits;
      expect(apk_check.containsBytes([1, 2, ...marker, 3], marker), isTrue);
      expect(apk_check.containsBytes([1, 2, ...marker.take(10), 3], marker), isFalse);
      expect(apk_check.isDartCode('lib/armeabi-v7a/libapp.so'), isTrue);
      expect(apk_check.isDartCode('assets/flutter_assets/kernel_blob.bin'), isTrue);
      expect(apk_check.isDartCode('lib/armeabi-v7a/libflutter.so'), isFalse);
    });

    testWidgets('liens « Diagnostic » et « Catalogue » sur l’écran de connexion', (tester) async {
      await AppHarness().start(tester);
      await tester.pumpAndSettle();
      expect(find.text('Diagnostic'), findsOneWidget);
      expect(find.text('Catalogue'), findsOneWidget);
    });
  });

  group('parcours sur la page (faux backend)', () {
    late FakeAuthBackend backend;
    late MemoryCacheStore cache;

    Widget page({StoredTokens? stored}) {
      final config = AppConfig.parse('http://127.0.0.1:8000', release: false);
      backend = FakeAuthBackend();
      cache = MemoryCacheStore();
      return ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          apiDioProvider.overrideWithValue(
            createApiDio(config)..httpClientAdapter = backend.server,
          ),
          authenticatedDioProvider.overrideWith((ref) {
            final dio = createApiDio(config)..httpClientAdapter = backend.server;
            dio.interceptors.add(AuthInterceptor(ref.watch(sessionManagerProvider), dio));
            return dio;
          }),
          tokenStoreProvider.overrideWithValue(MemoryTokenStore(stored)),
          cacheStoreProvider.overrideWithValue(cache),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const DiagnosticScreen()),
      );
    }

    Future<void> tap(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    // Défauts vus sur l'itel au jalon F1.
    testWidgets('à l’ouverture : session déjà lue (jamais bloquée sur « lecture… »)', (
      tester,
    ) async {
      await tester.pumpWidget(page(stored: SessionHarness.tokens(1)));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('connectée (utilisateur 42)'), findsOneWidget);
      expect(find.textContaining('valable jusqu’au'), findsOneWidget);
      expect(find.textContaining('lecture…'), findsNothing);
    });

    testWidgets('sans session : « aucune », et les lectures sont désactivées', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Session : aucune'), findsOneWidget);
      for (final label in ['Lire mon profil', '5 lectures en même temps', 'Se déconnecter']) {
        final button = tester.widget<OutlinedButton>(
          find.ancestor(of: find.text(label), matching: find.byType(OutlinedButton)),
        );
        expect(button.onPressed, isNull, reason: label);
      }
    });

    testWidgets('titre court (tient sur un petit écran)', (tester) async {
      await tester.pumpWidget(page());
      expect(find.text('Diagnostic'), findsOneWidget);
    });

    testWidgets('interrupteur « Effet verre » : flou ↔ sans flou (jalon F3)', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();
      final container = ProviderScope.containerOf(tester.element(find.byType(DiagnosticScreen)));
      expect(container.read(glassModeProvider), GlassMode.blur);
      expect(find.text('Flou d’arrière-plan (barre du bas, feuilles)'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(container.read(glassModeProvider), GlassMode.opaque);
      expect(find.text('Sans flou : fond opaque'), findsOneWidget);
    });

    testWidgets('connexion, profil, expiration absorbée, hors ligne, déconnexion', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();

      await tap(tester, 'Se connecter');
      expect(
        find.text('Connecté : ${(backend.tokenResponse(1)['user']! as Map)['full_name']}'),
        findsOneWidget,
      );
      expect(find.textContaining('connectée (utilisateur 42)'), findsOneWidget);

      await tap(tester, 'Lire mon profil');
      expect(find.textContaining('donnée fraîche'), findsOneWidget);

      backend.expireAccessTokens();
      await tap(tester, '5 lectures en même temps');
      expect(
        find.text('5 lectures simultanées réussies, 1 rafraîchissement de jeton'),
        findsOneWidget,
      );
      expect(backend.refreshCalls, 1);

      backend.forced['/me'] = const FailReply(DioExceptionType.connectionError);
      await tap(tester, 'Lire mon profil');
      expect(
        find.textContaining('Hors connexion. Les données affichées datent du'),
        findsOneWidget,
      );

      await tap(tester, 'Se déconnecter');
      expect(find.text('Déconnecté : jetons et cache effacés'), findsOneWidget);
      expect(cache.users, isEmpty);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('échec affiché avec sa référence', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'faux');
      await tap(tester, 'Se connecter');
      expect(
        find.textContaining('Numéro ou mot de passe incorrect. (Référence : app-'),
        findsOneWidget,
      );
    });
  });
}
