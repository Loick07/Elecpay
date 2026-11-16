import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import 'auth_interceptor.dart';
import 'session_manager.dart';
import 'token_store.dart';

/// Où sont gardés les jetons (remplacé par un stockage en mémoire dans les tests).
final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// Le gestionnaire de session, unique pour toute l'application.
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    store: ref.watch(tokenStoreProvider),
    publicApi: ApiClient(ref.watch(apiDioProvider)),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// État de la session, pour les écrans (F3 : redirection vers la connexion, « session expirée »).
final sessionStateProvider = NotifierProvider<SessionStateNotifier, SessionState>(
  SessionStateNotifier.new,
);

class SessionStateNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final manager = ref.watch(sessionManagerProvider);
    void sync() => state = manager.state;
    manager.addListener(sync);
    ref.onDispose(() => manager.removeListener(sync));
    return manager.state;
  }
}

/// Client pour les routes PROTÉGÉES : jeton ajouté, expiration absorbée (rafraîchissement + rejeu).
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = createApiDio(ref.watch(appConfigProvider));
  dio.interceptors.add(AuthInterceptor(ref.watch(sessionManagerProvider), dio));
  return dio;
});

/// Le client que les écrans utilisent pour appeler l'API.
final authenticatedApiProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(authenticatedDioProvider)),
);
