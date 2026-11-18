import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

// Modèles de l'authentification, écrits à la main d'après `backend/openapi.json`
// (vérifiés par test/contract/openapi_contract_test.dart). Guide : backend/docs/AUTHENTIFICATION.md.

/// Schéma OpenAPI : `UserRole`. « Payeur délégué » n'en fait pas partie (c'est un rôle dans un foyer).
enum UserRole {
  client,
  support,
  admin,
  @JsonValue('super_admin')
  superAdmin,

  /// Rôle ajouté plus tard par l'API : l'application ne plante pas, elle le traite comme inconnu.
  unknown,
}

/// Droits liés au rôle, côté application (l'API reste seule juge : elle vérifie tout côté serveur).
///
/// `unknown` ne donne AUCUN droit : niveau 0, en dessous même du client.
extension UserRoleRights on UserRole {
  /// 0 = aucun droit (rôle inconnu), puis client < support < admin < super admin.
  int get level => switch (this) {
    UserRole.unknown => 0,
    UserRole.client => 1,
    UserRole.support => 2,
    UserRole.admin => 3,
    UserRole.superAdmin => 4,
  };

  /// A-t-il au moins les droits de `other` ? Un rôle inconnu n'a jamais ceux d'un rôle connu.
  bool hasAtLeast(UserRole other) => level >= other.level && this != UserRole.unknown;

  /// Membre de l'équipe ElecPay (support, admin, super admin) : utilise le back-office.
  bool get isTeam => hasAtLeast(UserRole.support);

  /// Peut utiliser l'application client (un abonné).
  bool get isClient => this == UserRole.client;
}

/// Schéma OpenAPI : `UserPublic` (réponse de `GET /me`, et `user` des jetons).
@freezed
abstract class UserPublic with _$UserPublic {
  const factory UserPublic({
    required int id,
    required String fullName,
    required String phone,
    required String? email,
    DateTime? emailVerifiedAt,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,
    required bool isActive,
    required DateTime? lastLoginAt,
    required DateTime createdAt,
  }) = _UserPublic;

  factory UserPublic.fromJson(Map<String, dynamic> json) => _$UserPublicFromJson(json);
}

/// Schéma OpenAPI : `TokenResponse` (connexion, inscription, rafraîchissement).
@freezed
abstract class TokenResponse with _$TokenResponse {
  const factory TokenResponse({
    required String accessToken,
    required DateTime accessExpiresAt,

    /// Durée de validité du jeton d'accès, en secondes.
    required int expiresIn,
    required String refreshToken,
    required DateTime refreshExpiresAt,
    @Default('bearer') String tokenType,
    required UserPublic user,
  }) = _TokenResponse;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);
}

/// Schéma OpenAPI : `TwoFactorChallenge`. Mot de passe correct mais code 2FA demandé : n'arrive
/// qu'aux membres de l'équipe, qui n'utilisent pas l'application client.
@freezed
abstract class TwoFactorChallenge with _$TwoFactorChallenge {
  const factory TwoFactorChallenge({
    required String challengeToken,
    required DateTime expiresAt,
    @Default(<String>['totp', 'backup_code']) List<String> methods,
    @Default(true) bool twoFactorRequired,
  }) = _TwoFactorChallenge;

  factory TwoFactorChallenge.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorChallengeFromJson(json);
}

/// Schéma OpenAPI : `LoginRequest` (`POST /auth/login`).
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({required String phone, required String password}) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

/// Schéma OpenAPI : `RegisterRequest` (`POST /auth/register`, clients seulement). L'e-mail est
/// facultatif (`null` : pas d'e-mail).
@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String fullName,
    required String phone,
    String? email,
    required String password,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}

/// Schéma OpenAPI : `ForgotPasswordRequest` (`POST /auth/password/forgot`).
@freezed
abstract class ForgotPasswordRequest with _$ForgotPasswordRequest {
  const factory ForgotPasswordRequest({required String phone}) = _ForgotPasswordRequest;

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
}

/// Schéma OpenAPI : `ForgotPasswordResponse`. La même réponse, que le numéro ait un compte ou non ;
/// `demoCode` n'existe qu'en mode démo, et seulement si le compte existe (voir docs/API.md).
@freezed
abstract class ForgotPasswordResponse with _$ForgotPasswordResponse {
  const factory ForgotPasswordResponse({
    required String message,

    /// Durée de validité du code, en secondes.
    required int expiresIn,
    String? demoCode,
  }) = _ForgotPasswordResponse;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordResponseFromJson(json);
}

/// Schéma OpenAPI : `ResetPasswordRequest` (`POST /auth/password/reset`, réponse 204).
@freezed
abstract class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String phone,
    required String code,
    required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}

/// Schéma OpenAPI : `RefreshRequest` (`POST /auth/refresh` et `POST /auth/logout`).
@freezed
abstract class RefreshRequest with _$RefreshRequest {
  const factory RefreshRequest({required String refreshToken}) = _RefreshRequest;

  factory RefreshRequest.fromJson(Map<String, dynamic> json) => _$RefreshRequestFromJson(json);
}

/// Réponse 200 de `POST /auth/login` : des jetons, OU un défi 2FA (schéma `anyOf` du contrat).
sealed class LoginResult {
  const LoginResult();

  /// Distingue les deux formes par `two_factor_required`, présent seulement dans le défi.
  factory LoginResult.fromJson(Map<String, dynamic> json) => json['two_factor_required'] == true
      ? LoginNeedsTwoFactor(TwoFactorChallenge.fromJson(json))
      : LoginSucceeded(TokenResponse.fromJson(json));
}

final class LoginSucceeded extends LoginResult {
  const LoginSucceeded(this.tokens);

  final TokenResponse tokens;
}

final class LoginNeedsTwoFactor extends LoginResult {
  const LoginNeedsTwoFactor(this.challenge);

  final TwoFactorChallenge challenge;
}
