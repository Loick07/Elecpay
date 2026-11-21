import '../core/widgets/bottom_nav.dart';

/// Adresses des écrans de l'application.
abstract final class Routes {
  static const splash = '/';
  static const login = '/connexion';
  static const register = '/inscription';
  static const forgotPassword = '/mot-de-passe';
  static final home = AppTab.home.path;

  /// Écran 7 : détail d'une facture, poussé (sous `/factures/` : protégé).
  static final billPath = '${AppTab.bills.path}/:billId';
  static String bill(int id) => '${AppTab.bills.path}/$id';

  /// Écran 9 : suivi du paiement d'une facture, poussé (sous `/factures/` : protégé).
  static final paymentPath = '${AppTab.bills.path}/:billId/paiement';
  static String payment(int billId) => '${AppTab.bills.path}/$billId/paiement';

  /// Écran 10 : reçu d'un paiement réussi, poussé (sous `/factures/` : protégé).
  static final receiptPath = '${AppTab.bills.path}/recus/:receiptId';
  static String receipt(int receiptId) => '${AppTab.bills.path}/recus/$receiptId';

  /// Écran 12 : historique des paiements, poussé depuis « Tout voir » de l'accueil.
  static final history = '${AppTab.home.path}/paiements';

  /// Écran 13, poussé depuis la cloche de l'accueil.
  static final notifications = '${AppTab.home.path}/notifications';

  /// « Modifier » de l'écran 14 : nom, e-mail et sa vérification (sous `/compte/` : protégé).
  static final profile = '${AppTab.account.path}/profil';

  /// « Mot de passe et sécurité » de l'écran 14 (sous `/compte/` : protégé).
  static final security = '${AppTab.account.path}/securite';

  /// Écran 16 : Assistance (sous `/compte/` : protégé).
  static final support = '${AppTab.account.path}/assistance';

  /// Écran 15 : Compteurs et foyers, poussé (sous `/compte/` : protégé). D8.3 : depuis Compte,
  /// l'état « Ajoutez votre premier compteur », Consommation sans compteur et les invitations.
  static final households = '${AppTab.account.path}/compteurs';

  /// Le même écran, feuille « Ajouter un compteur » ouverte (accueil et Conso sans compteur).
  static final addMeter = '$households?ajouter=1';

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
