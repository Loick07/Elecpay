import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

// Notifications, écrites à la main d'après `backend/openapi.json` (vérifiées par
// test/contract/openapi_contract_test.dart). Guide : backend/docs/NOTIFICATIONS.md.

/// Schéma OpenAPI : `UnreadCount` (`GET /notifications/unread-count`, badge de la cloche).
@freezed
abstract class UnreadCount with _$UnreadCount {
  const factory UnreadCount({required int unreadCount}) = _UnreadCount;

  factory UnreadCount.fromJson(Map<String, dynamic> json) => _$UnreadCountFromJson(json);
}
