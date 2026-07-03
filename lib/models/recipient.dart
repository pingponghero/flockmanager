import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'recipient.freezed.dart';

/// A person or business that receives egg sales or gifts.
/// Managed like the bird directory and selectable when recording
/// a sale or gift, enabling per-recipient statistics.
@freezed
abstract class Recipient with _$Recipient {
  const Recipient._();

  const factory Recipient({
    required String id,
    required String name,
    String? notes,
    required DateTime createdAt,
  }) = _Recipient;

  /// Create a new recipient with generated ID and timestamp
  factory Recipient.create({
    required String name,
    String? notes,
  }) {
    return Recipient(
      id: const Uuid().v4(),
      name: name,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory Recipient.fromMap(Map<String, dynamic> map) {
    return Recipient(
      id: map['id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
