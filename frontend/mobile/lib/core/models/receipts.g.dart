// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReceiptPublic _$ReceiptPublicFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ReceiptPublic',
  json,
  ($checkedConvert) {
    final val = _ReceiptPublic(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      number: $checkedConvert('number', (v) => v as String),
      issuedAt: $checkedConvert(
        'issued_at',
        (v) => DateTime.parse(v as String),
      ),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      verificationCode: $checkedConvert(
        'verification_code',
        (v) => v as String,
      ),
      billId: $checkedConvert('bill_id', (v) => (v as num).toInt()),
      billReference: $checkedConvert('bill_reference', (v) => v as String),
      billPeriodLabel: $checkedConvert('bill_period_label', (v) => v as String),
      billPeriodStart: $checkedConvert(
        'bill_period_start',
        (v) => DateTime.parse(v as String),
      ),
      billPeriodEnd: $checkedConvert(
        'bill_period_end',
        (v) => DateTime.parse(v as String),
      ),
      meterId: $checkedConvert('meter_id', (v) => (v as num).toInt()),
      meterReference: $checkedConvert('meter_reference', (v) => v as String),
      householdId: $checkedConvert('household_id', (v) => (v as num?)?.toInt()),
      householdName: $checkedConvert('household_name', (v) => v as String?),
      payerId: $checkedConvert('payer_id', (v) => (v as num).toInt()),
      payerName: $checkedConvert('payer_name', (v) => v as String),
      isMine: $checkedConvert('is_mine', (v) => v as bool),
      operator: $checkedConvert('operator', (v) => v as String),
      operatorLabel: $checkedConvert('operator_label', (v) => v as String),
      phoneNumber: $checkedConvert('phone_number', (v) => v as String),
      transactionId: $checkedConvert(
        'transaction_id',
        (v) => (v as num).toInt(),
      ),
      transactionReference: $checkedConvert(
        'transaction_reference',
        (v) => v as String,
      ),
      source: $checkedConvert('source', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'issuedAt': 'issued_at',
    'verificationCode': 'verification_code',
    'billId': 'bill_id',
    'billReference': 'bill_reference',
    'billPeriodLabel': 'bill_period_label',
    'billPeriodStart': 'bill_period_start',
    'billPeriodEnd': 'bill_period_end',
    'meterId': 'meter_id',
    'meterReference': 'meter_reference',
    'householdId': 'household_id',
    'householdName': 'household_name',
    'payerId': 'payer_id',
    'payerName': 'payer_name',
    'isMine': 'is_mine',
    'operatorLabel': 'operator_label',
    'phoneNumber': 'phone_number',
    'transactionId': 'transaction_id',
    'transactionReference': 'transaction_reference',
  },
);

Map<String, dynamic> _$ReceiptPublicToJson(_ReceiptPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'issued_at': instance.issuedAt.toIso8601String(),
      'amount': instance.amount,
      'verification_code': instance.verificationCode,
      'bill_id': instance.billId,
      'bill_reference': instance.billReference,
      'bill_period_label': instance.billPeriodLabel,
      'bill_period_start': instance.billPeriodStart.toIso8601String(),
      'bill_period_end': instance.billPeriodEnd.toIso8601String(),
      'meter_id': instance.meterId,
      'meter_reference': instance.meterReference,
      'household_id': instance.householdId,
      'household_name': instance.householdName,
      'payer_id': instance.payerId,
      'payer_name': instance.payerName,
      'is_mine': instance.isMine,
      'operator': instance.operator,
      'operator_label': instance.operatorLabel,
      'phone_number': instance.phoneNumber,
      'transaction_id': instance.transactionId,
      'transaction_reference': instance.transactionReference,
      'source': instance.source,
    };

_ReceiptPage _$ReceiptPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReceiptPage', json, ($checkedConvert) {
      final val = _ReceiptPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ReceiptPublic.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ReceiptPageToJson(_ReceiptPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'size': instance.size,
      'total': instance.total,
    };
