import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account.dart';
import '../../core/session/session_providers.dart';
import '../auth/models/auth_models.dart';
import '../home/home_data.dart';

// Écran 14 (Compte) : actions sur le profil. Le compte lui-même est lu par `homeUserProvider`
// (`GET /me`, en cache). Actions envoyées UNE fois (aucune relance automatique).

/// Version affichée en bas de l'écran Compte (la même que `pubspec.yaml` : un test le vérifie).
const appVersion = '1.0.0';

class AccountActions {
  const AccountActions(this._ref);

  final Ref _ref;

  /// Modifier le profil : seuls les champs CHANGÉS partent (`full_name`, `email`). Un e-mail vide
  /// (`null`) retire l'adresse ; une nouvelle adresse est à revérifier.
  Future<UserPublic> updateProfile(Map<String, Object?> changes) async {
    final user = await _ref
        .read(authenticatedApiProvider)
        .patchObject('/me', UserPublic.fromJson, body: changes);
    _ref.invalidate(homeUserProvider);
    return user;
  }

  /// Envoie un code de vérification à l'adresse du profil (en mode démo, le code est renvoyé).
  Future<VerificationSent> sendEmailCode() => _ref
      .read(authenticatedApiProvider)
      .postObject('/me/email/verification', VerificationSent.fromJson);

  /// Confirme l'adresse avec le code reçu.
  Future<UserPublic> confirmEmail(String code) async {
    final user = await _ref
        .read(authenticatedApiProvider)
        .postObject(
          '/me/email/verification/confirm',
          UserPublic.fromJson,
          body: VerificationConfirm(code: code),
        );
    _ref.invalidate(homeUserProvider);
    return user;
  }
}

final accountActionsProvider = Provider<AccountActions>(AccountActions.new);
