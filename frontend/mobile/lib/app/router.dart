import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/design_check/charte_screen.dart';
import '../features/diagnostic/diagnostic_access.dart';
import '../features/diagnostic/diagnostic_screen.dart';
import '../features/startup/startup_screen.dart';
import 'app_shell.dart';

/// Les routes de l'application. Chaque étape (F3 → F9) ajoute les siennes.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
    // Écrans principaux, sous la barre du bas (pages d'attente jusqu'à F4 → F9).
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        for (final (tab, step) in [
          (AppTab.home, 'F4'),
          (AppTab.bills, 'F5'),
          (AppTab.consumption, 'F7'),
          (AppTab.account, 'F9'),
        ])
          GoRoute(
            path: tab.path,
            pageBuilder: (context, state) => NoTransitionPage(
              child: PendingTab(tab: tab, step: step),
            ),
          ),
      ],
    ),
    // Page de contrôle de la charte : seulement dans les versions de développement.
    if (kDebugMode) GoRoute(path: '/charte', builder: (context, state) => const CharteScreen()),
    // Pages Diagnostic et Catalogue : debug et profile, JAMAIS en release (constante : retirées
    // par le compilateur ; vérifié dans l'APK par tool/apk_check.dart).
    if (diagnosticsEnabled) ...[
      GoRoute(path: '/diagnostic', builder: (context, state) => const DiagnosticScreen()),
      GoRoute(path: '/catalogue', builder: (context, state) => const CatalogueScreen()),
    ],
  ],
);
