// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consumption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayPeak _$DayPeakFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_DayPeak',
  json,
  ($checkedConvert) {
    final val = _DayPeak(
      day: $checkedConvert('day', (v) => DateTime.parse(v as String)),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
  },
);

Map<String, dynamic> _$DayPeakToJson(_DayPeak instance) => <String, dynamic>{
  'day': instance.day.toIso8601String(),
  'consumption_wh': instance.consumptionWh,
  'consumption_kwh': instance.consumptionKwh,
};

_MonthSoFar _$MonthSoFarFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_MonthSoFar',
  json,
  ($checkedConvert) {
    final val = _MonthSoFar(
      start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
      end: $checkedConvert(
        'end',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      daysWithData: $checkedConvert(
        'days_with_data',
        (v) => (v as num).toInt(),
      ),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
      energyCost: $checkedConvert('energy_cost', (v) => (v as num?)?.toInt()),
      dailyAverageWh: $checkedConvert(
        'daily_average_wh',
        (v) => (v as num).toInt(),
      ),
      highestDay: $checkedConvert(
        'highest_day',
        (v) => v == null ? null : DayPeak.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'daysWithData': 'days_with_data',
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
    'energyCost': 'energy_cost',
    'dailyAverageWh': 'daily_average_wh',
    'highestDay': 'highest_day',
  },
);

Map<String, dynamic> _$MonthSoFarToJson(_MonthSoFar instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end?.toIso8601String(),
      'days_with_data': instance.daysWithData,
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'energy_cost': instance.energyCost,
      'daily_average_wh': instance.dailyAverageWh,
      'highest_day': instance.highestDay?.toJson(),
    };

_LastMonth _$LastMonthFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LastMonth',
  json,
  ($checkedConvert) {
    final val = _LastMonth(
      start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
      end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
      daysWithData: $checkedConvert(
        'days_with_data',
        (v) => (v as num).toInt(),
      ),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
      energyCost: $checkedConvert('energy_cost', (v) => (v as num?)?.toInt()),
      estimatedTotal: $checkedConvert(
        'estimated_total',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'daysWithData': 'days_with_data',
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
    'energyCost': 'energy_cost',
    'estimatedTotal': 'estimated_total',
  },
);

Map<String, dynamic> _$LastMonthToJson(_LastMonth instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'days_with_data': instance.daysWithData,
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'energy_cost': instance.energyCost,
      'estimated_total': instance.estimatedTotal,
    };

_MonthEndEstimate _$MonthEndEstimateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_MonthEndEstimate',
      json,
      ($checkedConvert) {
        final val = _MonthEndEstimate(
          consumptionWh: $checkedConvert(
            'consumption_wh',
            (v) => (v as num).toInt(),
          ),
          consumptionKwh: $checkedConvert(
            'consumption_kwh',
            (v) => (v as num).toDouble(),
          ),
          energyCost: $checkedConvert(
            'energy_cost',
            (v) => (v as num?)?.toInt(),
          ),
          estimatedTotal: $checkedConvert(
            'estimated_total',
            (v) => (v as num?)?.toInt(),
          ),
          remainingDays: $checkedConvert(
            'remaining_days',
            (v) => (v as num).toInt(),
          ),
          basis: $checkedConvert('basis', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'consumptionWh': 'consumption_wh',
        'consumptionKwh': 'consumption_kwh',
        'energyCost': 'energy_cost',
        'estimatedTotal': 'estimated_total',
        'remainingDays': 'remaining_days',
      },
    );

Map<String, dynamic> _$MonthEndEstimateToJson(_MonthEndEstimate instance) =>
    <String, dynamic>{
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'energy_cost': instance.energyCost,
      'estimated_total': instance.estimatedTotal,
      'remaining_days': instance.remainingDays,
      'basis': instance.basis,
    };

_ConsumptionSummary _$ConsumptionSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ConsumptionSummary',
      json,
      ($checkedConvert) {
        final val = _ConsumptionSummary(
          meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
          measuredUntil: $checkedConvert(
            'measured_until',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          thisMonth: $checkedConvert(
            'this_month',
            (v) => MonthSoFar.fromJson(v as Map<String, dynamic>),
          ),
          lastMonth: $checkedConvert(
            'last_month',
            (v) => LastMonth.fromJson(v as Map<String, dynamic>),
          ),
          variationPercent: $checkedConvert(
            'variation_percent',
            (v) => (v as num?)?.toDouble(),
          ),
          monthEndEstimate: $checkedConvert(
            'month_end_estimate',
            (v) => v == null
                ? null
                : MonthEndEstimate.fromJson(v as Map<String, dynamic>),
          ),
          tariffIsAssumption: $checkedConvert(
            'tariff_is_assumption',
            (v) => v as bool,
          ),
          source: $checkedConvert('source', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'meterId': 'meter_id',
        'measuredUntil': 'measured_until',
        'thisMonth': 'this_month',
        'lastMonth': 'last_month',
        'variationPercent': 'variation_percent',
        'monthEndEstimate': 'month_end_estimate',
        'tariffIsAssumption': 'tariff_is_assumption',
      },
    );

Map<String, dynamic> _$ConsumptionSummaryToJson(_ConsumptionSummary instance) =>
    <String, dynamic>{
      'meter_id': instance.meterId,
      'measured_until': instance.measuredUntil?.toIso8601String(),
      'this_month': instance.thisMonth.toJson(),
      'last_month': instance.lastMonth.toJson(),
      'variation_percent': instance.variationPercent,
      'month_end_estimate': instance.monthEndEstimate?.toJson(),
      'tariff_is_assumption': instance.tariffIsAssumption,
      'source': instance.source,
    };

_ConsumptionPoint _$ConsumptionPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ConsumptionPoint',
      json,
      ($checkedConvert) {
        final val = _ConsumptionPoint(
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          label: $checkedConvert('label', (v) => v as String),
          consumptionWh: $checkedConvert(
            'consumption_wh',
            (v) => (v as num).toInt(),
          ),
          consumptionKwh: $checkedConvert(
            'consumption_kwh',
            (v) => (v as num).toDouble(),
          ),
          daysWithData: $checkedConvert(
            'days_with_data',
            (v) => (v as num).toInt(),
          ),
          dailyAverageWh: $checkedConvert(
            'daily_average_wh',
            (v) => (v as num).toInt(),
          ),
          energyCost: $checkedConvert(
            'energy_cost',
            (v) => (v as num?)?.toInt(),
          ),
          estimatedTotal: $checkedConvert(
            'estimated_total',
            (v) => (v as num?)?.toInt(),
          ),
          isCurrent: $checkedConvert('is_current', (v) => v as bool),
          isPartial: $checkedConvert('is_partial', (v) => v as bool),
          isEstimated: $checkedConvert('is_estimated', (v) => v as bool),
          hasAnomaly: $checkedConvert('has_anomaly', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'consumptionWh': 'consumption_wh',
        'consumptionKwh': 'consumption_kwh',
        'daysWithData': 'days_with_data',
        'dailyAverageWh': 'daily_average_wh',
        'energyCost': 'energy_cost',
        'estimatedTotal': 'estimated_total',
        'isCurrent': 'is_current',
        'isPartial': 'is_partial',
        'isEstimated': 'is_estimated',
        'hasAnomaly': 'has_anomaly',
      },
    );

Map<String, dynamic> _$ConsumptionPointToJson(_ConsumptionPoint instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'label': instance.label,
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'days_with_data': instance.daysWithData,
      'daily_average_wh': instance.dailyAverageWh,
      'energy_cost': instance.energyCost,
      'estimated_total': instance.estimatedTotal,
      'is_current': instance.isCurrent,
      'is_partial': instance.isPartial,
      'is_estimated': instance.isEstimated,
      'has_anomaly': instance.hasAnomaly,
    };

_ConsumptionTotals _$ConsumptionTotalsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ConsumptionTotals',
      json,
      ($checkedConvert) {
        final val = _ConsumptionTotals(
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          consumptionWh: $checkedConvert(
            'consumption_wh',
            (v) => (v as num).toInt(),
          ),
          consumptionKwh: $checkedConvert(
            'consumption_kwh',
            (v) => (v as num).toDouble(),
          ),
          daysWithData: $checkedConvert(
            'days_with_data',
            (v) => (v as num).toInt(),
          ),
          energyCost: $checkedConvert(
            'energy_cost',
            (v) => (v as num?)?.toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'consumptionWh': 'consumption_wh',
        'consumptionKwh': 'consumption_kwh',
        'daysWithData': 'days_with_data',
        'energyCost': 'energy_cost',
      },
    );

Map<String, dynamic> _$ConsumptionTotalsToJson(_ConsumptionTotals instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'days_with_data': instance.daysWithData,
      'energy_cost': instance.energyCost,
    };

_ConsumptionComparison _$ConsumptionComparisonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_ConsumptionComparison', json, ($checkedConvert) {
  final val = _ConsumptionComparison(
    mode: $checkedConvert('mode', (v) => v as String),
    current: $checkedConvert(
      'current',
      (v) => ConsumptionTotals.fromJson(v as Map<String, dynamic>),
    ),
    reference: $checkedConvert(
      'reference',
      (v) => ConsumptionTotals.fromJson(v as Map<String, dynamic>),
    ),
    variationPercent: $checkedConvert(
      'variation_percent',
      (v) => (v as num?)?.toDouble(),
    ),
  );
  return val;
}, fieldKeyMap: const {'variationPercent': 'variation_percent'});

Map<String, dynamic> _$ConsumptionComparisonToJson(
  _ConsumptionComparison instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'current': instance.current.toJson(),
  'reference': instance.reference.toJson(),
  'variation_percent': instance.variationPercent,
};

_ConsumptionSeries _$ConsumptionSeriesFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ConsumptionSeries',
      json,
      ($checkedConvert) {
        final val = _ConsumptionSeries(
          meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
          granularity: $checkedConvert('granularity', (v) => v as String),
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          measuredUntil: $checkedConvert(
            'measured_until',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          points: $checkedConvert(
            'points',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => ConsumptionPoint.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          comparison: $checkedConvert(
            'comparison',
            (v) => v == null
                ? null
                : ConsumptionComparison.fromJson(v as Map<String, dynamic>),
          ),
          tariffIsAssumption: $checkedConvert(
            'tariff_is_assumption',
            (v) => v as bool,
          ),
          source: $checkedConvert('source', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'meterId': 'meter_id',
        'measuredUntil': 'measured_until',
        'tariffIsAssumption': 'tariff_is_assumption',
      },
    );

Map<String, dynamic> _$ConsumptionSeriesToJson(_ConsumptionSeries instance) =>
    <String, dynamic>{
      'meter_id': instance.meterId,
      'granularity': instance.granularity,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'measured_until': instance.measuredUntil?.toIso8601String(),
      'points': instance.points.map((e) => e.toJson()).toList(),
      'comparison': instance.comparison?.toJson(),
      'tariff_is_assumption': instance.tariffIsAssumption,
      'source': instance.source,
    };

_DayDetail _$DayDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_DayDetail',
  json,
  ($checkedConvert) {
    final val = _DayDetail(
      meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
      day: $checkedConvert('day', (v) => DateTime.parse(v as String)),
      label: $checkedConvert('label', (v) => v as String),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
      energyCost: $checkedConvert('energy_cost', (v) => (v as num?)?.toInt()),
      indexStartWh: $checkedConvert(
        'index_start_wh',
        (v) => (v as num?)?.toInt(),
      ),
      indexEndWh: $checkedConvert('index_end_wh', (v) => (v as num).toInt()),
      isEstimated: $checkedConvert('is_estimated', (v) => v as bool),
      isAnomaly: $checkedConvert('is_anomaly', (v) => v as bool),
      anomalyReason: $checkedConvert('anomaly_reason', (v) => v as String?),
      weekdayAverageWh: $checkedConvert(
        'weekday_average_wh',
        (v) => (v as num?)?.toInt(),
      ),
      weekdaySamples: $checkedConvert(
        'weekday_samples',
        (v) => (v as num).toInt(),
      ),
      rankInMonth: $checkedConvert('rank_in_month', (v) => (v as num).toInt()),
      daysRanked: $checkedConvert('days_ranked', (v) => (v as num).toInt()),
      source: $checkedConvert('source', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'meterId': 'meter_id',
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
    'energyCost': 'energy_cost',
    'indexStartWh': 'index_start_wh',
    'indexEndWh': 'index_end_wh',
    'isEstimated': 'is_estimated',
    'isAnomaly': 'is_anomaly',
    'anomalyReason': 'anomaly_reason',
    'weekdayAverageWh': 'weekday_average_wh',
    'weekdaySamples': 'weekday_samples',
    'rankInMonth': 'rank_in_month',
    'daysRanked': 'days_ranked',
  },
);

Map<String, dynamic> _$DayDetailToJson(_DayDetail instance) =>
    <String, dynamic>{
      'meter_id': instance.meterId,
      'day': instance.day.toIso8601String(),
      'label': instance.label,
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'energy_cost': instance.energyCost,
      'index_start_wh': instance.indexStartWh,
      'index_end_wh': instance.indexEndWh,
      'is_estimated': instance.isEstimated,
      'is_anomaly': instance.isAnomaly,
      'anomaly_reason': instance.anomalyReason,
      'weekday_average_wh': instance.weekdayAverageWh,
      'weekday_samples': instance.weekdaySamples,
      'rank_in_month': instance.rankInMonth,
      'days_ranked': instance.daysRanked,
      'source': instance.source,
    };
