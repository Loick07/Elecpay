import 'package:elecpay/app/app.dart';
import 'package:elecpay/core/cache/cache_store.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/session/auth_interceptor.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/session/token_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_backend.dart';
import 'fake_health.dart';
import 'itel_screen.dart';
import 'memory_cache_store.dart';

/// Dernière valeur connue du mode démo, en mémoire.
class MemoryDemoModeStore implements DemoModeStore {
  MemoryDemoModeStore([this.value]);

  bool? value;

  @override
  Future<bool?> read() async => value;

  @override
  Future<void> write(bool demo) async => value = demo;
}

/// L'application complète pour les tests : faux backend (jetons, rotation), stockages en mémoire,
/// santé de l'API choisie. Jamais de réseau ni de stockage réel.
class AppHarness {
  AppHarness({StoredTokens? stored, FakeHealthService? health, bool? storedDemoMode})
    : tokens = MemoryTokenStore(stored),
      health = health ?? demoApi(),
      demoStore = MemoryDemoModeStore(storedDemoMode);

  final backend = FakeAuthBackend();
  final MemoryTokenStore tokens;
  final FakeHealthService health;
  final cache = MemoryCacheStore();
  final MemoryDemoModeStore demoStore;

  static final config = AppConfig.parse('http://127.0.0.1:8000', release: false);

  List<Override> get overrides => [
    appConfigProvider.overrideWithValue(config),
    ...healthOverrides(health),
    tokenStoreProvider.overrideWithValue(tokens),
    cacheStoreProvider.overrideWithValue(cache),
    demoModeStoreProvider.overrideWithValue(demoStore),
    apiDioProvider.overrideWithValue(createApiDio(config)..httpClientAdapter = backend.server),
    authenticatedDioProvider.overrideWith((ref) {
      final dio = createApiDio(config)..httpClientAdapter = backend.server;
      dio.interceptors.add(AuthInterceptor(ref.watch(sessionManagerProvider), dio));
      return dio;
    }),
  ];

  /// Lance l'application sur l'écran de l'itel.
  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = itelPhysicalSize;
    tester.view.devicePixelRatio = itelPixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const ElecPayApp()));
  }

  /// Le conteneur de l'application lancée (pour lire la session, le routeur…).
  static ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ElecPayApp)));
}
