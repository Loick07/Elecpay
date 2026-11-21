import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// L'application : thèmes de la charte (Nuit par défaut, D9.2 ; Jour ou Auto au choix de l'abonné
/// sur l'écran Compte, gardé d'un lancement à l'autre), routes reliées à la session.
class ElecPayApp extends ConsumerWidget {
  const ElecPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ElecPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeModeOf(ref.watch(appSettingsProvider.select((s) => s.theme))),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Thème choisi → mode de Flutter : Nuit = sombre, Jour = clair, Auto = celui du téléphone.
ThemeMode themeModeOf(ThemeChoice choice) => switch (choice) {
  ThemeChoice.night => ThemeMode.dark,
  ThemeChoice.day => ThemeMode.light,
  ThemeChoice.auto => ThemeMode.system,
};
