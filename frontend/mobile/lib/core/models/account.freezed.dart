// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationSent {

 String get sentTo; DateTime get expiresAt; String? get demoCode;
/// Create a copy of VerificationSent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationSentCopyWith<VerificationSent> get copyWith => _$VerificationSentCopyWithImpl<VerificationSent>(this as VerificationSent, _$identity);

  /// Serializes this VerificationSent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VerificationSent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationSent&&(identical(other.sentTo, _this.sentTo) || other.sentTo == _this.sentTo)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.demoCode, _this.demoCode) || other.demoCode == _this.demoCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VerificationSent;
  return Object.hash(runtimeType,_this.sentTo,_this.expiresAt,_this.demoCode);
}

@override
String toString() {
  final _this = this as VerificationSent;
  return 'VerificationSent(sentTo: ${_this.sentTo}, expiresAt: ${_this.expiresAt}, demoCode: ${_this.demoCode})';
}


}

/// @nodoc
abstract mixin class $VerificationSentCopyWith<$Res>  {
  factory $VerificationSentCopyWith(VerificationSent value, $Res Function(VerificationSent) _then) = _$VerificationSentCopyWithImpl;
@useResult
$Res call({
 String sentTo, DateTime expiresAt, String? demoCode
});




}
/// @nodoc
class _$VerificationSentCopyWithImpl<$Res>
    implements $VerificationSentCopyWith<$Res> {
  _$VerificationSentCopyWithImpl(this._self, this._then);

  final VerificationSent _self;
  final $Res Function(VerificationSent) _then;

/// Create a copy of VerificationSent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sentTo = null,Object? expiresAt = null,Object? demoCode = freezed,}) {
  return _then(VerificationSent(
sentTo: null == sentTo ? _self.sentTo : sentTo // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,demoCode: freezed == demoCode ? _self.demoCode : demoCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationSent].
extension VerificationSentPatterns on VerificationSent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationSent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationSent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationSent value)  $default,){
final _that = this;
switch (_that) {
case _VerificationSent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationSent value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationSent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sentTo,  DateTime expiresAt,  String? demoCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationSent() when $default != null:
return $default(_that.sentTo,_that.expiresAt,_that.demoCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sentTo,  DateTime expiresAt,  String? demoCode)  $default,) {final _that = this;
switch (_that) {
case _VerificationSent():
return $default(_that.sentTo,_that.expiresAt,_that.demoCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sentTo,  DateTime expiresAt,  String? demoCode)?  $default,) {final _that = this;
switch (_that) {
case _VerificationSent() when $default != null:
return $default(_that.sentTo,_that.expiresAt,_that.demoCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationSent implements VerificationSent {
  const _VerificationSent({required this.sentTo, required this.expiresAt, required this.demoCode});
  factory _VerificationSent.fromJson(Map<String, dynamic> json) => _$VerificationSentFromJson(json);

@override final  String sentTo;
@override final  DateTime expiresAt;
@override final  String? demoCode;

/// Create a copy of VerificationSent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationSentCopyWith<_VerificationSent> get copyWith => __$VerificationSentCopyWithImpl<_VerificationSent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationSentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationSent&&(identical(other.sentTo, sentTo) || other.sentTo == sentTo)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.demoCode, demoCode) || other.demoCode == demoCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sentTo,expiresAt,demoCode);
}

@override
String toString() {
    return 'VerificationSent(sentTo: $sentTo, expiresAt: $expiresAt, demoCode: $demoCode)';
}


}

/// @nodoc
abstract mixin class _$VerificationSentCopyWith<$Res> implements $VerificationSentCopyWith<$Res> {
  factory _$VerificationSentCopyWith(_VerificationSent value, $Res Function(_VerificationSent) _then) = __$VerificationSentCopyWithImpl;
@override @useResult
$Res call({
 String sentTo, DateTime expiresAt, String? demoCode
});




}
/// @nodoc
class __$VerificationSentCopyWithImpl<$Res>
    implements _$VerificationSentCopyWith<$Res> {
  __$VerificationSentCopyWithImpl(this._self, this._then);

  final _VerificationSent _self;
  final $Res Function(_VerificationSent) _then;

/// Create a copy of VerificationSent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentTo = null,Object? expiresAt = null,Object? demoCode = freezed,}) {
  return _then(_VerificationSent(
sentTo: null == sentTo ? _self.sentTo : sentTo // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,demoCode: freezed == demoCode ? _self.demoCode : demoCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VerificationConfirm {

 String get code;
/// Create a copy of VerificationConfirm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationConfirmCopyWith<VerificationConfirm> get copyWith => _$VerificationConfirmCopyWithImpl<VerificationConfirm>(this as VerificationConfirm, _$identity);

  /// Serializes this VerificationConfirm to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VerificationConfirm;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationConfirm&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VerificationConfirm;
  return Object.hash(runtimeType,_this.code);
}

@override
String toString() {
  final _this = this as VerificationConfirm;
  return 'VerificationConfirm(code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $VerificationConfirmCopyWith<$Res>  {
  factory $VerificationConfirmCopyWith(VerificationConfirm value, $Res Function(VerificationConfirm) _then) = _$VerificationConfirmCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$VerificationConfirmCopyWithImpl<$Res>
    implements $VerificationConfirmCopyWith<$Res> {
  _$VerificationConfirmCopyWithImpl(this._self, this._then);

  final VerificationConfirm _self;
  final $Res Function(VerificationConfirm) _then;

/// Create a copy of VerificationConfirm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(VerificationConfirm(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationConfirm].
extension VerificationConfirmPatterns on VerificationConfirm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationConfirm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationConfirm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationConfirm value)  $default,){
final _that = this;
switch (_that) {
case _VerificationConfirm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationConfirm value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationConfirm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationConfirm() when $default != null:
return $default(_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code)  $default,) {final _that = this;
switch (_that) {
case _VerificationConfirm():
return $default(_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code)?  $default,) {final _that = this;
switch (_that) {
case _VerificationConfirm() when $default != null:
return $default(_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationConfirm implements VerificationConfirm {
  const _VerificationConfirm({required this.code});
  factory _VerificationConfirm.fromJson(Map<String, dynamic> json) => _$VerificationConfirmFromJson(json);

@override final  String code;

/// Create a copy of VerificationConfirm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationConfirmCopyWith<_VerificationConfirm> get copyWith => __$VerificationConfirmCopyWithImpl<_VerificationConfirm>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationConfirmToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationConfirm&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code);
}

@override
String toString() {
    return 'VerificationConfirm(code: $code)';
}


}

/// @nodoc
abstract mixin class _$VerificationConfirmCopyWith<$Res> implements $VerificationConfirmCopyWith<$Res> {
  factory _$VerificationConfirmCopyWith(_VerificationConfirm value, $Res Function(_VerificationConfirm) _then) = __$VerificationConfirmCopyWithImpl;
@override @useResult
$Res call({
 String code
});




}
/// @nodoc
class __$VerificationConfirmCopyWithImpl<$Res>
    implements _$VerificationConfirmCopyWith<$Res> {
  __$VerificationConfirmCopyWithImpl(this._self, this._then);

  final _VerificationConfirm _self;
  final $Res Function(_VerificationConfirm) _then;

/// Create a copy of VerificationConfirm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(_VerificationConfirm(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationPreferences {

 bool get dueSoon; bool get payments; bool get highConsumption; bool get emailReceipts;
/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<NotificationPreferences> get copyWith => _$NotificationPreferencesCopyWithImpl<NotificationPreferences>(this as NotificationPreferences, _$identity);

  /// Serializes this NotificationPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferences&&(identical(other.dueSoon, _this.dueSoon) || other.dueSoon == _this.dueSoon)&&(identical(other.payments, _this.payments) || other.payments == _this.payments)&&(identical(other.highConsumption, _this.highConsumption) || other.highConsumption == _this.highConsumption)&&(identical(other.emailReceipts, _this.emailReceipts) || other.emailReceipts == _this.emailReceipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationPreferences;
  return Object.hash(runtimeType,_this.dueSoon,_this.payments,_this.highConsumption,_this.emailReceipts);
}

@override
String toString() {
  final _this = this as NotificationPreferences;
  return 'NotificationPreferences(dueSoon: ${_this.dueSoon}, payments: ${_this.payments}, highConsumption: ${_this.highConsumption}, emailReceipts: ${_this.emailReceipts})';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesCopyWith<$Res>  {
  factory $NotificationPreferencesCopyWith(NotificationPreferences value, $Res Function(NotificationPreferences) _then) = _$NotificationPreferencesCopyWithImpl;
@useResult
$Res call({
 bool dueSoon, bool payments, bool highConsumption, bool emailReceipts
});




}
/// @nodoc
class _$NotificationPreferencesCopyWithImpl<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final NotificationPreferences _self;
  final $Res Function(NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dueSoon = null,Object? payments = null,Object? highConsumption = null,Object? emailReceipts = null,}) {
  return _then(NotificationPreferences(
dueSoon: null == dueSoon ? _self.dueSoon : dueSoon // ignore: cast_nullable_to_non_nullable
as bool,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as bool,highConsumption: null == highConsumption ? _self.highConsumption : highConsumption // ignore: cast_nullable_to_non_nullable
as bool,emailReceipts: null == emailReceipts ? _self.emailReceipts : emailReceipts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferences].
extension NotificationPreferencesPatterns on NotificationPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferences value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool dueSoon,  bool payments,  bool highConsumption,  bool emailReceipts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.dueSoon,_that.payments,_that.highConsumption,_that.emailReceipts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool dueSoon,  bool payments,  bool highConsumption,  bool emailReceipts)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that.dueSoon,_that.payments,_that.highConsumption,_that.emailReceipts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool dueSoon,  bool payments,  bool highConsumption,  bool emailReceipts)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.dueSoon,_that.payments,_that.highConsumption,_that.emailReceipts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreferences implements NotificationPreferences {
  const _NotificationPreferences({required this.dueSoon, required this.payments, required this.highConsumption, required this.emailReceipts});
  factory _NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);

@override final  bool dueSoon;
@override final  bool payments;
@override final  bool highConsumption;
@override final  bool emailReceipts;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesCopyWith<_NotificationPreferences> get copyWith => __$NotificationPreferencesCopyWithImpl<_NotificationPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferences&&(identical(other.dueSoon, dueSoon) || other.dueSoon == dueSoon)&&(identical(other.payments, payments) || other.payments == payments)&&(identical(other.highConsumption, highConsumption) || other.highConsumption == highConsumption)&&(identical(other.emailReceipts, emailReceipts) || other.emailReceipts == emailReceipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,dueSoon,payments,highConsumption,emailReceipts);
}

@override
String toString() {
    return 'NotificationPreferences(dueSoon: $dueSoon, payments: $payments, highConsumption: $highConsumption, emailReceipts: $emailReceipts)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesCopyWith<$Res> implements $NotificationPreferencesCopyWith<$Res> {
  factory _$NotificationPreferencesCopyWith(_NotificationPreferences value, $Res Function(_NotificationPreferences) _then) = __$NotificationPreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool dueSoon, bool payments, bool highConsumption, bool emailReceipts
});




}
/// @nodoc
class __$NotificationPreferencesCopyWithImpl<$Res>
    implements _$NotificationPreferencesCopyWith<$Res> {
  __$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final _NotificationPreferences _self;
  final $Res Function(_NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dueSoon = null,Object? payments = null,Object? highConsumption = null,Object? emailReceipts = null,}) {
  return _then(_NotificationPreferences(
dueSoon: null == dueSoon ? _self.dueSoon : dueSoon // ignore: cast_nullable_to_non_nullable
as bool,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as bool,highConsumption: null == highConsumption ? _self.highConsumption : highConsumption // ignore: cast_nullable_to_non_nullable
as bool,emailReceipts: null == emailReceipts ? _self.emailReceipts : emailReceipts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ChangePasswordRequest {

 String get currentPassword; String get newPassword;
/// Create a copy of ChangePasswordRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePasswordRequestCopyWith<ChangePasswordRequest> get copyWith => _$ChangePasswordRequestCopyWithImpl<ChangePasswordRequest>(this as ChangePasswordRequest, _$identity);

  /// Serializes this ChangePasswordRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangePasswordRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordRequest&&(identical(other.currentPassword, _this.currentPassword) || other.currentPassword == _this.currentPassword)&&(identical(other.newPassword, _this.newPassword) || other.newPassword == _this.newPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangePasswordRequest;
  return Object.hash(runtimeType,_this.currentPassword,_this.newPassword);
}

@override
String toString() {
  final _this = this as ChangePasswordRequest;
  return 'ChangePasswordRequest(currentPassword: ${_this.currentPassword}, newPassword: ${_this.newPassword})';
}


}

/// @nodoc
abstract mixin class $ChangePasswordRequestCopyWith<$Res>  {
  factory $ChangePasswordRequestCopyWith(ChangePasswordRequest value, $Res Function(ChangePasswordRequest) _then) = _$ChangePasswordRequestCopyWithImpl;
@useResult
$Res call({
 String currentPassword, String newPassword
});




}
/// @nodoc
class _$ChangePasswordRequestCopyWithImpl<$Res>
    implements $ChangePasswordRequestCopyWith<$Res> {
  _$ChangePasswordRequestCopyWithImpl(this._self, this._then);

  final ChangePasswordRequest _self;
  final $Res Function(ChangePasswordRequest) _then;

/// Create a copy of ChangePasswordRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPassword = null,Object? newPassword = null,}) {
  return _then(ChangePasswordRequest(
currentPassword: null == currentPassword ? _self.currentPassword : currentPassword // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangePasswordRequest].
extension ChangePasswordRequestPatterns on ChangePasswordRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangePasswordRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangePasswordRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangePasswordRequest value)  $default,){
final _that = this;
switch (_that) {
case _ChangePasswordRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangePasswordRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ChangePasswordRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currentPassword,  String newPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangePasswordRequest() when $default != null:
return $default(_that.currentPassword,_that.newPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currentPassword,  String newPassword)  $default,) {final _that = this;
switch (_that) {
case _ChangePasswordRequest():
return $default(_that.currentPassword,_that.newPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currentPassword,  String newPassword)?  $default,) {final _that = this;
switch (_that) {
case _ChangePasswordRequest() when $default != null:
return $default(_that.currentPassword,_that.newPassword);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangePasswordRequest implements ChangePasswordRequest {
  const _ChangePasswordRequest({required this.currentPassword, required this.newPassword});
  factory _ChangePasswordRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordRequestFromJson(json);

@override final  String currentPassword;
@override final  String newPassword;

/// Create a copy of ChangePasswordRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangePasswordRequestCopyWith<_ChangePasswordRequest> get copyWith => __$ChangePasswordRequestCopyWithImpl<_ChangePasswordRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangePasswordRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangePasswordRequest&&(identical(other.currentPassword, currentPassword) || other.currentPassword == currentPassword)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currentPassword,newPassword);
}

@override
String toString() {
    return 'ChangePasswordRequest(currentPassword: $currentPassword, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class _$ChangePasswordRequestCopyWith<$Res> implements $ChangePasswordRequestCopyWith<$Res> {
  factory _$ChangePasswordRequestCopyWith(_ChangePasswordRequest value, $Res Function(_ChangePasswordRequest) _then) = __$ChangePasswordRequestCopyWithImpl;
@override @useResult
$Res call({
 String currentPassword, String newPassword
});




}
/// @nodoc
class __$ChangePasswordRequestCopyWithImpl<$Res>
    implements _$ChangePasswordRequestCopyWith<$Res> {
  __$ChangePasswordRequestCopyWithImpl(this._self, this._then);

  final _ChangePasswordRequest _self;
  final $Res Function(_ChangePasswordRequest) _then;

/// Create a copy of ChangePasswordRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPassword = null,Object? newPassword = null,}) {
  return _then(_ChangePasswordRequest(
currentPassword: null == currentPassword ? _self.currentPassword : currentPassword // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LogoutAllResponse {

 int get revokedSessions;
/// Create a copy of LogoutAllResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoutAllResponseCopyWith<LogoutAllResponse> get copyWith => _$LogoutAllResponseCopyWithImpl<LogoutAllResponse>(this as LogoutAllResponse, _$identity);

  /// Serializes this LogoutAllResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LogoutAllResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutAllResponse&&(identical(other.revokedSessions, _this.revokedSessions) || other.revokedSessions == _this.revokedSessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LogoutAllResponse;
  return Object.hash(runtimeType,_this.revokedSessions);
}

@override
String toString() {
  final _this = this as LogoutAllResponse;
  return 'LogoutAllResponse(revokedSessions: ${_this.revokedSessions})';
}


}

/// @nodoc
abstract mixin class $LogoutAllResponseCopyWith<$Res>  {
  factory $LogoutAllResponseCopyWith(LogoutAllResponse value, $Res Function(LogoutAllResponse) _then) = _$LogoutAllResponseCopyWithImpl;
@useResult
$Res call({
 int revokedSessions
});




}
/// @nodoc
class _$LogoutAllResponseCopyWithImpl<$Res>
    implements $LogoutAllResponseCopyWith<$Res> {
  _$LogoutAllResponseCopyWithImpl(this._self, this._then);

  final LogoutAllResponse _self;
  final $Res Function(LogoutAllResponse) _then;

/// Create a copy of LogoutAllResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revokedSessions = null,}) {
  return _then(LogoutAllResponse(
revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LogoutAllResponse].
extension LogoutAllResponsePatterns on LogoutAllResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogoutAllResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogoutAllResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogoutAllResponse value)  $default,){
final _that = this;
switch (_that) {
case _LogoutAllResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogoutAllResponse value)?  $default,){
final _that = this;
switch (_that) {
case _LogoutAllResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int revokedSessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogoutAllResponse() when $default != null:
return $default(_that.revokedSessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int revokedSessions)  $default,) {final _that = this;
switch (_that) {
case _LogoutAllResponse():
return $default(_that.revokedSessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int revokedSessions)?  $default,) {final _that = this;
switch (_that) {
case _LogoutAllResponse() when $default != null:
return $default(_that.revokedSessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogoutAllResponse implements LogoutAllResponse {
  const _LogoutAllResponse({required this.revokedSessions});
  factory _LogoutAllResponse.fromJson(Map<String, dynamic> json) => _$LogoutAllResponseFromJson(json);

@override final  int revokedSessions;

/// Create a copy of LogoutAllResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogoutAllResponseCopyWith<_LogoutAllResponse> get copyWith => __$LogoutAllResponseCopyWithImpl<_LogoutAllResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogoutAllResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogoutAllResponse&&(identical(other.revokedSessions, revokedSessions) || other.revokedSessions == revokedSessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,revokedSessions);
}

@override
String toString() {
    return 'LogoutAllResponse(revokedSessions: $revokedSessions)';
}


}

/// @nodoc
abstract mixin class _$LogoutAllResponseCopyWith<$Res> implements $LogoutAllResponseCopyWith<$Res> {
  factory _$LogoutAllResponseCopyWith(_LogoutAllResponse value, $Res Function(_LogoutAllResponse) _then) = __$LogoutAllResponseCopyWithImpl;
@override @useResult
$Res call({
 int revokedSessions
});




}
/// @nodoc
class __$LogoutAllResponseCopyWithImpl<$Res>
    implements _$LogoutAllResponseCopyWith<$Res> {
  __$LogoutAllResponseCopyWithImpl(this._self, this._then);

  final _LogoutAllResponse _self;
  final $Res Function(_LogoutAllResponse) _then;

/// Create a copy of LogoutAllResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revokedSessions = null,}) {
  return _then(_LogoutAllResponse(
revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
