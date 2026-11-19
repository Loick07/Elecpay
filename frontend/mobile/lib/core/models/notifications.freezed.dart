// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notifications.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnreadCount {

 int get unreadCount;
/// Create a copy of UnreadCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnreadCountCopyWith<UnreadCount> get copyWith => _$UnreadCountCopyWithImpl<UnreadCount>(this as UnreadCount, _$identity);

  /// Serializes this UnreadCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UnreadCount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadCount&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UnreadCount;
  return Object.hash(runtimeType,_this.unreadCount);
}

@override
String toString() {
  final _this = this as UnreadCount;
  return 'UnreadCount(unreadCount: ${_this.unreadCount})';
}


}

/// @nodoc
abstract mixin class $UnreadCountCopyWith<$Res>  {
  factory $UnreadCountCopyWith(UnreadCount value, $Res Function(UnreadCount) _then) = _$UnreadCountCopyWithImpl;
@useResult
$Res call({
 int unreadCount
});




}
/// @nodoc
class _$UnreadCountCopyWithImpl<$Res>
    implements $UnreadCountCopyWith<$Res> {
  _$UnreadCountCopyWithImpl(this._self, this._then);

  final UnreadCount _self;
  final $Res Function(UnreadCount) _then;

/// Create a copy of UnreadCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unreadCount = null,}) {
  return _then(UnreadCount(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UnreadCount].
extension UnreadCountPatterns on UnreadCount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnreadCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnreadCount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnreadCount value)  $default,){
final _that = this;
switch (_that) {
case _UnreadCount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnreadCount value)?  $default,){
final _that = this;
switch (_that) {
case _UnreadCount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnreadCount() when $default != null:
return $default(_that.unreadCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int unreadCount)  $default,) {final _that = this;
switch (_that) {
case _UnreadCount():
return $default(_that.unreadCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _UnreadCount() when $default != null:
return $default(_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnreadCount implements UnreadCount {
  const _UnreadCount({required this.unreadCount});
  factory _UnreadCount.fromJson(Map<String, dynamic> json) => _$UnreadCountFromJson(json);

@override final  int unreadCount;

/// Create a copy of UnreadCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnreadCountCopyWith<_UnreadCount> get copyWith => __$UnreadCountCopyWithImpl<_UnreadCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnreadCountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnreadCount&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,unreadCount);
}

@override
String toString() {
    return 'UnreadCount(unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$UnreadCountCopyWith<$Res> implements $UnreadCountCopyWith<$Res> {
  factory _$UnreadCountCopyWith(_UnreadCount value, $Res Function(_UnreadCount) _then) = __$UnreadCountCopyWithImpl;
@override @useResult
$Res call({
 int unreadCount
});




}
/// @nodoc
class __$UnreadCountCopyWithImpl<$Res>
    implements _$UnreadCountCopyWith<$Res> {
  __$UnreadCountCopyWithImpl(this._self, this._then);

  final _UnreadCount _self;
  final $Res Function(_UnreadCount) _then;

/// Create a copy of UnreadCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unreadCount = null,}) {
  return _then(_UnreadCount(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NotificationPublic {

 int get id; String get type; String get title; String get body;/// De quoi ouvrir le bon écran (`bill_id`, `receipt_id`…) ; un champ peut manquer.
 Map<String, dynamic>? get data; DateTime get createdAt; DateTime? get readAt; bool get isRead; String get group;
/// Create a copy of NotificationPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPublicCopyWith<NotificationPublic> get copyWith => _$NotificationPublicCopyWithImpl<NotificationPublic>(this as NotificationPublic, _$identity);

  /// Serializes this NotificationPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.data, _this.data)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.isRead, _this.isRead) || other.isRead == _this.isRead)&&(identical(other.group, _this.group) || other.group == _this.group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationPublic;
  return Object.hash(runtimeType,_this.id,_this.type,_this.title,_this.body,const DeepCollectionEquality().hash(_this.data),_this.createdAt,_this.readAt,_this.isRead,_this.group);
}

@override
String toString() {
  final _this = this as NotificationPublic;
  return 'NotificationPublic(id: ${_this.id}, type: ${_this.type}, title: ${_this.title}, body: ${_this.body}, data: ${_this.data}, createdAt: ${_this.createdAt}, readAt: ${_this.readAt}, isRead: ${_this.isRead}, group: ${_this.group})';
}


}

/// @nodoc
abstract mixin class $NotificationPublicCopyWith<$Res>  {
  factory $NotificationPublicCopyWith(NotificationPublic value, $Res Function(NotificationPublic) _then) = _$NotificationPublicCopyWithImpl;
@useResult
$Res call({
 int id, String type, String title, String body, Map<String, dynamic>? data, DateTime createdAt, DateTime? readAt, bool isRead, String group
});




}
/// @nodoc
class _$NotificationPublicCopyWithImpl<$Res>
    implements $NotificationPublicCopyWith<$Res> {
  _$NotificationPublicCopyWithImpl(this._self, this._then);

  final NotificationPublic _self;
  final $Res Function(NotificationPublic) _then;

/// Create a copy of NotificationPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? data = freezed,Object? createdAt = null,Object? readAt = freezed,Object? isRead = null,Object? group = null,}) {
  return _then(NotificationPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPublic].
extension NotificationPublicPatterns on NotificationPublic {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPublic() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPublic value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPublic():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPublic value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPublic() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String title,  String body,  Map<String, dynamic>? data,  DateTime createdAt,  DateTime? readAt,  bool isRead,  String group)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPublic() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.data,_that.createdAt,_that.readAt,_that.isRead,_that.group);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String title,  String body,  Map<String, dynamic>? data,  DateTime createdAt,  DateTime? readAt,  bool isRead,  String group)  $default,) {final _that = this;
switch (_that) {
case _NotificationPublic():
return $default(_that.id,_that.type,_that.title,_that.body,_that.data,_that.createdAt,_that.readAt,_that.isRead,_that.group);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String title,  String body,  Map<String, dynamic>? data,  DateTime createdAt,  DateTime? readAt,  bool isRead,  String group)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPublic() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.body,_that.data,_that.createdAt,_that.readAt,_that.isRead,_that.group);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPublic implements NotificationPublic {
  const _NotificationPublic({required this.id, required this.type, required this.title, required this.body, required  Map<String, dynamic>? data, required this.createdAt, required this.readAt, required this.isRead, required this.group}): _data = data;
  factory _NotificationPublic.fromJson(Map<String, dynamic> json) => _$NotificationPublicFromJson(json);

@override final  int id;
@override final  String type;
@override final  String title;
@override final  String body;
/// De quoi ouvrir le bon écran (`bill_id`, `receipt_id`…) ; un champ peut manquer.
 final  Map<String, dynamic>? _data;
/// De quoi ouvrir le bon écran (`bill_id`, `receipt_id`…) ; un champ peut manquer.
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;
@override final  DateTime? readAt;
@override final  bool isRead;
@override final  String group;

/// Create a copy of NotificationPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPublicCopyWith<_NotificationPublic> get copyWith => __$NotificationPublicCopyWithImpl<_NotificationPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.group, group) || other.group == group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,title,body,const DeepCollectionEquality().hash(_data),createdAt,readAt,isRead,group);
}

@override
String toString() {
    return 'NotificationPublic(id: $id, type: $type, title: $title, body: $body, data: $data, createdAt: $createdAt, readAt: $readAt, isRead: $isRead, group: $group)';
}


}

/// @nodoc
abstract mixin class _$NotificationPublicCopyWith<$Res> implements $NotificationPublicCopyWith<$Res> {
  factory _$NotificationPublicCopyWith(_NotificationPublic value, $Res Function(_NotificationPublic) _then) = __$NotificationPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String title, String body, Map<String, dynamic>? data, DateTime createdAt, DateTime? readAt, bool isRead, String group
});




}
/// @nodoc
class __$NotificationPublicCopyWithImpl<$Res>
    implements _$NotificationPublicCopyWith<$Res> {
  __$NotificationPublicCopyWithImpl(this._self, this._then);

  final _NotificationPublic _self;
  final $Res Function(_NotificationPublic) _then;

/// Create a copy of NotificationPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? body = null,Object? data = freezed,Object? createdAt = null,Object? readAt = freezed,Object? isRead = null,Object? group = null,}) {
  return _then(_NotificationPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationList {

 List<NotificationPublic> get items; int get total; int get page; int get size;/// Non lues, tous filtres confondus (badge de la cloche).
 int get unreadCount;
/// Create a copy of NotificationList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationListCopyWith<NotificationList> get copyWith => _$NotificationListCopyWithImpl<NotificationList>(this as NotificationList, _$identity);

  /// Serializes this NotificationList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationList&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationList;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.total,_this.page,_this.size,_this.unreadCount);
}

@override
String toString() {
  final _this = this as NotificationList;
  return 'NotificationList(items: ${_this.items}, total: ${_this.total}, page: ${_this.page}, size: ${_this.size}, unreadCount: ${_this.unreadCount})';
}


}

/// @nodoc
abstract mixin class $NotificationListCopyWith<$Res>  {
  factory $NotificationListCopyWith(NotificationList value, $Res Function(NotificationList) _then) = _$NotificationListCopyWithImpl;
@useResult
$Res call({
 List<NotificationPublic> items, int total, int page, int size, int unreadCount
});




}
/// @nodoc
class _$NotificationListCopyWithImpl<$Res>
    implements $NotificationListCopyWith<$Res> {
  _$NotificationListCopyWithImpl(this._self, this._then);

  final NotificationList _self;
  final $Res Function(NotificationList) _then;

/// Create a copy of NotificationList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,Object? page = null,Object? size = null,Object? unreadCount = null,}) {
  return _then(NotificationList(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationPublic>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationList].
extension NotificationListPatterns on NotificationList {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationList() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationList value)  $default,){
final _that = this;
switch (_that) {
case _NotificationList():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationList value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationList() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationPublic> items,  int total,  int page,  int size,  int unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationList() when $default != null:
return $default(_that.items,_that.total,_that.page,_that.size,_that.unreadCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationPublic> items,  int total,  int page,  int size,  int unreadCount)  $default,) {final _that = this;
switch (_that) {
case _NotificationList():
return $default(_that.items,_that.total,_that.page,_that.size,_that.unreadCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationPublic> items,  int total,  int page,  int size,  int unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _NotificationList() when $default != null:
return $default(_that.items,_that.total,_that.page,_that.size,_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationList implements NotificationList {
  const _NotificationList({required  List<NotificationPublic> items, required this.total, required this.page, required this.size, required this.unreadCount}): _items = items;
  factory _NotificationList.fromJson(Map<String, dynamic> json) => _$NotificationListFromJson(json);

 final  List<NotificationPublic> _items;
@override List<NotificationPublic> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int total;
@override final  int page;
@override final  int size;
/// Non lues, tous filtres confondus (badge de la cloche).
@override final  int unreadCount;

/// Create a copy of NotificationList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationListCopyWith<_NotificationList> get copyWith => __$NotificationListCopyWithImpl<_NotificationList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationList&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.total, total) || other.total == total)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total,page,size,unreadCount);
}

@override
String toString() {
    return 'NotificationList(items: $items, total: $total, page: $page, size: $size, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$NotificationListCopyWith<$Res> implements $NotificationListCopyWith<$Res> {
  factory _$NotificationListCopyWith(_NotificationList value, $Res Function(_NotificationList) _then) = __$NotificationListCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationPublic> items, int total, int page, int size, int unreadCount
});




}
/// @nodoc
class __$NotificationListCopyWithImpl<$Res>
    implements _$NotificationListCopyWith<$Res> {
  __$NotificationListCopyWithImpl(this._self, this._then);

  final _NotificationList _self;
  final $Res Function(_NotificationList) _then;

/// Create a copy of NotificationList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,Object? page = null,Object? size = null,Object? unreadCount = null,}) {
  return _then(_NotificationList(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationPublic>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReadAllResult {

 int get marked; int get unreadCount;
/// Create a copy of ReadAllResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadAllResultCopyWith<ReadAllResult> get copyWith => _$ReadAllResultCopyWithImpl<ReadAllResult>(this as ReadAllResult, _$identity);

  /// Serializes this ReadAllResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReadAllResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadAllResult&&(identical(other.marked, _this.marked) || other.marked == _this.marked)&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReadAllResult;
  return Object.hash(runtimeType,_this.marked,_this.unreadCount);
}

@override
String toString() {
  final _this = this as ReadAllResult;
  return 'ReadAllResult(marked: ${_this.marked}, unreadCount: ${_this.unreadCount})';
}


}

/// @nodoc
abstract mixin class $ReadAllResultCopyWith<$Res>  {
  factory $ReadAllResultCopyWith(ReadAllResult value, $Res Function(ReadAllResult) _then) = _$ReadAllResultCopyWithImpl;
@useResult
$Res call({
 int marked, int unreadCount
});




}
/// @nodoc
class _$ReadAllResultCopyWithImpl<$Res>
    implements $ReadAllResultCopyWith<$Res> {
  _$ReadAllResultCopyWithImpl(this._self, this._then);

  final ReadAllResult _self;
  final $Res Function(ReadAllResult) _then;

/// Create a copy of ReadAllResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? marked = null,Object? unreadCount = null,}) {
  return _then(ReadAllResult(
marked: null == marked ? _self.marked : marked // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadAllResult].
extension ReadAllResultPatterns on ReadAllResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadAllResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadAllResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadAllResult value)  $default,){
final _that = this;
switch (_that) {
case _ReadAllResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadAllResult value)?  $default,){
final _that = this;
switch (_that) {
case _ReadAllResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int marked,  int unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadAllResult() when $default != null:
return $default(_that.marked,_that.unreadCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int marked,  int unreadCount)  $default,) {final _that = this;
switch (_that) {
case _ReadAllResult():
return $default(_that.marked,_that.unreadCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int marked,  int unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _ReadAllResult() when $default != null:
return $default(_that.marked,_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadAllResult implements ReadAllResult {
  const _ReadAllResult({required this.marked, this.unreadCount = 0});
  factory _ReadAllResult.fromJson(Map<String, dynamic> json) => _$ReadAllResultFromJson(json);

@override final  int marked;
@override@JsonKey() final  int unreadCount;

/// Create a copy of ReadAllResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadAllResultCopyWith<_ReadAllResult> get copyWith => __$ReadAllResultCopyWithImpl<_ReadAllResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadAllResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadAllResult&&(identical(other.marked, marked) || other.marked == marked)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,marked,unreadCount);
}

@override
String toString() {
    return 'ReadAllResult(marked: $marked, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$ReadAllResultCopyWith<$Res> implements $ReadAllResultCopyWith<$Res> {
  factory _$ReadAllResultCopyWith(_ReadAllResult value, $Res Function(_ReadAllResult) _then) = __$ReadAllResultCopyWithImpl;
@override @useResult
$Res call({
 int marked, int unreadCount
});




}
/// @nodoc
class __$ReadAllResultCopyWithImpl<$Res>
    implements _$ReadAllResultCopyWith<$Res> {
  __$ReadAllResultCopyWithImpl(this._self, this._then);

  final _ReadAllResult _self;
  final $Res Function(_ReadAllResult) _then;

/// Create a copy of ReadAllResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? marked = null,Object? unreadCount = null,}) {
  return _then(_ReadAllResult(
marked: null == marked ? _self.marked : marked // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
