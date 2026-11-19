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

// dart format on
