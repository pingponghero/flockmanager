// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HealthNote {

 String get id; String get birdId; DateTime get date; HealthNoteType get type; String get description; DateTime get createdAt;
/// Create a copy of HealthNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthNoteCopyWith<HealthNote> get copyWith => _$HealthNoteCopyWithImpl<HealthNote>(this as HealthNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthNote&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,date,type,description,createdAt);

@override
String toString() {
  return 'HealthNote(id: $id, birdId: $birdId, date: $date, type: $type, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HealthNoteCopyWith<$Res>  {
  factory $HealthNoteCopyWith(HealthNote value, $Res Function(HealthNote) _then) = _$HealthNoteCopyWithImpl;
@useResult
$Res call({
 String id, String birdId, DateTime date, HealthNoteType type, String description, DateTime createdAt
});




}
/// @nodoc
class _$HealthNoteCopyWithImpl<$Res>
    implements $HealthNoteCopyWith<$Res> {
  _$HealthNoteCopyWithImpl(this._self, this._then);

  final HealthNote _self;
  final $Res Function(HealthNote) _then;

/// Create a copy of HealthNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? birdId = null,Object? date = null,Object? type = null,Object? description = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: null == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HealthNoteType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthNote].
extension HealthNotePatterns on HealthNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthNote value)  $default,){
final _that = this;
switch (_that) {
case _HealthNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthNote value)?  $default,){
final _that = this;
switch (_that) {
case _HealthNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String birdId,  DateTime date,  HealthNoteType type,  String description,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthNote() when $default != null:
return $default(_that.id,_that.birdId,_that.date,_that.type,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String birdId,  DateTime date,  HealthNoteType type,  String description,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _HealthNote():
return $default(_that.id,_that.birdId,_that.date,_that.type,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String birdId,  DateTime date,  HealthNoteType type,  String description,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HealthNote() when $default != null:
return $default(_that.id,_that.birdId,_that.date,_that.type,_that.description,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _HealthNote extends HealthNote {
  const _HealthNote({required this.id, required this.birdId, required this.date, required this.type, required this.description, required this.createdAt}): super._();
  

@override final  String id;
@override final  String birdId;
@override final  DateTime date;
@override final  HealthNoteType type;
@override final  String description;
@override final  DateTime createdAt;

/// Create a copy of HealthNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthNoteCopyWith<_HealthNote> get copyWith => __$HealthNoteCopyWithImpl<_HealthNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthNote&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,date,type,description,createdAt);

@override
String toString() {
  return 'HealthNote(id: $id, birdId: $birdId, date: $date, type: $type, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HealthNoteCopyWith<$Res> implements $HealthNoteCopyWith<$Res> {
  factory _$HealthNoteCopyWith(_HealthNote value, $Res Function(_HealthNote) _then) = __$HealthNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String birdId, DateTime date, HealthNoteType type, String description, DateTime createdAt
});




}
/// @nodoc
class __$HealthNoteCopyWithImpl<$Res>
    implements _$HealthNoteCopyWith<$Res> {
  __$HealthNoteCopyWithImpl(this._self, this._then);

  final _HealthNote _self;
  final $Res Function(_HealthNote) _then;

/// Create a copy of HealthNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? birdId = null,Object? date = null,Object? type = null,Object? description = null,Object? createdAt = null,}) {
  return _then(_HealthNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: null == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HealthNoteType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
