import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_expiry_notice.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_providers.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/auth/auth_pending_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/design_check/charte_screen.dart';
import '../features/diagnostic/diagnostic_access.dart';
import '../features/diagnostic/diagnostic_screen.dart';
import '../features/startup/splash_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

/// Les routes de l'application. Chaque étape (F3 → F9) ajoute les siennes.
List<RouteBase> appRoutes() => [
  GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
  // Connexion (F3.3, F3.4 remplacent les deux pages d'attente suivantes).
  GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
  GoRoute(
    path: Routes.register,
    builder: (context, state) => const AuthPendingScreen(title: 'Inscription', step: 'F3.3'),
  ),
  GoRoute(
    path: Routes.forgotPassword,
    builder: (context, state) =>
        const AuthPendingScreen(title: 'Mot de passe oublié', step: 'F3.4'),
  ),
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
];

/// Garde de navigation (pure, testée à part) : où aller selon la session.
///
/// - session pas encore lue : les écrans protégés passent par le splash (qui décide) ;
/// - connecté : plus d'écran de connexion → l'accueil ;
/// - déconnecté : les écrans protégés → la connexion, SAUF si la session vient d'expirer et que la
///   feuille « session expirée » n'a pas encore été vue (elle masque l'écran, fond opaque).
String? guard({
  required String location,
  required SessionState session,
  required bool expiryNoticePending,
}) {
  final protected = Routes.isProtected(location);
  return switch (session) {
    SessionUnknown() when protected => Routes.splash,
    SessionActive() when Routes.auth.contains(location) => Routes.home,
    SessionEnded() when protected && !expiryNoticePending => Routes.login,
    _ => null,
  };
}

/// Le routeur de l'application, relié à la session (il se réévalue à chaque changement).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionStateProvider, (_, _) => refresh.value++)
    ..listen(sessionExpiryNoticeProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    routes: appRoutes(),
    refreshListenable: refresh,
    redirect: (context, state) => guard(
      location: state.matchedLocation,
      session: ref.read(sessionStateProvider),
      expiryNoticePending: ref.read(sessionExpiryNoticeProvider),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
