import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/bird_status_event.dart';

void main() {
  group('BirdStatusEvent', () {
    test('create() generates unique ID and timestamp', () {
      final event = BirdStatusEvent.create(
        birdId: 'bird-123',
        flockId: 'flock-456',
        status: 'active',
        eventDate: DateTime(2024, 1, 15),
      );

      expect(event.id, isNotEmpty);
      expect(event.birdId, 'bird-123');
      expect(event.flockId, 'flock-456');
      expect(event.status, 'active');
      expect(event.eventDate, DateTime(2024, 1, 15));
      expect(event.createdAt, isNotNull);
    });

    test('create() with notes', () {
      final event = BirdStatusEvent.create(
        birdId: 'bird-123',
        flockId: 'flock-456',
        status: 'deceased',
        eventDate: DateTime(2024, 6, 15),
        notes: 'Predator attack',
      );

      expect(event.status, 'deceased');
      expect(event.notes, 'Predator attack');
    });

    test('toMap() converts to SQLite-compatible map', () {
      final eventDate = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 15, 10, 30);

      final event = BirdStatusEvent(
        id: 'event-123',
        birdId: 'bird-456',
        flockId: 'flock-789',
        status: 'sold',
        eventDate: eventDate,
        notes: 'Sold to neighbor',
        createdAt: createdAt,
      );

      final map = event.toMap();

      expect(map['id'], 'event-123');
      expect(map['bird_id'], 'bird-456');
      expect(map['flock_id'], 'flock-789');
      expect(map['status'], 'sold');
      expect(map['event_date'], '2024-01-15T00:00:00.000');
      expect(map['notes'], 'Sold to neighbor');
      expect(map['created_at'], '2024-01-15T10:30:00.000');
    });

    test('fromMap() creates BirdStatusEvent from SQLite map', () {
      final map = {
        'id': 'event-789',
        'bird_id': 'bird-123',
        'flock_id': 'flock-456',
        'status': 'givenAway',
        'event_date': '2024-03-20T00:00:00.000',
        'notes': 'Given to friend',
        'created_at': '2024-03-20T14:00:00.000',
      };

      final event = BirdStatusEvent.fromMap(map);

      expect(event.id, 'event-789');
      expect(event.birdId, 'bird-123');
      expect(event.flockId, 'flock-456');
      expect(event.status, 'givenAway');
      expect(event.eventDate, DateTime(2024, 3, 20));
      expect(event.notes, 'Given to friend');
      expect(event.createdAt, DateTime(2024, 3, 20, 14, 0));
    });

    test('fromMap() handles null notes', () {
      final map = {
        'id': 'event-123',
        'bird_id': 'bird-456',
        'flock_id': 'flock-789',
        'status': 'active',
        'event_date': '2024-01-01T00:00:00.000',
        'notes': null,
        'created_at': '2024-01-01T00:00:00.000',
      };

      final event = BirdStatusEvent.fromMap(map);

      expect(event.notes, isNull);
    });

    test('handles deleted status (not in BirdStatus enum)', () {
      final event = BirdStatusEvent.create(
        birdId: 'bird-123',
        flockId: 'flock-456',
        status: 'deleted',
        eventDate: DateTime(2024, 4, 1),
      );

      expect(event.status, 'deleted');

      final map = event.toMap();
      expect(map['status'], 'deleted');

      final restored = BirdStatusEvent.fromMap(map);
      expect(restored.status, 'deleted');
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = BirdStatusEvent.create(
        birdId: 'bird-roundtrip',
        flockId: 'flock-roundtrip',
        status: 'deceased',
        eventDate: DateTime(2024, 5, 10),
        notes: 'Natural causes',
      );

      final map = original.toMap();
      final restored = BirdStatusEvent.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.birdId, original.birdId);
      expect(restored.flockId, original.flockId);
      expect(restored.status, original.status);
      expect(restored.eventDate, original.eventDate);
      expect(restored.notes, original.notes);
    });
  });
}
