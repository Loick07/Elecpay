import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// L'application : thèmes de la charte (Nuit par défaut), routes reliées à la session. Le choix
/// Nuit / Jour / Auto par l'abonné arrive en F9 (écran Compte).
class ElecPayApp extends ConsumerWidget {
  const ElecPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ElecPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Nuit, thème par défaut de la charte
      routerConfig: ref.watch(routerProvider),
    );
  }
}
