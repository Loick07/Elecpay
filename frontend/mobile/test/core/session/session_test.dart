import 'package:dio/dio.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_backend.dart';
import '../../support/fake_server.dart';

Future<Map<String, dynamic>> me(SessionHarness h, [String path = '/me']) =>
    h.api.getObject(path, (json) => json);

Future<ApiFailure> failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on ApiFailure catch (failure) {
    return failure;
  }
  fail('aucune ApiFailure levée');
}

void main() {
  group('démarrage', () {
    test('aucun jeton enregistré → session terminée (aucune)', () async {
      final h = SessionHarness();
      expect(h.session.state, isA<SessionUnknown>());
      expect(await h.session.currentTokens(), isNull);
      expect(h.session.state, const SessionEnded(SessionEndReason.none));
    });

    test('jetons enregistrés → session active, jeton envoyé', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      await me(h);
      expect(h.session.state, const SessionActive(42));
      expect(h.backend.requestsTo('/me').single.headers['Authorization'], 'Bearer at-1');
    });
  });

  group('connexion', () {
    test('réussie : jetons enregistrés, session active', () async {
      final h = SessionHarness();
      final result = await h.session.login(
        const LoginRequest(phone: '+242060000101', password: 'Demo2026!'),
      );
      expect(result, isA<LoginSucceeded>());
      expect(h.store.tokens!.accessToken, 'at-1');
      expect(h.session.state, const SessionActive(42));
      expect(
        h.backend.requestsTo('/auth/login').single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test(
      'mauvais mot de passe : refus de l’API, aucune session, pas de « session expirée »',
      () async {
        final h = SessionHarness();
        final failure = await failureOf(
          () => h.session.login(const LoginRequest(phone: '+242060000101', password: 'faux')),
        );
        expect((failure as ApiRejected).code, 'INVALID_CREDENTIALS');
        expect(h.store.tokens, isNull);
      },
    );

    test('défi 2FA (compte de l’équipe) : aucune session ouverte', () async {
      final h = SessionHarness();
      h.backend.forced['/auth/login'] = const JsonReply(200, {
        'two_factor_required': true,
        'challenge_token': 'defi',
        'expires_at': '2026-11-16T12:30:00Z',
      });
      final result = await h.session.login(
        const LoginRequest(phone: '+242060000002', password: 'Demo2026!'),
      );
      expect(result, isA<LoginNeedsTwoFactor>());
      expect(h.store.tokens, isNull);
    });
  });

  group('jeton expiré : rafraîchissement puis rejeu', () {
    test('une requête : 1 rafraîchissement, rejouée avec le nouveau jeton', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.expireAccessTokens();
      final body = await me(h);
      expect(body['id'], 42);
      expect(h.backend.refreshCalls, 1);
      final calls = h.backend.requestsTo('/me');
      expect(calls.map((r) => r.headers['Authorization']), ['Bearer at-1', 'Bearer at-2']);
      expect(h.store.tokens, SessionHarness.tokens(2));
    });

    test('5 requêtes simultanées : UN SEUL rafraîchissement, les 5 réussissent', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.expireAccessTokens();
      final results = await Future.wait([for (var i = 0; i < 5; i++) me(h, '/me/$i')]);
      expect(results, hasLength(5));
      expect(h.backend.refreshCalls, 1);
      expect(h.backend.usedRefresh, {'rt-1'});
      expect(h.session.state, const SessionActive(42));
    });

    test('les nouveaux jetons sont ENREGISTRÉS avant le rejeu', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.store.writeDelay = const Duration(milliseconds: 50); // stockage lent
      h.backend.expireAccessTokens();
      final storedAtEachCall = <String?>[];
      h.backend.onProtectedRequest = (_) => storedAtEachCall.add(h.store.tokens?.accessToken);
      await me(h);
      // 1er appel : ancien jeton enregistré ; rejeu : le NOUVEAU est déjà enregistré.
      expect(storedAtEachCall, ['at-1', 'at-2']);
    });

    test(
      'jeton déjà remplacé par un autre rafraîchissement : pas de second rafraîchissement',
      () async {
        final h = SessionHarness(stored: SessionHarness.tokens(1));
        h.backend.expireAccessTokens();
        await me(h); // rafraîchit : at-2
        final token = await h.session.freshAccessToken(failedAccessToken: 'at-1');
        expect(token, 'at-2');
        expect(h.backend.refreshCalls, 1);
      },
    );

    test('POST rejoué une seule fois, avec le même corps et la même clé d’idempotence', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.expireAccessTokens();
      await h.api.postObject(
        '/payments',
        (json) => json,
        body: {'bill_id': 7},
        headers: {'Idempotency-Key': 'cle-123'},
      );
      final calls = h.backend.requestsTo('/payments');
      expect(calls, hasLength(2));
      for (final call in calls) {
        expect(call.headers['Idempotency-Key'], 'cle-123');
        expect(call.data, {'bill_id': 7});
      }
    });

    test('rejeu encore refusé (TOKEN_EXPIRED) : pas de boucle, session terminée', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.forced['/me'] = JsonReply(401, apiError('TOKEN_EXPIRED', 'Jeton expiré.'));
      final failure = await failureOf(() => me(h));
      expect(failure, isA<SessionExpired>());
      expect(h.backend.refreshCalls, 1);
      expect(h.backend.requestsTo('/me'), hasLength(2));
      expect(h.store.tokens, isNull);
    });
  });

  group('fin de session', () {
    test(
      'rafraîchissement refusé : jetons effacés, « session expirée », requête non rejouée',
      () async {
        final h = SessionHarness(stored: SessionHarness.tokens(1));
        h.backend.expireAccessTokens();
        h.backend.usedRefresh.add('rt-1'); // déjà utilisé ailleurs
        final failure = await failureOf(() => me(h));
        expect(failure, isA<SessionExpired>());
        expect(failure.message, contains('session a expiré'));
        expect(h.store.tokens, isNull);
        expect(h.session.state, const SessionEnded(SessionEndReason.expired));
        expect(h.backend.requestsTo('/me'), hasLength(1));
      },
    );

    for (final code in ['TOKEN_INVALID', 'REFRESH_TOKEN_REUSED', 'NOT_AUTHENTICATED']) {
      test('401 $code : session terminée sans tenter de rafraîchir', () async {
        final h = SessionHarness(stored: SessionHarness.tokens(1));
        h.backend.forced['/me'] = JsonReply(401, apiError(code, 'Refusé.'));
        final failure = await failureOf(() => me(h));
        expect(failure, isA<SessionExpired>());
        expect(h.backend.refreshCalls, 0);
        expect(h.session.state, const SessionEnded(SessionEndReason.expired));
      });
    }

    test('autre refus (403, 404…) : la session n’est pas touchée', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.forced['/me'] = JsonReply(403, apiError('FORBIDDEN', 'Accès refusé.'));
      final failure = await failureOf(() => me(h));
      expect((failure as ApiRejected).code, 'FORBIDDEN');
      expect(h.store.tokens, isNotNull);
    });
  });

  group('sans réseau', () {
    test('rafraîchissement impossible : session GARDÉE, échec « hors ligne »', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.expireAccessTokens();
      h.backend.forced['/auth/refresh'] = const FailReply(DioExceptionType.connectionError);
      final failure = await failureOf(() => me(h));
      expect(failure, isA<NoConnection>());
      expect(h.store.tokens, SessionHarness.tokens(1));
      expect(h.session.state, const SessionActive(42));
    });

    test('requête protégée hors ligne : aucune relance, session gardée', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.forced['/payments'] = const FailReply(DioExceptionType.receiveTimeout);
      final failure = await failureOf(() => h.api.postObject('/payments', (j) => j, body: {}));
      expect((failure as ApiTimeout).mayHaveReachedServer, isTrue);
      expect(h.backend.requestsTo('/payments'), hasLength(1));
      expect(h.store.tokens, isNotNull);
    });
  });

  group('déconnexion', () {
    test('prévient l’API (jeton de rafraîchissement, sans jeton d’accès) et efface tout', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      await h.session.logout();
      final call = h.backend.requestsTo('/auth/logout').single;
      expect(call.data, {'refresh_token': 'rt-1'});
      expect(call.headers.containsKey('Authorization'), isFalse);
      expect(h.store.tokens, isNull);
      expect(h.session.state, const SessionEnded(SessionEndReason.loggedOut));
    });

    test('sans réseau : tout est effacé quand même', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      h.backend.forced['/auth/logout'] = const FailReply(DioExceptionType.connectionError);
      await h.session.logout();
      expect(h.store.tokens, isNull);
      expect(h.session.state, const SessionEnded(SessionEndReason.loggedOut));
    });

    test('après déconnexion, une requête protégée part sans jeton', () async {
      final h = SessionHarness(stored: SessionHarness.tokens(1));
      await h.session.logout();
      await failureOf(() => me(h));
      expect(h.backend.requestsTo('/me').single.headers.containsKey('Authorization'), isFalse);
    });
  });

  test('l’état est annoncé aux écrans à chaque changement', () async {
    final h = SessionHarness();
    final states = <SessionState>[];
    h.session.addListener(() => states.add(h.session.state));
    await h.session.currentTokens();
    await h.session.login(const LoginRequest(phone: '+242060000101', password: 'Demo2026!'));
    await h.session.logout();
    expect(states, [
      const SessionEnded(SessionEndReason.none),
      const SessionActive(42),
      const SessionEnded(SessionEndReason.loggedOut),
    ]);
  });
}
