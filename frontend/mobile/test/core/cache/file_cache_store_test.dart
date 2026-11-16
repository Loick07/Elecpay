import 'dart:io';

import 'package:elecpay/core/cache/cache_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Dossier de test DANS le projet (build/ est ignoré par git), effacé après chaque test.
  final root = Directory('build/test-offline-cache');
  late FileCacheStore store;
  final entry = CacheEntry(savedAt: DateTime.utc(2026, 11, 16, 12, 20), data: {'id': 42});

  setUp(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
    store = FileCacheStore(() async => root);
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('écrit puis relit à l’identique (date en UTC)', () async {
    await store.write(42, '/bills?page=2', entry);
    final read = await store.read(42, '/bills?page=2');
    expect(read!.savedAt, entry.savedAt);
    expect(read.savedAt.isUtc, isTrue);
    expect(read.data, {'id': 42});
  });

  test('un dossier par utilisateur ; un compte ne lit pas le cache d’un autre', () async {
    await store.write(42, '/me', entry);
    expect(Directory('${root.path}/user-42').existsSync(), isTrue);
    expect(await store.read(7, '/me'), isNull);
  });

  test('nom de fichier sûr, quelle que soit la clé (/, ?, &, =)', () {
    final name = FileCacheStore.fileName('/meters/5/consumption?from=2026-01-01&to=2026-11-16');
    expect(name, matches(RegExp(r'^[A-Za-z0-9_-]+\.json$')));
  });

  test('déconnexion : tout le cache de l’utilisateur est effacé', () async {
    await store.write(42, '/me', entry);
    await store.write(42, '/bills', entry);
    await store.clearUser(42);
    expect(Directory('${root.path}/user-42').existsSync(), isFalse);
  });

  test('nouvelle connexion : le cache des autres comptes est effacé', () async {
    await store.write(42, '/me', entry);
    await store.write(7, '/me', entry);
    await store.write(142, '/me', entry); // « user-142 » se termine par « 42 » : ne pas confondre
    await store.keepOnly(42);
    expect(await store.read(42, '/me'), isNotNull);
    expect(await store.read(7, '/me'), isNull);
    expect(await store.read(142, '/me'), isNull);
  });

  test('fichier abîmé : ignoré et supprimé', () async {
    await store.write(42, '/me', entry);
    final file = File('${root.path}/user-42/${FileCacheStore.fileName('/me')}')
      ..writeAsStringSync('{abîmé');
    expect(await store.read(42, '/me'), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('aucun fichier temporaire laissé après écriture', () async {
    await store.write(42, '/me', entry);
    final files = Directory('${root.path}/user-42').listSync().map((f) => f.path);
    expect(files.where((p) => p.endsWith('.tmp')), isEmpty);
  });
}
