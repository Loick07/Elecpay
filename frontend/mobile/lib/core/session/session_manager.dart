import 'package:flutter/foundation.dart';

import '../../features/auth/models/auth_models.dart';
import '../network/api_client.dart';
import '../network/api_failure.dart';
import 'token_store.dart';

/// État de la session sur le téléphone.
@immutable
sealed class SessionState {
  const SessionState();
}

/// Pas encore lue depuis le stockage (démarrage de l'application).
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// Connecté : des jetons sont enregistrés pour cet utilisateur.
final class SessionActive extends SessionState {
  const SessionActive(this.userId);

  final int userId;

  @override
  bool operator ==(Object other) => other is SessionActive && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}

/// Déconnecté. `reason` permet à F3 d'afficher « Session expirée » plutôt que l'accueil.
final class SessionEnded extends SessionState {
  const SessionEnded(this.reason);

  final SessionEndReason reason;

  @override
  bool operator ==(Object other) => other is SessionEnded && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

enum SessionEndReason {
  /// Aucune session enregistrée (premier lancement, ou après effacement).
  none,

  /// L'utilisateur s'est déconnecté.
  loggedOut,

  /// L'API a refusé le rafraîchissement, ou le jeton est invalide / rejoué.
  expired,
}

/// Gère les jetons : lecture au démarrage, connexion, rafraîchissement, fin de session.
///
/// Règles (backend/docs/AUTHENTIFICATION.md) :
/// - **un seul rafraîchissement à la fois** : les requêtes qui reçoivent `TOKEN_EXPIRED` en même
///   temps attendent le même résultat (sinon le second présenterait un jeton déjà utilisé et l'API
///   fermerait toute la session) ;
/// - les nouveaux jetons sont **enregistrés avant** de rendre la main (donc avant tout rejeu) ;
/// - rafraîchissement refusé (`401`, quel que soit le code) → jetons effacés, session terminée ;
/// - rafraîchissement impossible faute de réseau → la session est GARDÉE (pas de déconnexion abusive).
class SessionManager extends ChangeNotifier {
  /// `publicApi` : client SANS l'intercepteur de session (connexion, rafraîchissement, déconnexion).
  SessionManager({required TokenStore store, required ApiClient publicApi})
    : _store = store, // ignore: prefer_initializing_formals (paramètre nommé public, champ privé)
      _api = publicApi;

  final TokenStore _store;
  final ApiClient _api;

  SessionState _state = const SessionUnknown();
  StoredTokens? _tokens;
  Future<StoredTokens?>? _restoring;
  Future<String>? _refreshing;

  /// Appelé après l'ouverture d'une session (le cache des AUTRES comptes est effacé).
  Future<void> Function(int userId)? onSignedIn;

  /// Appelé quand une session se termine, avec son propriétaire (déconnexion : son cache est effacé).
  Future<void> Function(int userId, SessionEndReason reason)? onEnded;

  SessionState get state => _state;

  /// Nombre de rafraîchissements de jeton réussis depuis le lancement (affiché par la page Diagnostic).
  int get refreshCount => _refreshCount;
  int _refreshCount = 0;

  /// Jetons de la session, lus depuis le stockage au premier appel.
  Future<StoredTokens?> currentTokens() async {
    if (_state is SessionUnknown) await (_restoring ??= _restore());
    return _tokens;
  }

  Future<StoredTokens?> _restore() async {
    final tokens = await _store.read();
    _tokens = tokens;
    _setState(
      tokens == null ? const SessionEnded(SessionEndReason.none) : SessionActive(tokens.userId),
    );
    return tokens;
  }

  /// Connexion par numéro et mot de passe. Un défi 2FA (compte de l'équipe) n'ouvre PAS de session.
  Future<LoginResult> login(LoginRequest request) async {
    final result = await _api.postObject(
      '/auth/login',
      LoginResult.fromJson,
      body: request,
      authenticated: false,
    );
    if (result case LoginSucceeded(:final tokens)) await signIn(tokens);
    return result;
  }

  /// Ouvre la session avec des jetons reçus (connexion, inscription, changement de mot de passe).
  Future<void> signIn(TokenResponse response) async {
    final tokens = StoredTokens.fromResponse(response);
    await _store.write(tokens);
    _tokens = tokens;
    _restoring = Future.value(tokens);
    await onSignedIn?.call(tokens.userId);
    _setState(SessionActive(tokens.userId));
  }

  /// Un jeton d'accès valable. `failedAccessToken` : celui que l'API vient de refuser
  /// (`TOKEN_EXPIRED`). S'il a déjà été remplacé entre-temps, on rend le nouveau SANS rafraîchir.
  Future<String> freshAccessToken({required String? failedAccessToken}) async {
    final tokens = await currentTokens();
    if (tokens == null) throw const SessionExpired();
    if (failedAccessToken != null && tokens.accessToken != failedAccessToken) {
      return tokens.accessToken;
    }
    return _refreshing ??= _refresh(tokens).whenComplete(() => _refreshing = null);
  }

  Future<String> _refresh(StoredTokens tokens) async {
    final TokenResponse response;
    try {
      response = await _api.postObject(
        '/auth/refresh',
        TokenResponse.fromJson,
        body: RefreshRequest(refreshToken: tokens.refreshToken),
        authenticated: false,
      );
    } on ApiRejected catch (rejected) {
      if (rejected.statusCode == 401) {
        await end(SessionEndReason.expired);
        throw SessionExpired(reference: rejected.reference);
      }
      rethrow;
    }
    // Les nouveaux jetons sont ENREGISTRÉS avant que les requêtes en attente soient rejouées :
    // si l'application est tuée juste après, l'ancien jeton (déjà consommé) n'est jamais réutilisé.
    final fresh = StoredTokens.fromResponse(response);
    await _store.write(fresh);
    _tokens = fresh;
    _refreshCount++;
    return fresh.accessToken;
  }

  /// Termine la session : jetons effacés du téléphone. Sans effet si elle est déjà terminée.
  Future<void> end(SessionEndReason reason) async {
    if (_state is SessionEnded && _tokens == null) return;
    final owner = _tokens?.userId;
    _tokens = null;
    _restoring = Future.value();
    await _store.clear();
    if (owner != null) {
      try {
        await onEnded?.call(owner, reason);
      } on Object {
        // Le nettoyage (cache) ne doit jamais empêcher la fin de session.
      }
    }
    _setState(SessionEnded(reason));
  }

  /// Déconnexion : prévient l'API si possible (révoque le jeton de rafraîchissement), puis efface
  /// tout sur le téléphone DANS TOUS LES CAS, même sans réseau.
  Future<void> logout() async {
    final tokens = await currentTokens();
    try {
      if (tokens != null) {
        await _api.postNoContent(
          '/auth/logout',
          body: RefreshRequest(refreshToken: tokens.refreshToken),
          authenticated: false,
        );
      }
    } on ApiFailure {
      // Hors ligne ou refus : la session locale est effacée quand même.
    } finally {
      await end(SessionEndReason.loggedOut);
    }
  }

  void _setState(SessionState next) {
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }
}
