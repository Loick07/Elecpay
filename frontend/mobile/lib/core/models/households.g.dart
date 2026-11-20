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

_PersonPublic _$PersonPublicFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_PersonPublic', json, ($checkedConvert) {
  final val = _PersonPublic(
    id: $checkedConvert('id', (v) => (v as num).toInt()),
    fullName: $checkedConvert('full_name', (v) => v as String),
    phoneMasked: $checkedConvert('phone_masked', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'fullName': 'full_name', 'phoneMasked': 'phone_masked'});

Map<String, dynamic> _$PersonPublicToJson(_PersonPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'phone_masked': instance.phoneMasked,
    };

_MemberPublic _$MemberPublicFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MemberPublic', json, ($checkedConvert) {
      final val = _MemberPublic(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        person: $checkedConvert(
          'person',
          (v) => PersonPublic.fromJson(v as Map<String, dynamic>),
        ),
        role: $checkedConvert('role', (v) => v as MemberRole),
        status: $checkedConvert('status', (v) => v as String),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$MemberPublicToJson(_MemberPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'person': instance.person.toJson(),
      'role': instance.role,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
    };

_HouseholdDetail _$HouseholdDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_HouseholdDetail',
      json,
      ($checkedConvert) {
        final val = _HouseholdDetail(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String),
          city: $checkedConvert('city', (v) => v as String),
          district: $checkedConvert('district', (v) => v as String?),
          address: $checkedConvert('address', (v) => v as String?),
          myRole: $checkedConvert('my_role', (v) => v as HouseholdRole),
          canPay: $checkedConvert('can_pay', (v) => v as bool),
          canManage: $checkedConvert('can_manage', (v) => v as bool),
          owner: $checkedConvert(
            'owner',
            (v) => PersonPublic.fromJson(v as Map<String, dynamic>),
          ),
          meters: $checkedConvert(
            'meters',
            (v) => (v as List<dynamic>)
                .map((e) => MeterSummary.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          members: $checkedConvert(
            'members',
            (v) => (v as List<dynamic>)
                .map((e) => MemberPublic.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'myRole': 'my_role',
        'canPay': 'can_pay',
        'canManage': 'can_manage',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$HouseholdDetailToJson(_HouseholdDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'district': instance.district,
      'address': instance.address,
      'my_role': instance.myRole,
      'can_pay': instance.canPay,
      'can_manage': instance.canManage,
      'owner': instance.owner.toJson(),
      'meters': instance.meters.map((e) => e.toJson()).toList(),
      'members': instance.members.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
    };

_MeterSummary _$MeterSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_MeterSummary',
      json,
      ($checkedConvert) {
        final val = _MeterSummary(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          reference: $checkedConvert('reference', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String?),
          type: $checkedConvert('type', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          subscribedPowerVa: $checkedConvert(
            'subscribed_power_va',
            (v) => (v as num?)?.toInt(),
          ),
          e2cCenter: $checkedConvert('e2c_center', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'subscribedPowerVa': 'subscribed_power_va',
        'e2cCenter': 'e2c_center',
      },
    );

Map<String, dynamic> _$MeterSummaryToJson(_MeterSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'label': instance.label,
      'type': instance.type,
      'status': instance.status,
      'subscribed_power_va': instance.subscribedPowerVa,
      'e2c_center': instance.e2cCenter,
    };

_HouseholdBrief _$HouseholdBriefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HouseholdBrief', json, ($checkedConvert) {
      final val = _HouseholdBrief(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$HouseholdBriefToJson(_HouseholdBrief instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
    };

_InvitationPublic _$InvitationPublicFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_InvitationPublic',
      json,
      ($checkedConvert) {
        final val = _InvitationPublic(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          household: $checkedConvert(
            'household',
            (v) => HouseholdBrief.fromJson(v as Map<String, dynamic>),
          ),
          role: $checkedConvert('role', (v) => v as MemberRole),
          invitedBy: $checkedConvert(
            'invited_by',
            (v) => PersonPublic.fromJson(v as Map<String, dynamic>),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'invitedBy': 'invited_by', 'createdAt': 'created_at'},
    );

Map<String, dynamic> _$InvitationPublicToJson(_InvitationPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household': instance.household.toJson(),
      'role': instance.role,
      'invited_by': instance.invitedBy.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
    };

_HouseholdCreate _$HouseholdCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HouseholdCreate', json, ($checkedConvert) {
      final val = _HouseholdCreate(
        name: $checkedConvert('name', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String),
        district: $checkedConvert('district', (v) => v as String?),
        address: $checkedConvert('address', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$HouseholdCreateToJson(_HouseholdCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'city': instance.city,
      'district': instance.district,
      'address': instance.address,
    };

_InviteRequest _$InviteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InviteRequest', json, ($checkedConvert) {
      final val = _InviteRequest(
        phone: $checkedConvert('phone', (v) => v as String),
        role: $checkedConvert('role', (v) => v as MemberRole),
      );
      return val;
    });

Map<String, dynamic> _$InviteRequestToJson(_InviteRequest instance) =>
    <String, dynamic>{'phone': instance.phone, 'role': instance.role};

_MeterAddRequest _$MeterAddRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MeterAddRequest', json, ($checkedConvert) {
      final val = _MeterAddRequest(
        reference: $checkedConvert('reference', (v) => v as String),
        customerNumber: $checkedConvert('customer_number', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'customerNumber': 'customer_number'});

Map<String, dynamic> _$MeterAddRequestToJson(_MeterAddRequest instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'customer_number': instance.customerNumber,
      'label': instance.label,
    };

_HistoryImportPublic _$HistoryImportPublicFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HistoryImportPublic', json, ($checkedConvert) {
      final val = _HistoryImportPublic(
        readings: $checkedConvert('readings', (v) => (v as num).toInt()),
        bills: $checkedConvert('bills', (v) => (v as num).toInt()),
        source: $checkedConvert('source', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$HistoryImportPublicToJson(
  _HistoryImportPublic instance,
) => <String, dynamic>{
  'readings': instance.readings,
  'bills': instance.bills,
  'source': instance.source,
};

_MeterAddResponse _$MeterAddResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MeterAddResponse', json, ($checkedConvert) {
      final val = _MeterAddResponse(
        meter: $checkedConvert(
          'meter',
          (v) => MeterDetail.fromJson(v as Map<String, dynamic>),
        ),
        history: $checkedConvert(
          'history',
          (v) => HistoryImportPublic.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MeterAddResponseToJson(_MeterAddResponse instance) =>
    <String, dynamic>{
      'meter': instance.meter.toJson(),
      'history': instance.history.toJson(),
    };
