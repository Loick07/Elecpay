// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationSent _$VerificationSentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_VerificationSent',
      json,
      ($checkedConvert) {
        final val = _VerificationSent(
          sentTo: $checkedConvert('sent_to', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          demoCode: $checkedConvert('demo_code', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'sentTo': 'sent_to',
        'expiresAt': 'expires_at',
        'demoCode': 'demo_code',
      },
    );

Map<String, dynamic> _$VerificationSentToJson(_VerificationSent instance) =>
    <String, dynamic>{
      'sent_to': instance.sentTo,
      'expires_at': instance.expiresAt.toIso8601String(),
      'demo_code': instance.demoCode,
    };

_VerificationConfirm _$VerificationConfirmFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_VerificationConfirm', json, ($checkedConvert) {
      final val = _VerificationConfirm(
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$VerificationConfirmToJson(
  _VerificationConfirm instance,
) => <String, dynamic>{'code': instance.code};

_NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NotificationPreferences',
  json,
  ($checkedConvert) {
    final val = _NotificationPreferences(
      dueSoon: $checkedConvert('due_soon', (v) => v as bool),
      payments: $checkedConvert('payments', (v) => v as bool),
      highConsumption: $checkedConvert('high_consumption', (v) => v as bool),
      emailReceipts: $checkedConvert('email_receipts', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'dueSoon': 'due_soon',
    'highConsumption': 'high_consumption',
    'emailReceipts': 'email_receipts',
  },
);

Map<String, dynamic> _$NotificationPreferencesToJson(
  _NotificationPreferences instance,
) => <String, dynamic>{
  'due_soon': instance.dueSoon,
  'payments': instance.payments,
  'high_consumption': instance.highConsumption,
  'email_receipts': instance.emailReceipts,
};

_ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ChangePasswordRequest',
  json,
  ($checkedConvert) {
    final val = _ChangePasswordRequest(
      currentPassword: $checkedConvert('current_password', (v) => v as String),
      newPassword: $checkedConvert('new_password', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'currentPassword': 'current_password',
    'newPassword': 'new_password',
  },
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  _ChangePasswordRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};

_LogoutAllResponse _$LogoutAllResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LogoutAllResponse', json, ($checkedConvert) {
      final val = _LogoutAllResponse(
        revokedSessions: $checkedConvert(
          'revoked_sessions',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'revokedSessions': 'revoked_sessions'});

Map<String, dynamic> _$LogoutAllResponseToJson(_LogoutAllResponse instance) =>
    <String, dynamic>{'revoked_sessions': instance.revokedSessions};
