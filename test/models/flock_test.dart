import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/flock.dart';

void main() {
  group('Flock', () {
    test('create() generates unique ID and timestamp', () {
      final flock = Flock.create(name: 'Test Flock');

      expect(flock.id, isNotEmpty);
      expect(flock.name, 'Test Flock');
      expect(flock.isArchived, false);
      expect(flock.createdAt, isNotNull);
    });

    test('create() with all optional fields', () {
      final flock = Flock.create(
        name: 'Backyard Flock',
        description: 'My chickens',
        icon: 'chicken',
        color: '#FF0000',
      );

      expect(flock.name, 'Backyard Flock');
      expect(flock.description, 'My chickens');
      expect(flock.icon, 'chicken');
      expect(flock.color, '#FF0000');
    });

    test('toMap() converts to SQLite-compatible map', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final flock = Flock(
        id: 'test-id-123',
        name: 'Test Flock',
        description: 'A test',
        icon: 'egg',
        color: '#00FF00',
        isArchived: true,
        createdAt: now,
      );

      final map = flock.toMap();

      expect(map['id'], 'test-id-123');
      expect(map['name'], 'Test Flock');
      expect(map['description'], 'A test');
      expect(map['icon'], 'egg');
      expect(map['color'], '#00FF00');
      expect(map['is_archived'], 1);
      expect(map['created_at'], '2024-01-15T10:30:00.000');
    });

    test('fromMap() creates Flock from SQLite map', () {
      final map = {
        'id': 'flock-456',
        'name': 'Farm Flock',
        'description': 'Farm chickens',
        'icon': 'barn',
        'color': '#0000FF',
        'is_archived': 0,
        'created_at': '2024-06-20T14:00:00.000',
      };

      final flock = Flock.fromMap(map);

      expect(flock.id, 'flock-456');
      expect(flock.name, 'Farm Flock');
      expect(flock.description, 'Farm chickens');
      expect(flock.icon, 'barn');
      expect(flock.color, '#0000FF');
      expect(flock.isArchived, false);
      expect(flock.createdAt, DateTime(2024, 6, 20, 14, 0));
    });

    test('fromMap() handles null optional fields', () {
      final map = {
        'id': 'flock-789',
        'name': 'Minimal Flock',
        'description': null,
        'icon': null,
        'color': null,
        'is_archived': null,
        'created_at': '2024-01-01T00:00:00.000',
      };

      final flock = Flock.fromMap(map);

      expect(flock.name, 'Minimal Flock');
      expect(flock.description, isNull);
      expect(flock.icon, isNull);
      expect(flock.color, isNull);
      expect(flock.isArchived, false);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = Flock.create(
        name: 'Roundtrip Flock',
        description: 'Testing roundtrip',
        icon: 'test',
        color: '#AABBCC',
      );

      final map = original.toMap();
      final restored = Flock.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.isArchived, original.isArchived);
    });

    test('copyWith creates modified copy', () {
      final flock = Flock.create(name: 'Original');
      final archived = flock.copyWith(isArchived: true);

      expect(flock.isArchived, false);
      expect(archived.isArchived, true);
      expect(archived.id, flock.id);
      expect(archived.name, flock.name);
    });
  });
}
