// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bird.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Bird {
  String get id => throw _privateConstructorUsedError;
  String get flockId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get breed => throw _privateConstructorUsedError;
  String? get breedId => throw _privateConstructorUsedError;
  String? get photoPrimary => throw _privateConstructorUsedError;
  DateTime? get hatchDate => throw _privateConstructorUsedError;
  DateTime? get acquiredDate => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  String? get eggColor => throw _privateConstructorUsedError;
  BirdStatus get status => throw _privateConstructorUsedError;
  DateTime? get statusDate => throw _privateConstructorUsedError;
  String? get statusNotes => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Bird
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BirdCopyWith<Bird> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BirdCopyWith<$Res> {
  factory $BirdCopyWith(Bird value, $Res Function(Bird) then) =
      _$BirdCopyWithImpl<$Res, Bird>;
  @useResult
  $Res call({
    String id,
    String flockId,
    String name,
    String? breed,
    String? breedId,
    String? photoPrimary,
    DateTime? hatchDate,
    DateTime? acquiredDate,
    String? source,
    String? eggColor,
    BirdStatus status,
    DateTime? statusDate,
    String? statusNotes,
    String? notes,
    DateTime createdAt,
  });
}

/// @nodoc
class _$BirdCopyWithImpl<$Res, $Val extends Bird>
    implements $BirdCopyWith<$Res> {
  _$BirdCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Bird
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? flockId = null,
    Object? name = null,
    Object? breed = freezed,
    Object? breedId = freezed,
    Object? photoPrimary = freezed,
    Object? hatchDate = freezed,
    Object? acquiredDate = freezed,
    Object? source = freezed,
    Object? eggColor = freezed,
    Object? status = null,
    Object? statusDate = freezed,
    Object? statusNotes = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            flockId: null == flockId
                ? _value.flockId
                : flockId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            breed: freezed == breed
                ? _value.breed
                : breed // ignore: cast_nullable_to_non_nullable
                      as String?,
            breedId: freezed == breedId
                ? _value.breedId
                : breedId // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoPrimary: freezed == photoPrimary
                ? _value.photoPrimary
                : photoPrimary // ignore: cast_nullable_to_non_nullable
                      as String?,
            hatchDate: freezed == hatchDate
                ? _value.hatchDate
                : hatchDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            acquiredDate: freezed == acquiredDate
                ? _value.acquiredDate
                : acquiredDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            eggColor: freezed == eggColor
                ? _value.eggColor
                : eggColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as BirdStatus,
            statusDate: freezed == statusDate
                ? _value.statusDate
                : statusDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            statusNotes: freezed == statusNotes
                ? _value.statusNotes
                : statusNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BirdImplCopyWith<$Res> implements $BirdCopyWith<$Res> {
  factory _$$BirdImplCopyWith(
    _$BirdImpl value,
    $Res Function(_$BirdImpl) then,
  ) = __$$BirdImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String flockId,
    String name,
    String? breed,
    String? breedId,
    String? photoPrimary,
    DateTime? hatchDate,
    DateTime? acquiredDate,
    String? source,
    String? eggColor,
    BirdStatus status,
    DateTime? statusDate,
    String? statusNotes,
    String? notes,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$BirdImplCopyWithImpl<$Res>
    extends _$BirdCopyWithImpl<$Res, _$BirdImpl>
    implements _$$BirdImplCopyWith<$Res> {
  __$$BirdImplCopyWithImpl(_$BirdImpl _value, $Res Function(_$BirdImpl) _then)
    : super(_value, _then);

  /// Create a copy of Bird
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? flockId = null,
    Object? name = null,
    Object? breed = freezed,
    Object? breedId = freezed,
    Object? photoPrimary = freezed,
    Object? hatchDate = freezed,
    Object? acquiredDate = freezed,
    Object? source = freezed,
    Object? eggColor = freezed,
    Object? status = null,
    Object? statusDate = freezed,
    Object? statusNotes = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$BirdImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        flockId: null == flockId
            ? _value.flockId
            : flockId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        breed: freezed == breed
            ? _value.breed
            : breed // ignore: cast_nullable_to_non_nullable
                  as String?,
        breedId: freezed == breedId
            ? _value.breedId
            : breedId // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoPrimary: freezed == photoPrimary
            ? _value.photoPrimary
            : photoPrimary // ignore: cast_nullable_to_non_nullable
                  as String?,
        hatchDate: freezed == hatchDate
            ? _value.hatchDate
            : hatchDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        acquiredDate: freezed == acquiredDate
            ? _value.acquiredDate
            : acquiredDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        eggColor: freezed == eggColor
            ? _value.eggColor
            : eggColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BirdStatus,
        statusDate: freezed == statusDate
            ? _value.statusDate
            : statusDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        statusNotes: freezed == statusNotes
            ? _value.statusNotes
            : statusNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$BirdImpl extends _Bird {
  const _$BirdImpl({
    required this.id,
    required this.flockId,
    required this.name,
    this.breed,
    this.breedId,
    this.photoPrimary,
    this.hatchDate,
    this.acquiredDate,
    this.source,
    this.eggColor,
    this.status = BirdStatus.active,
    this.statusDate,
    this.statusNotes,
    this.notes,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String flockId;
  @override
  final String name;
  @override
  final String? breed;
  @override
  final String? breedId;
  @override
  final String? photoPrimary;
  @override
  final DateTime? hatchDate;
  @override
  final DateTime? acquiredDate;
  @override
  final String? source;
  @override
  final String? eggColor;
  @override
  @JsonKey()
  final BirdStatus status;
  @override
  final DateTime? statusDate;
  @override
  final String? statusNotes;
  @override
  final String? notes;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Bird(id: $id, flockId: $flockId, name: $name, breed: $breed, breedId: $breedId, photoPrimary: $photoPrimary, hatchDate: $hatchDate, acquiredDate: $acquiredDate, source: $source, eggColor: $eggColor, status: $status, statusDate: $statusDate, statusNotes: $statusNotes, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BirdImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.flockId, flockId) || other.flockId == flockId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.breed, breed) || other.breed == breed) &&
            (identical(other.breedId, breedId) || other.breedId == breedId) &&
            (identical(other.photoPrimary, photoPrimary) ||
                other.photoPrimary == photoPrimary) &&
            (identical(other.hatchDate, hatchDate) ||
                other.hatchDate == hatchDate) &&
            (identical(other.acquiredDate, acquiredDate) ||
                other.acquiredDate == acquiredDate) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.eggColor, eggColor) ||
                other.eggColor == eggColor) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusDate, statusDate) ||
                other.statusDate == statusDate) &&
            (identical(other.statusNotes, statusNotes) ||
                other.statusNotes == statusNotes) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    flockId,
    name,
    breed,
    breedId,
    photoPrimary,
    hatchDate,
    acquiredDate,
    source,
    eggColor,
    status,
    statusDate,
    statusNotes,
    notes,
    createdAt,
  );

  /// Create a copy of Bird
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BirdImplCopyWith<_$BirdImpl> get copyWith =>
      __$$BirdImplCopyWithImpl<_$BirdImpl>(this, _$identity);
}

abstract class _Bird extends Bird {
  const factory _Bird({
    required final String id,
    required final String flockId,
    required final String name,
    final String? breed,
    final String? breedId,
    final String? photoPrimary,
    final DateTime? hatchDate,
    final DateTime? acquiredDate,
    final String? source,
    final String? eggColor,
    final BirdStatus status,
    final DateTime? statusDate,
    final String? statusNotes,
    final String? notes,
    required final DateTime createdAt,
  }) = _$BirdImpl;
  const _Bird._() : super._();

  @override
  String get id;
  @override
  String get flockId;
  @override
  String get name;
  @override
  String? get breed;
  @override
  String? get breedId;
  @override
  String? get photoPrimary;
  @override
  DateTime? get hatchDate;
  @override
  DateTime? get acquiredDate;
  @override
  String? get source;
  @override
  String? get eggColor;
  @override
  BirdStatus get status;
  @override
  DateTime? get statusDate;
  @override
  String? get statusNotes;
  @override
  String? get notes;
  @override
  DateTime get createdAt;

  /// Create a copy of Bird
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BirdImplCopyWith<_$BirdImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
