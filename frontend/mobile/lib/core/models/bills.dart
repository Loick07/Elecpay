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
