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
