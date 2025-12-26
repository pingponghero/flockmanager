// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$HealthNote {
  String get id => throw _privateConstructorUsedError;
  String get birdId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  HealthNoteType get type => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of HealthNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthNoteCopyWith<HealthNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthNoteCopyWith<$Res> {
  factory $HealthNoteCopyWith(
    HealthNote value,
    $Res Function(HealthNote) then,
  ) = _$HealthNoteCopyWithImpl<$Res, HealthNote>;
  @useResult
  $Res call({
    String id,
    String birdId,
    DateTime date,
    HealthNoteType type,
    String description,
    DateTime createdAt,
  });
}

/// @nodoc
class _$HealthNoteCopyWithImpl<$Res, $Val extends HealthNote>
    implements $HealthNoteCopyWith<$Res> {
  _$HealthNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? birdId = null,
    Object? date = null,
    Object? type = null,
    Object? description = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            birdId: null == birdId
                ? _value.birdId
                : birdId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as HealthNoteType,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$HealthNoteImplCopyWith<$Res>
    implements $HealthNoteCopyWith<$Res> {
  factory _$$HealthNoteImplCopyWith(
    _$HealthNoteImpl value,
    $Res Function(_$HealthNoteImpl) then,
  ) = __$$HealthNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String birdId,
    DateTime date,
    HealthNoteType type,
    String description,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$HealthNoteImplCopyWithImpl<$Res>
    extends _$HealthNoteCopyWithImpl<$Res, _$HealthNoteImpl>
    implements _$$HealthNoteImplCopyWith<$Res> {
  __$$HealthNoteImplCopyWithImpl(
    _$HealthNoteImpl _value,
    $Res Function(_$HealthNoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HealthNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? birdId = null,
    Object? date = null,
    Object? type = null,
    Object? description = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$HealthNoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        birdId: null == birdId
            ? _value.birdId
            : birdId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as HealthNoteType,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$HealthNoteImpl extends _HealthNote {
  const _$HealthNoteImpl({
    required this.id,
    required this.birdId,
    required this.date,
    required this.type,
    required this.description,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String birdId;
  @override
  final DateTime date;
  @override
  final HealthNoteType type;
  @override
  final String description;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'HealthNote(id: $id, birdId: $birdId, date: $date, type: $type, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.birdId, birdId) || other.birdId == birdId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, birdId, date, type, description, createdAt);

  /// Create a copy of HealthNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthNoteImplCopyWith<_$HealthNoteImpl> get copyWith =>
      __$$HealthNoteImplCopyWithImpl<_$HealthNoteImpl>(this, _$identity);
}

abstract class _HealthNote extends HealthNote {
  const factory _HealthNote({
    required final String id,
    required final String birdId,
    required final DateTime date,
    required final HealthNoteType type,
    required final String description,
    required final DateTime createdAt,
  }) = _$HealthNoteImpl;
  const _HealthNote._() : super._();

  @override
  String get id;
  @override
  String get birdId;
  @override
  DateTime get date;
  @override
  HealthNoteType get type;
  @override
  String get description;
  @override
  DateTime get createdAt;

  /// Create a copy of HealthNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthNoteImplCopyWith<_$HealthNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
