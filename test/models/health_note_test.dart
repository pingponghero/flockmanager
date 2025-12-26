import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/health_note.dart';
import 'package:flock_manager/models/enums.dart';

void main() {
  group('HealthNote', () {
    test('create() generates unique ID and timestamp', () {
      final note = HealthNote.create(
        birdId: 'bird-123',
        date: DateTime(2024, 1, 15),
        type: HealthNoteType.observation,
        description: 'Bird seems healthy',
      );

      expect(note.id, isNotEmpty);
      expect(note.birdId, 'bird-123');
      expect(note.type, HealthNoteType.observation);
      expect(note.createdAt, isNotNull);
    });

    test('toMap() converts to SQLite-compatible map', () {
      final date = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 15, 9, 30);

      final note = HealthNote(
        id: 'note-123',
        birdId: 'bird-456',
        date: date,
        type: HealthNoteType.symptom,
        description: 'Sneezing observed',
        createdAt: createdAt,
      );

      final map = note.toMap();

      expect(map['id'], 'note-123');
      expect(map['bird_id'], 'bird-456');
      expect(map['type'], 'symptom');
      expect(map['description'], 'Sneezing observed');
    });

    test('fromMap() creates HealthNote from SQLite map', () {
      final map = {
        'id': 'note-456',
        'bird_id': 'bird-789',
        'date': '2024-06-20T00:00:00.000',
        'type': 'vetVisit',
        'description': 'Annual checkup',
        'created_at': '2024-06-20T10:00:00.000',
      };

      final note = HealthNote.fromMap(map);

      expect(note.id, 'note-456');
      expect(note.birdId, 'bird-789');
      expect(note.type, HealthNoteType.vetVisit);
      expect(note.description, 'Annual checkup');
    });

    test('fromMap() handles all health note types', () {
      final types = [
        ('observation', HealthNoteType.observation),
        ('symptom', HealthNoteType.symptom),
        ('treatment', HealthNoteType.treatment),
        ('vetVisit', HealthNoteType.vetVisit),
        ('other', HealthNoteType.other),
      ];

      for (final (typeString, expectedType) in types) {
        final map = {
          'id': 'note-$typeString',
          'bird_id': 'bird-123',
          'date': '2024-01-01T00:00:00.000',
          'type': typeString,
          'description': 'Test',
          'created_at': '2024-01-01T00:00:00.000',
        };

        final note = HealthNote.fromMap(map);
        expect(note.type, expectedType, reason: 'Failed for type: $typeString');
      }
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = HealthNote.create(
        birdId: 'bird-123',
        date: DateTime(2024, 3, 15),
        type: HealthNoteType.treatment,
        description: 'Applied wound care',
      );

      final map = original.toMap();
      final restored = HealthNote.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.birdId, original.birdId);
      expect(restored.type, original.type);
      expect(restored.description, original.description);
    });
  });
}
