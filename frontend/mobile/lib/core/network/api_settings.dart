/// Réglages réseau de l'application : c'est le SEUL endroit où ils sont définis.
abstract final class ApiSettings {
  /// Temps maximal pour établir la connexion avec l'API.
  static const connectTimeout = Duration(seconds: 15);

  /// Temps maximal d'attente de la réponse, une fois la requête envoyée.
  static const receiveTimeout = Duration(seconds: 30);

  /// Identifiant de requête, repris par l'API dans ses journaux et dans sa réponse.
  static const requestIdHeader = 'X-Request-ID';

  /// Format accepté par l'API (`backend/app/core/logs.py`) : sinon elle en crée un autre.
  static final safeRequestId = RegExp(r'^[A-Za-z0-9._-]{8,64}$');
}
