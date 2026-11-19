// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bills.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillSummary _$BillSummaryFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_BillSummary',
  json,
  ($checkedConvert) {
    final val = _BillSummary(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      householdId: $checkedConvert('household_id', (v) => (v as num).toInt()),
      householdName: $checkedConvert('household_name', (v) => v as String),
      meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
      meterReference: $checkedConvert('meter_reference', (v) => v as String),
      meterLabel: $checkedConvert('meter_label', (v) => v as String?),
      myRole: $checkedConvert('my_role', (v) => v as String),
      periodStart: $checkedConvert(
        'period_start',
        (v) => DateTime.parse(v as String),
      ),
      periodEnd: $checkedConvert(
        'period_end',
        (v) => DateTime.parse(v as String),
      ),
      periodLabel: $checkedConvert('period_label', (v) => v as String),
      monthsCount: $checkedConvert('months_count', (v) => (v as num).toInt()),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
      amountTotal: $checkedConvert('amount_total', (v) => (v as num).toInt()),
      issuedAt: $checkedConvert(
        'issued_at',
        (v) => DateTime.parse(v as String),
      ),
      dueDate: $checkedConvert('due_date', (v) => DateTime.parse(v as String)),
      status: $checkedConvert('status', (v) => v as String),
      daysOverdue: $checkedConvert('days_overdue', (v) => (v as num).toInt()),
      paidAt: $checkedConvert(
        'paid_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      canPay: $checkedConvert('can_pay', (v) => v as bool),
      source: $checkedConvert('source', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'householdId': 'household_id',
    'householdName': 'household_name',
    'meterId': 'meter_id',
    'meterReference': 'meter_reference',
    'meterLabel': 'meter_label',
    'myRole': 'my_role',
    'periodStart': 'period_start',
    'periodEnd': 'period_end',
    'periodLabel': 'period_label',
    'monthsCount': 'months_count',
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
    'amountTotal': 'amount_total',
    'issuedAt': 'issued_at',
    'dueDate': 'due_date',
    'daysOverdue': 'days_overdue',
    'paidAt': 'paid_at',
    'canPay': 'can_pay',
  },
);

Map<String, dynamic> _$BillSummaryToJson(_BillSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'household_id': instance.householdId,
      'household_name': instance.householdName,
      'meter_id': instance.meterId,
      'meter_reference': instance.meterReference,
      'meter_label': instance.meterLabel,
      'my_role': instance.myRole,
      'period_start': instance.periodStart.toIso8601String(),
      'period_end': instance.periodEnd.toIso8601String(),
      'period_label': instance.periodLabel,
      'months_count': instance.monthsCount,
      'consumption_wh': instance.consumptionWh,
      'consumption_kwh': instance.consumptionKwh,
      'amount_total': instance.amountTotal,
      'issued_at': instance.issuedAt.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'days_overdue': instance.daysOverdue,
      'paid_at': instance.paidAt?.toIso8601String(),
      'can_pay': instance.canPay,
      'source': instance.source,
    };

_Outstanding _$OutstandingFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Outstanding',
  json,
  ($checkedConvert) {
    final val = _Outstanding(
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      count: $checkedConvert('count', (v) => (v as num).toInt()),
      overdueAmount: $checkedConvert(
        'overdue_amount',
        (v) => (v as num).toInt(),
      ),
      overdueCount: $checkedConvert('overdue_count', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'overdueAmount': 'overdue_amount',
    'overdueCount': 'overdue_count',
  },
);

Map<String, dynamic> _$OutstandingToJson(_Outstanding instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'count': instance.count,
      'overdue_amount': instance.overdueAmount,
      'overdue_count': instance.overdueCount,
    };

_BillList _$BillListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BillList', json, ($checkedConvert) {
      final val = _BillList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => BillSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        outstanding: $checkedConvert(
          'outstanding',
          (v) => Outstanding.fromJson(v as Map<String, dynamic>),
        ),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$BillListToJson(_BillList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'outstanding': instance.outstanding.toJson(),
  'page': instance.page,
  'size': instance.size,
  'total': instance.total,
};
