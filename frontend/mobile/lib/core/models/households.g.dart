// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'households.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdSummary _$HouseholdSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_HouseholdSummary',
  json,
  ($checkedConvert) {
    final val = _HouseholdSummary(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      name: $checkedConvert('name', (v) => v as String),
      city: $checkedConvert('city', (v) => v as String),
      district: $checkedConvert('district', (v) => v as String?),
      ownerName: $checkedConvert('owner_name', (v) => v as String),
      myRole: $checkedConvert('my_role', (v) => v as HouseholdRole),
      membersCount: $checkedConvert('members_count', (v) => (v as num).toInt()),
      metersCount: $checkedConvert('meters_count', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'ownerName': 'owner_name',
    'myRole': 'my_role',
    'membersCount': 'members_count',
    'metersCount': 'meters_count',
  },
);

Map<String, dynamic> _$HouseholdSummaryToJson(_HouseholdSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'district': instance.district,
      'owner_name': instance.ownerName,
      'my_role': instance.myRole,
      'members_count': instance.membersCount,
      'meters_count': instance.metersCount,
    };

_MeterDetail _$MeterDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_MeterDetail',
  json,
  ($checkedConvert) {
    final val = _MeterDetail(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      householdId: $checkedConvert('household_id', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String?),
      type: $checkedConvert('type', (v) => v as String),
      status: $checkedConvert('status', (v) => v as String),
      contractNumber: $checkedConvert('contract_number', (v) => v as String?),
      customerNumber: $checkedConvert('customer_number', (v) => v as String?),
      e2cCenter: $checkedConvert('e2c_center', (v) => v as String?),
      subscribedPowerVa: $checkedConvert(
        'subscribed_power_va',
        (v) => (v as num?)?.toInt(),
      ),
      installedAt: $checkedConvert(
        'installed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      myRole: $checkedConvert('my_role', (v) => v as HouseholdRole),
      canManage: $checkedConvert('can_manage', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'householdId': 'household_id',
    'contractNumber': 'contract_number',
    'customerNumber': 'customer_number',
    'e2cCenter': 'e2c_center',
    'subscribedPowerVa': 'subscribed_power_va',
    'installedAt': 'installed_at',
    'myRole': 'my_role',
    'canManage': 'can_manage',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$MeterDetailToJson(_MeterDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'reference': instance.reference,
      'label': instance.label,
      'type': instance.type,
      'status': instance.status,
      'contract_number': instance.contractNumber,
      'customer_number': instance.customerNumber,
      'e2c_center': instance.e2cCenter,
      'subscribed_power_va': instance.subscribedPowerVa,
      'installed_at': instance.installedAt?.toIso8601String(),
      'my_role': instance.myRole,
      'can_manage': instance.canManage,
      'created_at': instance.createdAt.toIso8601String(),
    };
