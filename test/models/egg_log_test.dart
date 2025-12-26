import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/models/enums.dart';

void main() {
  group('EggLog', () {
    test('create() generates unique ID and timestamp', () {
      final log = EggLog.create(
        date: DateTime(2024, 1, 15),
        flockId: 'flock-123',
        count: 5,
      );

      expect(log.id, isNotEmpty);
      expect(log.flockId, 'flock-123');
      expect(log.count, 5);
      expect(log.createdAt, isNotNull);
    });

    test('create() with all optional fields', () {
      final log = EggLog.create(
        date: DateTime(2024, 1, 15),
        flockId: 'flock-123',
        birdId: 'bird-456',
        count: 1,
        size: EggSize.large,
        quality: EggQuality.doubleYolk,
        notes: 'Double yolk from Henrietta!',
      );

      expect(log.birdId, 'bird-456');
      expect(log.size, EggSize.large);
      expect(log.quality, EggQuality.doubleYolk);
      expect(log.notes, 'Double yolk from Henrietta!');
    });

    test('toMap() converts to SQLite-compatible map', () {
      final date = DateTime(2024, 1, 15);
      final createdAt = DateTime(2024, 1, 15, 18, 30);

      final log = EggLog(
        id: 'log-123',
        date: date,
        flockId: 'flock-456',
        birdId: 'bird-789',
        count: 3,
        size: EggSize.medium,
        quality: EggQuality.normal,
        notes: 'Good eggs',
        createdAt: createdAt,
      );

      final map = log.toMap();

      expect(map['id'], 'log-123');
      expect(map['date'], '2024-01-15T00:00:00.000');
      expect(map['flock_id'], 'flock-456');
      expect(map['bird_id'], 'bird-789');
      expect(map['count'], 3);
      expect(map['size'], 'medium');
      expect(map['quality'], 'normal');
    });

    test('fromMap() creates EggLog from SQLite map', () {
      final map = {
        'id': 'log-456',
        'date': '2024-06-20T00:00:00.000',
        'flock_id': 'flock-123',
        'bird_id': null,
        'count': 7,
        'size': 'large',
        'quality': 'normal',
        'notes': null,
        'created_at': '2024-06-20T08:00:00.000',
      };

      final log = EggLog.fromMap(map);

      expect(log.id, 'log-456');
      expect(log.date, DateTime(2024, 6, 20));
      expect(log.count, 7);
      expect(log.size, EggSize.large);
      expect(log.quality, EggQuality.normal);
      expect(log.birdId, isNull);
    });

    test('fromMap() handles null size and quality', () {
      final map = {
        'id': 'log-789',
        'date': '2024-01-01T00:00:00.000',
        'flock_id': 'flock-123',
        'bird_id': null,
        'count': 4,
        'size': null,
        'quality': null,
        'notes': null,
        'created_at': '2024-01-01T00:00:00.000',
      };

      final log = EggLog.fromMap(map);

      expect(log.size, isNull);
      expect(log.quality, isNull);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = EggLog.create(
        date: DateTime(2024, 3, 15),
        flockId: 'flock-123',
        birdId: 'bird-456',
        count: 2,
        size: EggSize.jumbo,
        quality: EggQuality.softShell,
        notes: 'Soft shell egg',
      );

      final map = original.toMap();
      final restored = EggLog.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.count, original.count);
      expect(restored.size, original.size);
      expect(restored.quality, original.quality);
    });
  });
}
