import 'package:dio/dio.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/session/auth_interceptor.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/token_store.dart';

import 'fake_server.dart';
import 'openapi.dart';

/// Stockage des jetons en mémoire, avec un délai d'écriture réglable (pour vérifier l'ordre
/// « enregistrer, PUIS rejouer »).
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.tokens]);

  StoredTokens? tokens;
  Duration writeDelay = Duration.zero;
  int writes = 0;

  @override
  Future<StoredTokens?> read() async => tokens;

  @override
  Future<void> write(StoredTokens value) async {
    await Future<void>.delayed(writeDelay);
    tokens = value;
    writes++;
  }

  @override
  Future<void> clear() async => tokens = null;
}

/// Faux backend qui applique les règles de backend/docs/AUTHENTIFICATION.md :
/// jeton d'accès `at-N`, jeton de rafraîchissement `rt-N`, rotation à chaque rafraîchissement,
/// un jeton de rafraîchissement déjà utilisé → `401 REFRESH_TOKEN_REUSED`.
class FakeAuthBackend {
  FakeAuthBackend() {
    server = FakeServer(_handle);
  }

  late final FakeServer server;
  final _api = OpenApi.load();

  int generation = 1;
  final Set<String> validAccess = {'at-1'};
  final Set<String> usedRefresh = {};
  int refreshCalls = 0;

  /// Réponse forcée pour une route (prioritaire), ex. panne réseau sur `/auth/refresh`.
  final Map<String, FakeReply> forced = {};

  /// Appelé à chaque requête protégée reçue (pour observer l'état du téléphone à cet instant).
  void Function(RequestOptions request)? onProtectedRequest;

  /// Requêtes reçues sur une route.
  List<RequestOptions> requestsTo(String path) =>
      server.requests.where((r) => r.path == path).toList();

  /// Expire tous les jetons d'accès en cours (comme 15 minutes plus tard).
  void expireAccessTokens() => validAccess.clear();

  /// Compte renvoyé par la connexion (42 par défaut, comme les jetons de [SessionHarness]).
  int loginUserId = 42;

  /// Mot de passe oublié : seul ce numéro a un compte ; codes donnés tour à tour.
  static const resetAccountPhone = '+242060000101';
  static const resetCodes = ['482913', '715204'];
  int issuedResetCodes = 0;
  String? validResetCode;

  /// Mode démo de l'API (`demo_code` renvoyé) ; `false` comme en production.
  bool demoMode = true;

  Map<String, Object?> tokenResponse(int n) => {
    ..._api.sample('TokenResponse'),
    'access_token': 'at-$n',
    'refresh_token': 'rt-$n',
    'user': {..._api.sample('UserPublic'), 'id': loginUserId},
  };

  FakeReply _handle(RequestOptions request) {
    final forcedReply = forced[request.path];
    if (forcedReply != null) return forcedReply;

    switch (request.path) {
      case '/auth/login':
        final body = request.data as Map<String, dynamic>;
        if (body['password'] != 'Demo2026!') {
          return JsonReply(
            401,
            apiError('INVALID_CREDENTIALS', 'Numéro ou mot de passe incorrect.'),
          );
        }
        validAccess.add('at-$generation');
        return JsonReply(200, tokenResponse(generation));
      case '/auth/refresh':
        refreshCalls++;
        final token = (request.data as Map<String, dynamic>)['refresh_token'] as String;
        if (usedRefresh.contains(token)) {
          return JsonReply(401, apiError('REFRESH_TOKEN_REUSED', 'Session fermée par sécurité.'));
        }
        if (token != 'rt-$generation') {
          return JsonReply(401, apiError('REFRESH_TOKEN_INVALID', 'Session expirée.'));
        }
        usedRefresh.add(token);
        generation++;
        validAccess.add('at-$generation');
        return JsonReply(200, tokenResponse(generation));
      case '/auth/logout':
        return const JsonReply(204, null);
      case '/auth/register':
        final body = request.data as Map<String, dynamic>;
        if (body['phone'] == '+242060000101') {
          return JsonReply(
            409,
            apiError('PHONE_ALREADY_USED', 'Ce numéro est déjà utilisé par un compte.'),
          );
        }
        if (body['email'] == 'pris@example.com') {
          return JsonReply(
            409,
            apiError('EMAIL_ALREADY_USED', 'Cette adresse e-mail est déjà utilisée.'),
          );
        }
        validAccess.add('at-$generation');
        return JsonReply(201, tokenResponse(generation));
      case '/auth/password/forgot':
        // Comme le backend : même réponse pour tous les numéros ; un code n'existe que pour un
        // compte, et `demo_code` n'est donné qu'en mode démo.
        final phone = (request.data as Map<String, dynamic>)['phone'];
        String? code;
        if (phone == resetAccountPhone) {
          code = resetCodes[issuedResetCodes++ % resetCodes.length];
          validResetCode = code; // un nouveau code annule le précédent
        }
        return JsonReply(200, {
          'message': "Si ce numéro correspond à un compte, un code vient d'être envoyé par SMS.",
          'expires_in': 600,
          'demo_code': demoMode ? code : null,
        });
      case '/auth/password/reset':
        final body = request.data as Map<String, dynamic>;
        if (body['phone'] != resetAccountPhone ||
            validResetCode == null ||
            body['code'] != validResetCode) {
          return JsonReply(
            400,
            apiError('RESET_CODE_INVALID', 'Code invalide ou expiré. Demandez un nouveau code.'),
          );
        }
        validResetCode = null; // utilisé
        return const JsonReply(204, null);
    }

    // Route protégée.
    onProtectedRequest?.call(request);
    final auth = request.headers['Authorization'] as String?;
    if (auth == null) {
      return JsonReply(401, apiError('NOT_AUTHENTICATED', 'Authentification requise.'));
    }
    if (!validAccess.contains(auth.replaceFirst('Bearer ', ''))) {
      return JsonReply(401, apiError('TOKEN_EXPIRED', 'Jeton expiré.'));
    }
    if (request.path == '/me/password' && request.method == 'POST') {
      final body = request.data as Map<String, dynamic>;
      if (body['current_password'] != currentPassword) {
        return JsonReply(400, apiError('WRONG_CURRENT_PASSWORD', 'Mot de passe actuel incorrect.'));
      }
      if (body['new_password'] == currentPassword) {
        return JsonReply(
          400,
          apiError('SAME_PASSWORD', "Le nouveau mot de passe doit être différent de l'actuel."),
        );
      }
      // Comme l'API : les autres sessions sont fermées, celle-ci reçoit de nouveaux jetons.
      currentPassword = body['new_password'] as String;
      validAccess.clear();
      generation++;
      validAccess.add('at-$generation');
      return JsonReply(200, tokenResponse(generation));
    }
    if (request.path == '/auth/logout-all' && request.method == 'POST') {
      // Comme l'API : TOUTES les sessions sont fermées, celle-ci comprise.
      loggedOutEverywhere = true;
      return const JsonReply(200, {'revoked_sessions': 3});
    }
    return JsonReply(200, {..._api.sample('UserPublic'), 'path': request.path});
  }

  /// Mot de passe du compte (`POST /me/password`).
  String currentPassword = 'Demo2026!';

  /// `POST /auth/logout-all` reçu.
  bool loggedOutEverywhere = false;
}

/// Une application de test : session + client protégé, branchés sur le faux backend.
class SessionHarness {
  SessionHarness({StoredTokens? stored}) : store = MemoryTokenStore(stored) {
    final config = AppConfig.parse('http://127.0.0.1:8000', release: false);
    final publicDio = createApiDio(config)..httpClientAdapter = backend.server;
    session = SessionManager(store: store, publicApi: ApiClient(publicDio));
    final dio = createApiDio(config)..httpClientAdapter = backend.server;
    dio.interceptors.add(AuthInterceptor(session, dio));
    api = ApiClient(dio);
  }

  final backend = FakeAuthBackend();
  final MemoryTokenStore store;
  late final SessionManager session;
  late final ApiClient api;

  /// Jetons de la génération `n`, comme après une connexion de l'utilisateur 42.
  static StoredTokens tokens(int n) => StoredTokens(
    accessToken: 'at-$n',
    refreshToken: 'rt-$n',
    accessExpiresAt: DateTime.utc(2026, 11, 16, 12, 30),
    userId: 42,
  );
}
