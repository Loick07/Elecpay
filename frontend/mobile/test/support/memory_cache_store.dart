import 'package:elecpay/core/cache/cache_store.dart';

/// Cache en mémoire pour les tests (même règles que le cache en fichiers).
class MemoryCacheStore implements CacheStore {
  final Map<int, Map<String, CacheEntry>> users = {};
  bool failWrites = false;

  @override
  Future<CacheEntry?> read(int userId, String key) async => users[userId]?[key];

  @override
  Future<void> write(int userId, String key, CacheEntry entry) async {
    if (failWrites) throw StateError('téléphone plein');
    (users[userId] ??= {})[key] = entry;
  }

  @override
  Future<void> delete(int userId, String key) async => users[userId]?.remove(key);

  @override
  Future<void> clearUser(int userId) async => users.remove(userId);

  @override
  Future<void> keepOnly(int userId) async => users.removeWhere((id, _) => id != userId);
}
