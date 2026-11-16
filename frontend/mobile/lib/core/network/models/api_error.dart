import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

/// Format commun de TOUTES les erreurs de l'API : `{"error": {"code", "message", "details"}}`.
/// Schéma OpenAPI : `ErrorResponse`.
@freezed
abstract class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({required ErrorBody error}) = _ErrorResponse;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => _$ErrorResponseFromJson(json);
}

/// Schéma OpenAPI : `ErrorBody`. `code` est stable (ex. `TOKEN_EXPIRED`) : c'est lui qu'on teste,
/// jamais `message`. `details` dépend du code (ex. `retry_after_seconds`, `fields`).
@freezed
abstract class ErrorBody with _$ErrorBody {
  const factory ErrorBody({
    required String code,
    required String message,
    @Default(<String, Object?>{}) Map<String, Object?> details,
  }) = _ErrorBody;

  factory ErrorBody.fromJson(Map<String, dynamic> json) => _$ErrorBodyFromJson(json);
}
