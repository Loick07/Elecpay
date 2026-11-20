import 'package:freezed_annotation/freezed_annotation.dart';

part 'households.freezed.dart';
part 'households.g.dart';

// Foyers et compteurs, écrits à la main d'après `backend/openapi.json` (vérifiés par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/FOYERS_COMPTEURS.md.

/// Rôle dans un foyer (`HouseholdRole`) : `owner` (titulaire), `payer` (payeur délégué), `viewer`.
/// Gardé en texte : une valeur ajoutée plus tard par l'API ne fait pas planter l'application.
typedef HouseholdRole = String;

/// Schéma OpenAPI : `HouseholdSummary` (`GET /households`).
@freezed
abstract class HouseholdSummary with _$HouseholdSummary {
  const factory HouseholdSummary({
    required int id,
    required String name,
    required String city,
    required String? district,
    required String ownerName,
    required HouseholdRole myRole,
    required int membersCount,
    required int metersCount,
  }) = _HouseholdSummary;

  factory HouseholdSummary.fromJson(Map<String, dynamic> json) => _$HouseholdSummaryFromJson(json);
}

/// Schéma OpenAPI : `MeterDetail` (`GET /households/{id}/meters`, `GET /meters/{id}`).
@freezed
abstract class MeterDetail with _$MeterDetail {
  const factory MeterDetail({
    required int id,
    required int householdId,
    required String reference,
    required String? label,
    required String type,
    required String status,
    required String? contractNumber,
    required String? customerNumber,
    required String? e2cCenter,
    required int? subscribedPowerVa,
    required DateTime? installedAt,
    required HouseholdRole myRole,
    required bool canManage,
    required DateTime createdAt,
  }) = _MeterDetail;

  factory MeterDetail.fromJson(Map<String, dynamic> json) => _$MeterDetailFromJson(json);
}

/// Rôle d'un membre invité (`MemberRole`) : `payer` (payeur délégué) ou `viewer` (lecteur).
/// Gardé en texte, comme `HouseholdRole`.
typedef MemberRole = String;

/// Valeurs de `MemberRole`, `HouseholdRole` et `MemberStatus` (contrat).
abstract final class HouseholdRoles {
  static const owner = 'owner';
  static const payer = 'payer';
  static const viewer = 'viewer';
}

abstract final class MemberStatuses {
  static const invited = 'invited';
  static const active = 'active';
  static const revoked = 'revoked';
}

/// Schéma OpenAPI : `PersonPublic`. Le numéro des autres est TOUJOURS masqué par l'API
/// (`+242 06 *** ** 67`).
@freezed
abstract class PersonPublic with _$PersonPublic {
  const factory PersonPublic({
    required int id,
    required String fullName,
    required String phoneMasked,
  }) = _PersonPublic;

  factory PersonPublic.fromJson(Map<String, dynamic> json) => _$PersonPublicFromJson(json);
}

/// Schéma OpenAPI : `MemberPublic` (`GET /households/{id}/members`). Le propriétaire voit aussi
/// les invitations en attente (`status` = `invited`).
@freezed
abstract class MemberPublic with _$MemberPublic {
  const factory MemberPublic({
    required int id,
    required PersonPublic person,
    required MemberRole role,
    required String status,
    required DateTime createdAt,
  }) = _MemberPublic;

  factory MemberPublic.fromJson(Map<String, dynamic> json) => _$MemberPublicFromJson(json);
}

/// Schéma OpenAPI : `HouseholdDetail` (`GET /households/{id}`). `can_pay` et `can_manage`
/// décident des boutons : l'application ne recalcule jamais les droits (le serveur vérifie).
@freezed
abstract class HouseholdDetail with _$HouseholdDetail {
  const factory HouseholdDetail({
    required int id,
    required String name,
    required String city,
    required String? district,
    required String? address,
    required HouseholdRole myRole,
    required bool canPay,
    required bool canManage,
    required PersonPublic owner,
    required List<MeterSummary> meters,
    required List<MemberPublic> members,
    required DateTime createdAt,
  }) = _HouseholdDetail;

  factory HouseholdDetail.fromJson(Map<String, dynamic> json) => _$HouseholdDetailFromJson(json);
}

/// Schéma OpenAPI : `MeterSummary` (compteur dans la carte d'un foyer, `GET /households/{id}`).
@freezed
abstract class MeterSummary with _$MeterSummary {
  const factory MeterSummary({
    required int id,
    required String reference,
    required String? label,
    required String type,
    required String status,
    required int? subscribedPowerVa,
    required String? e2cCenter,
  }) = _MeterSummary;

  factory MeterSummary.fromJson(Map<String, dynamic> json) => _$MeterSummaryFromJson(json);
}

/// Schéma OpenAPI : `HouseholdBrief` (foyer d'une invitation).
@freezed
abstract class HouseholdBrief with _$HouseholdBrief {
  const factory HouseholdBrief({required int id, required String name, required String city}) =
      _HouseholdBrief;

  factory HouseholdBrief.fromJson(Map<String, dynamic> json) => _$HouseholdBriefFromJson(json);
}

/// Schéma OpenAPI : `InvitationPublic` (`GET /invitations`, invitations reçues en attente).
@freezed
abstract class InvitationPublic with _$InvitationPublic {
  const factory InvitationPublic({
    required int id,
    required HouseholdBrief household,
    required MemberRole role,
    required PersonPublic invitedBy,
    required DateTime createdAt,
  }) = _InvitationPublic;

  factory InvitationPublic.fromJson(Map<String, dynamic> json) => _$InvitationPublicFromJson(json);
}

/// Schéma OpenAPI : `HouseholdCreate` (`POST /households`).
@freezed
abstract class HouseholdCreate with _$HouseholdCreate {
  const factory HouseholdCreate({
    required String name,
    required String city,
    String? district,
    String? address,
  }) = _HouseholdCreate;

  factory HouseholdCreate.fromJson(Map<String, dynamic> json) => _$HouseholdCreateFromJson(json);
}

/// Schéma OpenAPI : `InviteRequest` (`POST /households/{id}/members`). Le numéro doit être celui
/// d'un compte ElecPay existant (sinon `INVITEE_NOT_FOUND`, D8.2).
@freezed
abstract class InviteRequest with _$InviteRequest {
  const factory InviteRequest({required String phone, required MemberRole role}) = _InviteRequest;

  factory InviteRequest.fromJson(Map<String, dynamic> json) => _$InviteRequestFromJson(json);
}

/// Schéma OpenAPI : `MeterAddRequest` (`POST /households/{id}/meters`) : N° de branchement et N°
/// client de la facture E²C, vérifiés chez E²C (`BillingSource`).
@freezed
abstract class MeterAddRequest with _$MeterAddRequest {
  const factory MeterAddRequest({
    required String reference,
    required String customerNumber,
    String? label,
  }) = _MeterAddRequest;

  factory MeterAddRequest.fromJson(Map<String, dynamic> json) => _$MeterAddRequestFromJson(json);
}

/// Schéma OpenAPI : `HistoryImportPublic` (historique importé avec le compteur ; `simulated` en
/// mode démo).
@freezed
abstract class HistoryImportPublic with _$HistoryImportPublic {
  const factory HistoryImportPublic({
    required int readings,
    required int bills,
    required String source,
  }) = _HistoryImportPublic;

  factory HistoryImportPublic.fromJson(Map<String, dynamic> json) =>
      _$HistoryImportPublicFromJson(json);
}

/// Schéma OpenAPI : `MeterAddResponse` (réponse de `POST /households/{id}/meters`).
@freezed
abstract class MeterAddResponse with _$MeterAddResponse {
  const factory MeterAddResponse({
    required MeterDetail meter,
    required HistoryImportPublic history,
  }) = _MeterAddResponse;

  factory MeterAddResponse.fromJson(Map<String, dynamic> json) => _$MeterAddResponseFromJson(json);
}
