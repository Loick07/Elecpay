// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPublic _$UserPublicFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_UserPublic',
  json,
  ($checkedConvert) {
    final val = _UserPublic(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      fullName: $checkedConvert('full_name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String?),
      emailVerifiedAt: $checkedConvert(
        'email_verified_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      role: $checkedConvert(
        'role',
        (v) =>
            $enumDecode(_$UserRoleEnumMap, v, unknownValue: UserRole.unknown),
      ),
      isActive: $checkedConvert('is_active', (v) => v as bool),
      lastLoginAt: $checkedConvert(
        'last_login_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fullName': 'full_name',
    'emailVerifiedAt': 'email_verified_at',
    'isActive': 'is_active',
    'lastLoginAt': 'last_login_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$UserPublicToJson(_UserPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'email': instance.email,
      'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
      'role': _$UserRoleEnumMap[instance.role]!,
      'is_active': instance.isActive,
      'last_login_at': instance.lastLoginAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.client: 'client',
  UserRole.support: 'support',
  UserRole.admin: 'admin',
  UserRole.superAdmin: 'super_admin',
  UserRole.unknown: 'unknown',
};

_TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_TokenResponse',
      json,
      ($checkedConvert) {
        final val = _TokenResponse(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          accessExpiresAt: $checkedConvert(
            'access_expires_at',
            (v) => DateTime.parse(v as String),
          ),
          expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          refreshExpiresAt: $checkedConvert(
            'refresh_expires_at',
            (v) => DateTime.parse(v as String),
          ),
          tokenType: $checkedConvert(
            'token_type',
            (v) => v as String? ?? 'bearer',
          ),
          user: $checkedConvert(
            'user',
            (v) => UserPublic.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'accessExpiresAt': 'access_expires_at',
        'expiresIn': 'expires_in',
        'refreshToken': 'refresh_token',
        'refreshExpiresAt': 'refresh_expires_at',
        'tokenType': 'token_type',
      },
    );

Map<String, dynamic> _$TokenResponseToJson(_TokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'access_expires_at': instance.accessExpiresAt.toIso8601String(),
      'expires_in': instance.expiresIn,
      'refresh_token': instance.refreshToken,
      'refresh_expires_at': instance.refreshExpiresAt.toIso8601String(),
      'token_type': instance.tokenType,
      'user': instance.user.toJson(),
    };

_TwoFactorChallenge _$TwoFactorChallengeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_TwoFactorChallenge',
      json,
      ($checkedConvert) {
        final val = _TwoFactorChallenge(
          challengeToken: $checkedConvert(
            'challenge_token',
            (v) => v as String,
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          methods: $checkedConvert(
            'methods',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const <String>['totp', 'backup_code'],
          ),
          twoFactorRequired: $checkedConvert(
            'two_factor_required',
            (v) => v as bool? ?? true,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'challengeToken': 'challenge_token',
        'expiresAt': 'expires_at',
        'twoFactorRequired': 'two_factor_required',
      },
    );

Map<String, dynamic> _$TwoFactorChallengeToJson(_TwoFactorChallenge instance) =>
    <String, dynamic>{
      'challenge_token': instance.challengeToken,
      'expires_at': instance.expiresAt.toIso8601String(),
      'methods': instance.methods,
      'two_factor_required': instance.twoFactorRequired,
    };

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LoginRequest', json, ($checkedConvert) {
      final val = _LoginRequest(
        phone: $checkedConvert('phone', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'phone': instance.phone, 'password': instance.password};

_RefreshRequest _$RefreshRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RefreshRequest', json, ($checkedConvert) {
      final val = _RefreshRequest(
        refreshToken: $checkedConvert('refresh_token', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'refreshToken': 'refresh_token'});

Map<String, dynamic> _$RefreshRequestToJson(_RefreshRequest instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};
