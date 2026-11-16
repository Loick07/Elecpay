import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Une donnée gardée en cache, avec le moment où elle a été reçue de l'API.
@immutable
class CacheEntry {
  const CacheEntry({required this.savedAt, required this.data});

  final DateTime savedAt;
  final Map<String, dynamic> data;
}

/// Le cache hors ligne : la dernière réponse de chaque lecture, rangée PAR UTILISATEUR.
abstract interface class CacheStore {
  Future<CacheEntry?> read(int userId, String key);
  Future<void> write(int userId, String key, CacheEntry entry);
  Future<void> delete(int userId, String key);

  /// Efface tout le cache d'un utilisateur (déconnexion).
  Future<void> clearUser(int userId);

  /// Efface le cache de tous les AUTRES utilisateurs (un seul compte en cache à la fois).
  Future<void> keepOnly(int userId);
}

/// Cache en fichiers JSON dans le dossier privé de l'application (`<racine>/user-<id>/…json`),
/// inaccessible aux autres applications, exclu des sauvegardes (allowBackup, dataExtractionRules).
class FileCacheStore implements CacheStore {
  /// `root` : dossier du cache, donné à la demande (le dossier privé n'est connu qu'au lancement).
  FileCacheStore(this._root);

  final Future<Directory> Function() _root;

  Future<Directory> _userDir(int userId) async => Directory('${(await _root()).path}/user-$userId');

  /// Nom de fichier sûr pour une clé (chemin + paramètres) : base64 sans caractère spécial.
  static String fileName(String key) =>
      '${base64Url.encode(utf8.encode(key)).replaceAll('=', '')}.json';

  Future<File> _file(int userId, String key) async =>
      File('${(await _userDir(userId)).path}/${fileName(key)}');

  @override
  Future<CacheEntry?> read(int userId, String key) async {
    final file = await _file(userId, key);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CacheEntry(
        savedAt: DateTime.parse(json['saved_at'] as String),
        data: json['data'] as Map<String, dynamic>,
      );
    } on Object {
      await file.delete(); // fichier abîmé : on l'oublie
      return null;
    }
  }

  @override
  Future<void> write(int userId, String key, CacheEntry entry) async {
    final file = await _file(userId, key);
    await file.parent.create(recursive: true);
    // Écriture dans un fichier temporaire puis renommage : jamais de fichier à moitié écrit.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'saved_at': entry.savedAt.toUtc().toIso8601String(), 'data': entry.data}),
    );
    await temp.rename(file.path);
  }

  @override
  Future<void> delete(int userId, String key) async {
    final file = await _file(userId, key);
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<void> clearUser(int userId) async {
    final dir = await _userDir(userId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<void> keepOnly(int userId) async {
    final root = await _root();
    if (!root.existsSync()) return;
    await for (final entity in root.list()) {
      final name = entity.path.split(RegExp(r'[\\/]')).last;
      if (entity is Directory && name.startsWith('user-') && name != 'user-$userId') {
        await entity.delete(recursive: true);
      }
    }
  }
}

/// Le cache de l'application, dans son dossier privé (`…/offline-cache`).
final cacheStoreProvider = Provider<CacheStore>(
  (ref) => FileCacheStore(
    () async => Directory('${(await getApplicationSupportDirectory()).path}/offline-cache'),
  ),
);
