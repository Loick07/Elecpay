import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// Réglages de l'appareil (D9.1) : thème et « Effet verre », gardés d'un lancement à l'autre dans
// un petit fichier JSON du dossier PRIVÉ de l'application (`path_provider`, sans nouveau paquet).
// Ils ne dépendent pas du compte : ils restent après une déconnexion, hors du cache par utilisateur.

/// Thème choisi (écran 14, « Affichage »). D9.2 : Nuit par défaut (la charte est pensée en navy).
enum ThemeChoice {
  night('Nuit'),
  day('Jour'),
  auto('Auto');

  const ThemeChoice(this.label);

  final String label;
}

@immutable
class AppSettings {
  const AppSettings({this.theme = ThemeChoice.night, this.glass = false});

  /// Lecture tolérante : une valeur inconnue ou absente prend sa valeur par défaut.
  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
    theme:
        ThemeChoice.values.where((t) => t.name == json['theme']).firstOrNull ?? ThemeChoice.night,
    glass: json['glass'] == true,
  );

  final ThemeChoice theme;

  /// « Effet verre » : flou de la barre du bas et des feuilles. Désactivé par défaut (mesuré sur
  /// l'itel : 12 ms par image sans flou, 40 ms avec).
  final bool glass;

  AppSettings copyWith({ThemeChoice? theme, bool? glass}) =>
      AppSettings(theme: theme ?? this.theme, glass: glass ?? this.glass);

  Map<String, Object?> toJson() => {'theme': theme.name, 'glass': glass};

  @override
  bool operator ==(Object other) =>
      other is AppSettings && other.theme == theme && other.glass == glass;

  @override
  int get hashCode => Object.hash(theme, glass);
}

/// Où sont gardés les réglages.
abstract interface class SettingsStore {
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?> json);
}

/// Fichier `settings.json` du dossier de support de l'application (privé, exclu des sauvegardes
/// Android comme le reste : `allowBackup="false"`).
class FileSettingsStore implements SettingsStore {
  Future<File> _file() async => File(
    '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}settings.json',
  );

  @override
  Future<Map<String, Object?>?> read() async {
    final file = await _file();
    if (!file.existsSync()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, Object?>;
  }

  @override
  Future<void> write(Map<String, Object?> json) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(json), flush: true);
  }
}

final settingsStoreProvider = Provider<SettingsStore>((ref) => FileSettingsStore());

/// Réglages courants. Au démarrage : les valeurs par défaut tout de suite, puis celles du fichier
/// dès qu'il est lu (jamais d'attente sur l'écran). Fichier illisible : valeurs par défaut.
class AppSettingsNotifier extends Notifier<AppSettings> {
  bool _changed = false;

  @override
  AppSettings build() {
    unawaited(_load());
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final json = await ref.read(settingsStoreProvider).read();
      // Un choix fait pendant la lecture l'emporte sur le fichier.
      if (json != null && !_changed) state = AppSettings.fromJson(json);
    } on Object {
      // Fichier absent, abîmé, ou pas de dossier (tests) : valeurs par défaut.
    }
  }

  Future<void> _save(AppSettings next) async {
    _changed = true;
    state = next;
    try {
      await ref.read(settingsStoreProvider).write(next.toJson());
    } on Object {
      // Non enregistré : le réglage vaut pour cette ouverture de l'application.
    }
  }

  Future<void> setTheme(ThemeChoice theme) => _save(state.copyWith(theme: theme));

  Future<void> setGlass(bool glass) => _save(state.copyWith(glass: glass));
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Réglages gardés en mémoire (tests, et repli).
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.saved]);

  Map<String, Object?>? saved;
  int writes = 0;

  @override
  Future<Map<String, Object?>?> read() async => saved;

  @override
  Future<void> write(Map<String, Object?> json) async {
    saved = json;
    writes++;
  }
}
