import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:elecpay/core/network/api_settings.dart';
import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';
import '../../support/openapi.dart';

final config = AppConfig.parse('http://127.0.0.1:8000', release: false);

/// Client branché sur un faux serveur.
(ApiClient, FakeServer) client(FakeReply Function(RequestOptions r) handler) {
  final server = FakeServer(handler);
  final dio = createApiDio(config)..httpClientAdapter = server;
  return (ApiClient(dio), server);
}

/// L'échec levé par `call`, pour l'inspecter.
Future<ApiFailure> failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on ApiFailure catch (failure) {
    return failure;
  }
  fail('aucune ApiFailure levée');
}

void main() {
  final profile = OpenApi.load().sample('UserPublic');

  group('réglages (un seul endroit : ApiSettings)', () {
    test('délais : 15 s pour se connecter, 30 s pour recevoir', () {
      expect(ApiSettings.connectTimeout, const Duration(seconds: 15));
      expect(ApiSettings.receiveTimeout, const Duration(seconds: 30));
      final options = createApiDio(config).options;
      expect(options.connectTimeout, ApiSettings.connectTimeout);
      expect(options.receiveTimeout, ApiSettings.receiveTimeout);
      expect(options.baseUrl, 'http://127.0.0.1:8000/api/v1');
    });

    test('le contrôle de santé utilise ce même client', () {
      final container = ProviderContainer(overrides: [appConfigProvider.overrideWithValue(config)]);
      addTearDown(container.dispose);
      final health = container.read(healthServiceProvider);
      expect(health.dio, same(container.read(apiDioProvider)));
    });
  });

  group('lecture réussie', () {
    test('GET décodé par le modèle, adresse complète', () async {
      final (api, server) = client((_) => JsonReply(200, profile));
      final me = await api.getObject('/me', UserPublic.fromJson);
      expect(me.id, 42);
      expect(server.requests.single.uri.toString(), 'http://127.0.0.1:8000/api/v1/me');
    });

    test('réponse 200 hors contrat → réponse inattendue, jamais une donnée à moitié lue', () async {
      final (api, _) = client((_) => const JsonReply(200, {'id': 'pas un nombre'}));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<UnexpectedResponse>());
      expect(failure.reference, isNotNull);
    });
  });

  group('X-Request-ID', () {
    test('chaque requête a son identifiant, au format accepté par l’API', () async {
      final (api, server) = client((_) => JsonReply(200, profile));
      for (var i = 0; i < 50; i++) {
        await api.getObject('/me', UserPublic.fromJson);
      }
      final ids = server.requests.map((r) => r.headers['X-Request-ID'] as String).toList();
      expect(ids.toSet(), hasLength(50), reason: 'tous différents');
      for (final id in ids) {
        expect(ApiSettings.safeRequestId.hasMatch(id), isTrue, reason: id);
      }
    });

    test('l’API reprend l’identifiant envoyé → c’est la référence affichée', () async {
      final (api, server) = client((_) => JsonReply(500, apiError('INTERNAL_ERROR', 'Erreur.')));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure.reference, server.requests.single.headers['X-Request-ID']);
    });

    test('l’API renvoie un autre identifiant → on affiche celui de la réponse', () async {
      final (api, _) = client(
        (_) => JsonReply(500, apiError('INTERNAL_ERROR', 'Erreur.'), requestId: 'serveur-1234'),
      );
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure.reference, 'serveur-1234');
    });

    test('aucune réponse (réseau coupé) → on garde celui envoyé', () async {
      final (api, server) = client((_) => const FailReply(DioExceptionType.connectionError));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure.reference, server.requests.single.headers['X-Request-ID']);
    });
  });

  group('échecs réseau', () {
    test('réseau coupé → hors ligne', () async {
      final (api, _) = client((_) => const FailReply(DioExceptionType.connectionError));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<NoConnection>());
      expect(failure.message, contains('Pas de connexion'));
    });

    test('erreur de socket non classée par Dio → hors ligne aussi', () async {
      final (api, _) = client(
        (_) => const FailReply(DioExceptionType.unknown, error: SocketException('refusé')),
      );
      expect(await failureOf(() => api.getObject('/me', UserPublic.fromJson)), isA<NoConnection>());
    });

    test('connexion trop longue : la requête n’a pas atteint l’API', () async {
      final (api, _) = client((_) => const FailReply(DioExceptionType.connectionTimeout));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<ApiTimeout>());
      expect((failure as ApiTimeout).mayHaveReachedServer, isFalse);
    });

    test('réponse trop longue : la requête a pu être traitée par l’API', () async {
      final (api, _) = client((_) => const FailReply(DioExceptionType.receiveTimeout));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect((failure as ApiTimeout).mayHaveReachedServer, isTrue);
      expect(failure.message, contains('trop de temps'));
    });

    test('certificat refusé → connexion non sécurisée', () async {
      final (api, _) = client((_) => const FailReply(DioExceptionType.badCertificate));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<InsecureConnection>());
    });
  });

  group('refus de l’API (format commun)', () {
    test('503 et 500 → indisponible', () async {
      for (final status in [500, 502, 503]) {
        final (api, _) = client((_) => JsonReply(status, apiError('X', 'Erreur.')));
        final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
        expect(failure, isA<ServerUnavailable>(), reason: '$status');
        expect(failure.message, contains('momentanément indisponible'));
      }
    });

    test('401 : code et message de l’API gardés', () async {
      final (api, _) = client(
        (_) => JsonReply(401, apiError('INVALID_CREDENTIALS', 'Numéro ou mot de passe incorrect.')),
      );
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<ApiRejected>());
      expect((failure as ApiRejected).code, 'INVALID_CREDENTIALS');
      expect(failure.statusCode, 401);
      expect(failure.message, 'Numéro ou mot de passe incorrect.');
    });

    test('message vide → message de secours en français selon le statut', () async {
      final (api, _) = client((_) => JsonReply(404, apiError('NOT_FOUND', ' ')));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure.message, 'Élément introuvable.');
    });

    test('429 : délai lu dans details.retry_after_seconds', () async {
      final (api, _) = client(
        (_) => JsonReply(
          429,
          apiError('TOO_MANY_ATTEMPTS', 'Trop de tentatives.', {'retry_after_seconds': 125}),
        ),
      );
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect((failure as TooManyRequests).retryAfter, const Duration(seconds: 125));
      expect(failure.message, 'Trop de tentatives. Réessayez dans 3 min.');
    });

    test('429 global : délai lu dans l’en-tête Retry-After', () async {
      final (api, _) = client(
        (_) => JsonReply(
          429,
          apiError('TOO_MANY_REQUESTS', 'Trop de requêtes.'),
          headers: {'Retry-After': '40'},
        ),
      );
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure.message, 'Trop de tentatives. Réessayez dans 40 s.');
    });

    test('422 : un type d’erreur par champ, sans le préfixe body.', () async {
      final (api, _) = client(
        (_) => JsonReply(
          422,
          apiError('VALIDATION_ERROR', 'Les données envoyées sont invalides.', {
            'fields': [
              {'field': 'body.phone', 'message': 'Field required', 'type': 'missing'},
              {'field': 'body.password', 'message': 'too short', 'type': 'string_too_short'},
            ],
          }),
        ),
      );
      final failure = await failureOf(() => api.postObject('/auth/login', UserPublic.fromJson));
      expect((failure as InvalidFields).fields, {
        'phone': 'missing',
        'password': 'string_too_short',
      });
      expect(failure.message, contains('Vérifiez les champs'));
    });

    test('4xx sans le format commun (page d’un proxy) → réponse inattendue', () async {
      final (api, _) = client((_) => const RawReply(403, '<html>Interdit</html>'));
      final failure = await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(failure, isA<UnexpectedResponse>());
      expect((failure as UnexpectedResponse).statusCode, 403);
    });
  });

  group('aucune relance automatique', () {
    for (final reply in [
      const FailReply(DioExceptionType.receiveTimeout),
      const FailReply(DioExceptionType.connectionError),
      JsonReply(503, apiError('X', 'Erreur.')),
    ]) {
      test('POST en échec (${reply.runtimeType}) : envoyé une seule fois', () async {
        final (api, server) = client((_) => reply);
        await failureOf(() => api.postNoContent('/auth/logout', body: {'refresh_token': 'x'}));
        expect(server.requests, hasLength(1));
      });
    }

    test('GET en échec : envoyé une seule fois aussi (l’écran propose « Réessayer »)', () async {
      final (api, server) = client((_) => const FailReply(DioExceptionType.connectionError));
      await failureOf(() => api.getObject('/me', UserPublic.fromJson));
      expect(server.requests, hasLength(1));
    });
  });

  group('corps envoyé sur le réseau (octets réels)', () {
    test('un modèle freezed part en JSON snake_case', () async {
      final (api, server) = client((_) => const JsonReply(204, null));
      await api.postNoContent('/auth/logout', body: const RefreshRequest(refreshToken: 'abc'));
      expect(jsonDecode(server.sentBodies.single!), {'refresh_token': 'abc'});
      expect(server.requests.single.contentType, startsWith('application/json'));
    });

    test('connexion : numéro et mot de passe en JSON, réponse lue', () async {
      final tokens = OpenApi.load().sample('TokenResponse');
      final (api, server) = client((_) => JsonReply(200, tokens));
      final result = await api.postObject(
        '/auth/login',
        LoginResult.fromJson,
        body: const LoginRequest(phone: '+242060000101', password: 'Demo2026!'),
      );
      expect(result, isA<LoginSucceeded>());
      expect(jsonDecode(server.sentBodies.single!), {
        'phone': '+242060000101',
        'password': 'Demo2026!',
      });
    });

    test('une Map part telle quelle', () async {
      final (api, server) = client((_) => const JsonReply(204, null));
      await api.postNoContent('/x', body: {'a': 1});
      expect(jsonDecode(server.sentBodies.single!), {'a': 1});
    });
  });

  group('durées d’attente lisibles', () {
    test('secondes, minutes arrondies au-dessus, heures', () {
      expect(formatWait(const Duration(seconds: 45)), '45 s');
      expect(formatWait(const Duration(seconds: 61)), '2 min');
      expect(formatWait(const Duration(minutes: 15)), '15 min');
      expect(formatWait(const Duration(hours: 1)), '1 h');
      expect(formatWait(const Duration(minutes: 90)), '1 h 30 min');
      expect(formatWait(Duration.zero), '1 s');
    });
  });
}
