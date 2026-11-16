import 'package:dio/dio.dart';
import 'package:elecpay/core/cache/cache_store.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/session/auth_interceptor.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_backend.dart';
import '../../support/fake_server.dart';
import '../../support/memory_cache_store.dart';

/// Le vrai branchement de l'application (providers), avec un faux backend et des stockages en mémoire.
void main() {
  final config = AppConfig.parse('http://127.0.0.1:8000', release: false);
  final entry = CacheEntry(savedAt: DateTime.utc(2026, 11, 16), data: {'id': 1});

  (ProviderContainer, MemoryCacheStore, FakeAuthBackend) app({bool loggedIn = false}) {
    final backend = FakeAuthBackend();
    final cache = MemoryCacheStore();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        apiDioProvider.overrideWithValue(createApiDio(config)..httpClientAdapter = backend.server),
        tokenStoreProvider.overrideWithValue(
          MemoryTokenStore(loggedIn ? SessionHarness.tokens(1) : null),
        ),
        cacheStoreProvider.overrideWithValue(cache),
        // Le client des écrans, branché lui aussi sur le faux backend (jamais sur le réseau).
        authenticatedDioProvider.overrideWith((ref) {
          final dio = createApiDio(config)..httpClientAdapter = backend.server;
          dio.interceptors.add(AuthInterceptor(ref.watch(sessionManagerProvider), dio));
          return dio;
        }),
      ],
    );
    addTearDown(container.dispose);
    return (container, cache, backend);
  }

  test('déconnexion : le cache de l’utilisateur est effacé', () async {
    final (container, cache, _) = app(loggedIn: true);
    await cache.write(42, '/me', entry);
    await container.read(sessionManagerProvider).logout();
    expect(cache.users, isEmpty);
  });

  test('déconnexion sans réseau : le cache est effacé quand même', () async {
    final (container, cache, backend) = app(loggedIn: true);
    await cache.write(42, '/me', entry);
    backend.forced['/auth/logout'] = const FailReply(DioExceptionType.connectionError);
    await container.read(sessionManagerProvider).logout();
    expect(backend.requestsTo('/auth/logout'), hasLength(1));
    expect(cache.users, isEmpty);
  });

  test('connexion : le cache d’un AUTRE compte est effacé, celui du compte est gardé', () async {
    final (container, cache, _) = app();
    await cache.write(7, '/me', entry);
    await cache.write(42, '/me', entry);
    await container
        .read(sessionManagerProvider)
        .login(const LoginRequest(phone: '+242060000101', password: 'Demo2026!'));
    expect(cache.users.keys, [42]);
  });

  test('session expirée : le cache est gardé (reconnexion du même utilisateur)', () async {
    final (container, cache, _) = app(loggedIn: true);
    await cache.write(42, '/me', entry);
    final session = container.read(sessionManagerProvider);
    await session.currentTokens();
    await session.end(SessionEndReason.expired);
    expect(cache.users.keys, [42]);
  });

  group('session expirée : rien ne s’affiche avant la reconnexion du MÊME compte', () {
    const login = LoginRequest(phone: '+242060000101', password: 'Demo2026!');

    /// L'application réelle, connectée (utilisateur 42).
    (ProviderContainer, MemoryCacheStore, FakeAuthBackend) appWithScreens() => app(loggedIn: true);

    Future<Fetched<UserPublic>> readMe(ProviderContainer c) =>
        c.read(cachedApiProvider).get('/me', UserPublic.fromJson);

    Future<Object?> outcome(ProviderContainer c) async {
      try {
        return await readMe(c);
      } on ApiFailure catch (failure) {
        return failure;
      }
    }

    test('hors ligne après expiration : aucune donnée, même si le cache existe', () async {
      final (c, cache, backend) = appWithScreens();
      expect(await readMe(c), isA<FreshData<UserPublic>>()); // en ligne : cache écrit
      expect(cache.users[42], isNotEmpty);

      await c.read(sessionManagerProvider).end(SessionEndReason.expired);
      backend.forced['/me'] = const FailReply(DioExceptionType.connectionError);

      expect(await outcome(c), isA<NoConnection>(), reason: 'pas de CachedData sans session');
      expect(cache.users[42], isNotEmpty, reason: 'cache gardé pour la reconnexion');
    });

    test('reconnexion du même compte : le cache réapparaît hors ligne', () async {
      final (c, cache, backend) = appWithScreens();
      await readMe(c);
      await c.read(sessionManagerProvider).end(SessionEndReason.expired);
      backend.forced['/me'] = const FailReply(DioExceptionType.connectionError);

      await c.read(sessionManagerProvider).login(login);
      expect(await outcome(c), isA<CachedData<UserPublic>>());
    });

    test('reconnexion d’un AUTRE compte : le cache précédent est effacé, jamais montré', () async {
      final (c, cache, backend) = appWithScreens();
      await readMe(c);
      await c.read(sessionManagerProvider).end(SessionEndReason.expired);
      backend
        ..forced['/me'] = const FailReply(DioExceptionType.connectionError)
        ..loginUserId = 7;

      await c.read(sessionManagerProvider).login(login);
      expect(cache.users.containsKey(42), isFalse);
      expect(await outcome(c), isA<NoConnection>());
    });
  });
}
