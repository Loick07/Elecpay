// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ErrorResponse', json, ($checkedConvert) {
      final val = _ErrorResponse(
        error: $checkedConvert(
          'error',
          (v) => ErrorBody.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ErrorResponseToJson(_ErrorResponse instance) =>
    <String, dynamic>{'error': instance.error.toJson()};

_ErrorBody _$ErrorBodyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ErrorBody', json, ($checkedConvert) {
      final val = _ErrorBody(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
        details: $checkedConvert(
          'details',
          (v) => v as Map<String, dynamic>? ?? const <String, Object?>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$ErrorBodyToJson(_ErrorBody instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };
