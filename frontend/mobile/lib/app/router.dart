import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/design_check/charte_screen.dart';
import '../features/startup/startup_screen.dart';

/// Les routes de l'application. Chaque étape (F3 → F9) ajoute les siennes.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupScreen()),
    // Page de contrôle de la charte : seulement dans les versions de développement.
    if (kDebugMode) GoRoute(path: '/charte', builder: (context, state) => const CharteScreen()),
  ],
);
