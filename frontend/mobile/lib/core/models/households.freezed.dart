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


/// @nodoc
mixin _$PersonPublic {

 int get id; String get fullName; String get phoneMasked;
/// Create a copy of PersonPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<PersonPublic> get copyWith => _$PersonPublicCopyWithImpl<PersonPublic>(this as PersonPublic, _$identity);

  /// Serializes this PersonPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PersonPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.phoneMasked, _this.phoneMasked) || other.phoneMasked == _this.phoneMasked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PersonPublic;
  return Object.hash(runtimeType,_this.id,_this.fullName,_this.phoneMasked);
}

@override
String toString() {
  final _this = this as PersonPublic;
  return 'PersonPublic(id: ${_this.id}, fullName: ${_this.fullName}, phoneMasked: ${_this.phoneMasked})';
}


}

/// @nodoc
abstract mixin class $PersonPublicCopyWith<$Res>  {
  factory $PersonPublicCopyWith(PersonPublic value, $Res Function(PersonPublic) _then) = _$PersonPublicCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, String phoneMasked
});




}
/// @nodoc
class _$PersonPublicCopyWithImpl<$Res>
    implements $PersonPublicCopyWith<$Res> {
  _$PersonPublicCopyWithImpl(this._self, this._then);

  final PersonPublic _self;
  final $Res Function(PersonPublic) _then;

/// Create a copy of PersonPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phoneMasked = null,}) {
  return _then(PersonPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneMasked: null == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonPublic].
extension PersonPublicPatterns on PersonPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonPublic value)  $default,){
final _that = this;
switch (_that) {
case _PersonPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonPublic value)?  $default,){
final _that = this;
switch (_that) {
case _PersonPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  String phoneMasked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonPublic() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneMasked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  String phoneMasked)  $default,) {final _that = this;
switch (_that) {
case _PersonPublic():
return $default(_that.id,_that.fullName,_that.phoneMasked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  String phoneMasked)?  $default,) {final _that = this;
switch (_that) {
case _PersonPublic() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneMasked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonPublic implements PersonPublic {
  const _PersonPublic({required this.id, required this.fullName, required this.phoneMasked});
  factory _PersonPublic.fromJson(Map<String, dynamic> json) => _$PersonPublicFromJson(json);

@override final  int id;
@override final  String fullName;
@override final  String phoneMasked;

/// Create a copy of PersonPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonPublicCopyWith<_PersonPublic> get copyWith => __$PersonPublicCopyWithImpl<_PersonPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneMasked, phoneMasked) || other.phoneMasked == phoneMasked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fullName,phoneMasked);
}

@override
String toString() {
    return 'PersonPublic(id: $id, fullName: $fullName, phoneMasked: $phoneMasked)';
}


}

/// @nodoc
abstract mixin class _$PersonPublicCopyWith<$Res> implements $PersonPublicCopyWith<$Res> {
  factory _$PersonPublicCopyWith(_PersonPublic value, $Res Function(_PersonPublic) _then) = __$PersonPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, String phoneMasked
});




}
/// @nodoc
class __$PersonPublicCopyWithImpl<$Res>
    implements _$PersonPublicCopyWith<$Res> {
  __$PersonPublicCopyWithImpl(this._self, this._then);

  final _PersonPublic _self;
  final $Res Function(_PersonPublic) _then;

/// Create a copy of PersonPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneMasked = null,}) {
  return _then(_PersonPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneMasked: null == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MemberPublic {

 int get id; PersonPublic get person; MemberRole get role; String get status; DateTime get createdAt;
/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberPublicCopyWith<MemberPublic> get copyWith => _$MemberPublicCopyWithImpl<MemberPublic>(this as MemberPublic, _$identity);

  /// Serializes this MemberPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.person, _this.person) || other.person == _this.person)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberPublic;
  return Object.hash(runtimeType,_this.id,_this.person,_this.role,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as MemberPublic;
  return 'MemberPublic(id: ${_this.id}, person: ${_this.person}, role: ${_this.role}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MemberPublicCopyWith<$Res>  {
  factory $MemberPublicCopyWith(MemberPublic value, $Res Function(MemberPublic) _then) = _$MemberPublicCopyWithImpl;
@useResult
$Res call({
 int id, PersonPublic person, MemberRole role, String status, DateTime createdAt
});


$PersonPublicCopyWith<$Res> get person;

}
/// @nodoc
class _$MemberPublicCopyWithImpl<$Res>
    implements $MemberPublicCopyWith<$Res> {
  _$MemberPublicCopyWithImpl(this._self, this._then);

  final MemberPublic _self;
  final $Res Function(MemberPublic) _then;

/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? person = null,Object? role = null,Object? status = null,Object? createdAt = null,}) {
  return _then(MemberPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as PersonPublic,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get person {
  
  return $PersonPublicCopyWith<$Res>(_self.person, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// Adds pattern-matching-related methods to [MemberPublic].
extension MemberPublicPatterns on MemberPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberPublic value)  $default,){
final _that = this;
switch (_that) {
case _MemberPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberPublic value)?  $default,){
final _that = this;
switch (_that) {
case _MemberPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  PersonPublic person,  MemberRole role,  String status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberPublic() when $default != null:
return $default(_that.id,_that.person,_that.role,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  PersonPublic person,  MemberRole role,  String status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MemberPublic():
return $default(_that.id,_that.person,_that.role,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  PersonPublic person,  MemberRole role,  String status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MemberPublic() when $default != null:
return $default(_that.id,_that.person,_that.role,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberPublic implements MemberPublic {
  const _MemberPublic({required this.id, required this.person, required this.role, required this.status, required this.createdAt});
  factory _MemberPublic.fromJson(Map<String, dynamic> json) => _$MemberPublicFromJson(json);

@override final  int id;
@override final  PersonPublic person;
@override final  MemberRole role;
@override final  String status;
@override final  DateTime createdAt;

/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberPublicCopyWith<_MemberPublic> get copyWith => __$MemberPublicCopyWithImpl<_MemberPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.person, person) || other.person == person)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,person,role,status,createdAt);
}

@override
String toString() {
    return 'MemberPublic(id: $id, person: $person, role: $role, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemberPublicCopyWith<$Res> implements $MemberPublicCopyWith<$Res> {
  factory _$MemberPublicCopyWith(_MemberPublic value, $Res Function(_MemberPublic) _then) = __$MemberPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, PersonPublic person, MemberRole role, String status, DateTime createdAt
});


@override $PersonPublicCopyWith<$Res> get person;

}
/// @nodoc
class __$MemberPublicCopyWithImpl<$Res>
    implements _$MemberPublicCopyWith<$Res> {
  __$MemberPublicCopyWithImpl(this._self, this._then);

  final _MemberPublic _self;
  final $Res Function(_MemberPublic) _then;

/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? person = null,Object? role = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_MemberPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as PersonPublic,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MemberPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get person {
  
  return $PersonPublicCopyWith<$Res>(_self.person, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// @nodoc
mixin _$HouseholdDetail {

 int get id; String get name; String get city; String? get district; String? get address; HouseholdRole get myRole; bool get canPay; bool get canManage; PersonPublic get owner; List<MeterSummary> get meters; List<MemberPublic> get members; DateTime get createdAt;
/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdDetailCopyWith<HouseholdDetail> get copyWith => _$HouseholdDetailCopyWithImpl<HouseholdDetail>(this as HouseholdDetail, _$identity);

  /// Serializes this HouseholdDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.district, _this.district) || other.district == _this.district)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.canPay, _this.canPay) || other.canPay == _this.canPay)&&(identical(other.canManage, _this.canManage) || other.canManage == _this.canManage)&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&const DeepCollectionEquality().equals(other.meters, _this.meters)&&const DeepCollectionEquality().equals(other.members, _this.members)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdDetail;
  return Object.hash(runtimeType,_this.id,_this.name,_this.city,_this.district,_this.address,_this.myRole,_this.canPay,_this.canManage,_this.owner,const DeepCollectionEquality().hash(_this.meters),const DeepCollectionEquality().hash(_this.members),_this.createdAt);
}

@override
String toString() {
  final _this = this as HouseholdDetail;
  return 'HouseholdDetail(id: ${_this.id}, name: ${_this.name}, city: ${_this.city}, district: ${_this.district}, address: ${_this.address}, myRole: ${_this.myRole}, canPay: ${_this.canPay}, canManage: ${_this.canManage}, owner: ${_this.owner}, meters: ${_this.meters}, members: ${_this.members}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $HouseholdDetailCopyWith<$Res>  {
  factory $HouseholdDetailCopyWith(HouseholdDetail value, $Res Function(HouseholdDetail) _then) = _$HouseholdDetailCopyWithImpl;
@useResult
$Res call({
 int id, String name, String city, String? district, String? address, HouseholdRole myRole, bool canPay, bool canManage, PersonPublic owner, List<MeterSummary> meters, List<MemberPublic> members, DateTime createdAt
});


$PersonPublicCopyWith<$Res> get owner;

}
/// @nodoc
class _$HouseholdDetailCopyWithImpl<$Res>
    implements $HouseholdDetailCopyWith<$Res> {
  _$HouseholdDetailCopyWithImpl(this._self, this._then);

  final HouseholdDetail _self;
  final $Res Function(HouseholdDetail) _then;

/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,Object? district = freezed,Object? address = freezed,Object? myRole = null,Object? canPay = null,Object? canManage = null,Object? owner = null,Object? meters = null,Object? members = null,Object? createdAt = null,}) {
  return _then(HouseholdDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as PersonPublic,meters: null == meters ? _self.meters : meters // ignore: cast_nullable_to_non_nullable
as List<MeterSummary>,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<MemberPublic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get owner {
  
  return $PersonPublicCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [HouseholdDetail].
extension HouseholdDetailPatterns on HouseholdDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdDetail value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdDetail value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String city,  String? district,  String? address,  HouseholdRole myRole,  bool canPay,  bool canManage,  PersonPublic owner,  List<MeterSummary> meters,  List<MemberPublic> members,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdDetail() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.district,_that.address,_that.myRole,_that.canPay,_that.canManage,_that.owner,_that.meters,_that.members,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String city,  String? district,  String? address,  HouseholdRole myRole,  bool canPay,  bool canManage,  PersonPublic owner,  List<MeterSummary> meters,  List<MemberPublic> members,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _HouseholdDetail():
return $default(_that.id,_that.name,_that.city,_that.district,_that.address,_that.myRole,_that.canPay,_that.canManage,_that.owner,_that.meters,_that.members,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String city,  String? district,  String? address,  HouseholdRole myRole,  bool canPay,  bool canManage,  PersonPublic owner,  List<MeterSummary> meters,  List<MemberPublic> members,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdDetail() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.district,_that.address,_that.myRole,_that.canPay,_that.canManage,_that.owner,_that.meters,_that.members,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdDetail implements HouseholdDetail {
  const _HouseholdDetail({required this.id, required this.name, required this.city, required this.district, required this.address, required this.myRole, required this.canPay, required this.canManage, required this.owner, required  List<MeterSummary> meters, required  List<MemberPublic> members, required this.createdAt}): _meters = meters,_members = members;
  factory _HouseholdDetail.fromJson(Map<String, dynamic> json) => _$HouseholdDetailFromJson(json);

@override final  int id;
@override final  String name;
@override final  String city;
@override final  String? district;
@override final  String? address;
@override final  HouseholdRole myRole;
@override final  bool canPay;
@override final  bool canManage;
@override final  PersonPublic owner;
 final  List<MeterSummary> _meters;
@override List<MeterSummary> get meters {
  if (_meters is EqualUnmodifiableListView) return _meters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meters);
}

 final  List<MemberPublic> _members;
@override List<MemberPublic> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  DateTime createdAt;

/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdDetailCopyWith<_HouseholdDetail> get copyWith => __$HouseholdDetailCopyWithImpl<_HouseholdDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.district, district) || other.district == district)&&(identical(other.address, address) || other.address == address)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&(identical(other.canManage, canManage) || other.canManage == canManage)&&(identical(other.owner, owner) || other.owner == owner)&&const DeepCollectionEquality().equals(other.meters, _meters)&&const DeepCollectionEquality().equals(other.members, _members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,city,district,address,myRole,canPay,canManage,owner,const DeepCollectionEquality().hash(_meters),const DeepCollectionEquality().hash(_members),createdAt);
}

@override
String toString() {
    return 'HouseholdDetail(id: $id, name: $name, city: $city, district: $district, address: $address, myRole: $myRole, canPay: $canPay, canManage: $canManage, owner: $owner, meters: $meters, members: $members, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HouseholdDetailCopyWith<$Res> implements $HouseholdDetailCopyWith<$Res> {
  factory _$HouseholdDetailCopyWith(_HouseholdDetail value, $Res Function(_HouseholdDetail) _then) = __$HouseholdDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String city, String? district, String? address, HouseholdRole myRole, bool canPay, bool canManage, PersonPublic owner, List<MeterSummary> meters, List<MemberPublic> members, DateTime createdAt
});


@override $PersonPublicCopyWith<$Res> get owner;

}
/// @nodoc
class __$HouseholdDetailCopyWithImpl<$Res>
    implements _$HouseholdDetailCopyWith<$Res> {
  __$HouseholdDetailCopyWithImpl(this._self, this._then);

  final _HouseholdDetail _self;
  final $Res Function(_HouseholdDetail) _then;

/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,Object? district = freezed,Object? address = freezed,Object? myRole = null,Object? canPay = null,Object? canManage = null,Object? owner = null,Object? meters = null,Object? members = null,Object? createdAt = null,}) {
  return _then(_HouseholdDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as HouseholdRole,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as PersonPublic,meters: null == meters ? _self._meters : meters // ignore: cast_nullable_to_non_nullable
as List<MeterSummary>,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<MemberPublic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of HouseholdDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get owner {
  
  return $PersonPublicCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// @nodoc
mixin _$MeterSummary {

 int get id; String get reference; String? get label; String get type; String get status; int? get subscribedPowerVa; String? get e2cCenter;
/// Create a copy of MeterSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeterSummaryCopyWith<MeterSummary> get copyWith => _$MeterSummaryCopyWithImpl<MeterSummary>(this as MeterSummary, _$identity);

  /// Serializes this MeterSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeterSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeterSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.subscribedPowerVa, _this.subscribedPowerVa) || other.subscribedPowerVa == _this.subscribedPowerVa)&&(identical(other.e2cCenter, _this.e2cCenter) || other.e2cCenter == _this.e2cCenter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeterSummary;
  return Object.hash(runtimeType,_this.id,_this.reference,_this.label,_this.type,_this.status,_this.subscribedPowerVa,_this.e2cCenter);
}

@override
String toString() {
  final _this = this as MeterSummary;
  return 'MeterSummary(id: ${_this.id}, reference: ${_this.reference}, label: ${_this.label}, type: ${_this.type}, status: ${_this.status}, subscribedPowerVa: ${_this.subscribedPowerVa}, e2cCenter: ${_this.e2cCenter})';
}


}

/// @nodoc
abstract mixin class $MeterSummaryCopyWith<$Res>  {
  factory $MeterSummaryCopyWith(MeterSummary value, $Res Function(MeterSummary) _then) = _$MeterSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String reference, String? label, String type, String status, int? subscribedPowerVa, String? e2cCenter
});




}
/// @nodoc
class _$MeterSummaryCopyWithImpl<$Res>
    implements $MeterSummaryCopyWith<$Res> {
  _$MeterSummaryCopyWithImpl(this._self, this._then);

  final MeterSummary _self;
  final $Res Function(MeterSummary) _then;

/// Create a copy of MeterSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? label = freezed,Object? type = null,Object? status = null,Object? subscribedPowerVa = freezed,Object? e2cCenter = freezed,}) {
  return _then(MeterSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subscribedPowerVa: freezed == subscribedPowerVa ? _self.subscribedPowerVa : subscribedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeterSummary].
extension MeterSummaryPatterns on MeterSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeterSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeterSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeterSummary value)  $default,){
final _that = this;
switch (_that) {
case _MeterSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeterSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MeterSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String reference,  String? label,  String type,  String status,  int? subscribedPowerVa,  String? e2cCenter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeterSummary() when $default != null:
return $default(_that.id,_that.reference,_that.label,_that.type,_that.status,_that.subscribedPowerVa,_that.e2cCenter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String reference,  String? label,  String type,  String status,  int? subscribedPowerVa,  String? e2cCenter)  $default,) {final _that = this;
switch (_that) {
case _MeterSummary():
return $default(_that.id,_that.reference,_that.label,_that.type,_that.status,_that.subscribedPowerVa,_that.e2cCenter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String reference,  String? label,  String type,  String status,  int? subscribedPowerVa,  String? e2cCenter)?  $default,) {final _that = this;
switch (_that) {
case _MeterSummary() when $default != null:
return $default(_that.id,_that.reference,_that.label,_that.type,_that.status,_that.subscribedPowerVa,_that.e2cCenter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeterSummary implements MeterSummary {
  const _MeterSummary({required this.id, required this.reference, required this.label, required this.type, required this.status, required this.subscribedPowerVa, required this.e2cCenter});
  factory _MeterSummary.fromJson(Map<String, dynamic> json) => _$MeterSummaryFromJson(json);

@override final  int id;
@override final  String reference;
@override final  String? label;
@override final  String type;
@override final  String status;
@override final  int? subscribedPowerVa;
@override final  String? e2cCenter;

/// Create a copy of MeterSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeterSummaryCopyWith<_MeterSummary> get copyWith => __$MeterSummaryCopyWithImpl<_MeterSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeterSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeterSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.subscribedPowerVa, subscribedPowerVa) || other.subscribedPowerVa == subscribedPowerVa)&&(identical(other.e2cCenter, e2cCenter) || other.e2cCenter == e2cCenter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,reference,label,type,status,subscribedPowerVa,e2cCenter);
}

@override
String toString() {
    return 'MeterSummary(id: $id, reference: $reference, label: $label, type: $type, status: $status, subscribedPowerVa: $subscribedPowerVa, e2cCenter: $e2cCenter)';
}


}

/// @nodoc
abstract mixin class _$MeterSummaryCopyWith<$Res> implements $MeterSummaryCopyWith<$Res> {
  factory _$MeterSummaryCopyWith(_MeterSummary value, $Res Function(_MeterSummary) _then) = __$MeterSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String reference, String? label, String type, String status, int? subscribedPowerVa, String? e2cCenter
});




}
/// @nodoc
class __$MeterSummaryCopyWithImpl<$Res>
    implements _$MeterSummaryCopyWith<$Res> {
  __$MeterSummaryCopyWithImpl(this._self, this._then);

  final _MeterSummary _self;
  final $Res Function(_MeterSummary) _then;

/// Create a copy of MeterSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? label = freezed,Object? type = null,Object? status = null,Object? subscribedPowerVa = freezed,Object? e2cCenter = freezed,}) {
  return _then(_MeterSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subscribedPowerVa: freezed == subscribedPowerVa ? _self.subscribedPowerVa : subscribedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$HouseholdBrief {

 int get id; String get name; String get city;
/// Create a copy of HouseholdBrief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdBriefCopyWith<HouseholdBrief> get copyWith => _$HouseholdBriefCopyWithImpl<HouseholdBrief>(this as HouseholdBrief, _$identity);

  /// Serializes this HouseholdBrief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdBrief;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdBrief&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdBrief;
  return Object.hash(runtimeType,_this.id,_this.name,_this.city);
}

@override
String toString() {
  final _this = this as HouseholdBrief;
  return 'HouseholdBrief(id: ${_this.id}, name: ${_this.name}, city: ${_this.city})';
}


}

/// @nodoc
abstract mixin class $HouseholdBriefCopyWith<$Res>  {
  factory $HouseholdBriefCopyWith(HouseholdBrief value, $Res Function(HouseholdBrief) _then) = _$HouseholdBriefCopyWithImpl;
@useResult
$Res call({
 int id, String name, String city
});




}
/// @nodoc
class _$HouseholdBriefCopyWithImpl<$Res>
    implements $HouseholdBriefCopyWith<$Res> {
  _$HouseholdBriefCopyWithImpl(this._self, this._then);

  final HouseholdBrief _self;
  final $Res Function(HouseholdBrief) _then;

/// Create a copy of HouseholdBrief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,}) {
  return _then(HouseholdBrief(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdBrief].
extension HouseholdBriefPatterns on HouseholdBrief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdBrief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdBrief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdBrief value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdBrief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdBrief value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdBrief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdBrief() when $default != null:
return $default(_that.id,_that.name,_that.city);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String city)  $default,) {final _that = this;
switch (_that) {
case _HouseholdBrief():
return $default(_that.id,_that.name,_that.city);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String city)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdBrief() when $default != null:
return $default(_that.id,_that.name,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdBrief implements HouseholdBrief {
  const _HouseholdBrief({required this.id, required this.name, required this.city});
  factory _HouseholdBrief.fromJson(Map<String, dynamic> json) => _$HouseholdBriefFromJson(json);

@override final  int id;
@override final  String name;
@override final  String city;

/// Create a copy of HouseholdBrief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdBriefCopyWith<_HouseholdBrief> get copyWith => __$HouseholdBriefCopyWithImpl<_HouseholdBrief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdBriefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdBrief&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,city);
}

@override
String toString() {
    return 'HouseholdBrief(id: $id, name: $name, city: $city)';
}


}

/// @nodoc
abstract mixin class _$HouseholdBriefCopyWith<$Res> implements $HouseholdBriefCopyWith<$Res> {
  factory _$HouseholdBriefCopyWith(_HouseholdBrief value, $Res Function(_HouseholdBrief) _then) = __$HouseholdBriefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String city
});




}
/// @nodoc
class __$HouseholdBriefCopyWithImpl<$Res>
    implements _$HouseholdBriefCopyWith<$Res> {
  __$HouseholdBriefCopyWithImpl(this._self, this._then);

  final _HouseholdBrief _self;
  final $Res Function(_HouseholdBrief) _then;

/// Create a copy of HouseholdBrief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,}) {
  return _then(_HouseholdBrief(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InvitationPublic {

 int get id; HouseholdBrief get household; MemberRole get role; PersonPublic get invitedBy; DateTime get createdAt;
/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationPublicCopyWith<InvitationPublic> get copyWith => _$InvitationPublicCopyWithImpl<InvitationPublic>(this as InvitationPublic, _$identity);

  /// Serializes this InvitationPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitationPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.household, _this.household) || other.household == _this.household)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.invitedBy, _this.invitedBy) || other.invitedBy == _this.invitedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitationPublic;
  return Object.hash(runtimeType,_this.id,_this.household,_this.role,_this.invitedBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as InvitationPublic;
  return 'InvitationPublic(id: ${_this.id}, household: ${_this.household}, role: ${_this.role}, invitedBy: ${_this.invitedBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $InvitationPublicCopyWith<$Res>  {
  factory $InvitationPublicCopyWith(InvitationPublic value, $Res Function(InvitationPublic) _then) = _$InvitationPublicCopyWithImpl;
@useResult
$Res call({
 int id, HouseholdBrief household, MemberRole role, PersonPublic invitedBy, DateTime createdAt
});


$HouseholdBriefCopyWith<$Res> get household;$PersonPublicCopyWith<$Res> get invitedBy;

}
/// @nodoc
class _$InvitationPublicCopyWithImpl<$Res>
    implements $InvitationPublicCopyWith<$Res> {
  _$InvitationPublicCopyWithImpl(this._self, this._then);

  final InvitationPublic _self;
  final $Res Function(InvitationPublic) _then;

/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? household = null,Object? role = null,Object? invitedBy = null,Object? createdAt = null,}) {
  return _then(InvitationPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,household: null == household ? _self.household : household // ignore: cast_nullable_to_non_nullable
as HouseholdBrief,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,invitedBy: null == invitedBy ? _self.invitedBy : invitedBy // ignore: cast_nullable_to_non_nullable
as PersonPublic,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HouseholdBriefCopyWith<$Res> get household {
  
  return $HouseholdBriefCopyWith<$Res>(_self.household, (value) {
    return _then(_self.copyWith(household: value));
  });
}/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get invitedBy {
  
  return $PersonPublicCopyWith<$Res>(_self.invitedBy, (value) {
    return _then(_self.copyWith(invitedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvitationPublic].
extension InvitationPublicPatterns on InvitationPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationPublic value)  $default,){
final _that = this;
switch (_that) {
case _InvitationPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationPublic value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  HouseholdBrief household,  MemberRole role,  PersonPublic invitedBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationPublic() when $default != null:
return $default(_that.id,_that.household,_that.role,_that.invitedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  HouseholdBrief household,  MemberRole role,  PersonPublic invitedBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvitationPublic():
return $default(_that.id,_that.household,_that.role,_that.invitedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  HouseholdBrief household,  MemberRole role,  PersonPublic invitedBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvitationPublic() when $default != null:
return $default(_that.id,_that.household,_that.role,_that.invitedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationPublic implements InvitationPublic {
  const _InvitationPublic({required this.id, required this.household, required this.role, required this.invitedBy, required this.createdAt});
  factory _InvitationPublic.fromJson(Map<String, dynamic> json) => _$InvitationPublicFromJson(json);

@override final  int id;
@override final  HouseholdBrief household;
@override final  MemberRole role;
@override final  PersonPublic invitedBy;
@override final  DateTime createdAt;

/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationPublicCopyWith<_InvitationPublic> get copyWith => __$InvitationPublicCopyWithImpl<_InvitationPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.household, household) || other.household == household)&&(identical(other.role, role) || other.role == role)&&(identical(other.invitedBy, invitedBy) || other.invitedBy == invitedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,household,role,invitedBy,createdAt);
}

@override
String toString() {
    return 'InvitationPublic(id: $id, household: $household, role: $role, invitedBy: $invitedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvitationPublicCopyWith<$Res> implements $InvitationPublicCopyWith<$Res> {
  factory _$InvitationPublicCopyWith(_InvitationPublic value, $Res Function(_InvitationPublic) _then) = __$InvitationPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, HouseholdBrief household, MemberRole role, PersonPublic invitedBy, DateTime createdAt
});


@override $HouseholdBriefCopyWith<$Res> get household;@override $PersonPublicCopyWith<$Res> get invitedBy;

}
/// @nodoc
class __$InvitationPublicCopyWithImpl<$Res>
    implements _$InvitationPublicCopyWith<$Res> {
  __$InvitationPublicCopyWithImpl(this._self, this._then);

  final _InvitationPublic _self;
  final $Res Function(_InvitationPublic) _then;

/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? household = null,Object? role = null,Object? invitedBy = null,Object? createdAt = null,}) {
  return _then(_InvitationPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,household: null == household ? _self.household : household // ignore: cast_nullable_to_non_nullable
as HouseholdBrief,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,invitedBy: null == invitedBy ? _self.invitedBy : invitedBy // ignore: cast_nullable_to_non_nullable
as PersonPublic,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HouseholdBriefCopyWith<$Res> get household {
  
  return $HouseholdBriefCopyWith<$Res>(_self.household, (value) {
    return _then(_self.copyWith(household: value));
  });
}/// Create a copy of InvitationPublic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonPublicCopyWith<$Res> get invitedBy {
  
  return $PersonPublicCopyWith<$Res>(_self.invitedBy, (value) {
    return _then(_self.copyWith(invitedBy: value));
  });
}
}


/// @nodoc
mixin _$HouseholdCreate {

 String get name; String get city; String? get district; String? get address;
/// Create a copy of HouseholdCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdCreateCopyWith<HouseholdCreate> get copyWith => _$HouseholdCreateCopyWithImpl<HouseholdCreate>(this as HouseholdCreate, _$identity);

  /// Serializes this HouseholdCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdCreate&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.district, _this.district) || other.district == _this.district)&&(identical(other.address, _this.address) || other.address == _this.address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdCreate;
  return Object.hash(runtimeType,_this.name,_this.city,_this.district,_this.address);
}

@override
String toString() {
  final _this = this as HouseholdCreate;
  return 'HouseholdCreate(name: ${_this.name}, city: ${_this.city}, district: ${_this.district}, address: ${_this.address})';
}


}

/// @nodoc
abstract mixin class $HouseholdCreateCopyWith<$Res>  {
  factory $HouseholdCreateCopyWith(HouseholdCreate value, $Res Function(HouseholdCreate) _then) = _$HouseholdCreateCopyWithImpl;
@useResult
$Res call({
 String name, String city, String? district, String? address
});




}
/// @nodoc
class _$HouseholdCreateCopyWithImpl<$Res>
    implements $HouseholdCreateCopyWith<$Res> {
  _$HouseholdCreateCopyWithImpl(this._self, this._then);

  final HouseholdCreate _self;
  final $Res Function(HouseholdCreate) _then;

/// Create a copy of HouseholdCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? city = null,Object? district = freezed,Object? address = freezed,}) {
  return _then(HouseholdCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdCreate].
extension HouseholdCreatePatterns on HouseholdCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdCreate value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdCreate value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String city,  String? district,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdCreate() when $default != null:
return $default(_that.name,_that.city,_that.district,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String city,  String? district,  String? address)  $default,) {final _that = this;
switch (_that) {
case _HouseholdCreate():
return $default(_that.name,_that.city,_that.district,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String city,  String? district,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdCreate() when $default != null:
return $default(_that.name,_that.city,_that.district,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdCreate implements HouseholdCreate {
  const _HouseholdCreate({required this.name, required this.city, this.district, this.address});
  factory _HouseholdCreate.fromJson(Map<String, dynamic> json) => _$HouseholdCreateFromJson(json);

@override final  String name;
@override final  String city;
@override final  String? district;
@override final  String? address;

/// Create a copy of HouseholdCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdCreateCopyWith<_HouseholdCreate> get copyWith => __$HouseholdCreateCopyWithImpl<_HouseholdCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdCreateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.district, district) || other.district == district)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,city,district,address);
}

@override
String toString() {
    return 'HouseholdCreate(name: $name, city: $city, district: $district, address: $address)';
}


}

/// @nodoc
abstract mixin class _$HouseholdCreateCopyWith<$Res> implements $HouseholdCreateCopyWith<$Res> {
  factory _$HouseholdCreateCopyWith(_HouseholdCreate value, $Res Function(_HouseholdCreate) _then) = __$HouseholdCreateCopyWithImpl;
@override @useResult
$Res call({
 String name, String city, String? district, String? address
});




}
/// @nodoc
class __$HouseholdCreateCopyWithImpl<$Res>
    implements _$HouseholdCreateCopyWith<$Res> {
  __$HouseholdCreateCopyWithImpl(this._self, this._then);

  final _HouseholdCreate _self;
  final $Res Function(_HouseholdCreate) _then;

/// Create a copy of HouseholdCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? city = null,Object? district = freezed,Object? address = freezed,}) {
  return _then(_HouseholdCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InviteRequest {

 String get phone; MemberRole get role;
/// Create a copy of InviteRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteRequestCopyWith<InviteRequest> get copyWith => _$InviteRequestCopyWithImpl<InviteRequest>(this as InviteRequest, _$identity);

  /// Serializes this InviteRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InviteRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteRequest&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.role, _this.role) || other.role == _this.role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InviteRequest;
  return Object.hash(runtimeType,_this.phone,_this.role);
}

@override
String toString() {
  final _this = this as InviteRequest;
  return 'InviteRequest(phone: ${_this.phone}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $InviteRequestCopyWith<$Res>  {
  factory $InviteRequestCopyWith(InviteRequest value, $Res Function(InviteRequest) _then) = _$InviteRequestCopyWithImpl;
@useResult
$Res call({
 String phone, MemberRole role
});




}
/// @nodoc
class _$InviteRequestCopyWithImpl<$Res>
    implements $InviteRequestCopyWith<$Res> {
  _$InviteRequestCopyWithImpl(this._self, this._then);

  final InviteRequest _self;
  final $Res Function(InviteRequest) _then;

/// Create a copy of InviteRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? role = null,}) {
  return _then(InviteRequest(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteRequest].
extension InviteRequestPatterns on InviteRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteRequest value)  $default,){
final _that = this;
switch (_that) {
case _InviteRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteRequest value)?  $default,){
final _that = this;
switch (_that) {
case _InviteRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  MemberRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteRequest() when $default != null:
return $default(_that.phone,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  MemberRole role)  $default,) {final _that = this;
switch (_that) {
case _InviteRequest():
return $default(_that.phone,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  MemberRole role)?  $default,) {final _that = this;
switch (_that) {
case _InviteRequest() when $default != null:
return $default(_that.phone,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteRequest implements InviteRequest {
  const _InviteRequest({required this.phone, required this.role});
  factory _InviteRequest.fromJson(Map<String, dynamic> json) => _$InviteRequestFromJson(json);

@override final  String phone;
@override final  MemberRole role;

/// Create a copy of InviteRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteRequestCopyWith<_InviteRequest> get copyWith => __$InviteRequestCopyWithImpl<_InviteRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteRequest&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,phone,role);
}

@override
String toString() {
    return 'InviteRequest(phone: $phone, role: $role)';
}


}

/// @nodoc
abstract mixin class _$InviteRequestCopyWith<$Res> implements $InviteRequestCopyWith<$Res> {
  factory _$InviteRequestCopyWith(_InviteRequest value, $Res Function(_InviteRequest) _then) = __$InviteRequestCopyWithImpl;
@override @useResult
$Res call({
 String phone, MemberRole role
});




}
/// @nodoc
class __$InviteRequestCopyWithImpl<$Res>
    implements _$InviteRequestCopyWith<$Res> {
  __$InviteRequestCopyWithImpl(this._self, this._then);

  final _InviteRequest _self;
  final $Res Function(_InviteRequest) _then;

/// Create a copy of InviteRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? role = null,}) {
  return _then(_InviteRequest(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MemberRole,
  ));
}


}


/// @nodoc
mixin _$MeterAddRequest {

 String get reference; String get customerNumber; String? get label;
/// Create a copy of MeterAddRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeterAddRequestCopyWith<MeterAddRequest> get copyWith => _$MeterAddRequestCopyWithImpl<MeterAddRequest>(this as MeterAddRequest, _$identity);

  /// Serializes this MeterAddRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeterAddRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeterAddRequest&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.customerNumber, _this.customerNumber) || other.customerNumber == _this.customerNumber)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeterAddRequest;
  return Object.hash(runtimeType,_this.reference,_this.customerNumber,_this.label);
}

@override
String toString() {
  final _this = this as MeterAddRequest;
  return 'MeterAddRequest(reference: ${_this.reference}, customerNumber: ${_this.customerNumber}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $MeterAddRequestCopyWith<$Res>  {
  factory $MeterAddRequestCopyWith(MeterAddRequest value, $Res Function(MeterAddRequest) _then) = _$MeterAddRequestCopyWithImpl;
@useResult
$Res call({
 String reference, String customerNumber, String? label
});




}
/// @nodoc
class _$MeterAddRequestCopyWithImpl<$Res>
    implements $MeterAddRequestCopyWith<$Res> {
  _$MeterAddRequestCopyWithImpl(this._self, this._then);

  final MeterAddRequest _self;
  final $Res Function(MeterAddRequest) _then;

/// Create a copy of MeterAddRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? customerNumber = null,Object? label = freezed,}) {
  return _then(MeterAddRequest(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,customerNumber: null == customerNumber ? _self.customerNumber : customerNumber // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MeterAddRequest].
extension MeterAddRequestPatterns on MeterAddRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeterAddRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeterAddRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeterAddRequest value)  $default,){
final _that = this;
switch (_that) {
case _MeterAddRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeterAddRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MeterAddRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reference,  String customerNumber,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeterAddRequest() when $default != null:
return $default(_that.reference,_that.customerNumber,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reference,  String customerNumber,  String? label)  $default,) {final _that = this;
switch (_that) {
case _MeterAddRequest():
return $default(_that.reference,_that.customerNumber,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reference,  String customerNumber,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _MeterAddRequest() when $default != null:
return $default(_that.reference,_that.customerNumber,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeterAddRequest implements MeterAddRequest {
  const _MeterAddRequest({required this.reference, required this.customerNumber, this.label});
  factory _MeterAddRequest.fromJson(Map<String, dynamic> json) => _$MeterAddRequestFromJson(json);

@override final  String reference;
@override final  String customerNumber;
@override final  String? label;

/// Create a copy of MeterAddRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeterAddRequestCopyWith<_MeterAddRequest> get copyWith => __$MeterAddRequestCopyWithImpl<_MeterAddRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeterAddRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeterAddRequest&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.customerNumber, customerNumber) || other.customerNumber == customerNumber)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reference,customerNumber,label);
}

@override
String toString() {
    return 'MeterAddRequest(reference: $reference, customerNumber: $customerNumber, label: $label)';
}


}

/// @nodoc
abstract mixin class _$MeterAddRequestCopyWith<$Res> implements $MeterAddRequestCopyWith<$Res> {
  factory _$MeterAddRequestCopyWith(_MeterAddRequest value, $Res Function(_MeterAddRequest) _then) = __$MeterAddRequestCopyWithImpl;
@override @useResult
$Res call({
 String reference, String customerNumber, String? label
});




}
/// @nodoc
class __$MeterAddRequestCopyWithImpl<$Res>
    implements _$MeterAddRequestCopyWith<$Res> {
  __$MeterAddRequestCopyWithImpl(this._self, this._then);

  final _MeterAddRequest _self;
  final $Res Function(_MeterAddRequest) _then;

/// Create a copy of MeterAddRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? customerNumber = null,Object? label = freezed,}) {
  return _then(_MeterAddRequest(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,customerNumber: null == customerNumber ? _self.customerNumber : customerNumber // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$HistoryImportPublic {

 int get readings; int get bills; String get source;
/// Create a copy of HistoryImportPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryImportPublicCopyWith<HistoryImportPublic> get copyWith => _$HistoryImportPublicCopyWithImpl<HistoryImportPublic>(this as HistoryImportPublic, _$identity);

  /// Serializes this HistoryImportPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HistoryImportPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryImportPublic&&(identical(other.readings, _this.readings) || other.readings == _this.readings)&&(identical(other.bills, _this.bills) || other.bills == _this.bills)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HistoryImportPublic;
  return Object.hash(runtimeType,_this.readings,_this.bills,_this.source);
}

@override
String toString() {
  final _this = this as HistoryImportPublic;
  return 'HistoryImportPublic(readings: ${_this.readings}, bills: ${_this.bills}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $HistoryImportPublicCopyWith<$Res>  {
  factory $HistoryImportPublicCopyWith(HistoryImportPublic value, $Res Function(HistoryImportPublic) _then) = _$HistoryImportPublicCopyWithImpl;
@useResult
$Res call({
 int readings, int bills, String source
});




}
/// @nodoc
class _$HistoryImportPublicCopyWithImpl<$Res>
    implements $HistoryImportPublicCopyWith<$Res> {
  _$HistoryImportPublicCopyWithImpl(this._self, this._then);

  final HistoryImportPublic _self;
  final $Res Function(HistoryImportPublic) _then;

/// Create a copy of HistoryImportPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readings = null,Object? bills = null,Object? source = null,}) {
  return _then(HistoryImportPublic(
readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as int,bills: null == bills ? _self.bills : bills // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryImportPublic].
extension HistoryImportPublicPatterns on HistoryImportPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryImportPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryImportPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryImportPublic value)  $default,){
final _that = this;
switch (_that) {
case _HistoryImportPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryImportPublic value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryImportPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int readings,  int bills,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryImportPublic() when $default != null:
return $default(_that.readings,_that.bills,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int readings,  int bills,  String source)  $default,) {final _that = this;
switch (_that) {
case _HistoryImportPublic():
return $default(_that.readings,_that.bills,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int readings,  int bills,  String source)?  $default,) {final _that = this;
switch (_that) {
case _HistoryImportPublic() when $default != null:
return $default(_that.readings,_that.bills,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryImportPublic implements HistoryImportPublic {
  const _HistoryImportPublic({required this.readings, required this.bills, required this.source});
  factory _HistoryImportPublic.fromJson(Map<String, dynamic> json) => _$HistoryImportPublicFromJson(json);

@override final  int readings;
@override final  int bills;
@override final  String source;

/// Create a copy of HistoryImportPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryImportPublicCopyWith<_HistoryImportPublic> get copyWith => __$HistoryImportPublicCopyWithImpl<_HistoryImportPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryImportPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryImportPublic&&(identical(other.readings, readings) || other.readings == readings)&&(identical(other.bills, bills) || other.bills == bills)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,readings,bills,source);
}

@override
String toString() {
    return 'HistoryImportPublic(readings: $readings, bills: $bills, source: $source)';
}


}

/// @nodoc
abstract mixin class _$HistoryImportPublicCopyWith<$Res> implements $HistoryImportPublicCopyWith<$Res> {
  factory _$HistoryImportPublicCopyWith(_HistoryImportPublic value, $Res Function(_HistoryImportPublic) _then) = __$HistoryImportPublicCopyWithImpl;
@override @useResult
$Res call({
 int readings, int bills, String source
});




}
/// @nodoc
class __$HistoryImportPublicCopyWithImpl<$Res>
    implements _$HistoryImportPublicCopyWith<$Res> {
  __$HistoryImportPublicCopyWithImpl(this._self, this._then);

  final _HistoryImportPublic _self;
  final $Res Function(_HistoryImportPublic) _then;

/// Create a copy of HistoryImportPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readings = null,Object? bills = null,Object? source = null,}) {
  return _then(_HistoryImportPublic(
readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as int,bills: null == bills ? _self.bills : bills // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MeterAddResponse {

 MeterDetail get meter; HistoryImportPublic get history;
/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeterAddResponseCopyWith<MeterAddResponse> get copyWith => _$MeterAddResponseCopyWithImpl<MeterAddResponse>(this as MeterAddResponse, _$identity);

  /// Serializes this MeterAddResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeterAddResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeterAddResponse&&(identical(other.meter, _this.meter) || other.meter == _this.meter)&&(identical(other.history, _this.history) || other.history == _this.history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeterAddResponse;
  return Object.hash(runtimeType,_this.meter,_this.history);
}

@override
String toString() {
  final _this = this as MeterAddResponse;
  return 'MeterAddResponse(meter: ${_this.meter}, history: ${_this.history})';
}


}

/// @nodoc
abstract mixin class $MeterAddResponseCopyWith<$Res>  {
  factory $MeterAddResponseCopyWith(MeterAddResponse value, $Res Function(MeterAddResponse) _then) = _$MeterAddResponseCopyWithImpl;
@useResult
$Res call({
 MeterDetail meter, HistoryImportPublic history
});


$MeterDetailCopyWith<$Res> get meter;$HistoryImportPublicCopyWith<$Res> get history;

}
/// @nodoc
class _$MeterAddResponseCopyWithImpl<$Res>
    implements $MeterAddResponseCopyWith<$Res> {
  _$MeterAddResponseCopyWithImpl(this._self, this._then);

  final MeterAddResponse _self;
  final $Res Function(MeterAddResponse) _then;

/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meter = null,Object? history = null,}) {
  return _then(MeterAddResponse(
meter: null == meter ? _self.meter : meter // ignore: cast_nullable_to_non_nullable
as MeterDetail,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as HistoryImportPublic,
  ));
}
/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeterDetailCopyWith<$Res> get meter {
  
  return $MeterDetailCopyWith<$Res>(_self.meter, (value) {
    return _then(_self.copyWith(meter: value));
  });
}/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HistoryImportPublicCopyWith<$Res> get history {
  
  return $HistoryImportPublicCopyWith<$Res>(_self.history, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}


/// Adds pattern-matching-related methods to [MeterAddResponse].
extension MeterAddResponsePatterns on MeterAddResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeterAddResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeterAddResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeterAddResponse value)  $default,){
final _that = this;
switch (_that) {
case _MeterAddResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeterAddResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MeterAddResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MeterDetail meter,  HistoryImportPublic history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeterAddResponse() when $default != null:
return $default(_that.meter,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MeterDetail meter,  HistoryImportPublic history)  $default,) {final _that = this;
switch (_that) {
case _MeterAddResponse():
return $default(_that.meter,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MeterDetail meter,  HistoryImportPublic history)?  $default,) {final _that = this;
switch (_that) {
case _MeterAddResponse() when $default != null:
return $default(_that.meter,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeterAddResponse implements MeterAddResponse {
  const _MeterAddResponse({required this.meter, required this.history});
  factory _MeterAddResponse.fromJson(Map<String, dynamic> json) => _$MeterAddResponseFromJson(json);

@override final  MeterDetail meter;
@override final  HistoryImportPublic history;

/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeterAddResponseCopyWith<_MeterAddResponse> get copyWith => __$MeterAddResponseCopyWithImpl<_MeterAddResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeterAddResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeterAddResponse&&(identical(other.meter, meter) || other.meter == meter)&&(identical(other.history, history) || other.history == history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,meter,history);
}

@override
String toString() {
    return 'MeterAddResponse(meter: $meter, history: $history)';
}


}

/// @nodoc
abstract mixin class _$MeterAddResponseCopyWith<$Res> implements $MeterAddResponseCopyWith<$Res> {
  factory _$MeterAddResponseCopyWith(_MeterAddResponse value, $Res Function(_MeterAddResponse) _then) = __$MeterAddResponseCopyWithImpl;
@override @useResult
$Res call({
 MeterDetail meter, HistoryImportPublic history
});


@override $MeterDetailCopyWith<$Res> get meter;@override $HistoryImportPublicCopyWith<$Res> get history;

}
/// @nodoc
class __$MeterAddResponseCopyWithImpl<$Res>
    implements _$MeterAddResponseCopyWith<$Res> {
  __$MeterAddResponseCopyWithImpl(this._self, this._then);

  final _MeterAddResponse _self;
  final $Res Function(_MeterAddResponse) _then;

/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meter = null,Object? history = null,}) {
  return _then(_MeterAddResponse(
meter: null == meter ? _self.meter : meter // ignore: cast_nullable_to_non_nullable
as MeterDetail,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as HistoryImportPublic,
  ));
}

/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeterDetailCopyWith<$Res> get meter {
  
  return $MeterDetailCopyWith<$Res>(_self.meter, (value) {
    return _then(_self.copyWith(meter: value));
  });
}/// Create a copy of MeterAddResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HistoryImportPublicCopyWith<$Res> get history {
  
  return $HistoryImportPublicCopyWith<$Res>(_self.history, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}

// dart format on
