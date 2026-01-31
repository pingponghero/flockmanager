// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'egg_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EggLog {

 String get id; DateTime get date; String get flockId; String? get birdId; int get count; EggSize? get size; EggQuality? get quality; String? get notes; DateTime get createdAt;
/// Create a copy of EggLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EggLogCopyWith<EggLog> get copyWith => _$EggLogCopyWithImpl<EggLog>(this as EggLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EggLog&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.count, count) || other.count == count)&&(identical(other.size, size) || other.size == size)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,flockId,birdId,count,size,quality,notes,createdAt);

@override
String toString() {
  return 'EggLog(id: $id, date: $date, flockId: $flockId, birdId: $birdId, count: $count, size: $size, quality: $quality, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EggLogCopyWith<$Res>  {
  factory $EggLogCopyWith(EggLog value, $Res Function(EggLog) _then) = _$EggLogCopyWithImpl;
@useResult
$Res call({
 String id, DateTime date, String flockId, String? birdId, int count, EggSize? size, EggQuality? quality, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$EggLogCopyWithImpl<$Res>
    implements $EggLogCopyWith<$Res> {
  _$EggLogCopyWithImpl(this._self, this._then);

  final EggLog _self;
  final $Res Function(EggLog) _then;

/// Create a copy of EggLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? flockId = null,Object? birdId = freezed,Object? count = null,Object? size = freezed,Object? quality = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,birdId: freezed == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as EggSize?,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as EggQuality?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EggLog].
extension EggLogPatterns on EggLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EggLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EggLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EggLog value)  $default,){
final _that = this;
switch (_that) {
case _EggLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EggLog value)?  $default,){
final _that = this;
switch (_that) {
case _EggLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime date,  String flockId,  String? birdId,  int count,  EggSize? size,  EggQuality? quality,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EggLog() when $default != null:
return $default(_that.id,_that.date,_that.flockId,_that.birdId,_that.count,_that.size,_that.quality,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime date,  String flockId,  String? birdId,  int count,  EggSize? size,  EggQuality? quality,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EggLog():
return $default(_that.id,_that.date,_that.flockId,_that.birdId,_that.count,_that.size,_that.quality,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime date,  String flockId,  String? birdId,  int count,  EggSize? size,  EggQuality? quality,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EggLog() when $default != null:
return $default(_that.id,_that.date,_that.flockId,_that.birdId,_that.count,_that.size,_that.quality,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _EggLog extends EggLog {
  const _EggLog({required this.id, required this.date, required this.flockId, this.birdId, required this.count, this.size, this.quality, this.notes, required this.createdAt}): super._();
  

@override final  String id;
@override final  DateTime date;
@override final  String flockId;
@override final  String? birdId;
@override final  int count;
@override final  EggSize? size;
@override final  EggQuality? quality;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of EggLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EggLogCopyWith<_EggLog> get copyWith => __$EggLogCopyWithImpl<_EggLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EggLog&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.count, count) || other.count == count)&&(identical(other.size, size) || other.size == size)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,date,flockId,birdId,count,size,quality,notes,createdAt);

@override
String toString() {
  return 'EggLog(id: $id, date: $date, flockId: $flockId, birdId: $birdId, count: $count, size: $size, quality: $quality, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EggLogCopyWith<$Res> implements $EggLogCopyWith<$Res> {
  factory _$EggLogCopyWith(_EggLog value, $Res Function(_EggLog) _then) = __$EggLogCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime date, String flockId, String? birdId, int count, EggSize? size, EggQuality? quality, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$EggLogCopyWithImpl<$Res>
    implements _$EggLogCopyWith<$Res> {
  __$EggLogCopyWithImpl(this._self, this._then);

  final _EggLog _self;
  final $Res Function(_EggLog) _then;

/// Create a copy of EggLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? flockId = null,Object? birdId = freezed,Object? count = null,Object? size = freezed,Object? quality = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_EggLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,birdId: freezed == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as EggSize?,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as EggQuality?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
