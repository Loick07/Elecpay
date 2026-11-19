// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bills.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillSummary {

 int get id; String get reference; int get householdId; String get householdName; int get meterId; String get meterReference; String? get meterLabel; String get myRole; DateTime get periodStart; DateTime get periodEnd; String get periodLabel; int get monthsCount; int get consumptionWh; double get consumptionKwh;/// Montant TTC, en FCFA entiers.
 int get amountTotal; DateTime get issuedAt; DateTime get dueDate; String get status; int get daysOverdue; DateTime? get paidAt;/// Le bouton « Payer » n'apparaît que si c'est vrai (rôle, statut, paiement en cours).
 bool get canPay;/// `simulated` (mode démo) ou `e2c`.
 String get source;
/// Create a copy of BillSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillSummaryCopyWith<BillSummary> get copyWith => _$BillSummaryCopyWithImpl<BillSummary>(this as BillSummary, _$identity);

  /// Serializes this BillSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.householdName, _this.householdName) || other.householdName == _this.householdName)&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.meterReference, _this.meterReference) || other.meterReference == _this.meterReference)&&(identical(other.meterLabel, _this.meterLabel) || other.meterLabel == _this.meterLabel)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.periodStart, _this.periodStart) || other.periodStart == _this.periodStart)&&(identical(other.periodEnd, _this.periodEnd) || other.periodEnd == _this.periodEnd)&&(identical(other.periodLabel, _this.periodLabel) || other.periodLabel == _this.periodLabel)&&(identical(other.monthsCount, _this.monthsCount) || other.monthsCount == _this.monthsCount)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.amountTotal, _this.amountTotal) || other.amountTotal == _this.amountTotal)&&(identical(other.issuedAt, _this.issuedAt) || other.issuedAt == _this.issuedAt)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.daysOverdue, _this.daysOverdue) || other.daysOverdue == _this.daysOverdue)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.canPay, _this.canPay) || other.canPay == _this.canPay)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillSummary;
  return Object.hashAll([runtimeType,_this.id,_this.reference,_this.householdId,_this.householdName,_this.meterId,_this.meterReference,_this.meterLabel,_this.myRole,_this.periodStart,_this.periodEnd,_this.periodLabel,_this.monthsCount,_this.consumptionWh,_this.consumptionKwh,_this.amountTotal,_this.issuedAt,_this.dueDate,_this.status,_this.daysOverdue,_this.paidAt,_this.canPay,_this.source]);
}

@override
String toString() {
  final _this = this as BillSummary;
  return 'BillSummary(id: ${_this.id}, reference: ${_this.reference}, householdId: ${_this.householdId}, householdName: ${_this.householdName}, meterId: ${_this.meterId}, meterReference: ${_this.meterReference}, meterLabel: ${_this.meterLabel}, myRole: ${_this.myRole}, periodStart: ${_this.periodStart}, periodEnd: ${_this.periodEnd}, periodLabel: ${_this.periodLabel}, monthsCount: ${_this.monthsCount}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, amountTotal: ${_this.amountTotal}, issuedAt: ${_this.issuedAt}, dueDate: ${_this.dueDate}, status: ${_this.status}, daysOverdue: ${_this.daysOverdue}, paidAt: ${_this.paidAt}, canPay: ${_this.canPay}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $BillSummaryCopyWith<$Res>  {
  factory $BillSummaryCopyWith(BillSummary value, $Res Function(BillSummary) _then) = _$BillSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String reference, int householdId, String householdName, int meterId, String meterReference, String? meterLabel, String myRole, DateTime periodStart, DateTime periodEnd, String periodLabel, int monthsCount, int consumptionWh, double consumptionKwh, int amountTotal, DateTime issuedAt, DateTime dueDate, String status, int daysOverdue, DateTime? paidAt, bool canPay, String source
});




}
/// @nodoc
class _$BillSummaryCopyWithImpl<$Res>
    implements $BillSummaryCopyWith<$Res> {
  _$BillSummaryCopyWithImpl(this._self, this._then);

  final BillSummary _self;
  final $Res Function(BillSummary) _then;

/// Create a copy of BillSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? householdId = null,Object? householdName = null,Object? meterId = null,Object? meterReference = null,Object? meterLabel = freezed,Object? myRole = null,Object? periodStart = null,Object? periodEnd = null,Object? periodLabel = null,Object? monthsCount = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? issuedAt = null,Object? dueDate = null,Object? status = null,Object? daysOverdue = null,Object? paidAt = freezed,Object? canPay = null,Object? source = null,}) {
  return _then(BillSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,meterLabel: freezed == meterLabel ? _self.meterLabel : meterLabel // ignore: cast_nullable_to_non_nullable
as String?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,monthsCount: null == monthsCount ? _self.monthsCount : monthsCount // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BillSummary].
extension BillSummaryPatterns on BillSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillSummary value)  $default,){
final _that = this;
switch (_that) {
case _BillSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillSummary value)?  $default,){
final _that = this;
switch (_that) {
case _BillSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String reference,  int householdId,  String householdName,  int meterId,  String meterReference,  String? meterLabel,  String myRole,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  bool canPay,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillSummary() when $default != null:
return $default(_that.id,_that.reference,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.meterLabel,_that.myRole,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.canPay,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String reference,  int householdId,  String householdName,  int meterId,  String meterReference,  String? meterLabel,  String myRole,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  bool canPay,  String source)  $default,) {final _that = this;
switch (_that) {
case _BillSummary():
return $default(_that.id,_that.reference,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.meterLabel,_that.myRole,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.canPay,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String reference,  int householdId,  String householdName,  int meterId,  String meterReference,  String? meterLabel,  String myRole,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  bool canPay,  String source)?  $default,) {final _that = this;
switch (_that) {
case _BillSummary() when $default != null:
return $default(_that.id,_that.reference,_that.householdId,_that.householdName,_that.meterId,_that.meterReference,_that.meterLabel,_that.myRole,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.canPay,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillSummary implements BillSummary {
  const _BillSummary({required this.id, required this.reference, required this.householdId, required this.householdName, required this.meterId, required this.meterReference, required this.meterLabel, required this.myRole, required this.periodStart, required this.periodEnd, required this.periodLabel, required this.monthsCount, required this.consumptionWh, required this.consumptionKwh, required this.amountTotal, required this.issuedAt, required this.dueDate, required this.status, required this.daysOverdue, required this.paidAt, required this.canPay, required this.source});
  factory _BillSummary.fromJson(Map<String, dynamic> json) => _$BillSummaryFromJson(json);

@override final  int id;
@override final  String reference;
@override final  int householdId;
@override final  String householdName;
@override final  int meterId;
@override final  String meterReference;
@override final  String? meterLabel;
@override final  String myRole;
@override final  DateTime periodStart;
@override final  DateTime periodEnd;
@override final  String periodLabel;
@override final  int monthsCount;
@override final  int consumptionWh;
@override final  double consumptionKwh;
/// Montant TTC, en FCFA entiers.
@override final  int amountTotal;
@override final  DateTime issuedAt;
@override final  DateTime dueDate;
@override final  String status;
@override final  int daysOverdue;
@override final  DateTime? paidAt;
/// Le bouton « Payer » n'apparaît que si c'est vrai (rôle, statut, paiement en cours).
@override final  bool canPay;
/// `simulated` (mode démo) ou `e2c`.
@override final  String source;

/// Create a copy of BillSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillSummaryCopyWith<_BillSummary> get copyWith => __$BillSummaryCopyWithImpl<_BillSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.meterReference, meterReference) || other.meterReference == meterReference)&&(identical(other.meterLabel, meterLabel) || other.meterLabel == meterLabel)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.periodLabel, periodLabel) || other.periodLabel == periodLabel)&&(identical(other.monthsCount, monthsCount) || other.monthsCount == monthsCount)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.amountTotal, amountTotal) || other.amountTotal == amountTotal)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,reference,householdId,householdName,meterId,meterReference,meterLabel,myRole,periodStart,periodEnd,periodLabel,monthsCount,consumptionWh,consumptionKwh,amountTotal,issuedAt,dueDate,status,daysOverdue,paidAt,canPay,source]);
}

@override
String toString() {
    return 'BillSummary(id: $id, reference: $reference, householdId: $householdId, householdName: $householdName, meterId: $meterId, meterReference: $meterReference, meterLabel: $meterLabel, myRole: $myRole, periodStart: $periodStart, periodEnd: $periodEnd, periodLabel: $periodLabel, monthsCount: $monthsCount, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, amountTotal: $amountTotal, issuedAt: $issuedAt, dueDate: $dueDate, status: $status, daysOverdue: $daysOverdue, paidAt: $paidAt, canPay: $canPay, source: $source)';
}


}

/// @nodoc
abstract mixin class _$BillSummaryCopyWith<$Res> implements $BillSummaryCopyWith<$Res> {
  factory _$BillSummaryCopyWith(_BillSummary value, $Res Function(_BillSummary) _then) = __$BillSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String reference, int householdId, String householdName, int meterId, String meterReference, String? meterLabel, String myRole, DateTime periodStart, DateTime periodEnd, String periodLabel, int monthsCount, int consumptionWh, double consumptionKwh, int amountTotal, DateTime issuedAt, DateTime dueDate, String status, int daysOverdue, DateTime? paidAt, bool canPay, String source
});




}
/// @nodoc
class __$BillSummaryCopyWithImpl<$Res>
    implements _$BillSummaryCopyWith<$Res> {
  __$BillSummaryCopyWithImpl(this._self, this._then);

  final _BillSummary _self;
  final $Res Function(_BillSummary) _then;

/// Create a copy of BillSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? householdId = null,Object? householdName = null,Object? meterId = null,Object? meterReference = null,Object? meterLabel = freezed,Object? myRole = null,Object? periodStart = null,Object? periodEnd = null,Object? periodLabel = null,Object? monthsCount = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? issuedAt = null,Object? dueDate = null,Object? status = null,Object? daysOverdue = null,Object? paidAt = freezed,Object? canPay = null,Object? source = null,}) {
  return _then(_BillSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,meterLabel: freezed == meterLabel ? _self.meterLabel : meterLabel // ignore: cast_nullable_to_non_nullable
as String?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,monthsCount: null == monthsCount ? _self.monthsCount : monthsCount // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Outstanding {

 int get amount; int get count; int get overdueAmount; int get overdueCount;
/// Create a copy of Outstanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutstandingCopyWith<Outstanding> get copyWith => _$OutstandingCopyWithImpl<Outstanding>(this as Outstanding, _$identity);

  /// Serializes this Outstanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Outstanding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Outstanding&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.overdueAmount, _this.overdueAmount) || other.overdueAmount == _this.overdueAmount)&&(identical(other.overdueCount, _this.overdueCount) || other.overdueCount == _this.overdueCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Outstanding;
  return Object.hash(runtimeType,_this.amount,_this.count,_this.overdueAmount,_this.overdueCount);
}

@override
String toString() {
  final _this = this as Outstanding;
  return 'Outstanding(amount: ${_this.amount}, count: ${_this.count}, overdueAmount: ${_this.overdueAmount}, overdueCount: ${_this.overdueCount})';
}


}

/// @nodoc
abstract mixin class $OutstandingCopyWith<$Res>  {
  factory $OutstandingCopyWith(Outstanding value, $Res Function(Outstanding) _then) = _$OutstandingCopyWithImpl;
@useResult
$Res call({
 int amount, int count, int overdueAmount, int overdueCount
});




}
/// @nodoc
class _$OutstandingCopyWithImpl<$Res>
    implements $OutstandingCopyWith<$Res> {
  _$OutstandingCopyWithImpl(this._self, this._then);

  final Outstanding _self;
  final $Res Function(Outstanding) _then;

/// Create a copy of Outstanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? count = null,Object? overdueAmount = null,Object? overdueCount = null,}) {
  return _then(Outstanding(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as int,overdueCount: null == overdueCount ? _self.overdueCount : overdueCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Outstanding].
extension OutstandingPatterns on Outstanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Outstanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Outstanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Outstanding value)  $default,){
final _that = this;
switch (_that) {
case _Outstanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Outstanding value)?  $default,){
final _that = this;
switch (_that) {
case _Outstanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amount,  int count,  int overdueAmount,  int overdueCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Outstanding() when $default != null:
return $default(_that.amount,_that.count,_that.overdueAmount,_that.overdueCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amount,  int count,  int overdueAmount,  int overdueCount)  $default,) {final _that = this;
switch (_that) {
case _Outstanding():
return $default(_that.amount,_that.count,_that.overdueAmount,_that.overdueCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amount,  int count,  int overdueAmount,  int overdueCount)?  $default,) {final _that = this;
switch (_that) {
case _Outstanding() when $default != null:
return $default(_that.amount,_that.count,_that.overdueAmount,_that.overdueCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Outstanding implements Outstanding {
  const _Outstanding({required this.amount, required this.count, required this.overdueAmount, required this.overdueCount});
  factory _Outstanding.fromJson(Map<String, dynamic> json) => _$OutstandingFromJson(json);

@override final  int amount;
@override final  int count;
@override final  int overdueAmount;
@override final  int overdueCount;

/// Create a copy of Outstanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutstandingCopyWith<_Outstanding> get copyWith => __$OutstandingCopyWithImpl<_Outstanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutstandingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Outstanding&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.count, count) || other.count == count)&&(identical(other.overdueAmount, overdueAmount) || other.overdueAmount == overdueAmount)&&(identical(other.overdueCount, overdueCount) || other.overdueCount == overdueCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,count,overdueAmount,overdueCount);
}

@override
String toString() {
    return 'Outstanding(amount: $amount, count: $count, overdueAmount: $overdueAmount, overdueCount: $overdueCount)';
}


}

/// @nodoc
abstract mixin class _$OutstandingCopyWith<$Res> implements $OutstandingCopyWith<$Res> {
  factory _$OutstandingCopyWith(_Outstanding value, $Res Function(_Outstanding) _then) = __$OutstandingCopyWithImpl;
@override @useResult
$Res call({
 int amount, int count, int overdueAmount, int overdueCount
});




}
/// @nodoc
class __$OutstandingCopyWithImpl<$Res>
    implements _$OutstandingCopyWith<$Res> {
  __$OutstandingCopyWithImpl(this._self, this._then);

  final _Outstanding _self;
  final $Res Function(_Outstanding) _then;

/// Create a copy of Outstanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? count = null,Object? overdueAmount = null,Object? overdueCount = null,}) {
  return _then(_Outstanding(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as int,overdueCount: null == overdueCount ? _self.overdueCount : overdueCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BillList {

 List<BillSummary> get items; Outstanding get outstanding; int get page; int get size; int get total;
/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillListCopyWith<BillList> get copyWith => _$BillListCopyWithImpl<BillList>(this as BillList, _$identity);

  /// Serializes this BillList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillList&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.outstanding, _this.outstanding) || other.outstanding == _this.outstanding)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillList;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.outstanding,_this.page,_this.size,_this.total);
}

@override
String toString() {
  final _this = this as BillList;
  return 'BillList(items: ${_this.items}, outstanding: ${_this.outstanding}, page: ${_this.page}, size: ${_this.size}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $BillListCopyWith<$Res>  {
  factory $BillListCopyWith(BillList value, $Res Function(BillList) _then) = _$BillListCopyWithImpl;
@useResult
$Res call({
 List<BillSummary> items, Outstanding outstanding, int page, int size, int total
});


$OutstandingCopyWith<$Res> get outstanding;

}
/// @nodoc
class _$BillListCopyWithImpl<$Res>
    implements $BillListCopyWith<$Res> {
  _$BillListCopyWithImpl(this._self, this._then);

  final BillList _self;
  final $Res Function(BillList) _then;

/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? outstanding = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(BillList(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BillSummary>,outstanding: null == outstanding ? _self.outstanding : outstanding // ignore: cast_nullable_to_non_nullable
as Outstanding,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutstandingCopyWith<$Res> get outstanding {
  
  return $OutstandingCopyWith<$Res>(_self.outstanding, (value) {
    return _then(_self.copyWith(outstanding: value));
  });
}
}


/// Adds pattern-matching-related methods to [BillList].
extension BillListPatterns on BillList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillList value)  $default,){
final _that = this;
switch (_that) {
case _BillList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillList value)?  $default,){
final _that = this;
switch (_that) {
case _BillList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BillSummary> items,  Outstanding outstanding,  int page,  int size,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillList() when $default != null:
return $default(_that.items,_that.outstanding,_that.page,_that.size,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BillSummary> items,  Outstanding outstanding,  int page,  int size,  int total)  $default,) {final _that = this;
switch (_that) {
case _BillList():
return $default(_that.items,_that.outstanding,_that.page,_that.size,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BillSummary> items,  Outstanding outstanding,  int page,  int size,  int total)?  $default,) {final _that = this;
switch (_that) {
case _BillList() when $default != null:
return $default(_that.items,_that.outstanding,_that.page,_that.size,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillList implements BillList {
  const _BillList({required  List<BillSummary> items, required this.outstanding, required this.page, required this.size, required this.total}): _items = items;
  factory _BillList.fromJson(Map<String, dynamic> json) => _$BillListFromJson(json);

 final  List<BillSummary> _items;
@override List<BillSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  Outstanding outstanding;
@override final  int page;
@override final  int size;
@override final  int total;

/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillListCopyWith<_BillList> get copyWith => __$BillListCopyWithImpl<_BillList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillList&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.outstanding, outstanding) || other.outstanding == outstanding)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),outstanding,page,size,total);
}

@override
String toString() {
    return 'BillList(items: $items, outstanding: $outstanding, page: $page, size: $size, total: $total)';
}


}

/// @nodoc
abstract mixin class _$BillListCopyWith<$Res> implements $BillListCopyWith<$Res> {
  factory _$BillListCopyWith(_BillList value, $Res Function(_BillList) _then) = __$BillListCopyWithImpl;
@override @useResult
$Res call({
 List<BillSummary> items, Outstanding outstanding, int page, int size, int total
});


@override $OutstandingCopyWith<$Res> get outstanding;

}
/// @nodoc
class __$BillListCopyWithImpl<$Res>
    implements _$BillListCopyWith<$Res> {
  __$BillListCopyWithImpl(this._self, this._then);

  final _BillList _self;
  final $Res Function(_BillList) _then;

/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? outstanding = null,Object? page = null,Object? size = null,Object? total = null,}) {
  return _then(_BillList(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BillSummary>,outstanding: null == outstanding ? _self.outstanding : outstanding // ignore: cast_nullable_to_non_nullable
as Outstanding,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of BillList
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutstandingCopyWith<$Res> get outstanding {
  
  return $OutstandingCopyWith<$Res>(_self.outstanding, (value) {
    return _then(_self.copyWith(outstanding: value));
  });
}
}


/// @nodoc
mixin _$BillLinePublic {

 int get position; String get kind; String get label; int? get quantityMilli; double? get quantity; String? get unit; int? get unitPriceMilli; double? get unitPrice; int? get rateBp; double? get ratePercent; int? get baseAmount; int get amount;
/// Create a copy of BillLinePublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillLinePublicCopyWith<BillLinePublic> get copyWith => _$BillLinePublicCopyWithImpl<BillLinePublic>(this as BillLinePublic, _$identity);

  /// Serializes this BillLinePublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillLinePublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillLinePublic&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.quantityMilli, _this.quantityMilli) || other.quantityMilli == _this.quantityMilli)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.unitPriceMilli, _this.unitPriceMilli) || other.unitPriceMilli == _this.unitPriceMilli)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice)&&(identical(other.rateBp, _this.rateBp) || other.rateBp == _this.rateBp)&&(identical(other.ratePercent, _this.ratePercent) || other.ratePercent == _this.ratePercent)&&(identical(other.baseAmount, _this.baseAmount) || other.baseAmount == _this.baseAmount)&&(identical(other.amount, _this.amount) || other.amount == _this.amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillLinePublic;
  return Object.hash(runtimeType,_this.position,_this.kind,_this.label,_this.quantityMilli,_this.quantity,_this.unit,_this.unitPriceMilli,_this.unitPrice,_this.rateBp,_this.ratePercent,_this.baseAmount,_this.amount);
}

@override
String toString() {
  final _this = this as BillLinePublic;
  return 'BillLinePublic(position: ${_this.position}, kind: ${_this.kind}, label: ${_this.label}, quantityMilli: ${_this.quantityMilli}, quantity: ${_this.quantity}, unit: ${_this.unit}, unitPriceMilli: ${_this.unitPriceMilli}, unitPrice: ${_this.unitPrice}, rateBp: ${_this.rateBp}, ratePercent: ${_this.ratePercent}, baseAmount: ${_this.baseAmount}, amount: ${_this.amount})';
}


}

/// @nodoc
abstract mixin class $BillLinePublicCopyWith<$Res>  {
  factory $BillLinePublicCopyWith(BillLinePublic value, $Res Function(BillLinePublic) _then) = _$BillLinePublicCopyWithImpl;
@useResult
$Res call({
 int position, String kind, String label, int? quantityMilli, double? quantity, String? unit, int? unitPriceMilli, double? unitPrice, int? rateBp, double? ratePercent, int? baseAmount, int amount
});




}
/// @nodoc
class _$BillLinePublicCopyWithImpl<$Res>
    implements $BillLinePublicCopyWith<$Res> {
  _$BillLinePublicCopyWithImpl(this._self, this._then);

  final BillLinePublic _self;
  final $Res Function(BillLinePublic) _then;

/// Create a copy of BillLinePublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? kind = null,Object? label = null,Object? quantityMilli = freezed,Object? quantity = freezed,Object? unit = freezed,Object? unitPriceMilli = freezed,Object? unitPrice = freezed,Object? rateBp = freezed,Object? ratePercent = freezed,Object? baseAmount = freezed,Object? amount = null,}) {
  return _then(BillLinePublic(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,quantityMilli: freezed == quantityMilli ? _self.quantityMilli : quantityMilli // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitPriceMilli: freezed == unitPriceMilli ? _self.unitPriceMilli : unitPriceMilli // ignore: cast_nullable_to_non_nullable
as int?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,rateBp: freezed == rateBp ? _self.rateBp : rateBp // ignore: cast_nullable_to_non_nullable
as int?,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,baseAmount: freezed == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as int?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BillLinePublic].
extension BillLinePublicPatterns on BillLinePublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillLinePublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillLinePublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillLinePublic value)  $default,){
final _that = this;
switch (_that) {
case _BillLinePublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillLinePublic value)?  $default,){
final _that = this;
switch (_that) {
case _BillLinePublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  String kind,  String label,  int? quantityMilli,  double? quantity,  String? unit,  int? unitPriceMilli,  double? unitPrice,  int? rateBp,  double? ratePercent,  int? baseAmount,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillLinePublic() when $default != null:
return $default(_that.position,_that.kind,_that.label,_that.quantityMilli,_that.quantity,_that.unit,_that.unitPriceMilli,_that.unitPrice,_that.rateBp,_that.ratePercent,_that.baseAmount,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  String kind,  String label,  int? quantityMilli,  double? quantity,  String? unit,  int? unitPriceMilli,  double? unitPrice,  int? rateBp,  double? ratePercent,  int? baseAmount,  int amount)  $default,) {final _that = this;
switch (_that) {
case _BillLinePublic():
return $default(_that.position,_that.kind,_that.label,_that.quantityMilli,_that.quantity,_that.unit,_that.unitPriceMilli,_that.unitPrice,_that.rateBp,_that.ratePercent,_that.baseAmount,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  String kind,  String label,  int? quantityMilli,  double? quantity,  String? unit,  int? unitPriceMilli,  double? unitPrice,  int? rateBp,  double? ratePercent,  int? baseAmount,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _BillLinePublic() when $default != null:
return $default(_that.position,_that.kind,_that.label,_that.quantityMilli,_that.quantity,_that.unit,_that.unitPriceMilli,_that.unitPrice,_that.rateBp,_that.ratePercent,_that.baseAmount,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillLinePublic implements BillLinePublic {
  const _BillLinePublic({required this.position, required this.kind, required this.label, required this.quantityMilli, required this.quantity, required this.unit, required this.unitPriceMilli, required this.unitPrice, required this.rateBp, required this.ratePercent, required this.baseAmount, required this.amount});
  factory _BillLinePublic.fromJson(Map<String, dynamic> json) => _$BillLinePublicFromJson(json);

@override final  int position;
@override final  String kind;
@override final  String label;
@override final  int? quantityMilli;
@override final  double? quantity;
@override final  String? unit;
@override final  int? unitPriceMilli;
@override final  double? unitPrice;
@override final  int? rateBp;
@override final  double? ratePercent;
@override final  int? baseAmount;
@override final  int amount;

/// Create a copy of BillLinePublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillLinePublicCopyWith<_BillLinePublic> get copyWith => __$BillLinePublicCopyWithImpl<_BillLinePublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillLinePublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillLinePublic&&(identical(other.position, position) || other.position == position)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.quantityMilli, quantityMilli) || other.quantityMilli == quantityMilli)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitPriceMilli, unitPriceMilli) || other.unitPriceMilli == unitPriceMilli)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.rateBp, rateBp) || other.rateBp == rateBp)&&(identical(other.ratePercent, ratePercent) || other.ratePercent == ratePercent)&&(identical(other.baseAmount, baseAmount) || other.baseAmount == baseAmount)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,position,kind,label,quantityMilli,quantity,unit,unitPriceMilli,unitPrice,rateBp,ratePercent,baseAmount,amount);
}

@override
String toString() {
    return 'BillLinePublic(position: $position, kind: $kind, label: $label, quantityMilli: $quantityMilli, quantity: $quantity, unit: $unit, unitPriceMilli: $unitPriceMilli, unitPrice: $unitPrice, rateBp: $rateBp, ratePercent: $ratePercent, baseAmount: $baseAmount, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$BillLinePublicCopyWith<$Res> implements $BillLinePublicCopyWith<$Res> {
  factory _$BillLinePublicCopyWith(_BillLinePublic value, $Res Function(_BillLinePublic) _then) = __$BillLinePublicCopyWithImpl;
@override @useResult
$Res call({
 int position, String kind, String label, int? quantityMilli, double? quantity, String? unit, int? unitPriceMilli, double? unitPrice, int? rateBp, double? ratePercent, int? baseAmount, int amount
});




}
/// @nodoc
class __$BillLinePublicCopyWithImpl<$Res>
    implements _$BillLinePublicCopyWith<$Res> {
  __$BillLinePublicCopyWithImpl(this._self, this._then);

  final _BillLinePublic _self;
  final $Res Function(_BillLinePublic) _then;

/// Create a copy of BillLinePublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? kind = null,Object? label = null,Object? quantityMilli = freezed,Object? quantity = freezed,Object? unit = freezed,Object? unitPriceMilli = freezed,Object? unitPrice = freezed,Object? rateBp = freezed,Object? ratePercent = freezed,Object? baseAmount = freezed,Object? amount = null,}) {
  return _then(_BillLinePublic(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,quantityMilli: freezed == quantityMilli ? _self.quantityMilli : quantityMilli // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitPriceMilli: freezed == unitPriceMilli ? _self.unitPriceMilli : unitPriceMilli // ignore: cast_nullable_to_non_nullable
as int?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,rateBp: freezed == rateBp ? _self.rateBp : rateBp // ignore: cast_nullable_to_non_nullable
as int?,ratePercent: freezed == ratePercent ? _self.ratePercent : ratePercent // ignore: cast_nullable_to_non_nullable
as double?,baseAmount: freezed == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as int?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TariffPublic {

 int get id; String get code; String get label; int get pricePerKwhMilli; bool get isAssumption;
/// Create a copy of TariffPublic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TariffPublicCopyWith<TariffPublic> get copyWith => _$TariffPublicCopyWithImpl<TariffPublic>(this as TariffPublic, _$identity);

  /// Serializes this TariffPublic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TariffPublic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TariffPublic&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.pricePerKwhMilli, _this.pricePerKwhMilli) || other.pricePerKwhMilli == _this.pricePerKwhMilli)&&(identical(other.isAssumption, _this.isAssumption) || other.isAssumption == _this.isAssumption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TariffPublic;
  return Object.hash(runtimeType,_this.id,_this.code,_this.label,_this.pricePerKwhMilli,_this.isAssumption);
}

@override
String toString() {
  final _this = this as TariffPublic;
  return 'TariffPublic(id: ${_this.id}, code: ${_this.code}, label: ${_this.label}, pricePerKwhMilli: ${_this.pricePerKwhMilli}, isAssumption: ${_this.isAssumption})';
}


}

/// @nodoc
abstract mixin class $TariffPublicCopyWith<$Res>  {
  factory $TariffPublicCopyWith(TariffPublic value, $Res Function(TariffPublic) _then) = _$TariffPublicCopyWithImpl;
@useResult
$Res call({
 int id, String code, String label, int pricePerKwhMilli, bool isAssumption
});




}
/// @nodoc
class _$TariffPublicCopyWithImpl<$Res>
    implements $TariffPublicCopyWith<$Res> {
  _$TariffPublicCopyWithImpl(this._self, this._then);

  final TariffPublic _self;
  final $Res Function(TariffPublic) _then;

/// Create a copy of TariffPublic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? label = null,Object? pricePerKwhMilli = null,Object? isAssumption = null,}) {
  return _then(TariffPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pricePerKwhMilli: null == pricePerKwhMilli ? _self.pricePerKwhMilli : pricePerKwhMilli // ignore: cast_nullable_to_non_nullable
as int,isAssumption: null == isAssumption ? _self.isAssumption : isAssumption // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TariffPublic].
extension TariffPublicPatterns on TariffPublic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TariffPublic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TariffPublic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TariffPublic value)  $default,){
final _that = this;
switch (_that) {
case _TariffPublic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TariffPublic value)?  $default,){
final _that = this;
switch (_that) {
case _TariffPublic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String label,  int pricePerKwhMilli,  bool isAssumption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TariffPublic() when $default != null:
return $default(_that.id,_that.code,_that.label,_that.pricePerKwhMilli,_that.isAssumption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String label,  int pricePerKwhMilli,  bool isAssumption)  $default,) {final _that = this;
switch (_that) {
case _TariffPublic():
return $default(_that.id,_that.code,_that.label,_that.pricePerKwhMilli,_that.isAssumption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String label,  int pricePerKwhMilli,  bool isAssumption)?  $default,) {final _that = this;
switch (_that) {
case _TariffPublic() when $default != null:
return $default(_that.id,_that.code,_that.label,_that.pricePerKwhMilli,_that.isAssumption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TariffPublic implements TariffPublic {
  const _TariffPublic({required this.id, required this.code, required this.label, required this.pricePerKwhMilli, required this.isAssumption});
  factory _TariffPublic.fromJson(Map<String, dynamic> json) => _$TariffPublicFromJson(json);

@override final  int id;
@override final  String code;
@override final  String label;
@override final  int pricePerKwhMilli;
@override final  bool isAssumption;

/// Create a copy of TariffPublic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TariffPublicCopyWith<_TariffPublic> get copyWith => __$TariffPublicCopyWithImpl<_TariffPublic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TariffPublicToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TariffPublic&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.pricePerKwhMilli, pricePerKwhMilli) || other.pricePerKwhMilli == pricePerKwhMilli)&&(identical(other.isAssumption, isAssumption) || other.isAssumption == isAssumption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,label,pricePerKwhMilli,isAssumption);
}

@override
String toString() {
    return 'TariffPublic(id: $id, code: $code, label: $label, pricePerKwhMilli: $pricePerKwhMilli, isAssumption: $isAssumption)';
}


}

/// @nodoc
abstract mixin class _$TariffPublicCopyWith<$Res> implements $TariffPublicCopyWith<$Res> {
  factory _$TariffPublicCopyWith(_TariffPublic value, $Res Function(_TariffPublic) _then) = __$TariffPublicCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String label, int pricePerKwhMilli, bool isAssumption
});




}
/// @nodoc
class __$TariffPublicCopyWithImpl<$Res>
    implements _$TariffPublicCopyWith<$Res> {
  __$TariffPublicCopyWithImpl(this._self, this._then);

  final _TariffPublic _self;
  final $Res Function(_TariffPublic) _then;

/// Create a copy of TariffPublic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? label = null,Object? pricePerKwhMilli = null,Object? isAssumption = null,}) {
  return _then(_TariffPublic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pricePerKwhMilli: null == pricePerKwhMilli ? _self.pricePerKwhMilli : pricePerKwhMilli // ignore: cast_nullable_to_non_nullable
as int,isAssumption: null == isAssumption ? _self.isAssumption : isAssumption // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PreviousBillComparison {

 int get billId; String get reference; String get periodLabel;/// Période de la précédente : le libellé affiché est construit avec `formats.dart`.
 DateTime get periodStart; DateTime get periodEnd; int get consumptionWh; double get consumptionKwh; int get amountTotal; int get consumptionChangeWh;/// `null` si la précédente vaut 0.
 double? get consumptionChangePercent; int get amountChange; double? get amountChangePercent;
/// Create a copy of PreviousBillComparison
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreviousBillComparisonCopyWith<PreviousBillComparison> get copyWith => _$PreviousBillComparisonCopyWithImpl<PreviousBillComparison>(this as PreviousBillComparison, _$identity);

  /// Serializes this PreviousBillComparison to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PreviousBillComparison;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviousBillComparison&&(identical(other.billId, _this.billId) || other.billId == _this.billId)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.periodLabel, _this.periodLabel) || other.periodLabel == _this.periodLabel)&&(identical(other.periodStart, _this.periodStart) || other.periodStart == _this.periodStart)&&(identical(other.periodEnd, _this.periodEnd) || other.periodEnd == _this.periodEnd)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.amountTotal, _this.amountTotal) || other.amountTotal == _this.amountTotal)&&(identical(other.consumptionChangeWh, _this.consumptionChangeWh) || other.consumptionChangeWh == _this.consumptionChangeWh)&&(identical(other.consumptionChangePercent, _this.consumptionChangePercent) || other.consumptionChangePercent == _this.consumptionChangePercent)&&(identical(other.amountChange, _this.amountChange) || other.amountChange == _this.amountChange)&&(identical(other.amountChangePercent, _this.amountChangePercent) || other.amountChangePercent == _this.amountChangePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PreviousBillComparison;
  return Object.hash(runtimeType,_this.billId,_this.reference,_this.periodLabel,_this.periodStart,_this.periodEnd,_this.consumptionWh,_this.consumptionKwh,_this.amountTotal,_this.consumptionChangeWh,_this.consumptionChangePercent,_this.amountChange,_this.amountChangePercent);
}

@override
String toString() {
  final _this = this as PreviousBillComparison;
  return 'PreviousBillComparison(billId: ${_this.billId}, reference: ${_this.reference}, periodLabel: ${_this.periodLabel}, periodStart: ${_this.periodStart}, periodEnd: ${_this.periodEnd}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, amountTotal: ${_this.amountTotal}, consumptionChangeWh: ${_this.consumptionChangeWh}, consumptionChangePercent: ${_this.consumptionChangePercent}, amountChange: ${_this.amountChange}, amountChangePercent: ${_this.amountChangePercent})';
}


}

/// @nodoc
abstract mixin class $PreviousBillComparisonCopyWith<$Res>  {
  factory $PreviousBillComparisonCopyWith(PreviousBillComparison value, $Res Function(PreviousBillComparison) _then) = _$PreviousBillComparisonCopyWithImpl;
@useResult
$Res call({
 int billId, String reference, String periodLabel, DateTime periodStart, DateTime periodEnd, int consumptionWh, double consumptionKwh, int amountTotal, int consumptionChangeWh, double? consumptionChangePercent, int amountChange, double? amountChangePercent
});




}
/// @nodoc
class _$PreviousBillComparisonCopyWithImpl<$Res>
    implements $PreviousBillComparisonCopyWith<$Res> {
  _$PreviousBillComparisonCopyWithImpl(this._self, this._then);

  final PreviousBillComparison _self;
  final $Res Function(PreviousBillComparison) _then;

/// Create a copy of PreviousBillComparison
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? billId = null,Object? reference = null,Object? periodLabel = null,Object? periodStart = null,Object? periodEnd = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? consumptionChangeWh = null,Object? consumptionChangePercent = freezed,Object? amountChange = null,Object? amountChangePercent = freezed,}) {
  return _then(PreviousBillComparison(
billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,consumptionChangeWh: null == consumptionChangeWh ? _self.consumptionChangeWh : consumptionChangeWh // ignore: cast_nullable_to_non_nullable
as int,consumptionChangePercent: freezed == consumptionChangePercent ? _self.consumptionChangePercent : consumptionChangePercent // ignore: cast_nullable_to_non_nullable
as double?,amountChange: null == amountChange ? _self.amountChange : amountChange // ignore: cast_nullable_to_non_nullable
as int,amountChangePercent: freezed == amountChangePercent ? _self.amountChangePercent : amountChangePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PreviousBillComparison].
extension PreviousBillComparisonPatterns on PreviousBillComparison {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreviousBillComparison value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreviousBillComparison() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreviousBillComparison value)  $default,){
final _that = this;
switch (_that) {
case _PreviousBillComparison():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreviousBillComparison value)?  $default,){
final _that = this;
switch (_that) {
case _PreviousBillComparison() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int billId,  String reference,  String periodLabel,  DateTime periodStart,  DateTime periodEnd,  int consumptionWh,  double consumptionKwh,  int amountTotal,  int consumptionChangeWh,  double? consumptionChangePercent,  int amountChange,  double? amountChangePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreviousBillComparison() when $default != null:
return $default(_that.billId,_that.reference,_that.periodLabel,_that.periodStart,_that.periodEnd,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.consumptionChangeWh,_that.consumptionChangePercent,_that.amountChange,_that.amountChangePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int billId,  String reference,  String periodLabel,  DateTime periodStart,  DateTime periodEnd,  int consumptionWh,  double consumptionKwh,  int amountTotal,  int consumptionChangeWh,  double? consumptionChangePercent,  int amountChange,  double? amountChangePercent)  $default,) {final _that = this;
switch (_that) {
case _PreviousBillComparison():
return $default(_that.billId,_that.reference,_that.periodLabel,_that.periodStart,_that.periodEnd,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.consumptionChangeWh,_that.consumptionChangePercent,_that.amountChange,_that.amountChangePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int billId,  String reference,  String periodLabel,  DateTime periodStart,  DateTime periodEnd,  int consumptionWh,  double consumptionKwh,  int amountTotal,  int consumptionChangeWh,  double? consumptionChangePercent,  int amountChange,  double? amountChangePercent)?  $default,) {final _that = this;
switch (_that) {
case _PreviousBillComparison() when $default != null:
return $default(_that.billId,_that.reference,_that.periodLabel,_that.periodStart,_that.periodEnd,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.consumptionChangeWh,_that.consumptionChangePercent,_that.amountChange,_that.amountChangePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreviousBillComparison implements PreviousBillComparison {
  const _PreviousBillComparison({required this.billId, required this.reference, required this.periodLabel, required this.periodStart, required this.periodEnd, required this.consumptionWh, required this.consumptionKwh, required this.amountTotal, required this.consumptionChangeWh, required this.consumptionChangePercent, required this.amountChange, required this.amountChangePercent});
  factory _PreviousBillComparison.fromJson(Map<String, dynamic> json) => _$PreviousBillComparisonFromJson(json);

@override final  int billId;
@override final  String reference;
@override final  String periodLabel;
/// Période de la précédente : le libellé affiché est construit avec `formats.dart`.
@override final  DateTime periodStart;
@override final  DateTime periodEnd;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int amountTotal;
@override final  int consumptionChangeWh;
/// `null` si la précédente vaut 0.
@override final  double? consumptionChangePercent;
@override final  int amountChange;
@override final  double? amountChangePercent;

/// Create a copy of PreviousBillComparison
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreviousBillComparisonCopyWith<_PreviousBillComparison> get copyWith => __$PreviousBillComparisonCopyWithImpl<_PreviousBillComparison>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreviousBillComparisonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreviousBillComparison&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.periodLabel, periodLabel) || other.periodLabel == periodLabel)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.amountTotal, amountTotal) || other.amountTotal == amountTotal)&&(identical(other.consumptionChangeWh, consumptionChangeWh) || other.consumptionChangeWh == consumptionChangeWh)&&(identical(other.consumptionChangePercent, consumptionChangePercent) || other.consumptionChangePercent == consumptionChangePercent)&&(identical(other.amountChange, amountChange) || other.amountChange == amountChange)&&(identical(other.amountChangePercent, amountChangePercent) || other.amountChangePercent == amountChangePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,billId,reference,periodLabel,periodStart,periodEnd,consumptionWh,consumptionKwh,amountTotal,consumptionChangeWh,consumptionChangePercent,amountChange,amountChangePercent);
}

@override
String toString() {
    return 'PreviousBillComparison(billId: $billId, reference: $reference, periodLabel: $periodLabel, periodStart: $periodStart, periodEnd: $periodEnd, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, amountTotal: $amountTotal, consumptionChangeWh: $consumptionChangeWh, consumptionChangePercent: $consumptionChangePercent, amountChange: $amountChange, amountChangePercent: $amountChangePercent)';
}


}

/// @nodoc
abstract mixin class _$PreviousBillComparisonCopyWith<$Res> implements $PreviousBillComparisonCopyWith<$Res> {
  factory _$PreviousBillComparisonCopyWith(_PreviousBillComparison value, $Res Function(_PreviousBillComparison) _then) = __$PreviousBillComparisonCopyWithImpl;
@override @useResult
$Res call({
 int billId, String reference, String periodLabel, DateTime periodStart, DateTime periodEnd, int consumptionWh, double consumptionKwh, int amountTotal, int consumptionChangeWh, double? consumptionChangePercent, int amountChange, double? amountChangePercent
});




}
/// @nodoc
class __$PreviousBillComparisonCopyWithImpl<$Res>
    implements _$PreviousBillComparisonCopyWith<$Res> {
  __$PreviousBillComparisonCopyWithImpl(this._self, this._then);

  final _PreviousBillComparison _self;
  final $Res Function(_PreviousBillComparison) _then;

/// Create a copy of PreviousBillComparison
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? billId = null,Object? reference = null,Object? periodLabel = null,Object? periodStart = null,Object? periodEnd = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? consumptionChangeWh = null,Object? consumptionChangePercent = freezed,Object? amountChange = null,Object? amountChangePercent = freezed,}) {
  return _then(_PreviousBillComparison(
billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,consumptionChangeWh: null == consumptionChangeWh ? _self.consumptionChangeWh : consumptionChangeWh // ignore: cast_nullable_to_non_nullable
as int,consumptionChangePercent: freezed == consumptionChangePercent ? _self.consumptionChangePercent : consumptionChangePercent // ignore: cast_nullable_to_non_nullable
as double?,amountChange: null == amountChange ? _self.amountChange : amountChange // ignore: cast_nullable_to_non_nullable
as int,amountChangePercent: freezed == amountChangePercent ? _self.amountChangePercent : amountChangePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$BillDetail {

 int get id; String get reference; int get meterId; String get meterReference; String? get meterLabel; int get householdId; String get householdName; DateTime get periodStart; DateTime get periodEnd; String get periodLabel; int get monthsCount; int get consumptionWh; double get consumptionKwh; int get amountTotal; DateTime get issuedAt; DateTime get dueDate; String get status; int get daysOverdue; DateTime? get paidAt; String get myRole; bool get canPay; String get source; String? get meterContractNumber; String? get meterCustomerNumber; String? get e2cCenter; int get previousIndexWh; int get currentIndexWh; double get previousIndexKwh; double get currentIndexKwh; int? get billedPowerVa; int get amountHt; int get amountTax; int get amountFees; List<BillLinePublic> get lines; TariffPublic get tariff; PreviousBillComparison? get previousBill; DateTime? get cancelledAt; String? get cancelledReason;
/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillDetailCopyWith<BillDetail> get copyWith => _$BillDetailCopyWithImpl<BillDetail>(this as BillDetail, _$identity);

  /// Serializes this BillDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.meterId, _this.meterId) || other.meterId == _this.meterId)&&(identical(other.meterReference, _this.meterReference) || other.meterReference == _this.meterReference)&&(identical(other.meterLabel, _this.meterLabel) || other.meterLabel == _this.meterLabel)&&(identical(other.householdId, _this.householdId) || other.householdId == _this.householdId)&&(identical(other.householdName, _this.householdName) || other.householdName == _this.householdName)&&(identical(other.periodStart, _this.periodStart) || other.periodStart == _this.periodStart)&&(identical(other.periodEnd, _this.periodEnd) || other.periodEnd == _this.periodEnd)&&(identical(other.periodLabel, _this.periodLabel) || other.periodLabel == _this.periodLabel)&&(identical(other.monthsCount, _this.monthsCount) || other.monthsCount == _this.monthsCount)&&(identical(other.consumptionWh, _this.consumptionWh) || other.consumptionWh == _this.consumptionWh)&&(identical(other.consumptionKwh, _this.consumptionKwh) || other.consumptionKwh == _this.consumptionKwh)&&(identical(other.amountTotal, _this.amountTotal) || other.amountTotal == _this.amountTotal)&&(identical(other.issuedAt, _this.issuedAt) || other.issuedAt == _this.issuedAt)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.daysOverdue, _this.daysOverdue) || other.daysOverdue == _this.daysOverdue)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.myRole, _this.myRole) || other.myRole == _this.myRole)&&(identical(other.canPay, _this.canPay) || other.canPay == _this.canPay)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.meterContractNumber, _this.meterContractNumber) || other.meterContractNumber == _this.meterContractNumber)&&(identical(other.meterCustomerNumber, _this.meterCustomerNumber) || other.meterCustomerNumber == _this.meterCustomerNumber)&&(identical(other.e2cCenter, _this.e2cCenter) || other.e2cCenter == _this.e2cCenter)&&(identical(other.previousIndexWh, _this.previousIndexWh) || other.previousIndexWh == _this.previousIndexWh)&&(identical(other.currentIndexWh, _this.currentIndexWh) || other.currentIndexWh == _this.currentIndexWh)&&(identical(other.previousIndexKwh, _this.previousIndexKwh) || other.previousIndexKwh == _this.previousIndexKwh)&&(identical(other.currentIndexKwh, _this.currentIndexKwh) || other.currentIndexKwh == _this.currentIndexKwh)&&(identical(other.billedPowerVa, _this.billedPowerVa) || other.billedPowerVa == _this.billedPowerVa)&&(identical(other.amountHt, _this.amountHt) || other.amountHt == _this.amountHt)&&(identical(other.amountTax, _this.amountTax) || other.amountTax == _this.amountTax)&&(identical(other.amountFees, _this.amountFees) || other.amountFees == _this.amountFees)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.tariff, _this.tariff) || other.tariff == _this.tariff)&&(identical(other.previousBill, _this.previousBill) || other.previousBill == _this.previousBill)&&(identical(other.cancelledAt, _this.cancelledAt) || other.cancelledAt == _this.cancelledAt)&&(identical(other.cancelledReason, _this.cancelledReason) || other.cancelledReason == _this.cancelledReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillDetail;
  return Object.hashAll([runtimeType,_this.id,_this.reference,_this.meterId,_this.meterReference,_this.meterLabel,_this.householdId,_this.householdName,_this.periodStart,_this.periodEnd,_this.periodLabel,_this.monthsCount,_this.consumptionWh,_this.consumptionKwh,_this.amountTotal,_this.issuedAt,_this.dueDate,_this.status,_this.daysOverdue,_this.paidAt,_this.myRole,_this.canPay,_this.source,_this.meterContractNumber,_this.meterCustomerNumber,_this.e2cCenter,_this.previousIndexWh,_this.currentIndexWh,_this.previousIndexKwh,_this.currentIndexKwh,_this.billedPowerVa,_this.amountHt,_this.amountTax,_this.amountFees,const DeepCollectionEquality().hash(_this.lines),_this.tariff,_this.previousBill,_this.cancelledAt,_this.cancelledReason]);
}

@override
String toString() {
  final _this = this as BillDetail;
  return 'BillDetail(id: ${_this.id}, reference: ${_this.reference}, meterId: ${_this.meterId}, meterReference: ${_this.meterReference}, meterLabel: ${_this.meterLabel}, householdId: ${_this.householdId}, householdName: ${_this.householdName}, periodStart: ${_this.periodStart}, periodEnd: ${_this.periodEnd}, periodLabel: ${_this.periodLabel}, monthsCount: ${_this.monthsCount}, consumptionWh: ${_this.consumptionWh}, consumptionKwh: ${_this.consumptionKwh}, amountTotal: ${_this.amountTotal}, issuedAt: ${_this.issuedAt}, dueDate: ${_this.dueDate}, status: ${_this.status}, daysOverdue: ${_this.daysOverdue}, paidAt: ${_this.paidAt}, myRole: ${_this.myRole}, canPay: ${_this.canPay}, source: ${_this.source}, meterContractNumber: ${_this.meterContractNumber}, meterCustomerNumber: ${_this.meterCustomerNumber}, e2cCenter: ${_this.e2cCenter}, previousIndexWh: ${_this.previousIndexWh}, currentIndexWh: ${_this.currentIndexWh}, previousIndexKwh: ${_this.previousIndexKwh}, currentIndexKwh: ${_this.currentIndexKwh}, billedPowerVa: ${_this.billedPowerVa}, amountHt: ${_this.amountHt}, amountTax: ${_this.amountTax}, amountFees: ${_this.amountFees}, lines: ${_this.lines}, tariff: ${_this.tariff}, previousBill: ${_this.previousBill}, cancelledAt: ${_this.cancelledAt}, cancelledReason: ${_this.cancelledReason})';
}


}

/// @nodoc
abstract mixin class $BillDetailCopyWith<$Res>  {
  factory $BillDetailCopyWith(BillDetail value, $Res Function(BillDetail) _then) = _$BillDetailCopyWithImpl;
@useResult
$Res call({
 int id, String reference, int meterId, String meterReference, String? meterLabel, int householdId, String householdName, DateTime periodStart, DateTime periodEnd, String periodLabel, int monthsCount, int consumptionWh, double consumptionKwh, int amountTotal, DateTime issuedAt, DateTime dueDate, String status, int daysOverdue, DateTime? paidAt, String myRole, bool canPay, String source, String? meterContractNumber, String? meterCustomerNumber, String? e2cCenter, int previousIndexWh, int currentIndexWh, double previousIndexKwh, double currentIndexKwh, int? billedPowerVa, int amountHt, int amountTax, int amountFees, List<BillLinePublic> lines, TariffPublic tariff, PreviousBillComparison? previousBill, DateTime? cancelledAt, String? cancelledReason
});


$TariffPublicCopyWith<$Res> get tariff;$PreviousBillComparisonCopyWith<$Res>? get previousBill;

}
/// @nodoc
class _$BillDetailCopyWithImpl<$Res>
    implements $BillDetailCopyWith<$Res> {
  _$BillDetailCopyWithImpl(this._self, this._then);

  final BillDetail _self;
  final $Res Function(BillDetail) _then;

/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? meterId = null,Object? meterReference = null,Object? meterLabel = freezed,Object? householdId = null,Object? householdName = null,Object? periodStart = null,Object? periodEnd = null,Object? periodLabel = null,Object? monthsCount = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? issuedAt = null,Object? dueDate = null,Object? status = null,Object? daysOverdue = null,Object? paidAt = freezed,Object? myRole = null,Object? canPay = null,Object? source = null,Object? meterContractNumber = freezed,Object? meterCustomerNumber = freezed,Object? e2cCenter = freezed,Object? previousIndexWh = null,Object? currentIndexWh = null,Object? previousIndexKwh = null,Object? currentIndexKwh = null,Object? billedPowerVa = freezed,Object? amountHt = null,Object? amountTax = null,Object? amountFees = null,Object? lines = null,Object? tariff = null,Object? previousBill = freezed,Object? cancelledAt = freezed,Object? cancelledReason = freezed,}) {
  return _then(BillDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,meterLabel: freezed == meterLabel ? _self.meterLabel : meterLabel // ignore: cast_nullable_to_non_nullable
as String?,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,monthsCount: null == monthsCount ? _self.monthsCount : monthsCount // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,meterContractNumber: freezed == meterContractNumber ? _self.meterContractNumber : meterContractNumber // ignore: cast_nullable_to_non_nullable
as String?,meterCustomerNumber: freezed == meterCustomerNumber ? _self.meterCustomerNumber : meterCustomerNumber // ignore: cast_nullable_to_non_nullable
as String?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,previousIndexWh: null == previousIndexWh ? _self.previousIndexWh : previousIndexWh // ignore: cast_nullable_to_non_nullable
as int,currentIndexWh: null == currentIndexWh ? _self.currentIndexWh : currentIndexWh // ignore: cast_nullable_to_non_nullable
as int,previousIndexKwh: null == previousIndexKwh ? _self.previousIndexKwh : previousIndexKwh // ignore: cast_nullable_to_non_nullable
as double,currentIndexKwh: null == currentIndexKwh ? _self.currentIndexKwh : currentIndexKwh // ignore: cast_nullable_to_non_nullable
as double,billedPowerVa: freezed == billedPowerVa ? _self.billedPowerVa : billedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,amountHt: null == amountHt ? _self.amountHt : amountHt // ignore: cast_nullable_to_non_nullable
as int,amountTax: null == amountTax ? _self.amountTax : amountTax // ignore: cast_nullable_to_non_nullable
as int,amountFees: null == amountFees ? _self.amountFees : amountFees // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<BillLinePublic>,tariff: null == tariff ? _self.tariff : tariff // ignore: cast_nullable_to_non_nullable
as TariffPublic,previousBill: freezed == previousBill ? _self.previousBill : previousBill // ignore: cast_nullable_to_non_nullable
as PreviousBillComparison?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TariffPublicCopyWith<$Res> get tariff {
  
  return $TariffPublicCopyWith<$Res>(_self.tariff, (value) {
    return _then(_self.copyWith(tariff: value));
  });
}/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviousBillComparisonCopyWith<$Res>? get previousBill {
    if (_self.previousBill == null) {
    return null;
  }

  return $PreviousBillComparisonCopyWith<$Res>(_self.previousBill!, (value) {
    return _then(_self.copyWith(previousBill: value));
  });
}
}


/// Adds pattern-matching-related methods to [BillDetail].
extension BillDetailPatterns on BillDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillDetail value)  $default,){
final _that = this;
switch (_that) {
case _BillDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillDetail value)?  $default,){
final _that = this;
switch (_that) {
case _BillDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String reference,  int meterId,  String meterReference,  String? meterLabel,  int householdId,  String householdName,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  String myRole,  bool canPay,  String source,  String? meterContractNumber,  String? meterCustomerNumber,  String? e2cCenter,  int previousIndexWh,  int currentIndexWh,  double previousIndexKwh,  double currentIndexKwh,  int? billedPowerVa,  int amountHt,  int amountTax,  int amountFees,  List<BillLinePublic> lines,  TariffPublic tariff,  PreviousBillComparison? previousBill,  DateTime? cancelledAt,  String? cancelledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillDetail() when $default != null:
return $default(_that.id,_that.reference,_that.meterId,_that.meterReference,_that.meterLabel,_that.householdId,_that.householdName,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.myRole,_that.canPay,_that.source,_that.meterContractNumber,_that.meterCustomerNumber,_that.e2cCenter,_that.previousIndexWh,_that.currentIndexWh,_that.previousIndexKwh,_that.currentIndexKwh,_that.billedPowerVa,_that.amountHt,_that.amountTax,_that.amountFees,_that.lines,_that.tariff,_that.previousBill,_that.cancelledAt,_that.cancelledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String reference,  int meterId,  String meterReference,  String? meterLabel,  int householdId,  String householdName,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  String myRole,  bool canPay,  String source,  String? meterContractNumber,  String? meterCustomerNumber,  String? e2cCenter,  int previousIndexWh,  int currentIndexWh,  double previousIndexKwh,  double currentIndexKwh,  int? billedPowerVa,  int amountHt,  int amountTax,  int amountFees,  List<BillLinePublic> lines,  TariffPublic tariff,  PreviousBillComparison? previousBill,  DateTime? cancelledAt,  String? cancelledReason)  $default,) {final _that = this;
switch (_that) {
case _BillDetail():
return $default(_that.id,_that.reference,_that.meterId,_that.meterReference,_that.meterLabel,_that.householdId,_that.householdName,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.myRole,_that.canPay,_that.source,_that.meterContractNumber,_that.meterCustomerNumber,_that.e2cCenter,_that.previousIndexWh,_that.currentIndexWh,_that.previousIndexKwh,_that.currentIndexKwh,_that.billedPowerVa,_that.amountHt,_that.amountTax,_that.amountFees,_that.lines,_that.tariff,_that.previousBill,_that.cancelledAt,_that.cancelledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String reference,  int meterId,  String meterReference,  String? meterLabel,  int householdId,  String householdName,  DateTime periodStart,  DateTime periodEnd,  String periodLabel,  int monthsCount,  int consumptionWh,  double consumptionKwh,  int amountTotal,  DateTime issuedAt,  DateTime dueDate,  String status,  int daysOverdue,  DateTime? paidAt,  String myRole,  bool canPay,  String source,  String? meterContractNumber,  String? meterCustomerNumber,  String? e2cCenter,  int previousIndexWh,  int currentIndexWh,  double previousIndexKwh,  double currentIndexKwh,  int? billedPowerVa,  int amountHt,  int amountTax,  int amountFees,  List<BillLinePublic> lines,  TariffPublic tariff,  PreviousBillComparison? previousBill,  DateTime? cancelledAt,  String? cancelledReason)?  $default,) {final _that = this;
switch (_that) {
case _BillDetail() when $default != null:
return $default(_that.id,_that.reference,_that.meterId,_that.meterReference,_that.meterLabel,_that.householdId,_that.householdName,_that.periodStart,_that.periodEnd,_that.periodLabel,_that.monthsCount,_that.consumptionWh,_that.consumptionKwh,_that.amountTotal,_that.issuedAt,_that.dueDate,_that.status,_that.daysOverdue,_that.paidAt,_that.myRole,_that.canPay,_that.source,_that.meterContractNumber,_that.meterCustomerNumber,_that.e2cCenter,_that.previousIndexWh,_that.currentIndexWh,_that.previousIndexKwh,_that.currentIndexKwh,_that.billedPowerVa,_that.amountHt,_that.amountTax,_that.amountFees,_that.lines,_that.tariff,_that.previousBill,_that.cancelledAt,_that.cancelledReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillDetail implements BillDetail {
  const _BillDetail({required this.id, required this.reference, required this.meterId, required this.meterReference, required this.meterLabel, required this.householdId, required this.householdName, required this.periodStart, required this.periodEnd, required this.periodLabel, required this.monthsCount, required this.consumptionWh, required this.consumptionKwh, required this.amountTotal, required this.issuedAt, required this.dueDate, required this.status, required this.daysOverdue, required this.paidAt, required this.myRole, required this.canPay, required this.source, required this.meterContractNumber, required this.meterCustomerNumber, required this.e2cCenter, required this.previousIndexWh, required this.currentIndexWh, required this.previousIndexKwh, required this.currentIndexKwh, required this.billedPowerVa, required this.amountHt, required this.amountTax, required this.amountFees, required  List<BillLinePublic> lines, required this.tariff, required this.previousBill, required this.cancelledAt, required this.cancelledReason}): _lines = lines;
  factory _BillDetail.fromJson(Map<String, dynamic> json) => _$BillDetailFromJson(json);

@override final  int id;
@override final  String reference;
@override final  int meterId;
@override final  String meterReference;
@override final  String? meterLabel;
@override final  int householdId;
@override final  String householdName;
@override final  DateTime periodStart;
@override final  DateTime periodEnd;
@override final  String periodLabel;
@override final  int monthsCount;
@override final  int consumptionWh;
@override final  double consumptionKwh;
@override final  int amountTotal;
@override final  DateTime issuedAt;
@override final  DateTime dueDate;
@override final  String status;
@override final  int daysOverdue;
@override final  DateTime? paidAt;
@override final  String myRole;
@override final  bool canPay;
@override final  String source;
@override final  String? meterContractNumber;
@override final  String? meterCustomerNumber;
@override final  String? e2cCenter;
@override final  int previousIndexWh;
@override final  int currentIndexWh;
@override final  double previousIndexKwh;
@override final  double currentIndexKwh;
@override final  int? billedPowerVa;
@override final  int amountHt;
@override final  int amountTax;
@override final  int amountFees;
 final  List<BillLinePublic> _lines;
@override List<BillLinePublic> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  TariffPublic tariff;
@override final  PreviousBillComparison? previousBill;
@override final  DateTime? cancelledAt;
@override final  String? cancelledReason;

/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillDetailCopyWith<_BillDetail> get copyWith => __$BillDetailCopyWithImpl<_BillDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.meterId, meterId) || other.meterId == meterId)&&(identical(other.meterReference, meterReference) || other.meterReference == meterReference)&&(identical(other.meterLabel, meterLabel) || other.meterLabel == meterLabel)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.periodLabel, periodLabel) || other.periodLabel == periodLabel)&&(identical(other.monthsCount, monthsCount) || other.monthsCount == monthsCount)&&(identical(other.consumptionWh, consumptionWh) || other.consumptionWh == consumptionWh)&&(identical(other.consumptionKwh, consumptionKwh) || other.consumptionKwh == consumptionKwh)&&(identical(other.amountTotal, amountTotal) || other.amountTotal == amountTotal)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&(identical(other.source, source) || other.source == source)&&(identical(other.meterContractNumber, meterContractNumber) || other.meterContractNumber == meterContractNumber)&&(identical(other.meterCustomerNumber, meterCustomerNumber) || other.meterCustomerNumber == meterCustomerNumber)&&(identical(other.e2cCenter, e2cCenter) || other.e2cCenter == e2cCenter)&&(identical(other.previousIndexWh, previousIndexWh) || other.previousIndexWh == previousIndexWh)&&(identical(other.currentIndexWh, currentIndexWh) || other.currentIndexWh == currentIndexWh)&&(identical(other.previousIndexKwh, previousIndexKwh) || other.previousIndexKwh == previousIndexKwh)&&(identical(other.currentIndexKwh, currentIndexKwh) || other.currentIndexKwh == currentIndexKwh)&&(identical(other.billedPowerVa, billedPowerVa) || other.billedPowerVa == billedPowerVa)&&(identical(other.amountHt, amountHt) || other.amountHt == amountHt)&&(identical(other.amountTax, amountTax) || other.amountTax == amountTax)&&(identical(other.amountFees, amountFees) || other.amountFees == amountFees)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.tariff, tariff) || other.tariff == tariff)&&(identical(other.previousBill, previousBill) || other.previousBill == previousBill)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.cancelledReason, cancelledReason) || other.cancelledReason == cancelledReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,reference,meterId,meterReference,meterLabel,householdId,householdName,periodStart,periodEnd,periodLabel,monthsCount,consumptionWh,consumptionKwh,amountTotal,issuedAt,dueDate,status,daysOverdue,paidAt,myRole,canPay,source,meterContractNumber,meterCustomerNumber,e2cCenter,previousIndexWh,currentIndexWh,previousIndexKwh,currentIndexKwh,billedPowerVa,amountHt,amountTax,amountFees,const DeepCollectionEquality().hash(_lines),tariff,previousBill,cancelledAt,cancelledReason]);
}

@override
String toString() {
    return 'BillDetail(id: $id, reference: $reference, meterId: $meterId, meterReference: $meterReference, meterLabel: $meterLabel, householdId: $householdId, householdName: $householdName, periodStart: $periodStart, periodEnd: $periodEnd, periodLabel: $periodLabel, monthsCount: $monthsCount, consumptionWh: $consumptionWh, consumptionKwh: $consumptionKwh, amountTotal: $amountTotal, issuedAt: $issuedAt, dueDate: $dueDate, status: $status, daysOverdue: $daysOverdue, paidAt: $paidAt, myRole: $myRole, canPay: $canPay, source: $source, meterContractNumber: $meterContractNumber, meterCustomerNumber: $meterCustomerNumber, e2cCenter: $e2cCenter, previousIndexWh: $previousIndexWh, currentIndexWh: $currentIndexWh, previousIndexKwh: $previousIndexKwh, currentIndexKwh: $currentIndexKwh, billedPowerVa: $billedPowerVa, amountHt: $amountHt, amountTax: $amountTax, amountFees: $amountFees, lines: $lines, tariff: $tariff, previousBill: $previousBill, cancelledAt: $cancelledAt, cancelledReason: $cancelledReason)';
}


}

/// @nodoc
abstract mixin class _$BillDetailCopyWith<$Res> implements $BillDetailCopyWith<$Res> {
  factory _$BillDetailCopyWith(_BillDetail value, $Res Function(_BillDetail) _then) = __$BillDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String reference, int meterId, String meterReference, String? meterLabel, int householdId, String householdName, DateTime periodStart, DateTime periodEnd, String periodLabel, int monthsCount, int consumptionWh, double consumptionKwh, int amountTotal, DateTime issuedAt, DateTime dueDate, String status, int daysOverdue, DateTime? paidAt, String myRole, bool canPay, String source, String? meterContractNumber, String? meterCustomerNumber, String? e2cCenter, int previousIndexWh, int currentIndexWh, double previousIndexKwh, double currentIndexKwh, int? billedPowerVa, int amountHt, int amountTax, int amountFees, List<BillLinePublic> lines, TariffPublic tariff, PreviousBillComparison? previousBill, DateTime? cancelledAt, String? cancelledReason
});


@override $TariffPublicCopyWith<$Res> get tariff;@override $PreviousBillComparisonCopyWith<$Res>? get previousBill;

}
/// @nodoc
class __$BillDetailCopyWithImpl<$Res>
    implements _$BillDetailCopyWith<$Res> {
  __$BillDetailCopyWithImpl(this._self, this._then);

  final _BillDetail _self;
  final $Res Function(_BillDetail) _then;

/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? meterId = null,Object? meterReference = null,Object? meterLabel = freezed,Object? householdId = null,Object? householdName = null,Object? periodStart = null,Object? periodEnd = null,Object? periodLabel = null,Object? monthsCount = null,Object? consumptionWh = null,Object? consumptionKwh = null,Object? amountTotal = null,Object? issuedAt = null,Object? dueDate = null,Object? status = null,Object? daysOverdue = null,Object? paidAt = freezed,Object? myRole = null,Object? canPay = null,Object? source = null,Object? meterContractNumber = freezed,Object? meterCustomerNumber = freezed,Object? e2cCenter = freezed,Object? previousIndexWh = null,Object? currentIndexWh = null,Object? previousIndexKwh = null,Object? currentIndexKwh = null,Object? billedPowerVa = freezed,Object? amountHt = null,Object? amountTax = null,Object? amountFees = null,Object? lines = null,Object? tariff = null,Object? previousBill = freezed,Object? cancelledAt = freezed,Object? cancelledReason = freezed,}) {
  return _then(_BillDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,meterId: null == meterId ? _self.meterId : meterId // ignore: cast_nullable_to_non_nullable
as int,meterReference: null == meterReference ? _self.meterReference : meterReference // ignore: cast_nullable_to_non_nullable
as String,meterLabel: freezed == meterLabel ? _self.meterLabel : meterLabel // ignore: cast_nullable_to_non_nullable
as String?,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as int,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,periodLabel: null == periodLabel ? _self.periodLabel : periodLabel // ignore: cast_nullable_to_non_nullable
as String,monthsCount: null == monthsCount ? _self.monthsCount : monthsCount // ignore: cast_nullable_to_non_nullable
as int,consumptionWh: null == consumptionWh ? _self.consumptionWh : consumptionWh // ignore: cast_nullable_to_non_nullable
as int,consumptionKwh: null == consumptionKwh ? _self.consumptionKwh : consumptionKwh // ignore: cast_nullable_to_non_nullable
as double,amountTotal: null == amountTotal ? _self.amountTotal : amountTotal // ignore: cast_nullable_to_non_nullable
as int,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,myRole: null == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,meterContractNumber: freezed == meterContractNumber ? _self.meterContractNumber : meterContractNumber // ignore: cast_nullable_to_non_nullable
as String?,meterCustomerNumber: freezed == meterCustomerNumber ? _self.meterCustomerNumber : meterCustomerNumber // ignore: cast_nullable_to_non_nullable
as String?,e2cCenter: freezed == e2cCenter ? _self.e2cCenter : e2cCenter // ignore: cast_nullable_to_non_nullable
as String?,previousIndexWh: null == previousIndexWh ? _self.previousIndexWh : previousIndexWh // ignore: cast_nullable_to_non_nullable
as int,currentIndexWh: null == currentIndexWh ? _self.currentIndexWh : currentIndexWh // ignore: cast_nullable_to_non_nullable
as int,previousIndexKwh: null == previousIndexKwh ? _self.previousIndexKwh : previousIndexKwh // ignore: cast_nullable_to_non_nullable
as double,currentIndexKwh: null == currentIndexKwh ? _self.currentIndexKwh : currentIndexKwh // ignore: cast_nullable_to_non_nullable
as double,billedPowerVa: freezed == billedPowerVa ? _self.billedPowerVa : billedPowerVa // ignore: cast_nullable_to_non_nullable
as int?,amountHt: null == amountHt ? _self.amountHt : amountHt // ignore: cast_nullable_to_non_nullable
as int,amountTax: null == amountTax ? _self.amountTax : amountTax // ignore: cast_nullable_to_non_nullable
as int,amountFees: null == amountFees ? _self.amountFees : amountFees // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<BillLinePublic>,tariff: null == tariff ? _self.tariff : tariff // ignore: cast_nullable_to_non_nullable
as TariffPublic,previousBill: freezed == previousBill ? _self.previousBill : previousBill // ignore: cast_nullable_to_non_nullable
as PreviousBillComparison?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelledReason: freezed == cancelledReason ? _self.cancelledReason : cancelledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TariffPublicCopyWith<$Res> get tariff {
  
  return $TariffPublicCopyWith<$Res>(_self.tariff, (value) {
    return _then(_self.copyWith(tariff: value));
  });
}/// Create a copy of BillDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviousBillComparisonCopyWith<$Res>? get previousBill {
    if (_self.previousBill == null) {
    return null;
  }

  return $PreviousBillComparisonCopyWith<$Res>(_self.previousBill!, (value) {
    return _then(_self.copyWith(previousBill: value));
  });
}
}

// dart format on
