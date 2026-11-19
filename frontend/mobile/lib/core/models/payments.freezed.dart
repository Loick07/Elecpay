// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payments.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentPublic {

 int get id; String get reference; int get billId; String get billReference; String get billPeriodLabel; int? get householdId; String? get householdName; int get meterId; String get meterReference;/// Montant, en FCFA entiers (celui de la facture).
 int get amount; String get operator; String get operatorLabel;/// Numéro Mobile Money (masqué par l'API si ce n'est pas le mien).
 String get phoneNumber; int get payerId; String get payerName; bool get isMine; String get status; String get step; String? get failureReason; DateTime get initiatedAt; DateTime? get pinEnteredAt; DateTime? get confirmedAt; DateTime get expiresAt; int? get receiptId; String? get receiptNumber; String get source;
/// Create a copy of PaymentPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentPublicCopyWith<PaymentPublic> get copyWith => _$PaymentPublicCopyWithImpl<PaymentPublic>(this as PaymentPublic, _$identity);

  /// Serializes this PaymentPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.billId, _this.billId) || other.billId == _this.billId)&&(identical(other.billReference, _this.billReference) || other.billReference == _this.billReference)&&(identical(other.billPeriodLabel, _this.billPeriodLabel) || other.billPeriodLabel == _this.billPeriodLabel)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.householdName, _this.householdName) || other.householdName == _this.householdName)&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.meterReference, _this.meterReference) || other.meterReference == _this.meterReference)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.operator, _this.operator) || other.operator == _this.operator)&&(identical(other.operatorLabel, _this.operatorLabel) || other.operatorLabel == _this.operatorLabel)&&(identical(other.phoneNumber, _this.phoneNumber) || other.phoneNumber == _this.phoneNumber)&&(identical(other.payerId, _this.payerId) || other.payerId == _this.payerId)&&(identical(other.payerName, _this.payerName) || other.payerName == _this.payerName)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.failureReason, _this.failureReason) || other.failureReason == _this.failureReason)&&(identical(other.initiatedAt, _this.initiatedAt) || other.initiatedAt == _this.initiatedAt)&&(identical(other.pinEnteredAt, _this.pinEnteredAt) || other.pinEnteredAt == _this.pinEnteredAt)&&(identical(other.confirmedAt, _this.confirmedAt) || other.confirmedAt == _this.confirmedAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.receiptId, _this.receiptId) || other.receiptId == _this.receiptId)&&(identical(other.receiptNumber, _this.receiptNumber) || other.receiptNumber == _this.receiptNumber)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentPublic;
  return Object.hashAll([runtimeType,_this.id,_this.reference,_this.billId,_this.billReference,_this.billPeriodLabel,_this.householdId,_this.householdName,_this.meterId,_this.meterReference,_this.amount,_this.operator,_this.operatorLabel,_this.phoneNumber,_this.payerId,_this.payerName,_this.isMine,_this.status,_this.step,_this.failureReason,_this.initiatedAt,_this.pinEnteredAt,_this.confirmedAt,_this.expiresAt,_this.receiptId,_this.receiptNumber,_this.source]);
}

@override
String toString() {
  final _this = this as PaymentPublic;
  return 'PaymentPublic(id: ${_this.id}, reference: ${_this.reference}, billId: ${_this.billId}, billReference: ${_this.billReference}, billPeriodLabel: ${_this.billPeriodLabel}, householdId: ${_this.householdId}, householdName: ${_this.householdName}, meterId: ${_this.meterId}, meterReference: ${_this.meterReference}, amount: ${_this.amount}, operator: ${_this.operator}, operatorLabel: ${_this.operatorLabel}, phoneNumber: ${_this.phoneNumber}, payerId: ${_this.payerId}, payerName: ${_this.payerName}, isMine: ${_this.isMine}, status: ${_this.status}, step: ${_this.step}, failureReason: ${_this.failureReason}, initiatedAt: ${_this.initiatedAt}, pinEnteredAt: ${_this.pinEnteredAt}, confirmedAt: ${_this.confirmedAt}, expiresAt: ${_this.expiresAt}, receiptId: ${_this.receiptId}, receiptNumber: ${_this.receiptNumber}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $PaymentPublicCopyWith<$Res>  {
  factory $PaymentPublicCopyWith(PaymentPublic value, $Res Function(PaymentPublic) _then) = _$PaymentPublicCopyWithImpl;
@useResult
$Res call({
 int id, String reference, int billId, String billReference, String billPeriodLabel, int? householdId, String? householdName, int meterId, String meterReference, int amount, String operator, String operatorLabel, String phoneNumber, int payerId, String payerName, bool isMine, String status, String step, String? failureReason, DateTime initiatedAt, DateTime? pinEnteredAt, DateTime? confirmedAt, DateTime expiresAt, int? receiptId, String? receiptNumber, String source
});




}
/// @nodoc
class _$PaymentPublicCopyWithImpl<$Res>
    implements $PaymentPublicCopyWith<$Res> {
  _$PaymentPublicCopyWithImpl(this._self, this._then);

  final PaymentPublic _self;
  final $Res Function(PaymentPublic) _then;

/// Create a copy of PaymentPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? billId = null,Object? billReference = null,Object? billPeriodLabel = null,Object? householdId = freezed,Object? householdName = freezed,Object? meterId = null,Object? meterReference = null,Object? amount = null,Object? operator = null,Object? operatorLabel = null,Object? phoneNumber = null,Object? payerId = null,Object? payerName = null,Object? isMine = null,Object? status = null,Object? step = null,Object? failureReason = freezed,Object? initiatedAt = null,Object? pinEnteredAt = freezed,Object? confirmedAt = freezed,Object? expiresAt = null,Object? receiptId = freezed,Object? receiptNumber = freezed,Object? source = null,}) {
  return _then(PaymentPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,billReference: null == billReference ? _self.billReference : billReference // ignore: cast_nullable_to_non_nullable
as String,billPeriodLabel: null == billPeriodLabel ? _self.billPeriodLabel : billPeriodLabel // ignore: cast_nullable_to_non_nullable
as String,householdId: freezed == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int?,householdName: freezed == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String?,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,payerId: null == payerId ? _self.payerId : payerId // ignore: cast_nullable_to_non_nullable
as int,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,initiatedAt: null == initiatedAt ? _self.initiatedAt : initiatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pinEnteredAt: freezed == pinEnteredAt ? _self.pinEnteredAt : pinEnteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as int?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentPublic].
extension PaymentPublicPatterns on PaymentPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentPublic value)  $default,){
final _that = this;
switch (_that) {
case _PaymentPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentPublic value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String reference,  int billId,  String billReference,  String billPeriodLabel,  int? householdId,  String? householdName,  int meterId,  String meterReference,  int amount,  String operator,  String operatorLabel,  String phoneNumber,  int payerId,  String payerName,  bool isMine,  String status,  String step,  String? failureReason,  DateTime initiatedAt,  DateTime? pinEnteredAt,  DateTime? confirmedAt,  DateTime expiresAt,  int? receiptId,  String? receiptNumber,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentPublic() when $default != null:
return $default(_that.id,_that.reference,_that.billId,_that.billReference,_that.billPeriodLabel,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.amount,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.payerId,_that.payerName,_that.isMine,_that.status,_that.step,_that.failureReason,_that.initiatedAt,_that.pinEnteredAt,_that.confirmedAt,_that.expiresAt,_that.receiptId,_that.receiptNumber,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String reference,  int billId,  String billReference,  String billPeriodLabel,  int? householdId,  String? householdName,  int meterId,  String meterReference,  int amount,  String operator,  String operatorLabel,  String phoneNumber,  int payerId,  String payerName,  bool isMine,  String status,  String step,  String? failureReason,  DateTime initiatedAt,  DateTime? pinEnteredAt,  DateTime? confirmedAt,  DateTime expiresAt,  int? receiptId,  String? receiptNumber,  String source)  $default,) {final _that = this;
switch (_that) {
case _PaymentPublic():
return $default(_that.id,_that.reference,_that.billId,_that.billReference,_that.billPeriodLabel,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.amount,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.payerId,_that.payerName,_that.isMine,_that.status,_that.step,_that.failureReason,_that.initiatedAt,_that.pinEnteredAt,_that.confirmedAt,_that.expiresAt,_that.receiptId,_that.receiptNumber,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String reference,  int billId,  String billReference,  String billPeriodLabel,  int? householdId,  String? householdName,  int meterId,  String meterReference,  int amount,  String operator,  String operatorLabel,  String phoneNumber,  int payerId,  String payerName,  bool isMine,  String status,  String step,  String? failureReason,  DateTime initiatedAt,  DateTime? pinEnteredAt,  DateTime? confirmedAt,  DateTime expiresAt,  int? receiptId,  String? receiptNumber,  String source)?  $default,) {final _that = this;
switch (_that) {
case _PaymentPublic() when $default != null:
return $default(_that.id,_that.reference,_that.billId,_that.billReference,_that.billPeriodLabel,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.amount,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.payerId,_that.payerName,_that.isMine,_that.status,_that.step,_that.failureReason,_that.initiatedAt,_that.pinEnteredAt,_that.confirmedAt,_that.expiresAt,_that.receiptId,_that.receiptNumber,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentPublic implements PaymentPublic {
  const _PaymentPublic({required this.id, required this.reference, required this.billId, required this.billReference, required this.billPeriodLabel, required this.householdId, required this.householdName, required this.meterId, required this.meterReference, required this.amount, required this.operator, required this.operatorLabel, required this.phoneNumber, required this.payerId, required this.payerName, required this.isMine, required this.status, required this.step, required this.failureReason, required this.initiatedAt, required this.pinEnteredAt, required this.confirmedAt, required this.expiresAt, required this.receiptId, required this.receiptNumber, required this.source});
  factory _PaymentPublic.fromJson(Map<String, dynamic> json) => _$PaymentPublicFromJson(json);

@override final  int id;
@override final  String reference;
@override final  int billId;
@override final  String billReference;
@override final  String billPeriodLabel;
@override final  int? householdId;
@override final  String? householdName;
@override final  int meterId;
@override final  String meterReference;
/// Montant, en FCFA entiers (celui de la facture).
@override final  int amount;
@override final  String operator;
@override final  String operatorLabel;
/// Numéro Mobile Money (masqué par l'API si ce n'est pas le mien).
@override final  String phoneNumber;
@override final  int payerId;
@override final  String payerName;
@override final  bool isMine;
@override final  String status;
@override final  String step;
@override final  String? failureReason;
@override final  DateTime initiatedAt;
@override final  DateTime? pinEnteredAt;
@override final  DateTime? confirmedAt;
@override final  DateTime expiresAt;
@override final  int? receiptId;
@override final  String? receiptNumber;
@override final  String source;

/// Create a copy of PaymentPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentPublicCopyWith<_PaymentPublic> get copyWith => __$PaymentPublicCopyWithImpl<_PaymentPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.billReference, billReference) || other.billReference == billReference)&&(identical(other.billPeriodLabel, billPeriodLabel) || other.billPeriodLabel == billPeriodLabel)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.meterReference, meterReference) || other.meterReference == meterReference)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.operatorLabel, operatorLabel) || other.operatorLabel == operatorLabel)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.payerId, payerId) || other.payerId == payerId)&&(identical(other.payerName, payerName) || other.payerName == payerName)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.status, status) || other.status == status)&&(identical(other.step, step) || other.step == step)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.initiatedAt, initiatedAt) || other.initiatedAt == initiatedAt)&&(identical(other.pinEnteredAt, pinEnteredAt) || other.pinEnteredAt == pinEnteredAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,reference,billId,billReference,billPeriodLabel,householdId,householdName,meterId,meterReference,amount,operator,operatorLabel,phoneNumber,payerId,payerName,isMine,status,step,failureReason,initiatedAt,pinEnteredAt,confirmedAt,expiresAt,receiptId,receiptNumber,source]);
}

@override
String toString() {
    return 'PaymentPublic(id: $id, reference: $reference, billId: $billId, billReference: $billReference, billPeriodLabel: $billPeriodLabel, householdId: $householdId, householdName: $householdName, meterId: $meterId, meterReference: $meterReference, amount: $amount, operator: $operator, operatorLabel: $operatorLabel, phoneNumber: $phoneNumber, payerId: $payerId, payerName: $payerName, isMine: $isMine, status: $status, step: $step, failureReason: $failureReason, initiatedAt: $initiatedAt, pinEnteredAt: $pinEnteredAt, confirmedAt: $confirmedAt, expiresAt: $expiresAt, receiptId: $receiptId, receiptNumber: $receiptNumber, source: $source)';
}


}

/// @nodoc
abstract mixin class _$PaymentPublicCopyWith<$Res> implements $PaymentPublicCopyWith<$Res> {
  factory _$PaymentPublicCopyWith(_PaymentPublic value, $Res Function(_PaymentPublic) _then) = __$PaymentPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, String reference, int billId, String billReference, String billPeriodLabel, int? householdId, String? householdName, int meterId, String meterReference, int amount, String operator, String operatorLabel, String phoneNumber, int payerId, String payerName, bool isMine, String status, String step, String? failureReason, DateTime initiatedAt, DateTime? pinEnteredAt, DateTime? confirmedAt, DateTime expiresAt, int? receiptId, String? receiptNumber, String source
});




}
/// @nodoc
class __$PaymentPublicCopyWithImpl<$Res>
    implements _$PaymentPublicCopyWith<$Res> {
  __$PaymentPublicCopyWithImpl(this._self, this._then);

  final _PaymentPublic _self;
  final $Res Function(_PaymentPublic) _then;

/// Create a copy of PaymentPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? billId = null,Object? billReference = null,Object? billPeriodLabel = null,Object? householdId = freezed,Object? householdName = freezed,Object? meterId = null,Object? meterReference = null,Object? amount = null,Object? operator = null,Object? operatorLabel = null,Object? phoneNumber = null,Object? payerId = null,Object? payerName = null,Object? isMine = null,Object? status = null,Object? step = null,Object? failureReason = freezed,Object? initiatedAt = null,Object? pinEnteredAt = freezed,Object? confirmedAt = freezed,Object? expiresAt = null,Object? receiptId = freezed,Object? receiptNumber = freezed,Object? source = null,}) {
  return _then(_PaymentPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,billReference: null == billReference ? _self.billReference : billReference // ignore: cast_nullable_to_non_nullable
as String,billPeriodLabel: null == billPeriodLabel ? _self.billPeriodLabel : billPeriodLabel // ignore: cast_nullable_to_non_nullable
as String,householdId: freezed == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int?,householdName: freezed == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String?,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,payerId: null == payerId ? _self.payerId : payerId // ignore: cast_nullable_to_non_nullable
as int,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,initiatedAt: null == initiatedAt ? _self.initiatedAt : initiatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pinEnteredAt: freezed == pinEnteredAt ? _self.pinEnteredAt : pinEnteredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as int?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PaymentPage {

 List<PaymentPublic> get items; int get page; int get size; int get total;
/// Create a copy of PaymentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentPageCopyWith<PaymentPage> get copyWith => _$PaymentPageCopyWithImpl<PaymentPage>(this as PaymentPage, _$identity);

  /// Serializes this PaymentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.page,_this.size,_this.total);
}

@override
String toString() {
  final _this = this as PaymentPage;
  return 'PaymentPage(items: ${_this.items}, page: ${_this.page}, size: ${_this.size}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $PaymentPageCopyWith<$Res>  {
  factory $PaymentPageCopyWith(PaymentPage value, $Res Function(PaymentPage) _then) = _$PaymentPageCopyWithImpl;
@useResult
$Res call({
 List<PaymentPublic> items, int page, int size, int total
});




}
/// @nodoc
class _$PaymentPageCopyWithImpl<$Res>
    implements $PaymentPageCopyWith<$Res> {
  _$PaymentPageCopyWithImpl(this._self, this._then);

  final PaymentPage _self;
  final $Res Function(PaymentPage) _then;

/// Create a copy of PaymentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(PaymentPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PaymentPublic>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentPage].
extension PaymentPagePatterns on PaymentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentPage value)  $default,){
final _that = this;
switch (_that) {
case _PaymentPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentPage value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PaymentPublic> items,  int page,  int size,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PaymentPublic> items,  int page,  int size,  int total)  $default,) {final _that = this;
switch (_that) {
case _PaymentPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PaymentPublic> items,  int page,  int size,  int total)?  $default,) {final _that = this;
switch (_that) {
case _PaymentPage() when $default != null:
return $default(_that.items,_that.page,_that.size,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentPage implements PaymentPage {
  const _PaymentPage({required  List<PaymentPublic> items, required this.page, required this.size, required this.total}): _items = items;
  factory _PaymentPage.fromJson(Map<String, dynamic> json) => _$PaymentPageFromJson(json);

 final  List<PaymentPublic> _items;
@override List<PaymentPublic> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  int size;
@override final  int total;

/// Create a copy of PaymentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentPageCopyWith<_PaymentPage> get copyWith => __$PaymentPageCopyWithImpl<_PaymentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,size,total);
}

@override
String toString() {
    return 'PaymentPage(items: $items, page: $page, size: $size, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PaymentPageCopyWith<$Res> implements $PaymentPageCopyWith<$Res> {
  factory _$PaymentPageCopyWith(_PaymentPage value, $Res Function(_PaymentPage) _then) = __$PaymentPageCopyWithImpl;
@override @useResult
$Res call({
 List<PaymentPublic> items, int page, int size, int total
});




}
/// @nodoc
class __$PaymentPageCopyWithImpl<$Res>
    implements _$PaymentPageCopyWith<$Res> {
  __$PaymentPageCopyWithImpl(this._self, this._then);

  final _PaymentPage _self;
  final $Res Function(_PaymentPage) _then;

/// Create a copy of PaymentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(_PaymentPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PaymentPublic>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
