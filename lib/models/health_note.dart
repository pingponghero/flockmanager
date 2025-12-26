import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'enums.dart';

part 'health_note.freezed.dart';

@freezed
class HealthNote with _$HealthNote {
  const HealthNote._();

  const factory HealthNote({
    required String id,
    required String birdId,
    required DateTime date,
    required HealthNoteType type,
    required String description,
    required DateTime createdAt,
  }) = _HealthNote;

  /// Create a new health note with generated ID and timestamp
  factory HealthNote.create({
    required String birdId,
    required DateTime date,
    required HealthNoteType type,
    required String description,
  }) {
    return HealthNote(
      id: const Uuid().v4(),
      birdId: birdId,
      date: date,
      type: type,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory HealthNote.fromMap(Map<String, dynamic> map) {
    return HealthNote(
      id: map['id'] as String,
      birdId: map['bird_id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: HealthNoteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HealthNoteType.other,
      ),
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bird_id': birdId,
      'date': date.toIso8601String(),
      'type': type.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
