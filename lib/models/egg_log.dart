import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'enums.dart';

part 'egg_log.freezed.dart';

@freezed
class EggLog with _$EggLog {
  const EggLog._();

  const factory EggLog({
    required String id,
    required DateTime date,
    required String flockId,
    String? birdId,
    required int count,
    EggSize? size,
    EggQuality? quality,
    String? notes,
    required DateTime createdAt,
  }) = _EggLog;

  /// Create a new egg log with generated ID and timestamp
  factory EggLog.create({
    required DateTime date,
    required String flockId,
    String? birdId,
    required int count,
    EggSize? size,
    EggQuality? quality,
    String? notes,
  }) {
    return EggLog(
      id: const Uuid().v4(),
      date: date,
      flockId: flockId,
      birdId: birdId,
      count: count,
      size: size,
      quality: quality,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory EggLog.fromMap(Map<String, dynamic> map) {
    return EggLog(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      flockId: map['flock_id'] as String,
      birdId: map['bird_id'] as String?,
      count: map['count'] as int,
      size: map['size'] != null
          ? EggSize.values.firstWhere(
              (e) => e.name == map['size'],
              orElse: () => EggSize.medium,
            )
          : null,
      quality: map['quality'] != null
          ? EggQuality.values.firstWhere(
              (e) => e.name == map['quality'],
              orElse: () => EggQuality.normal,
            )
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'flock_id': flockId,
      'bird_id': birdId,
      'count': count,
      'size': size?.name,
      'quality': quality?.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
