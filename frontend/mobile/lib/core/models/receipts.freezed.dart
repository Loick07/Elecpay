// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptPublic {

 int get id;/// « EP-2026-000123 ».
 String get number;/// Date du paiement confirmé (instant : affiché à l'heure de Brazzaville).
 DateTime get issuedAt;/// Montant payé, en FCFA entiers.
 int get amount;/// Déjà en groupes de 4 (« 8F3K-2Q9M-7XHT »).
 String get verificationCode; int get billId; String get billReference;/// Texte de l'API : jamais affiché (la période est construite à partir des dates ci-dessous).
 String get billPeriodLabel; DateTime get billPeriodStart; DateTime get billPeriodEnd; int get meterId; String get meterReference; int? get householdId; String? get householdName; int get payerId; String get payerName; bool get isMine; String get operator; String get operatorLabel;/// TOUJOURS masqué par l'API, même pour le payeur (un reçu est fait pour être partagé).
 String get phoneNumber; int get transactionId; String get transactionReference;/// `simulated` (mode démo) ou `e2c`.
 String get source;
/// Create a copy of ReceiptPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptPublicCopyWith<ReceiptPublic> get copyWith => _$ReceiptPublicCopyWithImpl<ReceiptPublic>(this as ReceiptPublic, _$identity);

  /// Serializes this ReceiptPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReceiptPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.issuedAt, _this.issuedAt) || other.issuedAt == _this.issuedAt)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.verificationCode, _this.verificationCode) || other.verificationCode == _this.verificationCode)&&(identical(other.billId, _this.billId) || other.billId == _this.billId)&&(identical(other.billReference, _this.billReference) || other.billReference == _this.billReference)&&(identical(other.billPeriodLabel, _this.billPeriodLabel) || other.billPeriodLabel == _this.billPeriodLabel)&&(identical(other.billPeriodStart, _this.billPeriodStart) || other.billPeriodStart == _this.billPeriodStart)&&(identical(other.billPeriodEnd, _this.billPeriodEnd) || other.billPeriodEnd == _this.billPeriodEnd)&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.meterReference, _this.meterReference) || other.meterReference == _this.meterReference)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.householdName, _this.householdName) || other.householdName == _this.householdName)&&(identical(other.payerId, _this.payerId) || other.payerId == _this.payerId)&&(identical(other.payerName, _this.payerName) || other.payerName == _this.payerName)&&(identical(other.isMine, _this.isMine) || other.isMine == _this.isMine)&&(identical(other.operator, _this.operator) || other.operator == _this.operator)&&(identical(other.operatorLabel, _this.operatorLabel) || other.operatorLabel == _this.operatorLabel)&&(identical(other.phoneNumber, _this.phoneNumber) || other.phoneNumber == _this.phoneNumber)&&(identical(other.transactionId, _this.transactionId) || other.transactionId == _this.transactionId)&&(identical(other.transactionReference, _this.transactionReference) || other.transactionReference == _this.transactionReference)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReceiptPublic;
  return Object.hashAll([runtimeType,_this.id,_this.number,_this.issuedAt,_this.amount,_this.verificationCode,_this.billId,_this.billReference,_this.billPeriodLabel,_this.billPeriodStart,_this.billPeriodEnd,_this.meterId,_this.meterReference,_this.householdId,_this.householdName,_this.payerId,_this.payerName,_this.isMine,_this.operator,_this.operatorLabel,_this.phoneNumber,_this.transactionId,_this.transactionReference,_this.source]);
}

@override
String toString() {
  final _this = this as ReceiptPublic;
  return 'ReceiptPublic(id: ${_this.id}, number: ${_this.number}, issuedAt: ${_this.issuedAt}, amount: ${_this.amount}, verificationCode: ${_this.verificationCode}, billId: ${_this.billId}, billReference: ${_this.billReference}, billPeriodLabel: ${_this.billPeriodLabel}, billPeriodStart: ${_this.billPeriodStart}, billPeriodEnd: ${_this.billPeriodEnd}, meterId: ${_this.meterId}, meterReference: ${_this.meterReference}, householdId: ${_this.householdId}, householdName: ${_this.householdName}, payerId: ${_this.payerId}, payerName: ${_this.payerName}, isMine: ${_this.isMine}, operator: ${_this.operator}, operatorLabel: ${_this.operatorLabel}, phoneNumber: ${_this.phoneNumber}, transactionId: ${_this.transactionId}, transactionReference: ${_this.transactionReference}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $ReceiptPublicCopyWith<$Res>  {
  factory $ReceiptPublicCopyWith(ReceiptPublic value, $Res Function(ReceiptPublic) _then) = _$ReceiptPublicCopyWithImpl;
@useResult
$Res call({
 int id, String number, DateTime issuedAt, int amount, String verificationCode, int billId, String billReference, String billPeriodLabel, DateTime billPeriodStart, DateTime billPeriodEnd, int meterId, String meterReference, int? householdId, String? householdName, int payerId, String payerName, bool isMine, String operator, String operatorLabel, String phoneNumber, int transactionId, String transactionReference, String source
});




}
/// @nodoc
class _$ReceiptPublicCopyWithImpl<$Res>
    implements $ReceiptPublicCopyWith<$Res> {
  _$ReceiptPublicCopyWithImpl(this._self, this._then);

  final ReceiptPublic _self;
  final $Res Function(ReceiptPublic) _then;

/// Create a copy of ReceiptPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? issuedAt = null,Object? amount = null,Object? verificationCode = null,Object? billId = null,Object? billReference = null,Object? billPeriodLabel = null,Object? billPeriodStart = null,Object? billPeriodEnd = null,Object? meterId = null,Object? meterReference = null,Object? householdId = freezed,Object? householdName = freezed,Object? payerId = null,Object? payerName = null,Object? isMine = null,Object? operator = null,Object? operatorLabel = null,Object? phoneNumber = null,Object? transactionId = null,Object? transactionReference = null,Object? source = null,}) {
  return _then(ReceiptPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,verificationCode: null == verificationCode ? _self.verificationCode : verificationCode // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,billReference: null == billReference ? _self.billReference : billReference // ignore: cast_nullable_to_non_nullable
as String,billPeriodLabel: null == billPeriodLabel ? _self.billPeriodLabel : billPeriodLabel // ignore: cast_nullable_to_non_nullable
as String,billPeriodStart: null == billPeriodStart ? _self.billPeriodStart : billPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,billPeriodEnd: null == billPeriodEnd ? _self.billPeriodEnd : billPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,householdId: freezed == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int?,householdName: freezed == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String?,payerId: null == payerId ? _self.payerId : payerId // ignore: cast_nullable_to_non_nullable
as int,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as int,transactionReference: null == transactionReference ? _self.transactionReference : transactionReference // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptPublic].
extension ReceiptPublicPatterns on ReceiptPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptPublic value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptPublic value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String number,  DateTime issuedAt,  int amount,  String verificationCode,  int billId,  String billReference,  String billPeriodLabel,  DateTime billPeriodStart,  DateTime billPeriodEnd,  int meterId,  String meterReference,  int? householdId,  String? householdName,  int payerId,  String payerName,  bool isMine,  String operator,  String operatorLabel,  String phoneNumber,  int transactionId,  String transactionReference,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptPublic() when $default != null:
return $default(_that.id,_that.number,_that.issuedAt,_that.amount,_that.verificationCode,_that.billId,_that.billReference,_that.billPeriodLabel,_that.billPeriodStart,_that.billPeriodEnd,_that.meterId,_that.meterReference,_that.householdId,_that.householdName,_that.payerId,_that.payerName,_that.isMine,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.transactionId,_that.transactionReference,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String number,  DateTime issuedAt,  int amount,  String verificationCode,  int billId,  String billReference,  String billPeriodLabel,  DateTime billPeriodStart,  DateTime billPeriodEnd,  int meterId,  String meterReference,  int? householdId,  String? householdName,  int payerId,  String payerName,  bool isMine,  String operator,  String operatorLabel,  String phoneNumber,  int transactionId,  String transactionReference,  String source)  $default,) {final _that = this;
switch (_that) {
case _ReceiptPublic():
return $default(_that.id,_that.number,_that.issuedAt,_that.amount,_that.verificationCode,_that.billId,_that.billReference,_that.billPeriodLabel,_that.billPeriodStart,_that.billPeriodEnd,_that.meterId,_that.meterReference,_that.householdId,_that.householdName,_that.payerId,_that.payerName,_that.isMine,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.transactionId,_that.transactionReference,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String number,  DateTime issuedAt,  int amount,  String verificationCode,  int billId,  String billReference,  String billPeriodLabel,  DateTime billPeriodStart,  DateTime billPeriodEnd,  int meterId,  String meterReference,  int? householdId,  String? householdName,  int payerId,  String payerName,  bool isMine,  String operator,  String operatorLabel,  String phoneNumber,  int transactionId,  String transactionReference,  String source)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptPublic() when $default != null:
return $default(_that.id,_that.number,_that.issuedAt,_that.amount,_that.verificationCode,_that.billId,_that.billReference,_that.billPeriodLabel,_that.billPeriodStart,_that.billPeriodEnd,_that.meterId,_that.meterReference,_that.householdId,_that.householdName,_that.payerId,_that.payerName,_that.isMine,_that.operator,_that.operatorLabel,_that.phoneNumber,_that.transactionId,_that.transactionReference,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptPublic implements ReceiptPublic {
  const _ReceiptPublic({required this.id, required this.number, required this.issuedAt, required this.amount, required this.verificationCode, required this.billId, required this.billReference, required this.billPeriodLabel, required this.billPeriodStart, required this.billPeriodEnd, required this.meterId, required this.meterReference, required this.householdId, required this.householdName, required this.payerId, required this.payerName, required this.isMine, required this.operator, required this.operatorLabel, required this.phoneNumber, required this.transactionId, required this.transactionReference, required this.source});
  factory _ReceiptPublic.fromJson(Map<String, dynamic> json) => _$ReceiptPublicFromJson(json);

@override final  int id;
/// « EP-2026-000123 ».
@override final  String number;
/// Date du paiement confirmé (instant : affiché à l'heure de Brazzaville).
@override final  DateTime issuedAt;
/// Montant payé, en FCFA entiers.
@override final  int amount;
/// Déjà en groupes de 4 (« 8F3K-2Q9M-7XHT »).
@override final  String verificationCode;
@override final  int billId;
@override final  String billReference;
/// Texte de l'API : jamais affiché (la période est construite à partir des dates ci-dessous).
@override final  String billPeriodLabel;
@override final  DateTime billPeriodStart;
@override final  DateTime billPeriodEnd;
@override final  int meterId;
@override final  String meterReference;
@override final  int? householdId;
@override final  String? householdName;
@override final  int payerId;
@override final  String payerName;
@override final  bool isMine;
@override final  String operator;
@override final  String operatorLabel;
/// TOUJOURS masqué par l'API, même pour le payeur (un reçu est fait pour être partagé).
@override final  String phoneNumber;
@override final  int transactionId;
@override final  String transactionReference;
/// `simulated` (mode démo) ou `e2c`.
@override final  String source;

/// Create a copy of ReceiptPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptPublicCopyWith<_ReceiptPublic> get copyWith => __$ReceiptPublicCopyWithImpl<_ReceiptPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.verificationCode, verificationCode) || other.verificationCode == verificationCode)&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.billReference, billReference) || other.billReference == billReference)&&(identical(other.billPeriodLabel, billPeriodLabel) || other.billPeriodLabel == billPeriodLabel)&&(identical(other.billPeriodStart, billPeriodStart) || other.billPeriodStart == billPeriodStart)&&(identical(other.billPeriodEnd, billPeriodEnd) || other.billPeriodEnd == billPeriodEnd)&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.meterReference, meterReference) || other.meterReference == meterReference)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.payerId, payerId) || other.payerId == payerId)&&(identical(other.payerName, payerName) || other.payerName == payerName)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.operatorLabel, operatorLabel) || other.operatorLabel == operatorLabel)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.transactionReference, transactionReference) || other.transactionReference == transactionReference)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,number,issuedAt,amount,verificationCode,billId,billReference,billPeriodLabel,billPeriodStart,billPeriodEnd,meterId,meterReference,householdId,householdName,payerId,payerName,isMine,operator,operatorLabel,phoneNumber,transactionId,transactionReference,source]);
}

@override
String toString() {
    return 'ReceiptPublic(id: $id, number: $number, issuedAt: $issuedAt, amount: $amount, verificationCode: $verificationCode, billId: $billId, billReference: $billReference, billPeriodLabel: $billPeriodLabel, billPeriodStart: $billPeriodStart, billPeriodEnd: $billPeriodEnd, meterId: $meterId, meterReference: $meterReference, householdId: $householdId, householdName: $householdName, payerId: $payerId, payerName: $payerName, isMine: $isMine, operator: $operator, operatorLabel: $operatorLabel, phoneNumber: $phoneNumber, transactionId: $transactionId, transactionReference: $transactionReference, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ReceiptPublicCopyWith<$Res> implements $ReceiptPublicCopyWith<$Res> {
  factory _$ReceiptPublicCopyWith(_ReceiptPublic value, $Res Function(_ReceiptPublic) _then) = __$ReceiptPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, String number, DateTime issuedAt, int amount, String verificationCode, int billId, String billReference, String billPeriodLabel, DateTime billPeriodStart, DateTime billPeriodEnd, int meterId, String meterReference, int? householdId, String? householdName, int payerId, String payerName, bool isMine, String operator, String operatorLabel, String phoneNumber, int transactionId, String transactionReference, String source
});




}
/// @nodoc
class __$ReceiptPublicCopyWithImpl<$Res>
    implements _$ReceiptPublicCopyWith<$Res> {
  __$ReceiptPublicCopyWithImpl(this._self, this._then);

  final _ReceiptPublic _self;
  final $Res Function(_ReceiptPublic) _then;

/// Create a copy of ReceiptPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? issuedAt = null,Object? amount = null,Object? verificationCode = null,Object? billId = null,Object? billReference = null,Object? billPeriodLabel = null,Object? billPeriodStart = null,Object? billPeriodEnd = null,Object? meterId = null,Object? meterReference = null,Object? householdId = freezed,Object? householdName = freezed,Object? payerId = null,Object? payerName = null,Object? isMine = null,Object? operator = null,Object? operatorLabel = null,Object? phoneNumber = null,Object? transactionId = null,Object? transactionReference = null,Object? source = null,}) {
  return _then(_ReceiptPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,verificationCode: null == verificationCode ? _self.verificationCode : verificationCode // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,billReference: null == billReference ? _self.billReference : billReference // ignore: cast_nullable_to_non_nullable
as String,billPeriodLabel: null == billPeriodLabel ? _self.billPeriodLabel : billPeriodLabel // ignore: cast_nullable_to_non_nullable
as String,billPeriodStart: null == billPeriodStart ? _self.billPeriodStart : billPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,billPeriodEnd: null == billPeriodEnd ? _self.billPeriodEnd : billPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,householdId: freezed == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int?,householdName: freezed == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String?,payerId: null == payerId ? _self.payerId : payerId // ignore: cast_nullable_to_non_nullable
as int,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,operatorLabel: null == operatorLabel ? _self.operatorLabel : operatorLabel // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as int,transactionReference: null == transactionReference ? _self.transactionReference : transactionReference // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
