import 'package:freezed_annotation/freezed_annotation.dart';

part 'consumption.freezed.dart';
part 'consumption.g.dart';

// Consommation d'un compteur, écrite à la main d'après `backend/openapi.json` (vérifiée par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/CONSOMMATION.md.
// Relevés PÉRIODIQUES (quotidiens) ou estimés : jamais « temps réel ». Coûts en FCFA entiers ;
// `energy_cost` = énergie seule, `estimated_total` = estimation de facture (taxes comprises).

/// Schéma OpenAPI : `DayPeak` (jour le plus consommé du mois).
@freezed
abstract class DayPeak with _$DayPeak {
  const factory DayPeak({
    required DateTime day,
    required int consumptionWh,
    required double consumptionKwh,
  }) = _DayPeak;

  factory DayPeak.fromJson(Map<String, dynamic> json) => _$DayPeakFromJson(json);
}

/// Schéma OpenAPI : `MonthSoFar` (le mois en cours, du 1er au dernier relevé).
@freezed
abstract class MonthSoFar with _$MonthSoFar {
  const factory MonthSoFar({
    required DateTime start,
    required DateTime? end,
    required int daysWithData,
    required int consumptionWh,
    required double consumptionKwh,
    required int? energyCost,
    required int dailyAverageWh,
    required DayPeak? highestDay,
  }) = _MonthSoFar;

  factory MonthSoFar.fromJson(Map<String, dynamic> json) => _$MonthSoFarFromJson(json);
}

/// Schéma OpenAPI : `LastMonth`.
@freezed
abstract class LastMonth with _$LastMonth {
  const factory LastMonth({
    required DateTime start,
    required DateTime end,
    required int daysWithData,
    required int consumptionWh,
    required double consumptionKwh,
    required int? energyCost,
    required int? estimatedTotal,
  }) = _LastMonth;

  factory LastMonth.fromJson(Map<String, dynamic> json) => _$LastMonthFromJson(json);
}

/// Schéma OpenAPI : `MonthEndEstimate` (estimation de fin de mois ; `basis` : `current_month`
/// ou `last_7_days`).
@freezed
abstract class MonthEndEstimate with _$MonthEndEstimate {
  const factory MonthEndEstimate({
    required int consumptionWh,
    required double consumptionKwh,
    required int? energyCost,
    required int? estimatedTotal,
    required int remainingDays,
    required String basis,
  }) = _MonthEndEstimate;

  factory MonthEndEstimate.fromJson(Map<String, dynamic> json) => _$MonthEndEstimateFromJson(json);
}

/// Schéma OpenAPI : `ConsumptionSummary` (`GET /meters/{id}/consumption/summary`).
@freezed
abstract class ConsumptionSummary with _$ConsumptionSummary {
  const factory ConsumptionSummary({
    required int meterId,

    /// Dernier jour relevé (`null` : aucun relevé).
    required DateTime? measuredUntil,
    required MonthSoFar thisMonth,
    required LastMonth lastMonth,
    required double? variationPercent,
    required MonthEndEstimate? monthEndEstimate,

    /// Le tarif appliqué est-il une hypothèse (aucun tarif daté connu) ?
    required bool tariffIsAssumption,

    /// `simulated` (mode démo) ou `e2c`.
    required String source,
  }) = _ConsumptionSummary;

  factory ConsumptionSummary.fromJson(Map<String, dynamic> json) =>
      _$ConsumptionSummaryFromJson(json);
}

/// Schéma OpenAPI : `ConsumptionPoint` (une barre : un jour, une semaine, un mois…).
@freezed
abstract class ConsumptionPoint with _$ConsumptionPoint {
  const factory ConsumptionPoint({
    required DateTime start,
    required DateTime end,
    required String label,
    required int consumptionWh,
    required double consumptionKwh,
    required int daysWithData,
    required int dailyAverageWh,
    required int? energyCost,
    required int? estimatedTotal,

    /// Période en cours (ex. aujourd'hui).
    required bool isCurrent,

    /// Période incomplète (des jours sans relevé).
    required bool isPartial,

    /// Valeur estimée (pas encore relevée) : affichée en pointillé.
    required bool isEstimated,
    required bool hasAnomaly,
  }) = _ConsumptionPoint;

  factory ConsumptionPoint.fromJson(Map<String, dynamic> json) => _$ConsumptionPointFromJson(json);
}

/// Schéma OpenAPI : `ConsumptionTotals`.
@freezed
abstract class ConsumptionTotals with _$ConsumptionTotals {
  const factory ConsumptionTotals({
    required DateTime start,
    required DateTime end,
    required int consumptionWh,
    required double consumptionKwh,
    required int daysWithData,
    required int? energyCost,
  }) = _ConsumptionTotals;

  factory ConsumptionTotals.fromJson(Map<String, dynamic> json) =>
      _$ConsumptionTotalsFromJson(json);
}

/// Schéma OpenAPI : `ConsumptionComparison` (`mode` : `previous` ou `last_year`).
@freezed
abstract class ConsumptionComparison with _$ConsumptionComparison {
  const factory ConsumptionComparison({
    required String mode,
    required ConsumptionTotals current,
    required ConsumptionTotals reference,
    required double? variationPercent,
  }) = _ConsumptionComparison;

  factory ConsumptionComparison.fromJson(Map<String, dynamic> json) =>
      _$ConsumptionComparisonFromJson(json);
}

/// Schéma OpenAPI : `ConsumptionSeries` (`GET /meters/{id}/consumption`).
@freezed
abstract class ConsumptionSeries with _$ConsumptionSeries {
  const factory ConsumptionSeries({
    required int meterId,
    required String granularity,
    required DateTime start,
    required DateTime end,
    required DateTime? measuredUntil,
    required List<ConsumptionPoint> points,
    required ConsumptionComparison? comparison,
    required bool tariffIsAssumption,
    required String source,
  }) = _ConsumptionSeries;

  factory ConsumptionSeries.fromJson(Map<String, dynamic> json) =>
      _$ConsumptionSeriesFromJson(json);
}
