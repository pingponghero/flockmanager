// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'breed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Breed {

 String get id; String get name; String? get aka; String? get category; String? get eggColor; String? get eggSize; int? get eggsPerYear; String? get temperament; bool? get coldHardy; bool? get heatTolerant; String? get broodyTendency; String? get weight; String? get description;
/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreedCopyWith<Breed> get copyWith => _$BreedCopyWithImpl<Breed>(this as Breed, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Breed&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.aka, aka) || other.aka == aka)&&(identical(other.category, category) || other.category == category)&&(identical(other.eggColor, eggColor) || other.eggColor == eggColor)&&(identical(other.eggSize, eggSize) || other.eggSize == eggSize)&&(identical(other.eggsPerYear, eggsPerYear) || other.eggsPerYear == eggsPerYear)&&(identical(other.temperament, temperament) || other.temperament == temperament)&&(identical(other.coldHardy, coldHardy) || other.coldHardy == coldHardy)&&(identical(other.heatTolerant, heatTolerant) || other.heatTolerant == heatTolerant)&&(identical(other.broodyTendency, broodyTendency) || other.broodyTendency == broodyTendency)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,aka,category,eggColor,eggSize,eggsPerYear,temperament,coldHardy,heatTolerant,broodyTendency,weight,description);

@override
String toString() {
  return 'Breed(id: $id, name: $name, aka: $aka, category: $category, eggColor: $eggColor, eggSize: $eggSize, eggsPerYear: $eggsPerYear, temperament: $temperament, coldHardy: $coldHardy, heatTolerant: $heatTolerant, broodyTendency: $broodyTendency, weight: $weight, description: $description)';
}


}

/// @nodoc
abstract mixin class $BreedCopyWith<$Res>  {
  factory $BreedCopyWith(Breed value, $Res Function(Breed) _then) = _$BreedCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? aka, String? category, String? eggColor, String? eggSize, int? eggsPerYear, String? temperament, bool? coldHardy, bool? heatTolerant, String? broodyTendency, String? weight, String? description
});




}
/// @nodoc
class _$BreedCopyWithImpl<$Res>
    implements $BreedCopyWith<$Res> {
  _$BreedCopyWithImpl(this._self, this._then);

  final Breed _self;
  final $Res Function(Breed) _then;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? aka = freezed,Object? category = freezed,Object? eggColor = freezed,Object? eggSize = freezed,Object? eggsPerYear = freezed,Object? temperament = freezed,Object? coldHardy = freezed,Object? heatTolerant = freezed,Object? broodyTendency = freezed,Object? weight = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,aka: freezed == aka ? _self.aka : aka // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,eggColor: freezed == eggColor ? _self.eggColor : eggColor // ignore: cast_nullable_to_non_nullable
as String?,eggSize: freezed == eggSize ? _self.eggSize : eggSize // ignore: cast_nullable_to_non_nullable
as String?,eggsPerYear: freezed == eggsPerYear ? _self.eggsPerYear : eggsPerYear // ignore: cast_nullable_to_non_nullable
as int?,temperament: freezed == temperament ? _self.temperament : temperament // ignore: cast_nullable_to_non_nullable
as String?,coldHardy: freezed == coldHardy ? _self.coldHardy : coldHardy // ignore: cast_nullable_to_non_nullable
as bool?,heatTolerant: freezed == heatTolerant ? _self.heatTolerant : heatTolerant // ignore: cast_nullable_to_non_nullable
as bool?,broodyTendency: freezed == broodyTendency ? _self.broodyTendency : broodyTendency // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Breed].
extension BreedPatterns on Breed {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Breed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Breed() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Breed value)  $default,){
final _that = this;
switch (_that) {
case _Breed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Breed value)?  $default,){
final _that = this;
switch (_that) {
case _Breed() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? aka,  String? category,  String? eggColor,  String? eggSize,  int? eggsPerYear,  String? temperament,  bool? coldHardy,  bool? heatTolerant,  String? broodyTendency,  String? weight,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Breed() when $default != null:
return $default(_that.id,_that.name,_that.aka,_that.category,_that.eggColor,_that.eggSize,_that.eggsPerYear,_that.temperament,_that.coldHardy,_that.heatTolerant,_that.broodyTendency,_that.weight,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? aka,  String? category,  String? eggColor,  String? eggSize,  int? eggsPerYear,  String? temperament,  bool? coldHardy,  bool? heatTolerant,  String? broodyTendency,  String? weight,  String? description)  $default,) {final _that = this;
switch (_that) {
case _Breed():
return $default(_that.id,_that.name,_that.aka,_that.category,_that.eggColor,_that.eggSize,_that.eggsPerYear,_that.temperament,_that.coldHardy,_that.heatTolerant,_that.broodyTendency,_that.weight,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? aka,  String? category,  String? eggColor,  String? eggSize,  int? eggsPerYear,  String? temperament,  bool? coldHardy,  bool? heatTolerant,  String? broodyTendency,  String? weight,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _Breed() when $default != null:
return $default(_that.id,_that.name,_that.aka,_that.category,_that.eggColor,_that.eggSize,_that.eggsPerYear,_that.temperament,_that.coldHardy,_that.heatTolerant,_that.broodyTendency,_that.weight,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _Breed extends Breed {
  const _Breed({required this.id, required this.name, this.aka, this.category, this.eggColor, this.eggSize, this.eggsPerYear, this.temperament, this.coldHardy, this.heatTolerant, this.broodyTendency, this.weight, this.description}): super._();
  

@override final  String id;
@override final  String name;
@override final  String? aka;
@override final  String? category;
@override final  String? eggColor;
@override final  String? eggSize;
@override final  int? eggsPerYear;
@override final  String? temperament;
@override final  bool? coldHardy;
@override final  bool? heatTolerant;
@override final  String? broodyTendency;
@override final  String? weight;
@override final  String? description;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreedCopyWith<_Breed> get copyWith => __$BreedCopyWithImpl<_Breed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Breed&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.aka, aka) || other.aka == aka)&&(identical(other.category, category) || other.category == category)&&(identical(other.eggColor, eggColor) || other.eggColor == eggColor)&&(identical(other.eggSize, eggSize) || other.eggSize == eggSize)&&(identical(other.eggsPerYear, eggsPerYear) || other.eggsPerYear == eggsPerYear)&&(identical(other.temperament, temperament) || other.temperament == temperament)&&(identical(other.coldHardy, coldHardy) || other.coldHardy == coldHardy)&&(identical(other.heatTolerant, heatTolerant) || other.heatTolerant == heatTolerant)&&(identical(other.broodyTendency, broodyTendency) || other.broodyTendency == broodyTendency)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,aka,category,eggColor,eggSize,eggsPerYear,temperament,coldHardy,heatTolerant,broodyTendency,weight,description);

@override
String toString() {
  return 'Breed(id: $id, name: $name, aka: $aka, category: $category, eggColor: $eggColor, eggSize: $eggSize, eggsPerYear: $eggsPerYear, temperament: $temperament, coldHardy: $coldHardy, heatTolerant: $heatTolerant, broodyTendency: $broodyTendency, weight: $weight, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BreedCopyWith<$Res> implements $BreedCopyWith<$Res> {
  factory _$BreedCopyWith(_Breed value, $Res Function(_Breed) _then) = __$BreedCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? aka, String? category, String? eggColor, String? eggSize, int? eggsPerYear, String? temperament, bool? coldHardy, bool? heatTolerant, String? broodyTendency, String? weight, String? description
});




}
/// @nodoc
class __$BreedCopyWithImpl<$Res>
    implements _$BreedCopyWith<$Res> {
  __$BreedCopyWithImpl(this._self, this._then);

  final _Breed _self;
  final $Res Function(_Breed) _then;

/// Create a copy of Breed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? aka = freezed,Object? category = freezed,Object? eggColor = freezed,Object? eggSize = freezed,Object? eggsPerYear = freezed,Object? temperament = freezed,Object? coldHardy = freezed,Object? heatTolerant = freezed,Object? broodyTendency = freezed,Object? weight = freezed,Object? description = freezed,}) {
  return _then(_Breed(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,aka: freezed == aka ? _self.aka : aka // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,eggColor: freezed == eggColor ? _self.eggColor : eggColor // ignore: cast_nullable_to_non_nullable
as String?,eggSize: freezed == eggSize ? _self.eggSize : eggSize // ignore: cast_nullable_to_non_nullable
as String?,eggsPerYear: freezed == eggsPerYear ? _self.eggsPerYear : eggsPerYear // ignore: cast_nullable_to_non_nullable
as int?,temperament: freezed == temperament ? _self.temperament : temperament // ignore: cast_nullable_to_non_nullable
as String?,coldHardy: freezed == coldHardy ? _self.coldHardy : coldHardy // ignore: cast_nullable_to_non_nullable
as bool?,heatTolerant: freezed == heatTolerant ? _self.heatTolerant : heatTolerant // ignore: cast_nullable_to_non_nullable
as bool?,broodyTendency: freezed == broodyTendency ? _self.broodyTendency : broodyTendency // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
