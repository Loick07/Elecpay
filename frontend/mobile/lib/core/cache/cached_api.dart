// Paramètres nommés publics, champs privés : Dart n'accepte pas `this._champ` pour un paramètre nommé.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format/dates.dart';
import '../network/api_client.dart';
import '../network/api_failure.dart';
import '../session/session_providers.dart';
import 'cache_policy.dart';
import 'cache_store.dart';

/// Résultat d'une lecture : donnée fraîche de l'API, ou dernière version gardée (hors ligne).
@immutable
sealed class Fetched<T> {
  const Fetched(this.data);

  final T data;
}

/// Reçue de l'API à l'instant.
final class FreshData<T> extends Fetched<T> {
  const FreshData(super.data);
}

/// Lue dans le cache car l'API est injoignable : l'écran affiche [label].
final class CachedData<T> extends Fetched<T> {
  const CachedData(
    super.data, {
    required this.savedAt,
    required this.failure,
    required this.shownAt,
  });

  /// Moment où la donnée a été reçue de l'API.
  final DateTime savedAt;

  /// Pourquoi l'API n'a pas répondu (hors ligne, délai dépassé, panne).
  final ApiFailure failure;

  /// Moment où la donnée est montrée (l'année n'est écrite que si elle a changé depuis).
  final DateTime shownAt;

  /// Texte de la charte : « Hors connexion. Les données affichées datent du 12 nov. à 08:15. »
  String get label => offlineLabel(savedAt, now: shownAt);
}

/// Lectures avec cache hors ligne. Seules les routes de [cacheableRoutes] sont gardées ; les écritures
/// ne passent JAMAIS par ici (aucune action hors ligne, aucune file d'attente d'actions).
class CachedApi {
  CachedApi({
    required ApiClient api,
    required CacheStore store,
    required Future<int?> Function() currentUserId,
    DateTime Function()? clock,
  }) : _api = api,
       _store = store,
       _currentUserId = currentUserId,
       _clock = clock ?? DateTime.now;

  /// Au-delà, une donnée du cache n'est plus montrée (et elle est effacée).
  static const maxAge = Duration(days: 30);

  final ApiClient _api;
  final CacheStore _store;
  final Future<int?> Function() _currentUserId;
  final DateTime Function() _clock;

  /// Clé d'une lecture : chemin + paramètres triés (`/bills?page=2&status=unpaid`).
  static String cacheKey(String path, [Map<String, Object?>? query]) {
    if (query == null || query.isEmpty) return path;
    final keys = query.keys.toList()..sort();
    return '$path?${keys.map((k) => '$k=${query[k]}').join('&')}';
  }

  /// Lit `path` : depuis l'API (et met le cache à jour), sinon depuis le cache si l'API est
  /// injoignable. Un refus de l'API (403, 404, session expirée…) n'est JAMAIS masqué par le cache.
  Future<Fetched<T>> get<T>(
    String path,
    T Function(Map<String, dynamic> json) decode, {
    Map<String, Object?>? query,
  }) async {
    final key = cacheKey(path, query);
    final cacheable = isCacheable(path);
    late Map<String, dynamic> raw;
    try {
      final value = await _api.getObject(path, (json) {
        raw = json;
        return decode(json);
      }, query: query);
      if (cacheable) await _save(key, raw);
      return FreshData(value);
    } on ApiFailure catch (failure) {
      if (!cacheable || !_apiUnreachable(failure)) rethrow;
      final fromCache = await _load(key, decode, failure);
      if (fromCache == null) rethrow;
      return fromCache;
    }
  }

  static bool _apiUnreachable(ApiFailure failure) =>
      failure is NoConnection || failure is ApiTimeout || failure is ServerUnavailable;

  Future<void> _save(String key, Map<String, dynamic> data) async {
    final userId = await _currentUserId();
    if (userId == null) return;
    try {
      await _store.write(userId, key, CacheEntry(savedAt: _clock().toUtc(), data: data));
    } on Object {
      // Écriture impossible (téléphone plein…) : la donnée fraîche est affichée quand même.
    }
  }

  Future<CachedData<T>?> _load<T>(
    String key,
    T Function(Map<String, dynamic> json) decode,
    ApiFailure failure,
  ) async {
    final userId = await _currentUserId();
    if (userId == null) return null;
    final entry = await _store.read(userId, key);
    if (entry == null) return null;
    if (_clock().toUtc().difference(entry.savedAt) > maxAge) {
      await _store.delete(userId, key);
      return null;
    }
    try {
      return CachedData(
        decode(entry.data),
        savedAt: entry.savedAt,
        failure: failure,
        shownAt: _clock().toUtc(),
      );
    } on Object {
      // Donnée d'une ancienne version de l'application, illisible : oubliée.
      await _store.delete(userId, key);
      return null;
    }
  }
}

/// Lectures des écrans, avec le cache hors ligne de l'utilisateur connecté.
final cachedApiProvider = Provider<CachedApi>(
  (ref) => CachedApi(
    api: ref.watch(authenticatedApiProvider),
    store: ref.watch(cacheStoreProvider),
    currentUserId: () async => (await ref.read(sessionManagerProvider).currentTokens())?.userId,
  ),
);
