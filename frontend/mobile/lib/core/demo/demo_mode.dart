import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_health.dart';

/// Mode démo de l'API (« ne jamais présenter une donnée simulée comme réelle ») :
/// - vérifié en ARRIÈRE-PLAN (`/health`), sans retarder l'arrivée sur l'accueil ;
/// - la dernière valeur connue est gardée sur le téléphone (utile hors ligne) ;
/// - tant qu'on ne sait pas, le badge « Mode démo » est AFFICHÉ (prudence).
@immutable
class DemoMode {
  const DemoMode(this.known);

  /// `null` : jamais su (premier lancement sans réseau).
  final bool? known;

  /// Le badge « Mode démo » est-il affiché ? Oui tant qu'on ne sait pas.
  bool get showBadge => known ?? true;

  @override
  bool operator ==(Object other) => other is DemoMode && other.known == known;

  @override
  int get hashCode => known.hashCode;
}

/// Où est gardée la dernière valeur connue.
abstract interface class DemoModeStore {
  Future<bool?> read();
  Future<void> write(bool demo);
}

/// Dans le stockage sécurisé du téléphone (comme les jetons ; exclu des sauvegardes).
class SecureDemoModeStore implements DemoModeStore {
  SecureDemoModeStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'elecpay.demo_mode';
  final FlutterSecureStorage _storage;

  @override
  Future<bool?> read() async {
    try {
      return switch (await _storage.read(key: key)) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    } on Object {
      return null; // illisible : on ne sait pas → badge affiché
    }
  }

  @override
  Future<void> write(bool demo) async {
    try {
      await _storage.write(key: key, value: '$demo');
    } on Object {
      // Pas grave : la valeur sera revérifiée au prochain lancement.
    }
  }
}

final demoModeStoreProvider = Provider<DemoModeStore>((ref) => SecureDemoModeStore());

class DemoModeNotifier extends Notifier<DemoMode> {
  bool _fromApi = false;

  @override
  DemoMode build() {
    unawaited(_load());
    return const DemoMode(null);
  }

  Future<void> _load() async {
    final stored = await ref.read(demoModeStoreProvider).read();
    // La réponse de l'API, si elle est déjà arrivée, l'emporte sur la valeur gardée.
    if (!_fromApi && stored != null) state = DemoMode(stored);
    await refresh();
  }

  /// Revérifie auprès de l'API ; sans réponse, la valeur connue est gardée.
  Future<void> refresh() async {
    final health = await ref.read(healthServiceProvider).check();
    if (health case ApiReachable(:final demoMode)) {
      _fromApi = true;
      state = DemoMode(demoMode);
      await ref.read(demoModeStoreProvider).write(demoMode);
    }
  }
}

final demoModeProvider = NotifierProvider<DemoModeNotifier, DemoMode>(DemoModeNotifier.new);
