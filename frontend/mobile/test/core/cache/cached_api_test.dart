import 'package:dio/dio.dart';
import 'package:elecpay/core/cache/cache_store.dart';
import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/models/households.dart';
import 'package:elecpay/core/network/api_client.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/features/auth/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';
import '../../support/memory_cache_store.dart';
import '../../support/openapi.dart';

/// 16/11/2026 à 12:20 UTC, soit 13:20 à Brazzaville.
final now = DateTime.utc(2026, 11, 16, 12, 20);

class Harness {
  Harness() {
    final dio = createApiDio(AppConfig.parse('http://127.0.0.1:8000', release: false))
      ..httpClientAdapter = server;
    cached = CachedApi(
      api: ApiClient(dio),
      store: store,
      currentUserId: () async => userId,
      clock: () => clock,
    );
  }

  FakeReply reply = JsonReply(200, profile);
  late final server = FakeServer((_) => reply);
  final store = MemoryCacheStore();
  late final CachedApi cached;
  int? userId = 42;
  DateTime clock = now;

  static final profile = OpenApi.load().sample('UserPublic');

  Future<Fetched<UserPublic>> me([String path = '/me']) => cached.get(path, UserPublic.fromJson);
}

Future<ApiFailure> failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on ApiFailure catch (failure) {
    return failure;
  }
  fail('aucune ApiFailure levée');
}

void main() {
  group('en ligne', () {
    test('donnée fraîche, et cache mis à jour avec sa date', () async {
      final h = Harness();
      final result = await h.me();
      expect(result, isA<FreshData<UserPublic>>());
      expect(result.data.id, 42);
      final entry = h.store.users[42]!['/me']!;
      expect(entry.savedAt, now);
      expect(entry.data['full_name'], Harness.profile['full_name']);
    });

    test('clé = chemin + paramètres triés (deux filtres = deux entrées)', () {
      expect(
        CachedApi.cacheKey('/bills', {'status': 'unpaid', 'page': 2}),
        '/bills?page=2&status=unpaid',
      );
      expect(CachedApi.cacheKey('/bills'), '/bills');
    });

    test('écriture du cache impossible : la donnée fraîche est rendue quand même', () async {
      final h = Harness()..store.failWrites = true;
      expect(await h.me(), isA<FreshData<UserPublic>>());
    });

    test('sans session (aucun utilisateur) : rien n’est gardé', () async {
      final h = Harness()..userId = null;
      await h.me();
      expect(h.store.users, isEmpty);
    });
  });

  group('hors ligne', () {
    for (final (name, failure) in [
      ('réseau coupé', const FailReply(DioExceptionType.connectionError) as FakeReply),
      ('délai dépassé', const FailReply(DioExceptionType.receiveTimeout)),
      ('API en panne (503)', JsonReply(503, apiError('X', 'Erreur.'))),
    ]) {
      test('$name : dernière version + « Hors connexion. Les données… »', () async {
        final h = Harness();
        await h.me();
        h
          ..reply = failure
          ..clock = now.add(const Duration(hours: 3));
        final result = await h.me();
        expect(result, isA<CachedData<UserPublic>>());
        final cached = result as CachedData<UserPublic>;
        expect(cached.data.id, 42);
        expect(cached.savedAt, now);
        expect(cached.label, 'Hors connexion. Les données affichées datent du 16 nov. à 13:20.');
      });
    }

    test(
      'rien en cache : l’échec « hors ligne » remonte (l’écran affiche l’état hors ligne)',
      () async {
        final h = Harness()..reply = const FailReply(DioExceptionType.connectionError);
        expect(await failureOf(h.me), isA<NoConnection>());
      },
    );

    test('donnée de plus de 30 jours : plus montrée, et effacée', () async {
      final h = Harness();
      await h.me();
      h
        ..reply = const FailReply(DioExceptionType.connectionError)
        ..clock = now.add(const Duration(days: 30, minutes: 1));
      expect(await failureOf(h.me), isA<NoConnection>());
      expect(h.store.users[42], isEmpty);
    });

    test('donnée d’exactement 30 jours : encore montrée', () async {
      final h = Harness();
      await h.me();
      h
        ..reply = const FailReply(DioExceptionType.connectionError)
        ..clock = now.add(CachedApi.maxAge);
      expect(await h.me(), isA<CachedData<UserPublic>>());
    });

    test('donnée illisible (ancienne version de l’application) : oubliée, échec remonté', () async {
      final h = Harness();
      await h.store.write(42, '/me', CacheEntry(savedAt: now, data: {'autre': 'format'}));
      h.reply = const FailReply(DioExceptionType.connectionError);
      expect(await failureOf(h.me), isA<NoConnection>());
      expect(h.store.users[42], isEmpty);
    });
  });

  group('le cache ne masque jamais un refus de l’API', () {
    for (final (status, code) in [(403, 'FORBIDDEN'), (404, 'NOT_FOUND'), (401, 'TOKEN_INVALID')]) {
      test('$status $code : refus remonté, pas la donnée du cache', () async {
        final h = Harness();
        await h.me();
        h.reply = JsonReply(status, apiError(code, 'Refusé.'));
        expect(await failureOf(h.me), isA<ApiRejected>());
      });
    }
  });

  group('tableau (getList, ex. GET /households)', () {
    final household = OpenApi.load().sample('HouseholdSummary');
    Future<Fetched<List<HouseholdSummary>>> households(Harness h) =>
        h.cached.getList('/households', HouseholdSummary.fromJson);

    test('donnée fraîche, rangée en cache sous {"items": […]}', () async {
      final h = Harness()
        ..reply = JsonReply(200, [
          household,
          {...household, 'id': 7},
        ]);
      final result = await households(h);
      expect(result, isA<FreshData<List<HouseholdSummary>>>());
      expect(result.data.map((f) => f.id), [42, 7]);
      expect((h.store.users[42]!['/households']!.data['items'] as List).length, 2);
    });

    test('hors ligne : la dernière liste, avec sa date', () async {
      final h = Harness()..reply = JsonReply(200, [household]);
      await households(h);
      h.reply = const FailReply(DioExceptionType.connectionError);
      final result = await households(h);
      expect(result, isA<CachedData<List<HouseholdSummary>>>());
      expect(result.data.single.id, 42);
    });

    test('liste vide : rendue vide (aucun foyer), pas une erreur', () async {
      final h = Harness()..reply = const JsonReply(200, <Object>[]);
      expect((await households(h)).data, isEmpty);
    });

    test('un refus de l’API n’est jamais masqué par le cache', () async {
      final h = Harness()..reply = JsonReply(200, [household]);
      await households(h);
      h.reply = JsonReply(403, apiError('FORBIDDEN', 'Refusé.'));
      expect(await failureOf(() => households(h)), isA<ApiRejected>());
    });

    test('un objet au lieu d’un tableau (contrat non respecté) : réponse inattendue', () async {
      final h = Harness()..reply = JsonReply(200, household);
      expect(await failureOf(() => households(h)), isA<UnexpectedResponse>());
    });
  });

  group('rangé par utilisateur', () {
    test('le cache d’un compte n’est jamais montré à un autre', () async {
      final h = Harness();
      await h.me(); // utilisateur 42
      h
        ..userId = 7
        ..reply = const FailReply(DioExceptionType.connectionError);
      expect(await failureOf(h.me), isA<NoConnection>());
      expect(h.store.users.keys, [42]);
    });
  });

  group('jamais mis en cache', () {
    test('GET /payments/{id} : jamais écrit, jamais lu hors ligne', () async {
      final h = Harness()..reply = const JsonReply(200, {'id': 9, 'status': 'en_attente'});
      await h.cached.get('/payments/9', (json) => json);
      expect(h.store.users, isEmpty);

      // Même si une entrée existait (ancienne version), elle n'est pas servie.
      await h.store.write(42, '/payments/9', CacheEntry(savedAt: now, data: {'status': 'reussie'}));
      h.reply = const FailReply(DioExceptionType.connectionError);
      expect(
        await failureOf(() => h.cached.get('/payments/9', (json) => json)),
        isA<NoConnection>(),
      );
    });

    test('vérification publique d’un reçu : jamais écrite', () async {
      final h = Harness()..reply = const JsonReply(200, {'valid': true});
      await h.cached.get('/receipts/verify/ABCD2345EFGH', (json) => json);
      expect(h.store.users, isEmpty);
    });
  });
}
