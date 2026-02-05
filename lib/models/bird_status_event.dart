import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'bird_status_event.freezed.dart';

/// Represents a bird lifecycle event (added, status changed, deleted).
/// Events persist even after bird deletion to maintain accurate historical records.
@freezed
abstract class BirdStatusEvent with _$BirdStatusEvent {
  const BirdStatusEvent._();

  const factory BirdStatusEvent({
    required String id,
    required String birdId,
    required String flockId,
    /// Status: 'active', 'deceased', 'sold', 'givenAway', 'deleted'
    /// Using String instead of enum because 'deleted' isn't in BirdStatus
    required String status,
    required DateTime eventDate,
    String? notes,
    required DateTime createdAt,
  }) = _BirdStatusEvent;

  /// Create a new event with generated ID and timestamp
  factory BirdStatusEvent.create({
    required String birdId,
    required String flockId,
    required String status,
    required DateTime eventDate,
    String? notes,
  }) {
    return BirdStatusEvent(
      id: const Uuid().v4(),
      birdId: birdId,
      flockId: flockId,
      status: status,
      eventDate: eventDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory BirdStatusEvent.fromMap(Map<String, dynamic> map) {
    return BirdStatusEvent(
      id: map['id'] as String,
      birdId: map['bird_id'] as String,
      flockId: map['flock_id'] as String,
      status: map['status'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bird_id': birdId,
      'flock_id': flockId,
      'status': status,
      'event_date': eventDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
