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

_BillLinePublic _$BillLinePublicFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_BillLinePublic',
  json,
  ($checkedConvert) {
    final val = _BillLinePublic(
      position: $checkedConvert('position', (v) => (v as num).toInt()),
      kind: $checkedConvert('kind', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String),
      quantityMilli: $checkedConvert(
        'quantity_milli',
        (v) => (v as num?)?.toInt(),
      ),
      quantity: $checkedConvert('quantity', (v) => (v as num?)?.toDouble()),
      unit: $checkedConvert('unit', (v) => v as String?),
      unitPriceMilli: $checkedConvert(
        'unit_price_milli',
        (v) => (v as num?)?.toInt(),
      ),
      unitPrice: $checkedConvert('unit_price', (v) => (v as num?)?.toDouble()),
      rateBp: $checkedConvert('rate_bp', (v) => (v as num?)?.toInt()),
      ratePercent: $checkedConvert(
        'rate_percent',
        (v) => (v as num?)?.toDouble(),
      ),
      baseAmount: $checkedConvert('base_amount', (v) => (v as num?)?.toInt()),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'quantityMilli': 'quantity_milli',
    'unitPriceMilli': 'unit_price_milli',
    'unitPrice': 'unit_price',
    'rateBp': 'rate_bp',
    'ratePercent': 'rate_percent',
    'baseAmount': 'base_amount',
  },
);

Map<String, dynamic> _$BillLinePublicToJson(_BillLinePublic instance) =>
    <String, dynamic>{
      'position': instance.position,
      'kind': instance.kind,
      'label': instance.label,
      'quantity_milli': instance.quantityMilli,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'unit_price_milli': instance.unitPriceMilli,
      'unit_price': instance.unitPrice,
      'rate_bp': instance.rateBp,
      'rate_percent': instance.ratePercent,
      'base_amount': instance.baseAmount,
      'amount': instance.amount,
    };

_TariffPublic _$TariffPublicFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_TariffPublic',
      json,
      ($checkedConvert) {
        final val = _TariffPublic(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          code: $checkedConvert('code', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String),
          pricePerKwhMilli: $checkedConvert(
            'price_per_kwh_milli',
            (v) => (v as num).toInt(),
          ),
          isAssumption: $checkedConvert('is_assumption', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'pricePerKwhMilli': 'price_per_kwh_milli',
        'isAssumption': 'is_assumption',
      },
    );

Map<String, dynamic> _$TariffPublicToJson(_TariffPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'label': instance.label,
      'price_per_kwh_milli': instance.pricePerKwhMilli,
      'is_assumption': instance.isAssumption,
    };

_PreviousBillComparison _$PreviousBillComparisonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_PreviousBillComparison',
  json,
  ($checkedConvert) {
    final val = _PreviousBillComparison(
      billId: $checkedConvert('bill_id', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      periodLabel: $checkedConvert('period_label', (v) => v as String),
      periodStart: $checkedConvert(
        'period_start',
        (v) => DateTime.parse(v as String),
      ),
      periodEnd: $checkedConvert(
        'period_end',
        (v) => DateTime.parse(v as String),
      ),
      consumptionWh: $checkedConvert(
        'consumption_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionKwh: $checkedConvert(
        'consumption_kwh',
        (v) => (v as num).toDouble(),
      ),
      amountTotal: $checkedConvert('amount_total', (v) => (v as num).toInt()),
      consumptionChangeWh: $checkedConvert(
        'consumption_change_wh',
        (v) => (v as num).toInt(),
      ),
      consumptionChangePercent: $checkedConvert(
        'consumption_change_percent',
        (v) => (v as num?)?.toDouble(),
      ),
      amountChange: $checkedConvert('amount_change', (v) => (v as num).toInt()),
      amountChangePercent: $checkedConvert(
        'amount_change_percent',
        (v) => (v as num?)?.toDouble(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'billId': 'bill_id',
    'periodLabel': 'period_label',
    'periodStart': 'period_start',
    'periodEnd': 'period_end',
    'consumptionWh': 'consumption_wh',
    'consumptionKwh': 'consumption_kwh',
    'amountTotal': 'amount_total',
    'consumptionChangeWh': 'consumption_change_wh',
    'consumptionChangePercent': 'consumption_change_percent',
    'amountChange': 'amount_change',
    'amountChangePercent': 'amount_change_percent',
  },
);

Map<String, dynamic> _$PreviousBillComparisonToJson(
  _PreviousBillComparison instance,
) => <String, dynamic>{
  'bill_id': instance.billId,
  'reference': instance.reference,
  'period_label': instance.periodLabel,
  'period_start': instance.periodStart.toIso8601String(),
  'period_end': instance.periodEnd.toIso8601String(),
  'consumption_wh': instance.consumptionWh,
  'consumption_kwh': instance.consumptionKwh,
  'amount_total': instance.amountTotal,
  'consumption_change_wh': instance.consumptionChangeWh,
  'consumption_change_percent': instance.consumptionChangePercent,
  'amount_change': instance.amountChange,
  'amount_change_percent': instance.amountChangePercent,
};

_BillDetail _$BillDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_BillDetail',
  json,
  ($checkedConvert) {
    final val = _BillDetail(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
      meterReference: $checkedConvert('meter_reference', (v) => v as String),
      meterLabel: $checkedConvert('meter_label', (v) => v as String?),
      householdId: $checkedConvert('household_id', (v) => (v as num).toInt()),
      householdName: $checkedConvert('household_name', (v) => v as String),
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
      myRole: $checkedConvert('my_role', (v) => v as String),
      canPay: $checkedConvert('can_pay', (v) => v as bool),
      source: $checkedConvert('source', (v) => v as String),
      meterContractNumber: $checkedConvert(
        'meter_contract_number',
        (v) => v as String?,
      ),
      meterCustomerNumber: $checkedConvert(
        'meter_customer_number',
        (v) => v as String?,
      ),
      e2cCenter: $checkedConvert('e2c_center', (v) => v as String?),
      previousIndexWh: $checkedConvert(
        'previous_index_wh',
        (v) => (v as num).toInt(),
      ),
      currentIndexWh: $checkedConvert(
        'current_index_wh',
        (v) => (v as num).toInt(),
      ),
      previousIndexKwh: $checkedConvert(
        'previous_index_kwh',
        (v) => (v as num).toDouble(),
      ),
      currentIndexKwh: $checkedConvert(
        'current_index_kwh',
        (v) => (v as num).toDouble(),
      ),
      billedPowerVa: $checkedConvert(
        'billed_power_va',
        (v) => (v as num?)?.toInt(),
      ),
      amountHt: $checkedConvert('amount_ht', (v) => (v as num).toInt()),
      amountTax: $checkedConvert('amount_tax', (v) => (v as num).toInt()),
      amountFees: $checkedConvert('amount_fees', (v) => (v as num).toInt()),
      lines: $checkedConvert(
        'lines',
        (v) => (v as List<dynamic>)
            .map((e) => BillLinePublic.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      tariff: $checkedConvert(
        'tariff',
        (v) => TariffPublic.fromJson(v as Map<String, dynamic>),
      ),
      previousBill: $checkedConvert(
        'previous_bill',
        (v) => v == null
            ? null
            : PreviousBillComparison.fromJson(v as Map<String, dynamic>),
      ),
      cancelledAt: $checkedConvert(
        'cancelled_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      cancelledReason: $checkedConvert('cancelled_reason', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'meterId': 'meter_id',
    'meterReference': 'meter_reference',
    'meterLabel': 'meter_label',
    'householdId': 'household_id',
    'householdName': 'household_name',
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
    'myRole': 'my_role',
    'canPay': 'can_pay',
    'meterContractNumber': 'meter_contract_number',
    'meterCustomerNumber': 'meter_customer_number',
    'e2cCenter': 'e2c_center',
    'previousIndexWh': 'previous_index_wh',
    'currentIndexWh': 'current_index_wh',
    'previousIndexKwh': 'previous_index_kwh',
    'currentIndexKwh': 'current_index_kwh',
    'billedPowerVa': 'billed_power_va',
    'amountHt': 'amount_ht',
    'amountTax': 'amount_tax',
    'amountFees': 'amount_fees',
    'previousBill': 'previous_bill',
    'cancelledAt': 'cancelled_at',
    'cancelledReason': 'cancelled_reason',
  },
);

Map<String, dynamic> _$BillDetailToJson(_BillDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'meter_id': instance.meterId,
      'meter_reference': instance.meterReference,
      'meter_label': instance.meterLabel,
      'household_id': instance.householdId,
      'household_name': instance.householdName,
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
      'my_role': instance.myRole,
      'can_pay': instance.canPay,
      'source': instance.source,
      'meter_contract_number': instance.meterContractNumber,
      'meter_customer_number': instance.meterCustomerNumber,
      'e2c_center': instance.e2cCenter,
      'previous_index_wh': instance.previousIndexWh,
      'current_index_wh': instance.currentIndexWh,
      'previous_index_kwh': instance.previousIndexKwh,
      'current_index_kwh': instance.currentIndexKwh,
      'billed_power_va': instance.billedPowerVa,
      'amount_ht': instance.amountHt,
      'amount_tax': instance.amountTax,
      'amount_fees': instance.amountFees,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'tariff': instance.tariff.toJson(),
      'previous_bill': instance.previousBill?.toJson(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'cancelled_reason': instance.cancelledReason,
    };
