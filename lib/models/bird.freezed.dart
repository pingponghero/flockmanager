// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bird.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Bird {

 String get id; String get flockId; String get name; String? get breed; String? get breedId; String? get photoPrimary; DateTime? get hatchDate; DateTime? get acquiredDate; String? get source; String? get eggColor; BirdSex get sex; BirdSpecies get species; BirdStatus get status; DateTime? get statusDate; String? get statusNotes; String? get notes; DateTime get createdAt;
/// Create a copy of Bird
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BirdCopyWith<Bird> get copyWith => _$BirdCopyWithImpl<Bird>(this as Bird, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bird&&(identical(other.id, id) || other.id == id)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.name, name) || other.name == name)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.breedId, breedId) || other.breedId == breedId)&&(identical(other.photoPrimary, photoPrimary) || other.photoPrimary == photoPrimary)&&(identical(other.hatchDate, hatchDate) || other.hatchDate == hatchDate)&&(identical(other.acquiredDate, acquiredDate) || other.acquiredDate == acquiredDate)&&(identical(other.source, source) || other.source == source)&&(identical(other.eggColor, eggColor) || other.eggColor == eggColor)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.species, species) || other.species == species)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusDate, statusDate) || other.statusDate == statusDate)&&(identical(other.statusNotes, statusNotes) || other.statusNotes == statusNotes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,flockId,name,breed,breedId,photoPrimary,hatchDate,acquiredDate,source,eggColor,sex,species,status,statusDate,statusNotes,notes,createdAt);

@override
String toString() {
  return 'Bird(id: $id, flockId: $flockId, name: $name, breed: $breed, breedId: $breedId, photoPrimary: $photoPrimary, hatchDate: $hatchDate, acquiredDate: $acquiredDate, source: $source, eggColor: $eggColor, sex: $sex, species: $species, status: $status, statusDate: $statusDate, statusNotes: $statusNotes, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BirdCopyWith<$Res>  {
  factory $BirdCopyWith(Bird value, $Res Function(Bird) _then) = _$BirdCopyWithImpl;
@useResult
$Res call({
 String id, String flockId, String name, String? breed, String? breedId, String? photoPrimary, DateTime? hatchDate, DateTime? acquiredDate, String? source, String? eggColor, BirdSex sex, BirdSpecies species, BirdStatus status, DateTime? statusDate, String? statusNotes, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$BirdCopyWithImpl<$Res>
    implements $BirdCopyWith<$Res> {
  _$BirdCopyWithImpl(this._self, this._then);

  final Bird _self;
  final $Res Function(Bird) _then;

/// Create a copy of Bird
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? flockId = null,Object? name = null,Object? breed = freezed,Object? breedId = freezed,Object? photoPrimary = freezed,Object? hatchDate = freezed,Object? acquiredDate = freezed,Object? source = freezed,Object? eggColor = freezed,Object? sex = null,Object? species = null,Object? status = null,Object? statusDate = freezed,Object? statusNotes = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,breedId: freezed == breedId ? _self.breedId : breedId // ignore: cast_nullable_to_non_nullable
as String?,photoPrimary: freezed == photoPrimary ? _self.photoPrimary : photoPrimary // ignore: cast_nullable_to_non_nullable
as String?,hatchDate: freezed == hatchDate ? _self.hatchDate : hatchDate // ignore: cast_nullable_to_non_nullable
as DateTime?,acquiredDate: freezed == acquiredDate ? _self.acquiredDate : acquiredDate // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,eggColor: freezed == eggColor ? _self.eggColor : eggColor // ignore: cast_nullable_to_non_nullable
as String?,sex: null == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as BirdSex,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as BirdSpecies,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BirdStatus,statusDate: freezed == statusDate ? _self.statusDate : statusDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statusNotes: freezed == statusNotes ? _self.statusNotes : statusNotes // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Bird].
extension BirdPatterns on Bird {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bird value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bird() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bird value)  $default,){
final _that = this;
switch (_that) {
case _Bird():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bird value)?  $default,){
final _that = this;
switch (_that) {
case _Bird() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String flockId,  String name,  String? breed,  String? breedId,  String? photoPrimary,  DateTime? hatchDate,  DateTime? acquiredDate,  String? source,  String? eggColor,  BirdSex sex,  BirdSpecies species,  BirdStatus status,  DateTime? statusDate,  String? statusNotes,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bird() when $default != null:
return $default(_that.id,_that.flockId,_that.name,_that.breed,_that.breedId,_that.photoPrimary,_that.hatchDate,_that.acquiredDate,_that.source,_that.eggColor,_that.sex,_that.species,_that.status,_that.statusDate,_that.statusNotes,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String flockId,  String name,  String? breed,  String? breedId,  String? photoPrimary,  DateTime? hatchDate,  DateTime? acquiredDate,  String? source,  String? eggColor,  BirdSex sex,  BirdSpecies species,  BirdStatus status,  DateTime? statusDate,  String? statusNotes,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Bird():
return $default(_that.id,_that.flockId,_that.name,_that.breed,_that.breedId,_that.photoPrimary,_that.hatchDate,_that.acquiredDate,_that.source,_that.eggColor,_that.sex,_that.species,_that.status,_that.statusDate,_that.statusNotes,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String flockId,  String name,  String? breed,  String? breedId,  String? photoPrimary,  DateTime? hatchDate,  DateTime? acquiredDate,  String? source,  String? eggColor,  BirdSex sex,  BirdSpecies species,  BirdStatus status,  DateTime? statusDate,  String? statusNotes,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Bird() when $default != null:
return $default(_that.id,_that.flockId,_that.name,_that.breed,_that.breedId,_that.photoPrimary,_that.hatchDate,_that.acquiredDate,_that.source,_that.eggColor,_that.sex,_that.species,_that.status,_that.statusDate,_that.statusNotes,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Bird extends Bird {
  const _Bird({required this.id, required this.flockId, required this.name, this.breed, this.breedId, this.photoPrimary, this.hatchDate, this.acquiredDate, this.source, this.eggColor, this.sex = BirdSex.female, this.species = BirdSpecies.chicken, this.status = BirdStatus.active, this.statusDate, this.statusNotes, this.notes, required this.createdAt}): super._();
  

@override final  String id;
@override final  String flockId;
@override final  String name;
@override final  String? breed;
@override final  String? breedId;
@override final  String? photoPrimary;
@override final  DateTime? hatchDate;
@override final  DateTime? acquiredDate;
@override final  String? source;
@override final  String? eggColor;
@override@JsonKey() final  BirdSex sex;
@override@JsonKey() final  BirdSpecies species;
@override@JsonKey() final  BirdStatus status;
@override final  DateTime? statusDate;
@override final  String? statusNotes;
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of Bird
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BirdCopyWith<_Bird> get copyWith => __$BirdCopyWithImpl<_Bird>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bird&&(identical(other.id, id) || other.id == id)&&(identical(other.flockId, flockId) || other.flockId == flockId)&&(identical(other.name, name) || other.name == name)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.breedId, breedId) || other.breedId == breedId)&&(identical(other.photoPrimary, photoPrimary) || other.photoPrimary == photoPrimary)&&(identical(other.hatchDate, hatchDate) || other.hatchDate == hatchDate)&&(identical(other.acquiredDate, acquiredDate) || other.acquiredDate == acquiredDate)&&(identical(other.source, source) || other.source == source)&&(identical(other.eggColor, eggColor) || other.eggColor == eggColor)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.species, species) || other.species == species)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusDate, statusDate) || other.statusDate == statusDate)&&(identical(other.statusNotes, statusNotes) || other.statusNotes == statusNotes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,flockId,name,breed,breedId,photoPrimary,hatchDate,acquiredDate,source,eggColor,sex,species,status,statusDate,statusNotes,notes,createdAt);

@override
String toString() {
  return 'Bird(id: $id, flockId: $flockId, name: $name, breed: $breed, breedId: $breedId, photoPrimary: $photoPrimary, hatchDate: $hatchDate, acquiredDate: $acquiredDate, source: $source, eggColor: $eggColor, sex: $sex, species: $species, status: $status, statusDate: $statusDate, statusNotes: $statusNotes, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BirdCopyWith<$Res> implements $BirdCopyWith<$Res> {
  factory _$BirdCopyWith(_Bird value, $Res Function(_Bird) _then) = __$BirdCopyWithImpl;
@override @useResult
$Res call({
 String id, String flockId, String name, String? breed, String? breedId, String? photoPrimary, DateTime? hatchDate, DateTime? acquiredDate, String? source, String? eggColor, BirdSex sex, BirdSpecies species, BirdStatus status, DateTime? statusDate, String? statusNotes, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$BirdCopyWithImpl<$Res>
    implements _$BirdCopyWith<$Res> {
  __$BirdCopyWithImpl(this._self, this._then);

  final _Bird _self;
  final $Res Function(_Bird) _then;

/// Create a copy of Bird
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? flockId = null,Object? name = null,Object? breed = freezed,Object? breedId = freezed,Object? photoPrimary = freezed,Object? hatchDate = freezed,Object? acquiredDate = freezed,Object? source = freezed,Object? eggColor = freezed,Object? sex = null,Object? species = null,Object? status = null,Object? statusDate = freezed,Object? statusNotes = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_Bird(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,flockId: null == flockId ? _self.flockId : flockId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,breedId: freezed == breedId ? _self.breedId : breedId // ignore: cast_nullable_to_non_nullable
as String?,photoPrimary: freezed == photoPrimary ? _self.photoPrimary : photoPrimary // ignore: cast_nullable_to_non_nullable
as String?,hatchDate: freezed == hatchDate ? _self.hatchDate : hatchDate // ignore: cast_nullable_to_non_nullable
as DateTime?,acquiredDate: freezed == acquiredDate ? _self.acquiredDate : acquiredDate // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,eggColor: freezed == eggColor ? _self.eggColor : eggColor // ignore: cast_nullable_to_non_nullable
as String?,sex: null == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as BirdSex,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as BirdSpecies,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BirdStatus,statusDate: freezed == statusDate ? _self.statusDate : statusDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statusNotes: freezed == statusNotes ? _self.statusNotes : statusNotes // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
