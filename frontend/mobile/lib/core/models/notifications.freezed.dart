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

// dart format on
