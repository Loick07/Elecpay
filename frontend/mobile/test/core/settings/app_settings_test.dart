import 'package:elecpay/core/settings/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer containerWith(SettingsStore store) {
  final c = ProviderContainer(overrides: [settingsStoreProvider.overrideWithValue(store)]);
  addTearDown(c.dispose);
  return c;
}

class _BrokenStore implements SettingsStore {
  @override
  Future<Map<String, Object?>?> read() async => throw const FormatException('fichier abîmé');

  @override
  Future<void> write(Map<String, Object?> json) async => throw const FormatException('disque');
}

void main() {
  test('par défaut (D9.2) : Nuit, sans effet verre', () {
    expect(const AppSettings(), const AppSettings(theme: ThemeChoice.night, glass: false));
    expect(ThemeChoice.values.map((t) => t.label), ['Nuit', 'Jour', 'Auto']);
  });

  test('lecture tolérante : valeur inconnue → valeur par défaut', () {
    expect(AppSettings.fromJson({'theme': 'violet', 'glass': 'oui'}), const AppSettings());
    expect(
      AppSettings.fromJson({'theme': 'day', 'glass': true}),
      const AppSettings(theme: ThemeChoice.day, glass: true),
    );
  });

  test('gardés d’un lancement à l’autre (fichier relu au démarrage)', () async {
    final store = MemorySettingsStore();
    final first = containerWith(store);
    first.read(appSettingsProvider);
    await first.read(appSettingsProvider.notifier).setTheme(ThemeChoice.auto);
    await first.read(appSettingsProvider.notifier).setGlass(true);
    expect(store.saved, {'theme': 'auto', 'glass': true});

    final second = containerWith(store);
    expect(second.read(appSettingsProvider), const AppSettings(), reason: 'tout de suite');
    await Future<void>.delayed(Duration.zero);
    expect(
      second.read(appSettingsProvider),
      const AppSettings(theme: ThemeChoice.auto, glass: true),
    );
  });

  test(
    'fichier illisible : valeurs par défaut ; écriture impossible : le choix vaut quand même',
    () async {
      final c = containerWith(_BrokenStore());
      c.read(appSettingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(appSettingsProvider), const AppSettings());
      await c.read(appSettingsProvider.notifier).setTheme(ThemeChoice.day);
      expect(c.read(appSettingsProvider).theme, ThemeChoice.day);
    },
  );
}
