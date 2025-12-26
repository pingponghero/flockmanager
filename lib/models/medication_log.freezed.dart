// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medication_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MedicationLog {
  String get id => throw _privateConstructorUsedError;
  String? get birdId => throw _privateConstructorUsedError;
  String get flockId => throw _privateConstructorUsedError;
  String get medicationName => throw _privateConstructorUsedError;
  String? get dosage => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  int? get withdrawalDays => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of MedicationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicationLogCopyWith<MedicationLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicationLogCopyWith<$Res> {
  factory $MedicationLogCopyWith(
    MedicationLog value,
    $Res Function(MedicationLog) then,
  ) = _$MedicationLogCopyWithImpl<$Res, MedicationLog>;
  @useResult
  $Res call({
    String id,
    String? birdId,
    String flockId,
    String medicationName,
    String? dosage,
    DateTime startDate,
    DateTime? endDate,
    int? withdrawalDays,
    String? notes,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MedicationLogCopyWithImpl<$Res, $Val extends MedicationLog>
    implements $MedicationLogCopyWith<$Res> {
  _$MedicationLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? birdId = freezed,
    Object? flockId = null,
    Object? medicationName = null,
    Object? dosage = freezed,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? withdrawalDays = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            birdId: freezed == birdId
                ? _value.birdId
                : birdId // ignore: cast_nullable_to_non_nullable
                      as String?,
            flockId: null == flockId
                ? _value.flockId
                : flockId // ignore: cast_nullable_to_non_nullable
                      as String,
            medicationName: null == medicationName
                ? _value.medicationName
                : medicationName // ignore: cast_nullable_to_non_nullable
                      as String,
            dosage: freezed == dosage
                ? _value.dosage
                : dosage // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            withdrawalDays: freezed == withdrawalDays
                ? _value.withdrawalDays
                : withdrawalDays // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$MedicationLogImplCopyWith<$Res>
    implements $MedicationLogCopyWith<$Res> {
  factory _$$MedicationLogImplCopyWith(
    _$MedicationLogImpl value,
    $Res Function(_$MedicationLogImpl) then,
  ) = __$$MedicationLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? birdId,
    String flockId,
    String medicationName,
    String? dosage,
    DateTime startDate,
    DateTime? endDate,
    int? withdrawalDays,
    String? notes,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MedicationLogImplCopyWithImpl<$Res>
    extends _$MedicationLogCopyWithImpl<$Res, _$MedicationLogImpl>
    implements _$$MedicationLogImplCopyWith<$Res> {
  __$$MedicationLogImplCopyWithImpl(
    _$MedicationLogImpl _value,
    $Res Function(_$MedicationLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? birdId = freezed,
    Object? flockId = null,
    Object? medicationName = null,
    Object? dosage = freezed,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? withdrawalDays = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$MedicationLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        birdId: freezed == birdId
            ? _value.birdId
            : birdId // ignore: cast_nullable_to_non_nullable
                  as String?,
        flockId: null == flockId
            ? _value.flockId
            : flockId // ignore: cast_nullable_to_non_nullable
                  as String,
        medicationName: null == medicationName
            ? _value.medicationName
            : medicationName // ignore: cast_nullable_to_non_nullable
                  as String,
        dosage: freezed == dosage
            ? _value.dosage
            : dosage // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        withdrawalDays: freezed == withdrawalDays
            ? _value.withdrawalDays
            : withdrawalDays // ignore: cast_nullable_to_non_nullable
                  as int?,
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

class _$MedicationLogImpl extends _MedicationLog {
  const _$MedicationLogImpl({
    required this.id,
    this.birdId,
    required this.flockId,
    required this.medicationName,
    this.dosage,
    required this.startDate,
    this.endDate,
    this.withdrawalDays,
    this.notes,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String? birdId;
  @override
  final String flockId;
  @override
  final String medicationName;
  @override
  final String? dosage;
  @override
  final DateTime startDate;
  @override
  final DateTime? endDate;
  @override
  final int? withdrawalDays;
  @override
  final String? notes;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'MedicationLog(id: $id, birdId: $birdId, flockId: $flockId, medicationName: $medicationName, dosage: $dosage, startDate: $startDate, endDate: $endDate, withdrawalDays: $withdrawalDays, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicationLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.birdId, birdId) || other.birdId == birdId) &&
            (identical(other.flockId, flockId) || other.flockId == flockId) &&
            (identical(other.medicationName, medicationName) ||
                other.medicationName == medicationName) &&
            (identical(other.dosage, dosage) || other.dosage == dosage) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.withdrawalDays, withdrawalDays) ||
                other.withdrawalDays == withdrawalDays) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    birdId,
    flockId,
    medicationName,
    dosage,
    startDate,
    endDate,
    withdrawalDays,
    notes,
    createdAt,
  );

  /// Create a copy of MedicationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicationLogImplCopyWith<_$MedicationLogImpl> get copyWith =>
      __$$MedicationLogImplCopyWithImpl<_$MedicationLogImpl>(this, _$identity);
}

abstract class _MedicationLog extends MedicationLog {
  const factory _MedicationLog({
    required final String id,
    final String? birdId,
    required final String flockId,
    required final String medicationName,
    final String? dosage,
    required final DateTime startDate,
    final DateTime? endDate,
    final int? withdrawalDays,
    final String? notes,
    required final DateTime createdAt,
  }) = _$MedicationLogImpl;
  const _MedicationLog._() : super._();

  @override
  String get id;
  @override
  String? get birdId;
  @override
  String get flockId;
  @override
  String get medicationName;
  @override
  String? get dosage;
  @override
  DateTime get startDate;
  @override
  DateTime? get endDate;
  @override
  int? get withdrawalDays;
  @override
  String? get notes;
  @override
  DateTime get createdAt;

  /// Create a copy of MedicationLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicationLogImplCopyWith<_$MedicationLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
