// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'households.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdSummary {

 int get id; String get name; String get city; String? get district; String get ownerName; HouseholdRole get myRole; int get membersCount; int get metersCount;
/// Create a copy of HouseholdSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdSummaryCopyWith<HouseholdSummary> get copyWith => _$HouseholdSummaryCopyWithImpl<HouseholdSummary>(this as HouseholdSummary, _$identity);

  /// Serializes this HouseholdSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.district, _this.district) || other.district == _this.district)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.membersCount, _this.membersCount) || other.membersCount == _this.membersCount)&&(identical(other.metersCount, _this.metersCount) || other.metersCount == _this.metersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.city,_this.district,_this.ownerName,_this.myRole,_this.membersCount,_this.metersCount);
}

@override
String toString() {
  final _this = this as HouseholdSummary;
  return 'HouseholdSummary(id: ${_this.id}, name: ${_this.name}, city: ${_this.city}, district: ${_this.district}, ownerName: ${_this.ownerName}, myRole: ${_this.myRole}, membersCount: ${_this.membersCount}, metersCount: ${_this.metersCount})';
}


}

/// @nodoc
abstract mixin class $HouseholdSummaryCopyWith<$Res>  {
  factory $HouseholdSummaryCopyWith(HouseholdSummary value, $Res Function(HouseholdSummary) _then) = _$HouseholdSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String city, String? district, String ownerName, HouseholdRole myRole, int membersCount, int metersCount
});




}
/// @nodoc
class _$HouseholdSummaryCopyWithImpl<$Res>
    implements $HouseholdSummaryCopyWith<$Res> {
  _$HouseholdSummaryCopyWithImpl(this._self, this._then);

  final HouseholdSummary _self;
  final $Res Function(HouseholdSummary) _then;

/// Create a copy of HouseholdSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,Object? district = freezed,Object? ownerName = null,Object? myRole = null,Object? membersCount = null,Object? metersCount = null,}) {
  return _then(HouseholdSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,metersCount: null == metersCount ? _self.metersCount : metersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdSummary].
extension HouseholdSummaryPatterns on HouseholdSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdSummary value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String city,  String? district,  String ownerName,  HouseholdRole myRole,  int membersCount,  int metersCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdSummary() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.district,_that.ownerName,_that.myRole,_that.membersCount,_that.metersCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String city,  String? district,  String ownerName,  HouseholdRole myRole,  int membersCount,  int metersCount)  $default,) {final _that = this;
switch (_that) {
case _HouseholdSummary():
return $default(_that.id,_that.name,_that.city,_that.district,_that.ownerName,_that.myRole,_that.membersCount,_that.metersCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String city,  String? district,  String ownerName,  HouseholdRole myRole,  int membersCount,  int metersCount)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdSummary() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.district,_that.ownerName,_that.myRole,_that.membersCount,_that.metersCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdSummary implements HouseholdSummary {
  const _HouseholdSummary({required this.id, required this.name, required this.city, required this.district, required this.ownerName, required this.myRole, required this.membersCount, required this.metersCount});
  factory _HouseholdSummary.fromJson(Map<String, dynamic> json) => _$HouseholdSummaryFromJson(json);

@override final  int id;
@override final  String name;
@override final  String city;
@override final  String? district;
@override final  String ownerName;
@override final  HouseholdRole myRole;
@override final  int membersCount;
@override final  int metersCount;

/// Create a copy of HouseholdSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdSummaryCopyWith<_HouseholdSummary> get copyWith => __$HouseholdSummaryCopyWithImpl<_HouseholdSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.district, district) || other.district == district)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.metersCount, metersCount) || other.metersCount == metersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,city,district,ownerName,myRole,membersCount,metersCount);
}

@override
String toString() {
    return 'HouseholdSummary(id: $id, name: $name, city: $city, district: $district, ownerName: $ownerName, myRole: $myRole, membersCount: $membersCount, metersCount: $metersCount)';
}


}

/// @nodoc
abstract mixin class _$HouseholdSummaryCopyWith<$Res> implements $HouseholdSummaryCopyWith<$Res> {
  factory _$HouseholdSummaryCopyWith(_HouseholdSummary value, $Res Function(_HouseholdSummary) _then) = __$HouseholdSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String city, String? district, String ownerName, HouseholdRole myRole, int membersCount, int metersCount
});




}
/// @nodoc
class __$HouseholdSummaryCopyWithImpl<$Res>
    implements _$HouseholdSummaryCopyWith<$Res> {
  __$HouseholdSummaryCopyWithImpl(this._self, this._then);

  final _HouseholdSummary _self;
  final $Res Function(_HouseholdSummary) _then;

/// Create a copy of HouseholdSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,Object? district = freezed,Object? ownerName = null,Object? myRole = null,Object? membersCount = null,Object? metersCount = null,}) {
  return _then(_HouseholdSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,metersCount: null == metersCount ? _self.metersCount : metersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MeterDetail {

 int get id; int get householdId; String get reference; String? get label; String get type; String get status; String? get contractNumber; String? get customerNumber; String? get e2cCenter; int? get subscribedPowerVa; DateTime? get installedAt; HouseholdRole get myRole; bool get canManage; DateTime get createdAt;
/// Create a copy of MeterDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeterDetailCopyWith<MeterDetail> get copyWith => _$MeterDetailCopyWithImpl<MeterDetail>(this as MeterDetail, _$identity);

  /// Serializes this MeterDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeterDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeterDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.contractNumber, _this.contractNumber) || other.contractNumber == _this.contractNumber)&&(identical(other.customerNumber, _this.customerNumber) || other.customerNumber == _this.customerNumber)&&(identical(other.e2cCenter, _this.e2cCenter) || other.e2cCenter == _this.e2cCenter)&&(identical(other.subscribedPowerVa, _this.subscribedPowerVa) || other.subscribedPowerVa == _this.subscribedPowerVa)&&(identical(other.installedAt, _this.installedAt) || other.installedAt == _this.installedAt)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.canManage, _this.canManage) || other.canManage == _this.canManage)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeterDetail;
  return Object.hash(runtimeType,_this.id,_this.householdId,_this.reference,_this.label,_this.type,_this.status,_this.contractNumber,_this.customerNumber,_this.e2cCenter,_this.subscribedPowerVa,_this.installedAt,_this.myRole,_this.canManage,_this.createdAt);
}

@override
String toString() {
  final _this = this as MeterDetail;
  return 'MeterDetail(id: ${_this.id}, householdId: ${_this.householdId}, reference: ${_this.reference}, label: ${_this.label}, type: ${_this.type}, status: ${_this.status}, contractNumber: ${_this.contractNumber}, customerNumber: ${_this.customerNumber}, e2cCenter: ${_this.e2cCenter}, subscribedPowerVa: ${_this.subscribedPowerVa}, installedAt: ${_this.installedAt}, myRole: ${_this.myRole}, canManage: ${_this.canManage}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MeterDetailCopyWith<$Res>  {
  factory $MeterDetailCopyWith(MeterDetail value, $Res Function(MeterDetail) _then) = _$MeterDetailCopyWithImpl;
@useResult
$Res call({
 int id, int householdId, String reference, String? label, String type, String status, String? contractNumber, String? customerNumber, String? e2cCenter, int? subscribedPowerVa, DateTime? installedAt, HouseholdRole myRole, bool canManage, DateTime createdAt
});




}
/// @nodoc
class _$MeterDetailCopyWithImpl<$Res>
    implements $MeterDetailCopyWith<$Res> {
  _$MeterDetailCopyWithImpl(this._self, this._then);

  final MeterDetail _self;
  final $Res Function(MeterDetail) _then;

/// Create a copy of MeterDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? reference = null,Object? label = freezed,Object? type = null,Object? status = null,Object? contractNumber = freezed,Object? customerNumber = freezed,Object? e2cCenter = freezed,Object? subscribedPowerVa = freezed,Object? installedAt = freezed,Object? myRole = null,Object? canManage = null,Object? createdAt = null,}) {
  return _then(MeterDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,customerNumber: freezed == customerNumber ? _self.customerNumber : customerNumber // ignore: cast_nullable_to_non_nullable
as String?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,subscribedPowerVa: freezed == subscribedPowerVa ? _self.subscribedPowerVa : subscribedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,installedAt: freezed == installedAt ? _self.installedAt : installedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MeterDetail].
extension MeterDetailPatterns on MeterDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeterDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeterDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeterDetail value)  $default,){
final _that = this;
switch (_that) {
case _MeterDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeterDetail value)?  $default,){
final _that = this;
switch (_that) {
case _MeterDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int householdId,  String reference,  String? label,  String type,  String status,  String? contractNumber,  String? customerNumber,  String? e2cCenter,  int? subscribedPowerVa,  DateTime? installedAt,  HouseholdRole myRole,  bool canManage,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeterDetail() when $default != null:
return $default(_that.id,_that.householdId,_that.reference,_that.label,_that.type,_that.status,_that.contractNumber,_that.customerNumber,_that.e2cCenter,_that.subscribedPowerVa,_that.installedAt,_that.myRole,_that.canManage,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int householdId,  String reference,  String? label,  String type,  String status,  String? contractNumber,  String? customerNumber,  String? e2cCenter,  int? subscribedPowerVa,  DateTime? installedAt,  HouseholdRole myRole,  bool canManage,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MeterDetail():
return $default(_that.id,_that.householdId,_that.reference,_that.label,_that.type,_that.status,_that.contractNumber,_that.customerNumber,_that.e2cCenter,_that.subscribedPowerVa,_that.installedAt,_that.myRole,_that.canManage,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int householdId,  String reference,  String? label,  String type,  String status,  String? contractNumber,  String? customerNumber,  String? e2cCenter,  int? subscribedPowerVa,  DateTime? installedAt,  HouseholdRole myRole,  bool canManage,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MeterDetail() when $default != null:
return $default(_that.id,_that.householdId,_that.reference,_that.label,_that.type,_that.status,_that.contractNumber,_that.customerNumber,_that.e2cCenter,_that.subscribedPowerVa,_that.installedAt,_that.myRole,_that.canManage,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeterDetail implements MeterDetail {
  const _MeterDetail({required this.id, required this.householdId, required this.reference, required this.label, required this.type, required this.status, required this.contractNumber, required this.customerNumber, required this.e2cCenter, required this.subscribedPowerVa, required this.installedAt, required this.myRole, required this.canManage, required this.createdAt});
  factory _MeterDetail.fromJson(Map<String, dynamic> json) => _$MeterDetailFromJson(json);

@override final  int id;
@override final  int householdId;
@override final  String reference;
@override final  String? label;
@override final  String type;
@override final  String status;
@override final  String? contractNumber;
@override final  String? customerNumber;
@override final  String? e2cCenter;
@override final  int? subscribedPowerVa;
@override final  DateTime? installedAt;
@override final  HouseholdRole myRole;
@override final  bool canManage;
@override final  DateTime createdAt;

/// Create a copy of MeterDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeterDetailCopyWith<_MeterDetail> get copyWith => __$MeterDetailCopyWithImpl<_MeterDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeterDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeterDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.customerNumber, customerNumber) || other.customerNumber == customerNumber)&&(identical(other.e2cCenter, e2cCenter) || other.e2cCenter == e2cCenter)&&(identical(other.subscribedPowerVa, subscribedPowerVa) || other.subscribedPowerVa == subscribedPowerVa)&&(identical(other.installedAt, installedAt) || other.installedAt == installedAt)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.canManage, canManage) || other.canManage == canManage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,householdId,reference,label,type,status,contractNumber,customerNumber,e2cCenter,subscribedPowerVa,installedAt,myRole,canManage,createdAt);
}

@override
String toString() {
    return 'MeterDetail(id: $id, householdId: $householdId, reference: $reference, label: $label, type: $type, status: $status, contractNumber: $contractNumber, customerNumber: $customerNumber, e2cCenter: $e2cCenter, subscribedPowerVa: $subscribedPowerVa, installedAt: $installedAt, myRole: $myRole, canManage: $canManage, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MeterDetailCopyWith<$Res> implements $MeterDetailCopyWith<$Res> {
  factory _$MeterDetailCopyWith(_MeterDetail value, $Res Function(_MeterDetail) _then) = __$MeterDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, int householdId, String reference, String? label, String type, String status, String? contractNumber, String? customerNumber, String? e2cCenter, int? subscribedPowerVa, DateTime? installedAt, HouseholdRole myRole, bool canManage, DateTime createdAt
});




}
/// @nodoc
class __$MeterDetailCopyWithImpl<$Res>
    implements _$MeterDetailCopyWith<$Res> {
  __$MeterDetailCopyWithImpl(this._self, this._then);

  final _MeterDetail _self;
  final $Res Function(_MeterDetail) _then;

/// Create a copy of MeterDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? reference = null,Object? label = freezed,Object? type = null,Object? status = null,Object? contractNumber = freezed,Object? customerNumber = freezed,Object? e2cCenter = freezed,Object? subscribedPowerVa = freezed,Object? installedAt = freezed,Object? myRole = null,Object? canManage = null,Object? createdAt = null,}) {
  return _then(_MeterDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,customerNumber: freezed == customerNumber ? _self.customerNumber : customerNumber // ignore: cast_nullable_to_non_nullable
as String?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,subscribedPowerVa: freezed == subscribedPowerVa ? _self.subscribedPowerVa : subscribedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,installedAt: freezed == installedAt ? _self.installedAt : installedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
