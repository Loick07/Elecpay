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
