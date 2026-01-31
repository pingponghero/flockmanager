// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MedicationLog {

 String get id; String? get birdId; String get flockId; String get medicationName; String? get dosage; DateTime get startDate; DateTime? get endDate; int? get withdrawalDays; String? get notes; DateTime get createdAt;
/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedicationLogCopyWith<MedicationLog> get copyWith => _$MedicationLogCopyWithImpl<MedicationLog>(this as MedicationLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedicationLog&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.withdrawalDays, withdrawalDays) || other.withdrawalDays == withdrawalDays)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,flockId,medicationName,dosage,startDate,endDate,withdrawalDays,notes,createdAt);

@override
String toString() {
  return 'MedicationLog(id: $id, birdId: $birdId, flockId: $flockId, medicationName: $medicationName, dosage: $dosage, startDate: $startDate, endDate: $endDate, withdrawalDays: $withdrawalDays, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MedicationLogCopyWith<$Res>  {
  factory $MedicationLogCopyWith(MedicationLog value, $Res Function(MedicationLog) _then) = _$MedicationLogCopyWithImpl;
@useResult
$Res call({
 String id, String? birdId, String flockId, String medicationName, String? dosage, DateTime startDate, DateTime? endDate, int? withdrawalDays, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$MedicationLogCopyWithImpl<$Res>
    implements $MedicationLogCopyWith<$Res> {
  _$MedicationLogCopyWithImpl(this._self, this._then);

  final MedicationLog _self;
  final $Res Function(MedicationLog) _then;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? birdId = freezed,Object? flockId = null,Object? medicationName = null,Object? dosage = freezed,Object? startDate = null,Object? endDate = freezed,Object? withdrawalDays = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: freezed == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String?,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,withdrawalDays: freezed == withdrawalDays ? _self.withdrawalDays : withdrawalDays // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MedicationLog].
extension MedicationLogPatterns on MedicationLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedicationLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedicationLog value)  $default,){
final _that = this;
switch (_that) {
case _MedicationLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedicationLog value)?  $default,){
final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? birdId,  String flockId,  String medicationName,  String? dosage,  DateTime startDate,  DateTime? endDate,  int? withdrawalDays,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
return $default(_that.id,_that.birdId,_that.flockId,_that.medicationName,_that.dosage,_that.startDate,_that.endDate,_that.withdrawalDays,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? birdId,  String flockId,  String medicationName,  String? dosage,  DateTime startDate,  DateTime? endDate,  int? withdrawalDays,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MedicationLog():
return $default(_that.id,_that.birdId,_that.flockId,_that.medicationName,_that.dosage,_that.startDate,_that.endDate,_that.withdrawalDays,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? birdId,  String flockId,  String medicationName,  String? dosage,  DateTime startDate,  DateTime? endDate,  int? withdrawalDays,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MedicationLog() when $default != null:
return $default(_that.id,_that.birdId,_that.flockId,_that.medicationName,_that.dosage,_that.startDate,_that.endDate,_that.withdrawalDays,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _MedicationLog extends MedicationLog {
  const _MedicationLog({required this.id, this.birdId, required this.flockId, required this.medicationName, this.dosage, required this.startDate, this.endDate, this.withdrawalDays, this.notes, required this.createdAt}): super._();
  

@override final  String id;
@override final  String? birdId;
@override final  String flockId;
@override final  String medicationName;
@override final  String? dosage;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override final  int? withdrawalDays;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedicationLogCopyWith<_MedicationLog> get copyWith => __$MedicationLogCopyWithImpl<_MedicationLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedicationLog&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.medicationName, medicationName) || other.medicationName == medicationName)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.withdrawalDays, withdrawalDays) || other.withdrawalDays == withdrawalDays)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,flockId,medicationName,dosage,startDate,endDate,withdrawalDays,notes,createdAt);

@override
String toString() {
  return 'MedicationLog(id: $id, birdId: $birdId, flockId: $flockId, medicationName: $medicationName, dosage: $dosage, startDate: $startDate, endDate: $endDate, withdrawalDays: $withdrawalDays, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MedicationLogCopyWith<$Res> implements $MedicationLogCopyWith<$Res> {
  factory _$MedicationLogCopyWith(_MedicationLog value, $Res Function(_MedicationLog) _then) = __$MedicationLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String? birdId, String flockId, String medicationName, String? dosage, DateTime startDate, DateTime? endDate, int? withdrawalDays, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$MedicationLogCopyWithImpl<$Res>
    implements _$MedicationLogCopyWith<$Res> {
  __$MedicationLogCopyWithImpl(this._self, this._then);

  final _MedicationLog _self;
  final $Res Function(_MedicationLog) _then;

/// Create a copy of MedicationLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? birdId = freezed,Object? flockId = null,Object? medicationName = null,Object? dosage = freezed,Object? startDate = null,Object? endDate = freezed,Object? withdrawalDays = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_MedicationLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: freezed == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String?,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,medicationName: null == medicationName ? _self.medicationName : medicationName // ignore: cast_nullable_to_non_nullable
as String,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,withdrawalDays: freezed == withdrawalDays ? _self.withdrawalDays : withdrawalDays // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
