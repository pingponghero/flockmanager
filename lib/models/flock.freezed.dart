// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Flock {

 String get id; String get name; String? get description; String? get icon; String? get color; bool get isArchived; DateTime get createdAt;
/// Create a copy of Flock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlockCopyWith<Flock> get copyWith => _$FlockCopyWithImpl<Flock>(this as Flock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Flock&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,isArchived,createdAt);

@override
String toString() {
  return 'Flock(id: $id, name: $name, description: $description, icon: $icon, color: $color, isArchived: $isArchived, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FlockCopyWith<$Res>  {
  factory $FlockCopyWith(Flock value, $Res Function(Flock) _then) = _$FlockCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? icon, String? color, bool isArchived, DateTime createdAt
});




}
/// @nodoc
class _$FlockCopyWithImpl<$Res>
    implements $FlockCopyWith<$Res> {
  _$FlockCopyWithImpl(this._self, this._then);

  final Flock _self;
  final $Res Function(Flock) _then;

/// Create a copy of Flock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? isArchived = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Flock].
extension FlockPatterns on Flock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Flock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Flock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Flock value)  $default,){
final _that = this;
switch (_that) {
case _Flock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Flock value)?  $default,){
final _that = this;
switch (_that) {
case _Flock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? icon,  String? color,  bool isArchived,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Flock() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.isArchived,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? icon,  String? color,  bool isArchived,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Flock():
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.isArchived,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? icon,  String? color,  bool isArchived,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Flock() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.color,_that.isArchived,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Flock extends Flock {
  const _Flock({required this.id, required this.name, this.description, this.icon, this.color, this.isArchived = false, required this.createdAt}): super._();
  

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String? icon;
@override final  String? color;
@override@JsonKey() final  bool isArchived;
@override final  DateTime createdAt;

/// Create a copy of Flock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlockCopyWith<_Flock> get copyWith => __$FlockCopyWithImpl<_Flock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Flock&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,color,isArchived,createdAt);

@override
String toString() {
  return 'Flock(id: $id, name: $name, description: $description, icon: $icon, color: $color, isArchived: $isArchived, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FlockCopyWith<$Res> implements $FlockCopyWith<$Res> {
  factory _$FlockCopyWith(_Flock value, $Res Function(_Flock) _then) = __$FlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? icon, String? color, bool isArchived, DateTime createdAt
});




}
/// @nodoc
class __$FlockCopyWithImpl<$Res>
    implements _$FlockCopyWith<$Res> {
  __$FlockCopyWithImpl(this._self, this._then);

  final _Flock _self;
  final $Res Function(_Flock) _then;

/// Create a copy of Flock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? isArchived = null,Object? createdAt = null,}) {
  return _then(_Flock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
