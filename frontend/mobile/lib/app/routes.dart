import '../core/widgets/bottom_nav.dart';

/// Adresses des écrans de l'application.
abstract final class Routes {
  static const splash = '/';
  static const login = '/connexion';
  static const register = '/inscription';
  static const forgotPassword = '/mot-de-passe';
  static final home = AppTab.home.path;

  /// Écran poussé pas encore construit (page d'attente), sous l'accueil : donc protégé.
  static final pendingPath = '${AppTab.home.path}/bientot';

  /// Adresse de la page d'attente de `screen` (« Détail de la facture »), apporté à l'étape `step`.
  static String pending(String screen, String step) =>
      Uri(path: pendingPath, queryParameters: {'ecran': screen, 'etape': step}).toString();

  /// Écrans de connexion : interdits une fois connecté.
  static const auth = {login, register, forgotPassword};

  /// Écrans qui demandent une session (les onglets de la barre du bas, et ce qui s'y ajoutera).
  static bool isProtected(String location) =>
      AppTab.values.any((tab) => location == tab.path || location.startsWith('${tab.path}/'));
}
