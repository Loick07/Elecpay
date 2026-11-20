// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consumption.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayPeak {

 DateTime get day; int get consumptionWh; double get consumptionKwh;
/// Create a copy of DayPeak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayPeakCopyWith<DayPeak> get copyWith => _$DayPeakCopyWithImpl<DayPeak>(this as DayPeak, _$identity);

  /// Serializes this DayPeak to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayPeak;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayPeak&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayPeak;
  return Object.hash(runtimeType,_this.day,_this.consumptionWh,_this.consumptionKwh);
}

@override
String toString() {
  final _this = this as DayPeak;
  return 'DayPeak(day: ${_this.day}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh})';
}


}

/// @nodoc
abstract mixin class $DayPeakCopyWith<$Res>  {
  factory $DayPeakCopyWith(DayPeak value, $Res Function(DayPeak) _then) = _$DayPeakCopyWithImpl;
@useResult
$Res call({
 DateTime day, int consumptionWh, double consumptionKwh
});




}
/// @nodoc
class _$DayPeakCopyWithImpl<$Res>
    implements $DayPeakCopyWith<$Res> {
  _$DayPeakCopyWithImpl(this._self, this._then);

  final DayPeak _self;
  final $Res Function(DayPeak) _then;

/// Create a copy of DayPeak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? consumptionWh = null,Object? consumptionKwh = null,}) {
  return _then(DayPeak(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DayPeak].
extension DayPeakPatterns on DayPeak {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayPeak value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayPeak() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayPeak value)  $default,){
final _that = this;
switch (_that) {
case _DayPeak():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayPeak value)?  $default,){
final _that = this;
switch (_that) {
case _DayPeak() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  int consumptionWh,  double consumptionKwh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayPeak() when $default != null:
return $default(_that.day,_that.consumptionWh,_that.consumptionKwh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  int consumptionWh,  double consumptionKwh)  $default,) {final _that = this;
switch (_that) {
case _DayPeak():
return $default(_that.day,_that.consumptionWh,_that.consumptionKwh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  int consumptionWh,  double consumptionKwh)?  $default,) {final _that = this;
switch (_that) {
case _DayPeak() when $default != null:
return $default(_that.day,_that.consumptionWh,_that.consumptionKwh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayPeak implements DayPeak {
  const _DayPeak({required this.day, required this.consumptionWh, required this.consumptionKwh});
  factory _DayPeak.fromJson(Map<String, dynamic> json) => _$DayPeakFromJson(json);

@override final  DateTime day;
@override final  int consumptionWh;
@override final  double consumptionKwh;

/// Create a copy of DayPeak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayPeakCopyWith<_DayPeak> get copyWith => __$DayPeakCopyWithImpl<_DayPeak>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayPeakToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayPeak&&(identical(other.day, day) || other.day == day)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,day,consumptionWh,consumptionKwh);
}

@override
String toString() {
    return 'DayPeak(day: $day, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh)';
}


}

/// @nodoc
abstract mixin class _$DayPeakCopyWith<$Res> implements $DayPeakCopyWith<$Res> {
  factory _$DayPeakCopyWith(_DayPeak value, $Res Function(_DayPeak) _then) = __$DayPeakCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, int consumptionWh, double consumptionKwh
});




}
/// @nodoc
class __$DayPeakCopyWithImpl<$Res>
    implements _$DayPeakCopyWith<$Res> {
  __$DayPeakCopyWithImpl(this._self, this._then);

  final _DayPeak _self;
  final $Res Function(_DayPeak) _then;

/// Create a copy of DayPeak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? consumptionWh = null,Object? consumptionKwh = null,}) {
  return _then(_DayPeak(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$MonthSoFar {

 DateTime get start; DateTime? get end; int get daysWithData; int get consumptionWh; double get consumptionKwh; int? get energyCost; int get dailyAverageWh; DayPeak? get highestDay;
/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthSoFarCopyWith<MonthSoFar> get copyWith => _$MonthSoFarCopyWithImpl<MonthSoFar>(this as MonthSoFar, _$identity);

  /// Serializes this MonthSoFar to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MonthSoFar;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthSoFar&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.daysWithData, _this.daysWithData) || other.daysWithData == _this.daysWithData)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost)&&(identical(other.dailyAverageWh, _this.dailyAverageWh) || other.dailyAverageWh == _this.dailyAverageWh)&&(identical(other.highestDay, _this.highestDay) || other.highestDay == _this.highestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MonthSoFar;
  return Object.hash(runtimeType,_this.start,_this.end,_this.daysWithData,_this.consumptionWh,_this.consumptionKwh,_this.energyCost,_this.dailyAverageWh,_this.highestDay);
}

@override
String toString() {
  final _this = this as MonthSoFar;
  return 'MonthSoFar(start: ${_this.start}, end: ${_this.end}, daysWithData: ${_this.daysWithData}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, energyCost: ${_this.energyCost}, dailyAverageWh: ${_this.dailyAverageWh}, highestDay: ${_this.highestDay})';
}


}

/// @nodoc
abstract mixin class $MonthSoFarCopyWith<$Res>  {
  factory $MonthSoFarCopyWith(MonthSoFar value, $Res Function(MonthSoFar) _then) = _$MonthSoFarCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime? end, int daysWithData, int consumptionWh, double consumptionKwh, int? energyCost, int dailyAverageWh, DayPeak? highestDay
});


$DayPeakCopyWith<$Res>? get highestDay;

}
/// @nodoc
class _$MonthSoFarCopyWithImpl<$Res>
    implements $MonthSoFarCopyWith<$Res> {
  _$MonthSoFarCopyWithImpl(this._self, this._then);

  final MonthSoFar _self;
  final $Res Function(MonthSoFar) _then;

/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = freezed,Object? daysWithData = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? dailyAverageWh = null,Object? highestDay = freezed,}) {
  return _then(MonthSoFar(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime?,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,dailyAverageWh: null == dailyAverageWh ? _self.dailyAverageWh : dailyAverageWh // ignore: cast_nullable_to_non_nullable
as int,highestDay: freezed == highestDay ? _self.highestDay : highestDay // ignore: cast_nullable_to_non_nullable
as DayPeak?,
  ));
}
/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayPeakCopyWith<$Res>? get highestDay {
    if (_self.highestDay == null) {
    return null;
  }

  return $DayPeakCopyWith<$Res>(_self.highestDay!, (value) {
    return _then(_self.copyWith(highestDay: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonthSoFar].
extension MonthSoFarPatterns on MonthSoFar {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthSoFar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthSoFar() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthSoFar value)  $default,){
final _that = this;
switch (_that) {
case _MonthSoFar():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthSoFar value)?  $default,){
final _that = this;
switch (_that) {
case _MonthSoFar() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  DateTime? end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int dailyAverageWh,  DayPeak? highestDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthSoFar() when $default != null:
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.dailyAverageWh,_that.highestDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  DateTime? end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int dailyAverageWh,  DayPeak? highestDay)  $default,) {final _that = this;
switch (_that) {
case _MonthSoFar():
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.dailyAverageWh,_that.highestDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  DateTime? end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int dailyAverageWh,  DayPeak? highestDay)?  $default,) {final _that = this;
switch (_that) {
case _MonthSoFar() when $default != null:
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.dailyAverageWh,_that.highestDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthSoFar implements MonthSoFar {
  const _MonthSoFar({required this.start, required this.end, required this.daysWithData, required this.consumptionWh, required this.consumptionKwh, required this.energyCost, required this.dailyAverageWh, required this.highestDay});
  factory _MonthSoFar.fromJson(Map<String, dynamic> json) => _$MonthSoFarFromJson(json);

@override final  DateTime start;
@override final  DateTime? end;
@override final  int daysWithData;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int? energyCost;
@override final  int dailyAverageWh;
@override final  DayPeak? highestDay;

/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthSoFarCopyWith<_MonthSoFar> get copyWith => __$MonthSoFarCopyWithImpl<_MonthSoFar>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthSoFarToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthSoFar&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.daysWithData, daysWithData) || other.daysWithData == daysWithData)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.dailyAverageWh, dailyAverageWh) || other.dailyAverageWh == dailyAverageWh)&&(identical(other.highestDay, highestDay) || other.highestDay == highestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,daysWithData,consumptionWh,consumptionKwh,energyCost,dailyAverageWh,highestDay);
}

@override
String toString() {
    return 'MonthSoFar(start: $start, end: $end, daysWithData: $daysWithData, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, energyCost: $energyCost, dailyAverageWh: $dailyAverageWh, highestDay: $highestDay)';
}


}

/// @nodoc
abstract mixin class _$MonthSoFarCopyWith<$Res> implements $MonthSoFarCopyWith<$Res> {
  factory _$MonthSoFarCopyWith(_MonthSoFar value, $Res Function(_MonthSoFar) _then) = __$MonthSoFarCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, DateTime? end, int daysWithData, int consumptionWh, double consumptionKwh, int? energyCost, int dailyAverageWh, DayPeak? highestDay
});


@override $DayPeakCopyWith<$Res>? get highestDay;

}
/// @nodoc
class __$MonthSoFarCopyWithImpl<$Res>
    implements _$MonthSoFarCopyWith<$Res> {
  __$MonthSoFarCopyWithImpl(this._self, this._then);

  final _MonthSoFar _self;
  final $Res Function(_MonthSoFar) _then;

/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = freezed,Object? daysWithData = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? dailyAverageWh = null,Object? highestDay = freezed,}) {
  return _then(_MonthSoFar(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime?,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,dailyAverageWh: null == dailyAverageWh ? _self.dailyAverageWh : dailyAverageWh // ignore: cast_nullable_to_non_nullable
as int,highestDay: freezed == highestDay ? _self.highestDay : highestDay // ignore: cast_nullable_to_non_nullable
as DayPeak?,
  ));
}

/// Create a copy of MonthSoFar
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayPeakCopyWith<$Res>? get highestDay {
    if (_self.highestDay == null) {
    return null;
  }

  return $DayPeakCopyWith<$Res>(_self.highestDay!, (value) {
    return _then(_self.copyWith(highestDay: value));
  });
}
}


/// @nodoc
mixin _$LastMonth {

 DateTime get start; DateTime get end; int get daysWithData; int get consumptionWh; double get consumptionKwh; int? get energyCost; int? get estimatedTotal;
/// Create a copy of LastMonth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastMonthCopyWith<LastMonth> get copyWith => _$LastMonthCopyWithImpl<LastMonth>(this as LastMonth, _$identity);

  /// Serializes this LastMonth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LastMonth;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastMonth&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.daysWithData, _this.daysWithData) || other.daysWithData == _this.daysWithData)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost)&&(identical(other.estimatedTotal, _this.estimatedTotal) || other.estimatedTotal == _this.estimatedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LastMonth;
  return Object.hash(runtimeType,_this.start,_this.end,_this.daysWithData,_this.consumptionWh,_this.consumptionKwh,_this.energyCost,_this.estimatedTotal);
}

@override
String toString() {
  final _this = this as LastMonth;
  return 'LastMonth(start: ${_this.start}, end: ${_this.end}, daysWithData: ${_this.daysWithData}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, energyCost: ${_this.energyCost}, estimatedTotal: ${_this.estimatedTotal})';
}


}

/// @nodoc
abstract mixin class $LastMonthCopyWith<$Res>  {
  factory $LastMonthCopyWith(LastMonth value, $Res Function(LastMonth) _then) = _$LastMonthCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, int daysWithData, int consumptionWh, double consumptionKwh, int? energyCost, int? estimatedTotal
});




}
/// @nodoc
class _$LastMonthCopyWithImpl<$Res>
    implements $LastMonthCopyWith<$Res> {
  _$LastMonthCopyWithImpl(this._self, this._then);

  final LastMonth _self;
  final $Res Function(LastMonth) _then;

/// Create a copy of LastMonth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? daysWithData = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,}) {
  return _then(LastMonth(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [LastMonth].
extension LastMonthPatterns on LastMonth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastMonth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastMonth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastMonth value)  $default,){
final _that = this;
switch (_that) {
case _LastMonth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastMonth value)?  $default,){
final _that = this;
switch (_that) {
case _LastMonth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastMonth() when $default != null:
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal)  $default,) {final _that = this;
switch (_that) {
case _LastMonth():
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  DateTime end,  int daysWithData,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal)?  $default,) {final _that = this;
switch (_that) {
case _LastMonth() when $default != null:
return $default(_that.start,_that.end,_that.daysWithData,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastMonth implements LastMonth {
  const _LastMonth({required this.start, required this.end, required this.daysWithData, required this.consumptionWh, required this.consumptionKwh, required this.energyCost, required this.estimatedTotal});
  factory _LastMonth.fromJson(Map<String, dynamic> json) => _$LastMonthFromJson(json);

@override final  DateTime start;
@override final  DateTime end;
@override final  int daysWithData;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int? energyCost;
@override final  int? estimatedTotal;

/// Create a copy of LastMonth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastMonthCopyWith<_LastMonth> get copyWith => __$LastMonthCopyWithImpl<_LastMonth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastMonthToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastMonth&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.daysWithData, daysWithData) || other.daysWithData == daysWithData)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.estimatedTotal, estimatedTotal) || other.estimatedTotal == estimatedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,daysWithData,consumptionWh,consumptionKwh,energyCost,estimatedTotal);
}

@override
String toString() {
    return 'LastMonth(start: $start, end: $end, daysWithData: $daysWithData, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, energyCost: $energyCost, estimatedTotal: $estimatedTotal)';
}


}

/// @nodoc
abstract mixin class _$LastMonthCopyWith<$Res> implements $LastMonthCopyWith<$Res> {
  factory _$LastMonthCopyWith(_LastMonth value, $Res Function(_LastMonth) _then) = __$LastMonthCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, DateTime end, int daysWithData, int consumptionWh, double consumptionKwh, int? energyCost, int? estimatedTotal
});




}
/// @nodoc
class __$LastMonthCopyWithImpl<$Res>
    implements _$LastMonthCopyWith<$Res> {
  __$LastMonthCopyWithImpl(this._self, this._then);

  final _LastMonth _self;
  final $Res Function(_LastMonth) _then;

/// Create a copy of LastMonth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? daysWithData = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,}) {
  return _then(_LastMonth(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MonthEndEstimate {

 int get consumptionWh; double get consumptionKwh; int? get energyCost; int? get estimatedTotal; int get remainingDays; String get basis;
/// Create a copy of MonthEndEstimate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthEndEstimateCopyWith<MonthEndEstimate> get copyWith => _$MonthEndEstimateCopyWithImpl<MonthEndEstimate>(this as MonthEndEstimate, _$identity);

  /// Serializes this MonthEndEstimate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MonthEndEstimate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthEndEstimate&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost)&&(identical(other.estimatedTotal, _this.estimatedTotal) || other.estimatedTotal == _this.estimatedTotal)&&(identical(other.remainingDays, _this.remainingDays) || other.remainingDays == _this.remainingDays)&&(identical(other.basis, _this.basis) || other.basis == _this.basis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MonthEndEstimate;
  return Object.hash(runtimeType,_this.consumptionWh,_this.consumptionKwh,_this.energyCost,_this.estimatedTotal,_this.remainingDays,_this.basis);
}

@override
String toString() {
  final _this = this as MonthEndEstimate;
  return 'MonthEndEstimate(consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, energyCost: ${_this.energyCost}, estimatedTotal: ${_this.estimatedTotal}, remainingDays: ${_this.remainingDays}, basis: ${_this.basis})';
}


}

/// @nodoc
abstract mixin class $MonthEndEstimateCopyWith<$Res>  {
  factory $MonthEndEstimateCopyWith(MonthEndEstimate value, $Res Function(MonthEndEstimate) _then) = _$MonthEndEstimateCopyWithImpl;
@useResult
$Res call({
 int consumptionWh, double consumptionKwh, int? energyCost, int? estimatedTotal, int remainingDays, String basis
});




}
/// @nodoc
class _$MonthEndEstimateCopyWithImpl<$Res>
    implements $MonthEndEstimateCopyWith<$Res> {
  _$MonthEndEstimateCopyWithImpl(this._self, this._then);

  final MonthEndEstimate _self;
  final $Res Function(MonthEndEstimate) _then;

/// Create a copy of MonthEndEstimate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,Object? remainingDays = null,Object? basis = null,}) {
  return _then(MonthEndEstimate(
consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,remainingDays: null == remainingDays ? _self.remainingDays : remainingDays // ignore: cast_nullable_to_non_nullable
as int,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthEndEstimate].
extension MonthEndEstimatePatterns on MonthEndEstimate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthEndEstimate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthEndEstimate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthEndEstimate value)  $default,){
final _that = this;
switch (_that) {
case _MonthEndEstimate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthEndEstimate value)?  $default,){
final _that = this;
switch (_that) {
case _MonthEndEstimate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal,  int remainingDays,  String basis)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthEndEstimate() when $default != null:
return $default(_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal,_that.remainingDays,_that.basis);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal,  int remainingDays,  String basis)  $default,) {final _that = this;
switch (_that) {
case _MonthEndEstimate():
return $default(_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal,_that.remainingDays,_that.basis);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int consumptionWh,  double consumptionKwh,  int? energyCost,  int? estimatedTotal,  int remainingDays,  String basis)?  $default,) {final _that = this;
switch (_that) {
case _MonthEndEstimate() when $default != null:
return $default(_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.estimatedTotal,_that.remainingDays,_that.basis);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthEndEstimate implements MonthEndEstimate {
  const _MonthEndEstimate({required this.consumptionWh, required this.consumptionKwh, required this.energyCost, required this.estimatedTotal, required this.remainingDays, required this.basis});
  factory _MonthEndEstimate.fromJson(Map<String, dynamic> json) => _$MonthEndEstimateFromJson(json);

@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int? energyCost;
@override final  int? estimatedTotal;
@override final  int remainingDays;
@override final  String basis;

/// Create a copy of MonthEndEstimate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthEndEstimateCopyWith<_MonthEndEstimate> get copyWith => __$MonthEndEstimateCopyWithImpl<_MonthEndEstimate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthEndEstimateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthEndEstimate&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.estimatedTotal, estimatedTotal) || other.estimatedTotal == estimatedTotal)&&(identical(other.remainingDays, remainingDays) || other.remainingDays == remainingDays)&&(identical(other.basis, basis) || other.basis == basis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,consumptionWh,consumptionKwh,energyCost,estimatedTotal,remainingDays,basis);
}

@override
String toString() {
    return 'MonthEndEstimate(consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, energyCost: $energyCost, estimatedTotal: $estimatedTotal, remainingDays: $remainingDays, basis: $basis)';
}


}

/// @nodoc
abstract mixin class _$MonthEndEstimateCopyWith<$Res> implements $MonthEndEstimateCopyWith<$Res> {
  factory _$MonthEndEstimateCopyWith(_MonthEndEstimate value, $Res Function(_MonthEndEstimate) _then) = __$MonthEndEstimateCopyWithImpl;
@override @useResult
$Res call({
 int consumptionWh, double consumptionKwh, int? energyCost, int? estimatedTotal, int remainingDays, String basis
});




}
/// @nodoc
class __$MonthEndEstimateCopyWithImpl<$Res>
    implements _$MonthEndEstimateCopyWith<$Res> {
  __$MonthEndEstimateCopyWithImpl(this._self, this._then);

  final _MonthEndEstimate _self;
  final $Res Function(_MonthEndEstimate) _then;

/// Create a copy of MonthEndEstimate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,Object? remainingDays = null,Object? basis = null,}) {
  return _then(_MonthEndEstimate(
consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,remainingDays: null == remainingDays ? _self.remainingDays : remainingDays // ignore: cast_nullable_to_non_nullable
as int,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ConsumptionSummary {

 int get meterId;/// Dernier jour relevé (`null` : aucun relevé).
 DateTime? get measuredUntil; MonthSoFar get thisMonth; LastMonth get lastMonth; double? get variationPercent; MonthEndEstimate? get monthEndEstimate;/// Le tarif appliqué est-il une hypothèse (aucun tarif daté connu) ?
 bool get tariffIsAssumption;/// `simulated` (mode démo) ou `e2c`.
 String get source;
/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionSummaryCopyWith<ConsumptionSummary> get copyWith => _$ConsumptionSummaryCopyWithImpl<ConsumptionSummary>(this as ConsumptionSummary, _$identity);

  /// Serializes this ConsumptionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsumptionSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionSummary&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.measuredUntil, _this.measuredUntil) || other.measuredUntil == _this.measuredUntil)&&(identical(other.thisMonth, _this.thisMonth) || other.thisMonth == _this.thisMonth)&&(identical(other.lastMonth, _this.lastMonth) || other.lastMonth == _this.lastMonth)&&(identical(other.variationPercent, _this.variationPercent) || other.variationPercent == _this.variationPercent)&&(identical(other.monthEndEstimate, _this.monthEndEstimate) || other.monthEndEstimate == _this.monthEndEstimate)&&(identical(other.tariffIsAssumption, _this.tariffIsAssumption) || other.tariffIsAssumption == _this.tariffIsAssumption)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsumptionSummary;
  return Object.hash(runtimeType,_this.meterId,_this.measuredUntil,_this.thisMonth,_this.lastMonth,_this.variationPercent,_this.monthEndEstimate,_this.tariffIsAssumption,_this.source);
}

@override
String toString() {
  final _this = this as ConsumptionSummary;
  return 'ConsumptionSummary(meterId: ${_this.meterId}, measuredUntil: ${_this.measuredUntil}, thisMonth: ${_this.thisMonth}, lastMonth: ${_this.lastMonth}, variationPercent: ${_this.variationPercent}, monthEndEstimate: ${_this.monthEndEstimate}, tariffIsAssumption: ${_this.tariffIsAssumption}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $ConsumptionSummaryCopyWith<$Res>  {
  factory $ConsumptionSummaryCopyWith(ConsumptionSummary value, $Res Function(ConsumptionSummary) _then) = _$ConsumptionSummaryCopyWithImpl;
@useResult
$Res call({
 int meterId, DateTime? measuredUntil, MonthSoFar thisMonth, LastMonth lastMonth, double? variationPercent, MonthEndEstimate? monthEndEstimate, bool tariffIsAssumption, String source
});


$MonthSoFarCopyWith<$Res> get thisMonth;$LastMonthCopyWith<$Res> get lastMonth;$MonthEndEstimateCopyWith<$Res>? get monthEndEstimate;

}
/// @nodoc
class _$ConsumptionSummaryCopyWithImpl<$Res>
    implements $ConsumptionSummaryCopyWith<$Res> {
  _$ConsumptionSummaryCopyWithImpl(this._self, this._then);

  final ConsumptionSummary _self;
  final $Res Function(ConsumptionSummary) _then;

/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meterId = null,Object? measuredUntil = freezed,Object? thisMonth = null,Object? lastMonth = null,Object? variationPercent = freezed,Object? monthEndEstimate = freezed,Object? tariffIsAssumption = null,Object? source = null,}) {
  return _then(ConsumptionSummary(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,measuredUntil: freezed == measuredUntil ? _self.measuredUntil : measuredUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,thisMonth: null == thisMonth ? _self.thisMonth : thisMonth // ignore: cast_nullable_to_non_nullable
as MonthSoFar,lastMonth: null == lastMonth ? _self.lastMonth : lastMonth // ignore: cast_nullable_to_non_nullable
as LastMonth,variationPercent: freezed == variationPercent ? _self.variationPercent : variationPercent // ignore: cast_nullable_to_non_nullable
as double?,monthEndEstimate: freezed == monthEndEstimate ? _self.monthEndEstimate : monthEndEstimate // ignore: cast_nullable_to_non_nullable
as MonthEndEstimate?,tariffIsAssumption: null == tariffIsAssumption ? _self.tariffIsAssumption : tariffIsAssumption // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthSoFarCopyWith<$Res> get thisMonth {
  
  return $MonthSoFarCopyWith<$Res>(_self.thisMonth, (value) {
    return _then(_self.copyWith(thisMonth: value));
  });
}/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMonthCopyWith<$Res> get lastMonth {
  
  return $LastMonthCopyWith<$Res>(_self.lastMonth, (value) {
    return _then(_self.copyWith(lastMonth: value));
  });
}/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthEndEstimateCopyWith<$Res>? get monthEndEstimate {
    if (_self.monthEndEstimate == null) {
    return null;
  }

  return $MonthEndEstimateCopyWith<$Res>(_self.monthEndEstimate!, (value) {
    return _then(_self.copyWith(monthEndEstimate: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsumptionSummary].
extension ConsumptionSummaryPatterns on ConsumptionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionSummary value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int meterId,  DateTime? measuredUntil,  MonthSoFar thisMonth,  LastMonth lastMonth,  double? variationPercent,  MonthEndEstimate? monthEndEstimate,  bool tariffIsAssumption,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionSummary() when $default != null:
return $default(_that.meterId,_that.measuredUntil,_that.thisMonth,_that.lastMonth,_that.variationPercent,_that.monthEndEstimate,_that.tariffIsAssumption,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int meterId,  DateTime? measuredUntil,  MonthSoFar thisMonth,  LastMonth lastMonth,  double? variationPercent,  MonthEndEstimate? monthEndEstimate,  bool tariffIsAssumption,  String source)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionSummary():
return $default(_that.meterId,_that.measuredUntil,_that.thisMonth,_that.lastMonth,_that.variationPercent,_that.monthEndEstimate,_that.tariffIsAssumption,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int meterId,  DateTime? measuredUntil,  MonthSoFar thisMonth,  LastMonth lastMonth,  double? variationPercent,  MonthEndEstimate? monthEndEstimate,  bool tariffIsAssumption,  String source)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionSummary() when $default != null:
return $default(_that.meterId,_that.measuredUntil,_that.thisMonth,_that.lastMonth,_that.variationPercent,_that.monthEndEstimate,_that.tariffIsAssumption,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsumptionSummary implements ConsumptionSummary {
  const _ConsumptionSummary({required this.meterId, required this.measuredUntil, required this.thisMonth, required this.lastMonth, required this.variationPercent, required this.monthEndEstimate, required this.tariffIsAssumption, required this.source});
  factory _ConsumptionSummary.fromJson(Map<String, dynamic> json) => _$ConsumptionSummaryFromJson(json);

@override final  int meterId;
/// Dernier jour relevé (`null` : aucun relevé).
@override final  DateTime? measuredUntil;
@override final  MonthSoFar thisMonth;
@override final  LastMonth lastMonth;
@override final  double? variationPercent;
@override final  MonthEndEstimate? monthEndEstimate;
/// Le tarif appliqué est-il une hypothèse (aucun tarif daté connu) ?
@override final  bool tariffIsAssumption;
/// `simulated` (mode démo) ou `e2c`.
@override final  String source;

/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionSummaryCopyWith<_ConsumptionSummary> get copyWith => __$ConsumptionSummaryCopyWithImpl<_ConsumptionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsumptionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionSummary&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.measuredUntil, measuredUntil) || other.measuredUntil == measuredUntil)&&(identical(other.thisMonth, thisMonth) || other.thisMonth == thisMonth)&&(identical(other.lastMonth, lastMonth) || other.lastMonth == lastMonth)&&(identical(other.variationPercent, variationPercent) || other.variationPercent == variationPercent)&&(identical(other.monthEndEstimate, monthEndEstimate) || other.monthEndEstimate == monthEndEstimate)&&(identical(other.tariffIsAssumption, tariffIsAssumption) || other.tariffIsAssumption == tariffIsAssumption)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,meterId,measuredUntil,thisMonth,lastMonth,variationPercent,monthEndEstimate,tariffIsAssumption,source);
}

@override
String toString() {
    return 'ConsumptionSummary(meterId: $meterId, measuredUntil: $measuredUntil, thisMonth: $thisMonth, lastMonth: $lastMonth, variationPercent: $variationPercent, monthEndEstimate: $monthEndEstimate, tariffIsAssumption: $tariffIsAssumption, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionSummaryCopyWith<$Res> implements $ConsumptionSummaryCopyWith<$Res> {
  factory _$ConsumptionSummaryCopyWith(_ConsumptionSummary value, $Res Function(_ConsumptionSummary) _then) = __$ConsumptionSummaryCopyWithImpl;
@override @useResult
$Res call({
 int meterId, DateTime? measuredUntil, MonthSoFar thisMonth, LastMonth lastMonth, double? variationPercent, MonthEndEstimate? monthEndEstimate, bool tariffIsAssumption, String source
});


@override $MonthSoFarCopyWith<$Res> get thisMonth;@override $LastMonthCopyWith<$Res> get lastMonth;@override $MonthEndEstimateCopyWith<$Res>? get monthEndEstimate;

}
/// @nodoc
class __$ConsumptionSummaryCopyWithImpl<$Res>
    implements _$ConsumptionSummaryCopyWith<$Res> {
  __$ConsumptionSummaryCopyWithImpl(this._self, this._then);

  final _ConsumptionSummary _self;
  final $Res Function(_ConsumptionSummary) _then;

/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meterId = null,Object? measuredUntil = freezed,Object? thisMonth = null,Object? lastMonth = null,Object? variationPercent = freezed,Object? monthEndEstimate = freezed,Object? tariffIsAssumption = null,Object? source = null,}) {
  return _then(_ConsumptionSummary(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,measuredUntil: freezed == measuredUntil ? _self.measuredUntil : measuredUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,thisMonth: null == thisMonth ? _self.thisMonth : thisMonth // ignore: cast_nullable_to_non_nullable
as MonthSoFar,lastMonth: null == lastMonth ? _self.lastMonth : lastMonth // ignore: cast_nullable_to_non_nullable
as LastMonth,variationPercent: freezed == variationPercent ? _self.variationPercent : variationPercent // ignore: cast_nullable_to_non_nullable
as double?,monthEndEstimate: freezed == monthEndEstimate ? _self.monthEndEstimate : monthEndEstimate // ignore: cast_nullable_to_non_nullable
as MonthEndEstimate?,tariffIsAssumption: null == tariffIsAssumption ? _self.tariffIsAssumption : tariffIsAssumption // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthSoFarCopyWith<$Res> get thisMonth {
  
  return $MonthSoFarCopyWith<$Res>(_self.thisMonth, (value) {
    return _then(_self.copyWith(thisMonth: value));
  });
}/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMonthCopyWith<$Res> get lastMonth {
  
  return $LastMonthCopyWith<$Res>(_self.lastMonth, (value) {
    return _then(_self.copyWith(lastMonth: value));
  });
}/// Create a copy of ConsumptionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthEndEstimateCopyWith<$Res>? get monthEndEstimate {
    if (_self.monthEndEstimate == null) {
    return null;
  }

  return $MonthEndEstimateCopyWith<$Res>(_self.monthEndEstimate!, (value) {
    return _then(_self.copyWith(monthEndEstimate: value));
  });
}
}


/// @nodoc
mixin _$ConsumptionPoint {

 DateTime get start; DateTime get end; String get label; int get consumptionWh; double get consumptionKwh; int get daysWithData; int get dailyAverageWh; int? get energyCost; int? get estimatedTotal;/// Période en cours (ex. aujourd'hui).
 bool get isCurrent;/// Période incomplète (des jours sans relevé).
 bool get isPartial;/// Valeur estimée (pas encore relevée) : affichée en pointillé.
 bool get isEstimated; bool get hasAnomaly;
/// Create a copy of ConsumptionPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionPointCopyWith<ConsumptionPoint> get copyWith => _$ConsumptionPointCopyWithImpl<ConsumptionPoint>(this as ConsumptionPoint, _$identity);

  /// Serializes this ConsumptionPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsumptionPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionPoint&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.daysWithData, _this.daysWithData) || other.daysWithData == _this.daysWithData)&&(identical(other.dailyAverageWh, _this.dailyAverageWh) || other.dailyAverageWh == _this.dailyAverageWh)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost)&&(identical(other.estimatedTotal, _this.estimatedTotal) || other.estimatedTotal == _this.estimatedTotal)&&(identical(other.isCurrent, _this.isCurrent) || other.isCurrent == _this.isCurrent)&&(identical(other.isPartial, _this.isPartial) || other.isPartial == _this.isPartial)&&(identical(other.isEstimated, _this.isEstimated) || other.isEstimated == _this.isEstimated)&&(identical(other.hasAnomaly, _this.hasAnomaly) || other.hasAnomaly == _this.hasAnomaly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsumptionPoint;
  return Object.hash(runtimeType,_this.start,_this.end,_this.label,_this.consumptionWh,_this.consumptionKwh,_this.daysWithData,_this.dailyAverageWh,_this.energyCost,_this.estimatedTotal,_this.isCurrent,_this.isPartial,_this.isEstimated,_this.hasAnomaly);
}

@override
String toString() {
  final _this = this as ConsumptionPoint;
  return 'ConsumptionPoint(start: ${_this.start}, end: ${_this.end}, label: ${_this.label}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, daysWithData: ${_this.daysWithData}, dailyAverageWh: ${_this.dailyAverageWh}, energyCost: ${_this.energyCost}, estimatedTotal: ${_this.estimatedTotal}, isCurrent: ${_this.isCurrent}, isPartial: ${_this.isPartial}, isEstimated: ${_this.isEstimated}, hasAnomaly: ${_this.hasAnomaly})';
}


}

/// @nodoc
abstract mixin class $ConsumptionPointCopyWith<$Res>  {
  factory $ConsumptionPointCopyWith(ConsumptionPoint value, $Res Function(ConsumptionPoint) _then) = _$ConsumptionPointCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, String label, int consumptionWh, double consumptionKwh, int daysWithData, int dailyAverageWh, int? energyCost, int? estimatedTotal, bool isCurrent, bool isPartial, bool isEstimated, bool hasAnomaly
});




}
/// @nodoc
class _$ConsumptionPointCopyWithImpl<$Res>
    implements $ConsumptionPointCopyWith<$Res> {
  _$ConsumptionPointCopyWithImpl(this._self, this._then);

  final ConsumptionPoint _self;
  final $Res Function(ConsumptionPoint) _then;

/// Create a copy of ConsumptionPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? label = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? daysWithData = null,Object? dailyAverageWh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,Object? isCurrent = null,Object? isPartial = null,Object? isEstimated = null,Object? hasAnomaly = null,}) {
  return _then(ConsumptionPoint(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,dailyAverageWh: null == dailyAverageWh ? _self.dailyAverageWh : dailyAverageWh // ignore: cast_nullable_to_non_nullable
as int,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,isPartial: null == isPartial ? _self.isPartial : isPartial // ignore: cast_nullable_to_non_nullable
as bool,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,hasAnomaly: null == hasAnomaly ? _self.hasAnomaly : hasAnomaly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsumptionPoint].
extension ConsumptionPointPatterns on ConsumptionPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionPoint value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  String label,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int dailyAverageWh,  int? energyCost,  int? estimatedTotal,  bool isCurrent,  bool isPartial,  bool isEstimated,  bool hasAnomaly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionPoint() when $default != null:
return $default(_that.start,_that.end,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.dailyAverageWh,_that.energyCost,_that.estimatedTotal,_that.isCurrent,_that.isPartial,_that.isEstimated,_that.hasAnomaly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  String label,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int dailyAverageWh,  int? energyCost,  int? estimatedTotal,  bool isCurrent,  bool isPartial,  bool isEstimated,  bool hasAnomaly)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionPoint():
return $default(_that.start,_that.end,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.dailyAverageWh,_that.energyCost,_that.estimatedTotal,_that.isCurrent,_that.isPartial,_that.isEstimated,_that.hasAnomaly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  DateTime end,  String label,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int dailyAverageWh,  int? energyCost,  int? estimatedTotal,  bool isCurrent,  bool isPartial,  bool isEstimated,  bool hasAnomaly)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionPoint() when $default != null:
return $default(_that.start,_that.end,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.dailyAverageWh,_that.energyCost,_that.estimatedTotal,_that.isCurrent,_that.isPartial,_that.isEstimated,_that.hasAnomaly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsumptionPoint implements ConsumptionPoint {
  const _ConsumptionPoint({required this.start, required this.end, required this.label, required this.consumptionWh, required this.consumptionKwh, required this.daysWithData, required this.dailyAverageWh, required this.energyCost, required this.estimatedTotal, required this.isCurrent, required this.isPartial, required this.isEstimated, required this.hasAnomaly});
  factory _ConsumptionPoint.fromJson(Map<String, dynamic> json) => _$ConsumptionPointFromJson(json);

@override final  DateTime start;
@override final  DateTime end;
@override final  String label;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int daysWithData;
@override final  int dailyAverageWh;
@override final  int? energyCost;
@override final  int? estimatedTotal;
/// Période en cours (ex. aujourd'hui).
@override final  bool isCurrent;
/// Période incomplète (des jours sans relevé).
@override final  bool isPartial;
/// Valeur estimée (pas encore relevée) : affichée en pointillé.
@override final  bool isEstimated;
@override final  bool hasAnomaly;

/// Create a copy of ConsumptionPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionPointCopyWith<_ConsumptionPoint> get copyWith => __$ConsumptionPointCopyWithImpl<_ConsumptionPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsumptionPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionPoint&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.label, label) || other.label == label)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.daysWithData, daysWithData) || other.daysWithData == daysWithData)&&(identical(other.dailyAverageWh, dailyAverageWh) || other.dailyAverageWh == dailyAverageWh)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.estimatedTotal, estimatedTotal) || other.estimatedTotal == estimatedTotal)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.isPartial, isPartial) || other.isPartial == isPartial)&&(identical(other.isEstimated, isEstimated) || other.isEstimated == isEstimated)&&(identical(other.hasAnomaly, hasAnomaly) || other.hasAnomaly == hasAnomaly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,label,consumptionWh,consumptionKwh,daysWithData,dailyAverageWh,energyCost,estimatedTotal,isCurrent,isPartial,isEstimated,hasAnomaly);
}

@override
String toString() {
    return 'ConsumptionPoint(start: $start, end: $end, label: $label, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, daysWithData: $daysWithData, dailyAverageWh: $dailyAverageWh, energyCost: $energyCost, estimatedTotal: $estimatedTotal, isCurrent: $isCurrent, isPartial: $isPartial, isEstimated: $isEstimated, hasAnomaly: $hasAnomaly)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionPointCopyWith<$Res> implements $ConsumptionPointCopyWith<$Res> {
  factory _$ConsumptionPointCopyWith(_ConsumptionPoint value, $Res Function(_ConsumptionPoint) _then) = __$ConsumptionPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, DateTime end, String label, int consumptionWh, double consumptionKwh, int daysWithData, int dailyAverageWh, int? energyCost, int? estimatedTotal, bool isCurrent, bool isPartial, bool isEstimated, bool hasAnomaly
});




}
/// @nodoc
class __$ConsumptionPointCopyWithImpl<$Res>
    implements _$ConsumptionPointCopyWith<$Res> {
  __$ConsumptionPointCopyWithImpl(this._self, this._then);

  final _ConsumptionPoint _self;
  final $Res Function(_ConsumptionPoint) _then;

/// Create a copy of ConsumptionPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? label = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? daysWithData = null,Object? dailyAverageWh = null,Object? energyCost = freezed,Object? estimatedTotal = freezed,Object? isCurrent = null,Object? isPartial = null,Object? isEstimated = null,Object? hasAnomaly = null,}) {
  return _then(_ConsumptionPoint(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,dailyAverageWh: null == dailyAverageWh ? _self.dailyAverageWh : dailyAverageWh // ignore: cast_nullable_to_non_nullable
as int,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,estimatedTotal: freezed == estimatedTotal ? _self.estimatedTotal : estimatedTotal // ignore: cast_nullable_to_non_nullable
as int?,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,isPartial: null == isPartial ? _self.isPartial : isPartial // ignore: cast_nullable_to_non_nullable
as bool,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,hasAnomaly: null == hasAnomaly ? _self.hasAnomaly : hasAnomaly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ConsumptionTotals {

 DateTime get start; DateTime get end; int get consumptionWh; double get consumptionKwh; int get daysWithData; int? get energyCost;
/// Create a copy of ConsumptionTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionTotalsCopyWith<ConsumptionTotals> get copyWith => _$ConsumptionTotalsCopyWithImpl<ConsumptionTotals>(this as ConsumptionTotals, _$identity);

  /// Serializes this ConsumptionTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsumptionTotals;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionTotals&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.daysWithData, _this.daysWithData) || other.daysWithData == _this.daysWithData)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsumptionTotals;
  return Object.hash(runtimeType,_this.start,_this.end,_this.consumptionWh,_this.consumptionKwh,_this.daysWithData,_this.energyCost);
}

@override
String toString() {
  final _this = this as ConsumptionTotals;
  return 'ConsumptionTotals(start: ${_this.start}, end: ${_this.end}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, daysWithData: ${_this.daysWithData}, energyCost: ${_this.energyCost})';
}


}

/// @nodoc
abstract mixin class $ConsumptionTotalsCopyWith<$Res>  {
  factory $ConsumptionTotalsCopyWith(ConsumptionTotals value, $Res Function(ConsumptionTotals) _then) = _$ConsumptionTotalsCopyWithImpl;
@useResult
$Res call({
 DateTime start, DateTime end, int consumptionWh, double consumptionKwh, int daysWithData, int? energyCost
});




}
/// @nodoc
class _$ConsumptionTotalsCopyWithImpl<$Res>
    implements $ConsumptionTotalsCopyWith<$Res> {
  _$ConsumptionTotalsCopyWithImpl(this._self, this._then);

  final ConsumptionTotals _self;
  final $Res Function(ConsumptionTotals) _then;

/// Create a copy of ConsumptionTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? daysWithData = null,Object? energyCost = freezed,}) {
  return _then(ConsumptionTotals(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsumptionTotals].
extension ConsumptionTotalsPatterns on ConsumptionTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionTotals value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionTotals value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int? energyCost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionTotals() when $default != null:
return $default(_that.start,_that.end,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.energyCost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime start,  DateTime end,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int? energyCost)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionTotals():
return $default(_that.start,_that.end,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.energyCost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime start,  DateTime end,  int consumptionWh,  double consumptionKwh,  int daysWithData,  int? energyCost)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionTotals() when $default != null:
return $default(_that.start,_that.end,_that.consumptionWh,_that.consumptionKwh,_that.daysWithData,_that.energyCost);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsumptionTotals implements ConsumptionTotals {
  const _ConsumptionTotals({required this.start, required this.end, required this.consumptionWh, required this.consumptionKwh, required this.daysWithData, required this.energyCost});
  factory _ConsumptionTotals.fromJson(Map<String, dynamic> json) => _$ConsumptionTotalsFromJson(json);

@override final  DateTime start;
@override final  DateTime end;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int daysWithData;
@override final  int? energyCost;

/// Create a copy of ConsumptionTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionTotalsCopyWith<_ConsumptionTotals> get copyWith => __$ConsumptionTotalsCopyWithImpl<_ConsumptionTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsumptionTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionTotals&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.daysWithData, daysWithData) || other.daysWithData == daysWithData)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,consumptionWh,consumptionKwh,daysWithData,energyCost);
}

@override
String toString() {
    return 'ConsumptionTotals(start: $start, end: $end, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, daysWithData: $daysWithData, energyCost: $energyCost)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionTotalsCopyWith<$Res> implements $ConsumptionTotalsCopyWith<$Res> {
  factory _$ConsumptionTotalsCopyWith(_ConsumptionTotals value, $Res Function(_ConsumptionTotals) _then) = __$ConsumptionTotalsCopyWithImpl;
@override @useResult
$Res call({
 DateTime start, DateTime end, int consumptionWh, double consumptionKwh, int daysWithData, int? energyCost
});




}
/// @nodoc
class __$ConsumptionTotalsCopyWithImpl<$Res>
    implements _$ConsumptionTotalsCopyWith<$Res> {
  __$ConsumptionTotalsCopyWithImpl(this._self, this._then);

  final _ConsumptionTotals _self;
  final $Res Function(_ConsumptionTotals) _then;

/// Create a copy of ConsumptionTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? daysWithData = null,Object? energyCost = freezed,}) {
  return _then(_ConsumptionTotals(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ConsumptionComparison {

 String get mode; ConsumptionTotals get current; ConsumptionTotals get reference; double? get variationPercent;
/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionComparisonCopyWith<ConsumptionComparison> get copyWith => _$ConsumptionComparisonCopyWithImpl<ConsumptionComparison>(this as ConsumptionComparison, _$identity);

  /// Serializes this ConsumptionComparison to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsumptionComparison;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionComparison&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.variationPercent, _this.variationPercent) || other.variationPercent == _this.variationPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsumptionComparison;
  return Object.hash(runtimeType,_this.mode,_this.current,_this.reference,_this.variationPercent);
}

@override
String toString() {
  final _this = this as ConsumptionComparison;
  return 'ConsumptionComparison(mode: ${_this.mode}, current: ${_this.current}, reference: ${_this.reference}, variationPercent: ${_this.variationPercent})';
}


}

/// @nodoc
abstract mixin class $ConsumptionComparisonCopyWith<$Res>  {
  factory $ConsumptionComparisonCopyWith(ConsumptionComparison value, $Res Function(ConsumptionComparison) _then) = _$ConsumptionComparisonCopyWithImpl;
@useResult
$Res call({
 String mode, ConsumptionTotals current, ConsumptionTotals reference, double? variationPercent
});


$ConsumptionTotalsCopyWith<$Res> get current;$ConsumptionTotalsCopyWith<$Res> get reference;

}
/// @nodoc
class _$ConsumptionComparisonCopyWithImpl<$Res>
    implements $ConsumptionComparisonCopyWith<$Res> {
  _$ConsumptionComparisonCopyWithImpl(this._self, this._then);

  final ConsumptionComparison _self;
  final $Res Function(ConsumptionComparison) _then;

/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? current = null,Object? reference = null,Object? variationPercent = freezed,}) {
  return _then(ConsumptionComparison(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as ConsumptionTotals,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ConsumptionTotals,variationPercent: freezed == variationPercent ? _self.variationPercent : variationPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionTotalsCopyWith<$Res> get current {
  
  return $ConsumptionTotalsCopyWith<$Res>(_self.current, (value) {
    return _then(_self.copyWith(current: value));
  });
}/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionTotalsCopyWith<$Res> get reference {
  
  return $ConsumptionTotalsCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsumptionComparison].
extension ConsumptionComparisonPatterns on ConsumptionComparison {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionComparison value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionComparison() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionComparison value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionComparison():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionComparison value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionComparison() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mode,  ConsumptionTotals current,  ConsumptionTotals reference,  double? variationPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionComparison() when $default != null:
return $default(_that.mode,_that.current,_that.reference,_that.variationPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mode,  ConsumptionTotals current,  ConsumptionTotals reference,  double? variationPercent)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionComparison():
return $default(_that.mode,_that.current,_that.reference,_that.variationPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mode,  ConsumptionTotals current,  ConsumptionTotals reference,  double? variationPercent)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionComparison() when $default != null:
return $default(_that.mode,_that.current,_that.reference,_that.variationPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsumptionComparison implements ConsumptionComparison {
  const _ConsumptionComparison({required this.mode, required this.current, required this.reference, required this.variationPercent});
  factory _ConsumptionComparison.fromJson(Map<String, dynamic> json) => _$ConsumptionComparisonFromJson(json);

@override final  String mode;
@override final  ConsumptionTotals current;
@override final  ConsumptionTotals reference;
@override final  double? variationPercent;

/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionComparisonCopyWith<_ConsumptionComparison> get copyWith => __$ConsumptionComparisonCopyWithImpl<_ConsumptionComparison>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsumptionComparisonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionComparison&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.current, current) || other.current == current)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.variationPercent, variationPercent) || other.variationPercent == variationPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mode,current,reference,variationPercent);
}

@override
String toString() {
    return 'ConsumptionComparison(mode: $mode, current: $current, reference: $reference, variationPercent: $variationPercent)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionComparisonCopyWith<$Res> implements $ConsumptionComparisonCopyWith<$Res> {
  factory _$ConsumptionComparisonCopyWith(_ConsumptionComparison value, $Res Function(_ConsumptionComparison) _then) = __$ConsumptionComparisonCopyWithImpl;
@override @useResult
$Res call({
 String mode, ConsumptionTotals current, ConsumptionTotals reference, double? variationPercent
});


@override $ConsumptionTotalsCopyWith<$Res> get current;@override $ConsumptionTotalsCopyWith<$Res> get reference;

}
/// @nodoc
class __$ConsumptionComparisonCopyWithImpl<$Res>
    implements _$ConsumptionComparisonCopyWith<$Res> {
  __$ConsumptionComparisonCopyWithImpl(this._self, this._then);

  final _ConsumptionComparison _self;
  final $Res Function(_ConsumptionComparison) _then;

/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? current = null,Object? reference = null,Object? variationPercent = freezed,}) {
  return _then(_ConsumptionComparison(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as ConsumptionTotals,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as ConsumptionTotals,variationPercent: freezed == variationPercent ? _self.variationPercent : variationPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionTotalsCopyWith<$Res> get current {
  
  return $ConsumptionTotalsCopyWith<$Res>(_self.current, (value) {
    return _then(_self.copyWith(current: value));
  });
}/// Create a copy of ConsumptionComparison
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionTotalsCopyWith<$Res> get reference {
  
  return $ConsumptionTotalsCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// @nodoc
mixin _$ConsumptionSeries {

 int get meterId; String get granularity; DateTime get start; DateTime get end; DateTime? get measuredUntil; List<ConsumptionPoint> get points; ConsumptionComparison? get comparison; bool get tariffIsAssumption; String get source;
/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionSeriesCopyWith<ConsumptionSeries> get copyWith => _$ConsumptionSeriesCopyWithImpl<ConsumptionSeries>(this as ConsumptionSeries, _$identity);

  /// Serializes this ConsumptionSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConsumptionSeries;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionSeries&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.granularity, _this.granularity) || other.granularity == _this.granularity)&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.measuredUntil, _this.measuredUntil) || other.measuredUntil == _this.measuredUntil)&&const DeepCollectionEquality().equals(other.points, _this.points)&&(identical(other.comparison, _this.comparison) || other.comparison == _this.comparison)&&(identical(other.tariffIsAssumption, _this.tariffIsAssumption) || other.tariffIsAssumption == _this.tariffIsAssumption)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConsumptionSeries;
  return Object.hash(runtimeType,_this.meterId,_this.granularity,_this.start,_this.end,_this.measuredUntil,const DeepCollectionEquality().hash(_this.points),_this.comparison,_this.tariffIsAssumption,_this.source);
}

@override
String toString() {
  final _this = this as ConsumptionSeries;
  return 'ConsumptionSeries(meterId: ${_this.meterId}, granularity: ${_this.granularity}, start: ${_this.start}, end: ${_this.end}, measuredUntil: ${_this.measuredUntil}, points: ${_this.points}, comparison: ${_this.comparison}, tariffIsAssumption: ${_this.tariffIsAssumption}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $ConsumptionSeriesCopyWith<$Res>  {
  factory $ConsumptionSeriesCopyWith(ConsumptionSeries value, $Res Function(ConsumptionSeries) _then) = _$ConsumptionSeriesCopyWithImpl;
@useResult
$Res call({
 int meterId, String granularity, DateTime start, DateTime end, DateTime? measuredUntil, List<ConsumptionPoint> points, ConsumptionComparison? comparison, bool tariffIsAssumption, String source
});


$ConsumptionComparisonCopyWith<$Res>? get comparison;

}
/// @nodoc
class _$ConsumptionSeriesCopyWithImpl<$Res>
    implements $ConsumptionSeriesCopyWith<$Res> {
  _$ConsumptionSeriesCopyWithImpl(this._self, this._then);

  final ConsumptionSeries _self;
  final $Res Function(ConsumptionSeries) _then;

/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meterId = null,Object? granularity = null,Object? start = null,Object? end = null,Object? measuredUntil = freezed,Object? points = null,Object? comparison = freezed,Object? tariffIsAssumption = null,Object? source = null,}) {
  return _then(ConsumptionSeries(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,granularity: null == granularity ? _self.granularity : granularity // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,measuredUntil: freezed == measuredUntil ? _self.measuredUntil : measuredUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<ConsumptionPoint>,comparison: freezed == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as ConsumptionComparison?,tariffIsAssumption: null == tariffIsAssumption ? _self.tariffIsAssumption : tariffIsAssumption // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionComparisonCopyWith<$Res>? get comparison {
    if (_self.comparison == null) {
    return null;
  }

  return $ConsumptionComparisonCopyWith<$Res>(_self.comparison!, (value) {
    return _then(_self.copyWith(comparison: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsumptionSeries].
extension ConsumptionSeriesPatterns on ConsumptionSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionSeries value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionSeries value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int meterId,  String granularity,  DateTime start,  DateTime end,  DateTime? measuredUntil,  List<ConsumptionPoint> points,  ConsumptionComparison? comparison,  bool tariffIsAssumption,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionSeries() when $default != null:
return $default(_that.meterId,_that.granularity,_that.start,_that.end,_that.measuredUntil,_that.points,_that.comparison,_that.tariffIsAssumption,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int meterId,  String granularity,  DateTime start,  DateTime end,  DateTime? measuredUntil,  List<ConsumptionPoint> points,  ConsumptionComparison? comparison,  bool tariffIsAssumption,  String source)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionSeries():
return $default(_that.meterId,_that.granularity,_that.start,_that.end,_that.measuredUntil,_that.points,_that.comparison,_that.tariffIsAssumption,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int meterId,  String granularity,  DateTime start,  DateTime end,  DateTime? measuredUntil,  List<ConsumptionPoint> points,  ConsumptionComparison? comparison,  bool tariffIsAssumption,  String source)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionSeries() when $default != null:
return $default(_that.meterId,_that.granularity,_that.start,_that.end,_that.measuredUntil,_that.points,_that.comparison,_that.tariffIsAssumption,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConsumptionSeries implements ConsumptionSeries {
  const _ConsumptionSeries({required this.meterId, required this.granularity, required this.start, required this.end, required this.measuredUntil, required  List<ConsumptionPoint> points, required this.comparison, required this.tariffIsAssumption, required this.source}): _points = points;
  factory _ConsumptionSeries.fromJson(Map<String, dynamic> json) => _$ConsumptionSeriesFromJson(json);

@override final  int meterId;
@override final  String granularity;
@override final  DateTime start;
@override final  DateTime end;
@override final  DateTime? measuredUntil;
 final  List<ConsumptionPoint> _points;
@override List<ConsumptionPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

@override final  ConsumptionComparison? comparison;
@override final  bool tariffIsAssumption;
@override final  String source;

/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionSeriesCopyWith<_ConsumptionSeries> get copyWith => __$ConsumptionSeriesCopyWithImpl<_ConsumptionSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsumptionSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionSeries&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.granularity, granularity) || other.granularity == granularity)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.measuredUntil, measuredUntil) || other.measuredUntil == measuredUntil)&&const DeepCollectionEquality().equals(other.points, _points)&&(identical(other.comparison, comparison) || other.comparison == comparison)&&(identical(other.tariffIsAssumption, tariffIsAssumption) || other.tariffIsAssumption == tariffIsAssumption)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,meterId,granularity,start,end,measuredUntil,const DeepCollectionEquality().hash(_points),comparison,tariffIsAssumption,source);
}

@override
String toString() {
    return 'ConsumptionSeries(meterId: $meterId, granularity: $granularity, start: $start, end: $end, measuredUntil: $measuredUntil, points: $points, comparison: $comparison, tariffIsAssumption: $tariffIsAssumption, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionSeriesCopyWith<$Res> implements $ConsumptionSeriesCopyWith<$Res> {
  factory _$ConsumptionSeriesCopyWith(_ConsumptionSeries value, $Res Function(_ConsumptionSeries) _then) = __$ConsumptionSeriesCopyWithImpl;
@override @useResult
$Res call({
 int meterId, String granularity, DateTime start, DateTime end, DateTime? measuredUntil, List<ConsumptionPoint> points, ConsumptionComparison? comparison, bool tariffIsAssumption, String source
});


@override $ConsumptionComparisonCopyWith<$Res>? get comparison;

}
/// @nodoc
class __$ConsumptionSeriesCopyWithImpl<$Res>
    implements _$ConsumptionSeriesCopyWith<$Res> {
  __$ConsumptionSeriesCopyWithImpl(this._self, this._then);

  final _ConsumptionSeries _self;
  final $Res Function(_ConsumptionSeries) _then;

/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meterId = null,Object? granularity = null,Object? start = null,Object? end = null,Object? measuredUntil = freezed,Object? points = null,Object? comparison = freezed,Object? tariffIsAssumption = null,Object? source = null,}) {
  return _then(_ConsumptionSeries(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,granularity: null == granularity ? _self.granularity : granularity // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,measuredUntil: freezed == measuredUntil ? _self.measuredUntil : measuredUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<ConsumptionPoint>,comparison: freezed == comparison ? _self.comparison : comparison // ignore: cast_nullable_to_non_nullable
as ConsumptionComparison?,tariffIsAssumption: null == tariffIsAssumption ? _self.tariffIsAssumption : tariffIsAssumption // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ConsumptionSeries
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsumptionComparisonCopyWith<$Res>? get comparison {
    if (_self.comparison == null) {
    return null;
  }

  return $ConsumptionComparisonCopyWith<$Res>(_self.comparison!, (value) {
    return _then(_self.copyWith(comparison: value));
  });
}
}


/// @nodoc
mixin _$DayDetail {

 int get meterId; DateTime get day; String get label; int get consumptionWh; double get consumptionKwh;/// Énergie seule (kWh × tarif du jour), FCFA entiers ; `null` sans tarif connu.
 int? get energyCost; int? get indexStartWh; int get indexEndWh;/// Valeur estimée (relevé manquant), pas relevée.
 bool get isEstimated; bool get isAnomaly; String? get anomalyReason;/// Moyenne du même jour de la semaine (`null` sans assez de jours), et sur combien de jours.
 int? get weekdayAverageWh; int get weekdaySamples;/// Classement dans le mois (1 = le plus consommé), sur `daysRanked` jours relevés.
 int get rankInMonth; int get daysRanked; String get source;
/// Create a copy of DayDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayDetailCopyWith<DayDetail> get copyWith => _$DayDetailCopyWithImpl<DayDetail>(this as DayDetail, _$identity);

  /// Serializes this DayDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayDetail&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.energyCost, _this.energyCost) || other.energyCost == _this.energyCost)&&(identical(other.indexStartWh, _this.indexStartWh) || other.indexStartWh == _this.indexStartWh)&&(identical(other.indexEndWh, _this.indexEndWh) || other.indexEndWh == _this.indexEndWh)&&(identical(other.isEstimated, _this.isEstimated) || other.isEstimated == _this.isEstimated)&&(identical(other.isAnomaly, _this.isAnomaly) || other.isAnomaly == _this.isAnomaly)&&(identical(other.anomalyReason, _this.anomalyReason) || other.anomalyReason == _this.anomalyReason)&&(identical(other.weekdayAverageWh, _this.weekdayAverageWh) || other.weekdayAverageWh == _this.weekdayAverageWh)&&(identical(other.weekdaySamples, _this.weekdaySamples) || other.weekdaySamples == _this.weekdaySamples)&&(identical(other.rankInMonth, _this.rankInMonth) || other.rankInMonth == _this.rankInMonth)&&(identical(other.daysRanked, _this.daysRanked) || other.daysRanked == _this.daysRanked)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayDetail;
  return Object.hash(runtimeType,_this.meterId,_this.day,_this.label,_this.consumptionWh,_this.consumptionKwh,_this.energyCost,_this.indexStartWh,_this.indexEndWh,_this.isEstimated,_this.isAnomaly,_this.anomalyReason,_this.weekdayAverageWh,_this.weekdaySamples,_this.rankInMonth,_this.daysRanked,_this.source);
}

@override
String toString() {
  final _this = this as DayDetail;
  return 'DayDetail(meterId: ${_this.meterId}, day: ${_this.day}, label: ${_this.label}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, energyCost: ${_this.energyCost}, indexStartWh: ${_this.indexStartWh}, indexEndWh: ${_this.indexEndWh}, isEstimated: ${_this.isEstimated}, isAnomaly: ${_this.isAnomaly}, anomalyReason: ${_this.anomalyReason}, weekdayAverageWh: ${_this.weekdayAverageWh}, weekdaySamples: ${_this.weekdaySamples}, rankInMonth: ${_this.rankInMonth}, daysRanked: ${_this.daysRanked}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $DayDetailCopyWith<$Res>  {
  factory $DayDetailCopyWith(DayDetail value, $Res Function(DayDetail) _then) = _$DayDetailCopyWithImpl;
@useResult
$Res call({
 int meterId, DateTime day, String label, int consumptionWh, double consumptionKwh, int? energyCost, int? indexStartWh, int indexEndWh, bool isEstimated, bool isAnomaly, String? anomalyReason, int? weekdayAverageWh, int weekdaySamples, int rankInMonth, int daysRanked, String source
});




}
/// @nodoc
class _$DayDetailCopyWithImpl<$Res>
    implements $DayDetailCopyWith<$Res> {
  _$DayDetailCopyWithImpl(this._self, this._then);

  final DayDetail _self;
  final $Res Function(DayDetail) _then;

/// Create a copy of DayDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meterId = null,Object? day = null,Object? label = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? indexStartWh = freezed,Object? indexEndWh = null,Object? isEstimated = null,Object? isAnomaly = null,Object? anomalyReason = freezed,Object? weekdayAverageWh = freezed,Object? weekdaySamples = null,Object? rankInMonth = null,Object? daysRanked = null,Object? source = null,}) {
  return _then(DayDetail(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,indexStartWh: freezed == indexStartWh ? _self.indexStartWh : indexStartWh // ignore: cast_nullable_to_non_nullable
as int?,indexEndWh: null == indexEndWh ? _self.indexEndWh : indexEndWh // ignore: cast_nullable_to_non_nullable
as int,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,isAnomaly: null == isAnomaly ? _self.isAnomaly : isAnomaly // ignore: cast_nullable_to_non_nullable
as bool,anomalyReason: freezed == anomalyReason ? _self.anomalyReason : anomalyReason // ignore: cast_nullable_to_non_nullable
as String?,weekdayAverageWh: freezed == weekdayAverageWh ? _self.weekdayAverageWh : weekdayAverageWh // ignore: cast_nullable_to_non_nullable
as int?,weekdaySamples: null == weekdaySamples ? _self.weekdaySamples : weekdaySamples // ignore: cast_nullable_to_non_nullable
as int,rankInMonth: null == rankInMonth ? _self.rankInMonth : rankInMonth // ignore: cast_nullable_to_non_nullable
as int,daysRanked: null == daysRanked ? _self.daysRanked : daysRanked // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayDetail].
extension DayDetailPatterns on DayDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayDetail value)  $default,){
final _that = this;
switch (_that) {
case _DayDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayDetail value)?  $default,){
final _that = this;
switch (_that) {
case _DayDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int meterId,  DateTime day,  String label,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? indexStartWh,  int indexEndWh,  bool isEstimated,  bool isAnomaly,  String? anomalyReason,  int? weekdayAverageWh,  int weekdaySamples,  int rankInMonth,  int daysRanked,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayDetail() when $default != null:
return $default(_that.meterId,_that.day,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.indexStartWh,_that.indexEndWh,_that.isEstimated,_that.isAnomaly,_that.anomalyReason,_that.weekdayAverageWh,_that.weekdaySamples,_that.rankInMonth,_that.daysRanked,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int meterId,  DateTime day,  String label,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? indexStartWh,  int indexEndWh,  bool isEstimated,  bool isAnomaly,  String? anomalyReason,  int? weekdayAverageWh,  int weekdaySamples,  int rankInMonth,  int daysRanked,  String source)  $default,) {final _that = this;
switch (_that) {
case _DayDetail():
return $default(_that.meterId,_that.day,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.indexStartWh,_that.indexEndWh,_that.isEstimated,_that.isAnomaly,_that.anomalyReason,_that.weekdayAverageWh,_that.weekdaySamples,_that.rankInMonth,_that.daysRanked,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int meterId,  DateTime day,  String label,  int consumptionWh,  double consumptionKwh,  int? energyCost,  int? indexStartWh,  int indexEndWh,  bool isEstimated,  bool isAnomaly,  String? anomalyReason,  int? weekdayAverageWh,  int weekdaySamples,  int rankInMonth,  int daysRanked,  String source)?  $default,) {final _that = this;
switch (_that) {
case _DayDetail() when $default != null:
return $default(_that.meterId,_that.day,_that.label,_that.consumptionWh,_that.consumptionKwh,_that.energyCost,_that.indexStartWh,_that.indexEndWh,_that.isEstimated,_that.isAnomaly,_that.anomalyReason,_that.weekdayAverageWh,_that.weekdaySamples,_that.rankInMonth,_that.daysRanked,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayDetail implements DayDetail {
  const _DayDetail({required this.meterId, required this.day, required this.label, required this.consumptionWh, required this.consumptionKwh, required this.energyCost, required this.indexStartWh, required this.indexEndWh, required this.isEstimated, required this.isAnomaly, required this.anomalyReason, required this.weekdayAverageWh, required this.weekdaySamples, required this.rankInMonth, required this.daysRanked, required this.source});
  factory _DayDetail.fromJson(Map<String, dynamic> json) => _$DayDetailFromJson(json);

@override final  int meterId;
@override final  DateTime day;
@override final  String label;
@override final  int consumptionWh;
@override final  double consumptionKwh;
/// Énergie seule (kWh × tarif du jour), FCFA entiers ; `null` sans tarif connu.
@override final  int? energyCost;
@override final  int? indexStartWh;
@override final  int indexEndWh;
/// Valeur estimée (relevé manquant), pas relevée.
@override final  bool isEstimated;
@override final  bool isAnomaly;
@override final  String? anomalyReason;
/// Moyenne du même jour de la semaine (`null` sans assez de jours), et sur combien de jours.
@override final  int? weekdayAverageWh;
@override final  int weekdaySamples;
/// Classement dans le mois (1 = le plus consommé), sur `daysRanked` jours relevés.
@override final  int rankInMonth;
@override final  int daysRanked;
@override final  String source;

/// Create a copy of DayDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayDetailCopyWith<_DayDetail> get copyWith => __$DayDetailCopyWithImpl<_DayDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayDetail&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.day, day) || other.day == day)&&(identical(other.label, label) || other.label == label)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.energyCost, energyCost) || other.energyCost == energyCost)&&(identical(other.indexStartWh, indexStartWh) || other.indexStartWh == indexStartWh)&&(identical(other.indexEndWh, indexEndWh) || other.indexEndWh == indexEndWh)&&(identical(other.isEstimated, isEstimated) || other.isEstimated == isEstimated)&&(identical(other.isAnomaly, isAnomaly) || other.isAnomaly == isAnomaly)&&(identical(other.anomalyReason, anomalyReason) || other.anomalyReason == anomalyReason)&&(identical(other.weekdayAverageWh, weekdayAverageWh) || other.weekdayAverageWh == weekdayAverageWh)&&(identical(other.weekdaySamples, weekdaySamples) || other.weekdaySamples == weekdaySamples)&&(identical(other.rankInMonth, rankInMonth) || other.rankInMonth == rankInMonth)&&(identical(other.daysRanked, daysRanked) || other.daysRanked == daysRanked)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,meterId,day,label,consumptionWh,consumptionKwh,energyCost,indexStartWh,indexEndWh,isEstimated,isAnomaly,anomalyReason,weekdayAverageWh,weekdaySamples,rankInMonth,daysRanked,source);
}

@override
String toString() {
    return 'DayDetail(meterId: $meterId, day: $day, label: $label, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, energyCost: $energyCost, indexStartWh: $indexStartWh, indexEndWh: $indexEndWh, isEstimated: $isEstimated, isAnomaly: $isAnomaly, anomalyReason: $anomalyReason, weekdayAverageWh: $weekdayAverageWh, weekdaySamples: $weekdaySamples, rankInMonth: $rankInMonth, daysRanked: $daysRanked, source: $source)';
}


}

/// @nodoc
abstract mixin class _$DayDetailCopyWith<$Res> implements $DayDetailCopyWith<$Res> {
  factory _$DayDetailCopyWith(_DayDetail value, $Res Function(_DayDetail) _then) = __$DayDetailCopyWithImpl;
@override @useResult
$Res call({
 int meterId, DateTime day, String label, int consumptionWh, double consumptionKwh, int? energyCost, int? indexStartWh, int indexEndWh, bool isEstimated, bool isAnomaly, String? anomalyReason, int? weekdayAverageWh, int weekdaySamples, int rankInMonth, int daysRanked, String source
});




}
/// @nodoc
class __$DayDetailCopyWithImpl<$Res>
    implements _$DayDetailCopyWith<$Res> {
  __$DayDetailCopyWithImpl(this._self, this._then);

  final _DayDetail _self;
  final $Res Function(_DayDetail) _then;

/// Create a copy of DayDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meterId = null,Object? day = null,Object? label = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? energyCost = freezed,Object? indexStartWh = freezed,Object? indexEndWh = null,Object? isEstimated = null,Object? isAnomaly = null,Object? anomalyReason = freezed,Object? weekdayAverageWh = freezed,Object? weekdaySamples = null,Object? rankInMonth = null,Object? daysRanked = null,Object? source = null,}) {
  return _then(_DayDetail(
meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,energyCost: freezed == energyCost ? _self.energyCost : energyCost // ignore: cast_nullable_to_non_nullable
as int?,indexStartWh: freezed == indexStartWh ? _self.indexStartWh : indexStartWh // ignore: cast_nullable_to_non_nullable
as int?,indexEndWh: null == indexEndWh ? _self.indexEndWh : indexEndWh // ignore: cast_nullable_to_non_nullable
as int,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,isAnomaly: null == isAnomaly ? _self.isAnomaly : isAnomaly // ignore: cast_nullable_to_non_nullable
as bool,anomalyReason: freezed == anomalyReason ? _self.anomalyReason : anomalyReason // ignore: cast_nullable_to_non_nullable
as String?,weekdayAverageWh: freezed == weekdayAverageWh ? _self.weekdayAverageWh : weekdayAverageWh // ignore: cast_nullable_to_non_nullable
as int?,weekdaySamples: null == weekdaySamples ? _self.weekdaySamples : weekdaySamples // ignore: cast_nullable_to_non_nullable
as int,rankInMonth: null == rankInMonth ? _self.rankInMonth : rankInMonth // ignore: cast_nullable_to_non_nullable
as int,daysRanked: null == daysRanked ? _self.daysRanked : daysRanked // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ReadingPublic {

 int get id; DateTime get readAt; DateTime get day; int get indexWh; int get consumptionWh; double get consumptionKwh; String get source; bool get isEstimated; bool get isAnomaly; String? get anomalyReason;
/// Create a copy of ReadingPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingPublicCopyWith<ReadingPublic> get copyWith => _$ReadingPublicCopyWithImpl<ReadingPublic>(this as ReadingPublic, _$identity);

  /// Serializes this ReadingPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReadingPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.day, _this.day) || other.day == _this.day)&&(identical(other.indexWh, _this.indexWh) || other.indexWh == _this.indexWh)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.isEstimated, _this.isEstimated) || other.isEstimated == _this.isEstimated)&&(identical(other.isAnomaly, _this.isAnomaly) || other.isAnomaly == _this.isAnomaly)&&(identical(other.anomalyReason, _this.anomalyReason) || other.anomalyReason == _this.anomalyReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReadingPublic;
  return Object.hash(runtimeType,_this.id,_this.readAt,_this.day,_this.indexWh,_this.consumptionWh,_this.consumptionKwh,_this.source,_this.isEstimated,_this.isAnomaly,_this.anomalyReason);
}

@override
String toString() {
  final _this = this as ReadingPublic;
  return 'ReadingPublic(id: ${_this.id}, readAt: ${_this.readAt}, day: ${_this.day}, indexWh: ${_this.indexWh}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, source: ${_this.source}, isEstimated: ${_this.isEstimated}, isAnomaly: ${_this.isAnomaly}, anomalyReason: ${_this.anomalyReason})';
}


}

/// @nodoc
abstract mixin class $ReadingPublicCopyWith<$Res>  {
  factory $ReadingPublicCopyWith(ReadingPublic value, $Res Function(ReadingPublic) _then) = _$ReadingPublicCopyWithImpl;
@useResult
$Res call({
 int id, DateTime readAt, DateTime day, int indexWh, int consumptionWh, double consumptionKwh, String source, bool isEstimated, bool isAnomaly, String? anomalyReason
});




}
/// @nodoc
class _$ReadingPublicCopyWithImpl<$Res>
    implements $ReadingPublicCopyWith<$Res> {
  _$ReadingPublicCopyWithImpl(this._self, this._then);

  final ReadingPublic _self;
  final $Res Function(ReadingPublic) _then;

/// Create a copy of ReadingPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? readAt = null,Object? day = null,Object? indexWh = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? source = null,Object? isEstimated = null,Object? isAnomaly = null,Object? anomalyReason = freezed,}) {
  return _then(ReadingPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,readAt: null == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,indexWh: null == indexWh ? _self.indexWh : indexWh // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,isAnomaly: null == isAnomaly ? _self.isAnomaly : isAnomaly // ignore: cast_nullable_to_non_nullable
as bool,anomalyReason: freezed == anomalyReason ? _self.anomalyReason : anomalyReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingPublic].
extension ReadingPublicPatterns on ReadingPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingPublic value)  $default,){
final _that = this;
switch (_that) {
case _ReadingPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingPublic value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime readAt,  DateTime day,  int indexWh,  int consumptionWh,  double consumptionKwh,  String source,  bool isEstimated,  bool isAnomaly,  String? anomalyReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingPublic() when $default != null:
return $default(_that.id,_that.readAt,_that.day,_that.indexWh,_that.consumptionWh,_that.consumptionKwh,_that.source,_that.isEstimated,_that.isAnomaly,_that.anomalyReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime readAt,  DateTime day,  int indexWh,  int consumptionWh,  double consumptionKwh,  String source,  bool isEstimated,  bool isAnomaly,  String? anomalyReason)  $default,) {final _that = this;
switch (_that) {
case _ReadingPublic():
return $default(_that.id,_that.readAt,_that.day,_that.indexWh,_that.consumptionWh,_that.consumptionKwh,_that.source,_that.isEstimated,_that.isAnomaly,_that.anomalyReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime readAt,  DateTime day,  int indexWh,  int consumptionWh,  double consumptionKwh,  String source,  bool isEstimated,  bool isAnomaly,  String? anomalyReason)?  $default,) {final _that = this;
switch (_that) {
case _ReadingPublic() when $default != null:
return $default(_that.id,_that.readAt,_that.day,_that.indexWh,_that.consumptionWh,_that.consumptionKwh,_that.source,_that.isEstimated,_that.isAnomaly,_that.anomalyReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingPublic implements ReadingPublic {
  const _ReadingPublic({required this.id, required this.readAt, required this.day, required this.indexWh, required this.consumptionWh, required this.consumptionKwh, required this.source, required this.isEstimated, required this.isAnomaly, required this.anomalyReason});
  factory _ReadingPublic.fromJson(Map<String, dynamic> json) => _$ReadingPublicFromJson(json);

@override final  int id;
@override final  DateTime readAt;
@override final  DateTime day;
@override final  int indexWh;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  String source;
@override final  bool isEstimated;
@override final  bool isAnomaly;
@override final  String? anomalyReason;

/// Create a copy of ReadingPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingPublicCopyWith<_ReadingPublic> get copyWith => __$ReadingPublicCopyWithImpl<_ReadingPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.day, day) || other.day == day)&&(identical(other.indexWh, indexWh) || other.indexWh == indexWh)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.source, source) || other.source == source)&&(identical(other.isEstimated, isEstimated) || other.isEstimated == isEstimated)&&(identical(other.isAnomaly, isAnomaly) || other.isAnomaly == isAnomaly)&&(identical(other.anomalyReason, anomalyReason) || other.anomalyReason == anomalyReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,readAt,day,indexWh,consumptionWh,consumptionKwh,source,isEstimated,isAnomaly,anomalyReason);
}

@override
String toString() {
    return 'ReadingPublic(id: $id, readAt: $readAt, day: $day, indexWh: $indexWh, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, source: $source, isEstimated: $isEstimated, isAnomaly: $isAnomaly, anomalyReason: $anomalyReason)';
}


}

/// @nodoc
abstract mixin class _$ReadingPublicCopyWith<$Res> implements $ReadingPublicCopyWith<$Res> {
  factory _$ReadingPublicCopyWith(_ReadingPublic value, $Res Function(_ReadingPublic) _then) = __$ReadingPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime readAt, DateTime day, int indexWh, int consumptionWh, double consumptionKwh, String source, bool isEstimated, bool isAnomaly, String? anomalyReason
});




}
/// @nodoc
class __$ReadingPublicCopyWithImpl<$Res>
    implements _$ReadingPublicCopyWith<$Res> {
  __$ReadingPublicCopyWithImpl(this._self, this._then);

  final _ReadingPublic _self;
  final $Res Function(_ReadingPublic) _then;

/// Create a copy of ReadingPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? readAt = null,Object? day = null,Object? indexWh = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? source = null,Object? isEstimated = null,Object? isAnomaly = null,Object? anomalyReason = freezed,}) {
  return _then(_ReadingPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,readAt: null == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,indexWh: null == indexWh ? _self.indexWh : indexWh // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,isAnomaly: null == isAnomaly ? _self.isAnomaly : isAnomaly // ignore: cast_nullable_to_non_nullable
as bool,anomalyReason: freezed == anomalyReason ? _self.anomalyReason : anomalyReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ReadingPage {

 List<ReadingPublic> get items; int get page; int get size; int get total;
/// Create a copy of ReadingPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingPageCopyWith<ReadingPage> get copyWith => _$ReadingPageCopyWithImpl<ReadingPage>(this as ReadingPage, _$identity);

  /// Serializes this ReadingPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReadingPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReadingPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.page,_this.size,_this.total);
}

@override
String toString() {
  final _this = this as ReadingPage;
  return 'ReadingPage(items: ${_this.items}, page: ${_this.page}, size: ${_this.size}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ReadingPageCopyWith<$Res>  {
  factory $ReadingPageCopyWith(ReadingPage value, $Res Function(ReadingPage) _then) = _$ReadingPageCopyWithImpl;
@useResult
$Res call({
 List<ReadingPublic> items, int page, int size, int total
});




}
/// @nodoc
class _$ReadingPageCopyWithImpl<$Res>
    implements $ReadingPageCopyWith<$Res> {
  _$ReadingPageCopyWithImpl(this._self, this._then);

  final ReadingPage _self;
  final $Res Function(ReadingPage) _then;

/// Create a copy of ReadingPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(ReadingPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReadingPublic>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingPage].
extension ReadingPagePatterns on ReadingPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingPage value)  $default,){
final _that = this;
switch (_that) {
case _ReadingPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingPage value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ReadingPublic> items,  int page,  int size,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingPage() when $default != null:
return $default(_that.items,_that.page,_that.size,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ReadingPublic> items,  int page,  int size,  int total)  $default,) {final _that = this;
switch (_that) {
case _ReadingPage():
return $default(_that.items,_that.page,_that.size,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ReadingPublic> items,  int page,  int size,  int total)?  $default,) {final _that = this;
switch (_that) {
case _ReadingPage() when $default != null:
return $default(_that.items,_that.page,_that.size,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingPage implements ReadingPage {
  const _ReadingPage({required  List<ReadingPublic> items, required this.page, required this.size, required this.total}): _items = items;
  factory _ReadingPage.fromJson(Map<String, dynamic> json) => _$ReadingPageFromJson(json);

 final  List<ReadingPublic> _items;
@override List<ReadingPublic> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  int size;
@override final  int total;

/// Create a copy of ReadingPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingPageCopyWith<_ReadingPage> get copyWith => __$ReadingPageCopyWithImpl<_ReadingPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,size,total);
}

@override
String toString() {
    return 'ReadingPage(items: $items, page: $page, size: $size, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ReadingPageCopyWith<$Res> implements $ReadingPageCopyWith<$Res> {
  factory _$ReadingPageCopyWith(_ReadingPage value, $Res Function(_ReadingPage) _then) = __$ReadingPageCopyWithImpl;
@override @useResult
$Res call({
 List<ReadingPublic> items, int page, int size, int total
});




}
/// @nodoc
class __$ReadingPageCopyWithImpl<$Res>
    implements _$ReadingPageCopyWith<$Res> {
  __$ReadingPageCopyWithImpl(this._self, this._then);

  final _ReadingPage _self;
  final $Res Function(_ReadingPage) _then;

/// Create a copy of ReadingPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(_ReadingPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReadingPublic>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
