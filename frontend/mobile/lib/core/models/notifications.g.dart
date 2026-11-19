// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnreadCount _$UnreadCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UnreadCount', json, ($checkedConvert) {
      final val = _UnreadCount(
        unreadCount: $checkedConvert('unread_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'unreadCount': 'unread_count'});

Map<String, dynamic> _$UnreadCountToJson(_UnreadCount instance) =>
    <String, dynamic>{'unread_count': instance.unreadCount};

_NotificationPublic _$NotificationPublicFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_NotificationPublic',
      json,
      ($checkedConvert) {
        final val = _NotificationPublic(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          type: $checkedConvert('type', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          data: $checkedConvert('data', (v) => v as Map<String, dynamic>?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          readAt: $checkedConvert(
            'read_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          isRead: $checkedConvert('is_read', (v) => v as bool),
          group: $checkedConvert('group', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'readAt': 'read_at',
        'isRead': 'is_read',
      },
    );

Map<String, dynamic> _$NotificationPublicToJson(_NotificationPublic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'created_at': instance.createdAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
      'is_read': instance.isRead,
      'group': instance.group,
    };

_NotificationList _$NotificationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NotificationList', json, ($checkedConvert) {
      final val = _NotificationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => NotificationPublic.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        unreadCount: $checkedConvert('unread_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'unreadCount': 'unread_count'});

Map<String, dynamic> _$NotificationListToJson(_NotificationList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'size': instance.size,
      'unread_count': instance.unreadCount,
    };

_ReadAllResult _$ReadAllResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReadAllResult', json, ($checkedConvert) {
      final val = _ReadAllResult(
        marked: $checkedConvert('marked', (v) => (v as num).toInt()),
        unreadCount: $checkedConvert(
          'unread_count',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
      );
      return val;
    }, fieldKeyMap: const {'unreadCount': 'unread_count'});

Map<String, dynamic> _$ReadAllResultToJson(_ReadAllResult instance) =>
    <String, dynamic>{
      'marked': instance.marked,
      'unread_count': instance.unreadCount,
    };
