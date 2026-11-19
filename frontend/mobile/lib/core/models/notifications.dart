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

/// Groupes de l'écran 13 (`NotificationGroup`), calculés par l'API à l'heure de Brazzaville.
abstract final class NotificationGroups {
  static const today = 'today';
  static const thisWeek = 'this_week';
  static const earlier = 'earlier';
}

/// Types de notification (`NotificationType`). Gardés en texte : un type ajouté plus tard par l'API
/// s'affiche sans ouvrir d'écran particulier, sans planter l'application.
abstract final class NotificationTypes {
  static const billIssued = 'bill_issued';
  static const billDueSoon = 'bill_due_soon';
  static const billOverdue = 'bill_overdue';
  static const paymentSucceeded = 'payment_succeeded';
  static const paymentFailed = 'payment_failed';
  static const invitationReceived = 'invitation_received';
  static const consumptionAnomaly = 'consumption_anomaly';
  static const highConsumption = 'high_consumption';
  static const announcement = 'announcement';
}

/// Schéma OpenAPI : `NotificationPublic` (une ligne de l'écran 13).
@freezed
abstract class NotificationPublic with _$NotificationPublic {
  const factory NotificationPublic({
    required int id,
    required String type,
    required String title,
    required String body,

    /// De quoi ouvrir le bon écran (`bill_id`, `receipt_id`…) ; un champ peut manquer.
    required Map<String, dynamic>? data,
    required DateTime createdAt,
    required DateTime? readAt,
    required bool isRead,
    required String group,
  }) = _NotificationPublic;

  factory NotificationPublic.fromJson(Map<String, dynamic> json) =>
      _$NotificationPublicFromJson(json);
}

/// Schéma OpenAPI : `NotificationList` (`GET /notifications`).
@freezed
abstract class NotificationList with _$NotificationList {
  const factory NotificationList({
    required List<NotificationPublic> items,
    required int total,
    required int page,
    required int size,

    /// Non lues, tous filtres confondus (badge de la cloche).
    required int unreadCount,
  }) = _NotificationList;

  factory NotificationList.fromJson(Map<String, dynamic> json) => _$NotificationListFromJson(json);
}

/// Schéma OpenAPI : `ReadAllResult` (`POST /notifications/read-all`).
@freezed
abstract class ReadAllResult with _$ReadAllResult {
  const factory ReadAllResult({required int marked, @Default(0) int unreadCount}) = _ReadAllResult;

  factory ReadAllResult.fromJson(Map<String, dynamic> json) => _$ReadAllResultFromJson(json);
}
