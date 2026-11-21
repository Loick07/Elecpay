import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

// Compte de l'utilisateur (écran 14), écrit à la main d'après `backend/openapi.json` (vérifié par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/AUTHENTIFICATION.md.

/// Schéma OpenAPI : `VerificationSent` (`POST /me/email/verification`). `demo_code` : en mode
/// démo seulement (aucun e-mail réel ne part), le code est renvoyé pour être affiché.
@freezed
abstract class VerificationSent with _$VerificationSent {
  const factory VerificationSent({
    required String sentTo,
    required DateTime expiresAt,
    required String? demoCode,
  }) = _VerificationSent;

  factory VerificationSent.fromJson(Map<String, dynamic> json) => _$VerificationSentFromJson(json);
}

/// Schéma OpenAPI : `VerificationConfirm` (`POST /me/email/verification/confirm`).
@freezed
abstract class VerificationConfirm with _$VerificationConfirm {
  const factory VerificationConfirm({required String code}) = _VerificationConfirm;

  factory VerificationConfirm.fromJson(Map<String, dynamic> json) =>
      _$VerificationConfirmFromJson(json);
}

/// Schéma OpenAPI : `NotificationPreferences` (`GET` et `PATCH /me/notification-preferences`) :
/// les interrupteurs « Me prévenir » de l'écran 14.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required bool dueSoon,
    required bool payments,
    required bool highConsumption,
    required bool emailReceipts,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}

/// Schéma OpenAPI : `ChangePasswordRequest` (`POST /me/password`).
@freezed
abstract class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    required String currentPassword,
    required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
}

/// Schéma OpenAPI : `LogoutAllResponse` (`POST /auth/logout-all`).
@freezed
abstract class LogoutAllResponse with _$LogoutAllResponse {
  const factory LogoutAllResponse({required int revokedSessions}) = _LogoutAllResponse;

  factory LogoutAllResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutAllResponseFromJson(json);
}
