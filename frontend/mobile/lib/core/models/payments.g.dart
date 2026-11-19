// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentPublic _$PaymentPublicFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_PaymentPublic',
  json,
  ($checkedConvert) {
    final val = _PaymentPublic(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      billId: $checkedConvert('bill_id', (v) => (v as num).toInt()),
      billReference: $checkedConvert('bill_reference', (v) => v as String),
      billPeriodLabel: $checkedConvert('bill_period_label', (v) => v as String),
      householdId: $checkedConvert('household_id', (v) => (v as num?)?.toInt()),
      householdName: $checkedConvert('household_name', (v) => v as String?),
      meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
      meterReference: $checkedConvert('meter_reference', (v) => v as String),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      operator: $checkedConvert('operator', (v) => v as String),
      operatorLabel: $checkedConvert('operator_label', (v) => v as String),
      phoneNumber: $checkedConvert('phone_number', (v) => v as String),
      payerId: $checkedConvert('payer_id', (v) => (v as num).toInt()),
      payerName: $checkedConvert('payer_name', (v) => v as String),
      isMine: $checkedConvert('is_mine', (v) => v as bool),
      status: $checkedConvert('status', (v) => v as String),
      step: $checkedConvert('step', (v) => v as String),
      failureReason: $checkedConvert('failure_reason', (v) => v as String?),
      initiatedAt: $checkedConvert(
        'initiated_at',
        (v) => DateTime.parse(v as String),
      ),
      pinEnteredAt: $checkedConvert(
        'pin_entered_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      confirmedAt: $checkedConvert(
        'confirmed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      receiptId: $checkedConvert('receipt_id', (v) => (v as num?)?.toInt()),
      receiptNumber: $checkedConvert('receipt_number', (v) => v as String?),
      source: $checkedConvert('source', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'billId': 'bill_id',
    'billReference': 'bill_reference',
    'billPeriodLabel': 'bill_period_label',
    'householdId': 'household_id',
    'householdName': 'household_name',
    'meterId': 'meter_id',
    'meterReference': 'meter_reference',
    'operatorLabel': 'operator_label',
    'phoneNumber': 'phone_number',
    'payerId': 'payer_id',
    'payerName': 'payer_name',
    'isMine': 'is_mine',
    'failureReason': 'failure_reason',
    'initiatedAt': 'initiated_at',
    'pinEnteredAt': 'pin_entered_at',
    'confirmedAt': 'confirmed_at',
    'expiresAt': 'expires_at',
    'receiptId': 'receipt_id',
    'receiptNumber': 'receipt_number',
  },
);

Map<String, dynamic> _$PaymentPublicToJson(_PaymentPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'bill_id': instance.billId,
      'bill_reference': instance.billReference,
      'bill_period_label': instance.billPeriodLabel,
      'household_id': instance.householdId,
      'household_name': instance.householdName,
      'meter_id': instance.meterId,
      'meter_reference': instance.meterReference,
      'amount': instance.amount,
      'operator': instance.operator,
      'operator_label': instance.operatorLabel,
      'phone_number': instance.phoneNumber,
      'payer_id': instance.payerId,
      'payer_name': instance.payerName,
      'is_mine': instance.isMine,
      'status': instance.status,
      'step': instance.step,
      'failure_reason': instance.failureReason,
      'initiated_at': instance.initiatedAt.toIso8601String(),
      'pin_entered_at': instance.pinEnteredAt?.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'receipt_id': instance.receiptId,
      'receipt_number': instance.receiptNumber,
      'source': instance.source,
    };

_PaymentPage _$PaymentPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PaymentPage', json, ($checkedConvert) {
      final val = _PaymentPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PaymentPublic.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PaymentPageToJson(_PaymentPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'size': instance.size,
      'total': instance.total,
    };
