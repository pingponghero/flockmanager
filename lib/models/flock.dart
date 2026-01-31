import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'flock.freezed.dart';

@freezed
abstract class Flock with _$Flock {
  const Flock._();

  const factory Flock({
    required String id,
    required String name,
    String? description,
    String? icon,
    String? color,
    @Default(false) bool isArchived,
    required DateTime createdAt,
  }) = _Flock;

  /// Create a new flock with generated ID and timestamp
  factory Flock.create({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) {
    return Flock(
      id: const Uuid().v4(),
      name: name,
      description: description,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory Flock.fromMap(Map<String, dynamic> map) {
    return Flock(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
