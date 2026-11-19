import 'package:freezed_annotation/freezed_annotation.dart';

part 'bills.freezed.dart';
part 'bills.g.dart';

// Factures, écrites à la main d'après `backend/openapi.json` (vérifiées par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/FACTURES.md.

/// Statuts AFFICHÉS d'une facture (`BillStatus`), traduits par `billStatus()` (statuses.dart).
/// Gardés en texte : une valeur ajoutée plus tard par l'API ne fait pas planter l'application.
abstract final class BillStatuses {
  static const unpaid = 'unpaid';
  static const overdue = 'overdue';
  static const pendingPayment = 'pending_payment';
  static const paid = 'paid';
  static const cancelled = 'cancelled';
}

/// Filtres de `GET /bills?status=` (`BillFilter`).
abstract final class BillFilters {
  /// Impayées, en retard ET paiement en cours.
  static const toPay = 'to_pay';
  static const overdue = 'overdue';
  static const paid = 'paid';
}

/// Schéma OpenAPI : `BillSummary` (une ligne de `GET /bills`).
@freezed
abstract class BillSummary with _$BillSummary {
  const factory BillSummary({
    required int id,
    required String reference,
    required int householdId,
    required String householdName,
    required int meterId,
    required String meterReference,
    required String? meterLabel,
    required String myRole,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String periodLabel,
    required int monthsCount,
    required int consumptionWh,
    required double consumptionKwh,

    /// Montant TTC, en FCFA entiers.
    required int amountTotal,
    required DateTime issuedAt,
    required DateTime dueDate,
    required String status,
    required int daysOverdue,
    required DateTime? paidAt,

    /// Le bouton « Payer » n'apparaît que si c'est vrai (rôle, statut, paiement en cours).
    required bool canPay,

    /// `simulated` (mode démo) ou `e2c`.
    required String source,
  }) = _BillSummary;

  factory BillSummary.fromJson(Map<String, dynamic> json) => _$BillSummaryFromJson(json);
}

/// Schéma OpenAPI : `Outstanding` (reste à payer ; suit `household_id` / `meter_id`, ignore `status`).
@freezed
abstract class Outstanding with _$Outstanding {
  const factory Outstanding({
    required int amount,
    required int count,
    required int overdueAmount,
    required int overdueCount,
  }) = _Outstanding;

  factory Outstanding.fromJson(Map<String, dynamic> json) => _$OutstandingFromJson(json);
}

/// Schéma OpenAPI : `BillList` (`GET /bills`).
@freezed
abstract class BillList with _$BillList {
  const factory BillList({
    required List<BillSummary> items,
    required Outstanding outstanding,
    required int page,
    required int size,
    required int total,
  }) = _BillList;

  factory BillList.fromJson(Map<String, dynamic> json) => _$BillListFromJson(json);
}

/// Lignes d'une facture E²C (`BillLineKind`), dans l'ordre de la facture. Gardées en texte.
abstract final class BillLineKinds {
  static const energy = 'energy';
  static const fixedFee = 'fixed_fee';
  static const audiovisualFee = 'audiovisual_fee';
  static const vat = 'vat';
  static const additionalTax = 'additional_tax';
  static const stamp = 'stamp';
  static const other = 'other';
}

/// Schéma OpenAPI : `BillLinePublic` (une des 6 lignes E²C). Les entiers (`*_milli`, `rate_bp`)
/// sont exacts ; les nombres décimaux (`quantity`, `unit_price`, `rate_percent`) servent
/// SEULEMENT à l'affichage. `amount` : FCFA entiers, tronqués comme chez E²C.
@freezed
abstract class BillLinePublic with _$BillLinePublic {
  const factory BillLinePublic({
    required int position,
    required String kind,
    required String label,
    required int? quantityMilli,
    required double? quantity,
    required String? unit,
    required int? unitPriceMilli,
    required double? unitPrice,
    required int? rateBp,
    required double? ratePercent,
    required int? baseAmount,
    required int amount,
  }) = _BillLinePublic;

  factory BillLinePublic.fromJson(Map<String, dynamic> json) => _$BillLinePublicFromJson(json);
}

/// Schéma OpenAPI : `TariffPublic` (tarif appliqué ; `is_assumption` : « tarif à confirmer »).
@freezed
abstract class TariffPublic with _$TariffPublic {
  const factory TariffPublic({
    required int id,
    required String code,
    required String label,
    required int pricePerKwhMilli,
    required bool isAssumption,
  }) = _TariffPublic;

  factory TariffPublic.fromJson(Map<String, dynamic> json) => _$TariffPublicFromJson(json);
}

/// Schéma OpenAPI : `PreviousBillComparison` (facture précédente du même compteur).
@freezed
abstract class PreviousBillComparison with _$PreviousBillComparison {
  const factory PreviousBillComparison({
    required int billId,
    required String reference,
    required String periodLabel,
    required int consumptionWh,
    required double consumptionKwh,
    required int amountTotal,
    required int consumptionChangeWh,

    /// `null` si la précédente vaut 0.
    required double? consumptionChangePercent,
    required int amountChange,
    required double? amountChangePercent,
  }) = _PreviousBillComparison;

  factory PreviousBillComparison.fromJson(Map<String, dynamic> json) =>
      _$PreviousBillComparisonFromJson(json);
}

/// Schéma OpenAPI : `BillDetail` (`GET /bills/{id}`, écran 7).
@freezed
abstract class BillDetail with _$BillDetail {
  const factory BillDetail({
    required int id,
    required String reference,
    required int meterId,
    required String meterReference,
    required String? meterLabel,
    required int householdId,
    required String householdName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String periodLabel,
    required int monthsCount,
    required int consumptionWh,
    required double consumptionKwh,
    required int amountTotal,
    required DateTime issuedAt,
    required DateTime dueDate,
    required String status,
    required int daysOverdue,
    required DateTime? paidAt,
    required String myRole,
    required bool canPay,
    required String source,
    required String? meterContractNumber,
    required String? meterCustomerNumber,
    required String? e2cCenter,
    required int previousIndexWh,
    required int currentIndexWh,
    required double previousIndexKwh,
    required double currentIndexKwh,
    required int? billedPowerVa,
    required int amountHt,
    required int amountTax,
    required int amountFees,
    required List<BillLinePublic> lines,
    required TariffPublic tariff,
    required PreviousBillComparison? previousBill,
    required DateTime? cancelledAt,
    required String? cancelledReason,
  }) = _BillDetail;

  factory BillDetail.fromJson(Map<String, dynamic> json) => _$BillDetailFromJson(json);
}
