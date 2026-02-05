// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bird_status_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BirdStatusEvent {

 String get id; String get birdId; String get flockId;/// Status: 'active', 'deceased', 'sold', 'givenAway', 'deleted'
/// Using String instead of enum because 'deleted' isn't in BirdStatus
 String get status; DateTime get eventDate; String? get notes; DateTime get createdAt;
/// Create a copy of BirdStatusEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BirdStatusEventCopyWith<BirdStatusEvent> get copyWith => _$BirdStatusEventCopyWithImpl<BirdStatusEvent>(this as BirdStatusEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BirdStatusEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.status, status) || other.status == status)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,flockId,status,eventDate,notes,createdAt);

@override
String toString() {
  return 'BirdStatusEvent(id: $id, birdId: $birdId, flockId: $flockId, status: $status, eventDate: $eventDate, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BirdStatusEventCopyWith<$Res>  {
  factory $BirdStatusEventCopyWith(BirdStatusEvent value, $Res Function(BirdStatusEvent) _then) = _$BirdStatusEventCopyWithImpl;
@useResult
$Res call({
 String id, String birdId, String flockId, String status, DateTime eventDate, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$BirdStatusEventCopyWithImpl<$Res>
    implements $BirdStatusEventCopyWith<$Res> {
  _$BirdStatusEventCopyWithImpl(this._self, this._then);

  final BirdStatusEvent _self;
  final $Res Function(BirdStatusEvent) _then;

/// Create a copy of BirdStatusEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? birdId = null,Object? flockId = null,Object? status = null,Object? eventDate = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: null == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BirdStatusEvent].
extension BirdStatusEventPatterns on BirdStatusEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BirdStatusEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BirdStatusEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BirdStatusEvent value)  $default,){
final _that = this;
switch (_that) {
case _BirdStatusEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BirdStatusEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BirdStatusEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String birdId,  String flockId,  String status,  DateTime eventDate,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BirdStatusEvent() when $default != null:
return $default(_that.id,_that.birdId,_that.flockId,_that.status,_that.eventDate,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String birdId,  String flockId,  String status,  DateTime eventDate,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BirdStatusEvent():
return $default(_that.id,_that.birdId,_that.flockId,_that.status,_that.eventDate,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String birdId,  String flockId,  String status,  DateTime eventDate,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BirdStatusEvent() when $default != null:
return $default(_that.id,_that.birdId,_that.flockId,_that.status,_that.eventDate,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _BirdStatusEvent extends BirdStatusEvent {
  const _BirdStatusEvent({required this.id, required this.birdId, required this.flockId, required this.status, required this.eventDate, this.notes, required this.createdAt}): super._();
  

@override final  String id;
@override final  String birdId;
@override final  String flockId;
/// Status: 'active', 'deceased', 'sold', 'givenAway', 'deleted'
/// Using String instead of enum because 'deleted' isn't in BirdStatus
@override final  String status;
@override final  DateTime eventDate;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of BirdStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BirdStatusEventCopyWith<_BirdStatusEvent> get copyWith => __$BirdStatusEventCopyWithImpl<_BirdStatusEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BirdStatusEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.birdId, birdId) || other.birdId == birdId)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.status, status) || other.status == status)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,birdId,flockId,status,eventDate,notes,createdAt);

@override
String toString() {
  return 'BirdStatusEvent(id: $id, birdId: $birdId, flockId: $flockId, status: $status, eventDate: $eventDate, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BirdStatusEventCopyWith<$Res> implements $BirdStatusEventCopyWith<$Res> {
  factory _$BirdStatusEventCopyWith(_BirdStatusEvent value, $Res Function(_BirdStatusEvent) _then) = __$BirdStatusEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String birdId, String flockId, String status, DateTime eventDate, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$BirdStatusEventCopyWithImpl<$Res>
    implements _$BirdStatusEventCopyWith<$Res> {
  __$BirdStatusEventCopyWithImpl(this._self, this._then);

  final _BirdStatusEvent _self;
  final $Res Function(_BirdStatusEvent) _then;

/// Create a copy of BirdStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? birdId = null,Object? flockId = null,Object? status = null,Object? eventDate = null,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_BirdStatusEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,birdId: null == birdId ? _self.birdId : birdId // ignore: cast_nullable_to_non_nullable
as String,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
