import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';

void main() {
  group('Bird', () {
    test('create() generates unique ID and timestamp', () {
      final bird = Bird.create(
        flockId: 'flock-123',
        name: 'Henrietta',
      );

      expect(bird.id, isNotEmpty);
      expect(bird.flockId, 'flock-123');
      expect(bird.name, 'Henrietta');
      expect(bird.status, BirdStatus.active);
      expect(bird.createdAt, isNotNull);
    });

    test('create() with all optional fields', () {
      final hatchDate = DateTime(2023, 3, 15);
      final acquiredDate = DateTime(2023, 5, 1);

      final bird = Bird.create(
        flockId: 'flock-456',
        name: 'Goldie',
        breed: 'Buff Orpington',
        breedId: 'breed-123',
        photoPrimary: '/path/to/photo.jpg',
        hatchDate: hatchDate,
        acquiredDate: acquiredDate,
        source: 'Local farm',
        eggColor: 'Brown',
        notes: 'Very friendly',
      );

      expect(bird.breed, 'Buff Orpington');
      expect(bird.hatchDate, hatchDate);
      expect(bird.source, 'Local farm');
      expect(bird.eggColor, 'Brown');
    });

    test('toMap() converts to SQLite-compatible map', () {
      final now = DateTime(2024, 1, 15);
      final hatchDate = DateTime(2023, 6, 1);

      final bird = Bird(
        id: 'bird-123',
        flockId: 'flock-456',
        name: 'Clucky',
        breed: 'Rhode Island Red',
        hatchDate: hatchDate,
        status: BirdStatus.active,
        createdAt: now,
      );

      final map = bird.toMap();

      expect(map['id'], 'bird-123');
      expect(map['flock_id'], 'flock-456');
      expect(map['name'], 'Clucky');
      expect(map['breed'], 'Rhode Island Red');
      expect(map['hatch_date'], '2023-06-01T00:00:00.000');
      expect(map['status'], 'active');
    });

    test('fromMap() creates Bird from SQLite map', () {
      final map = {
        'id': 'bird-789',
        'flock_id': 'flock-123',
        'name': 'Pepper',
        'breed': 'Barred Rock',
        'breed_id': null,
        'photo_primary': null,
        'hatch_date': '2023-04-10T00:00:00.000',
        'acquired_date': null,
        'source': 'Hatchery',
        'egg_color': 'Brown',
        'status': 'active',
        'status_date': null,
        'status_notes': null,
        'notes': 'Good layer',
        'created_at': '2024-01-01T00:00:00.000',
      };

      final bird = Bird.fromMap(map);

      expect(bird.id, 'bird-789');
      expect(bird.name, 'Pepper');
      expect(bird.breed, 'Barred Rock');
      expect(bird.hatchDate, DateTime(2023, 4, 10));
      expect(bird.status, BirdStatus.active);
    });

    test('fromMap() handles deceased status', () {
      final map = {
        'id': 'bird-deceased',
        'flock_id': 'flock-123',
        'name': 'Old Hen',
        'status': 'deceased',
        'status_date': '2024-06-15T00:00:00.000',
        'status_notes': 'Natural causes',
        'created_at': '2022-01-01T00:00:00.000',
      };

      final bird = Bird.fromMap(map);

      expect(bird.status, BirdStatus.deceased);
      expect(bird.statusDate, DateTime(2024, 6, 15));
      expect(bird.statusNotes, 'Natural causes');
    });

    test('ageInDays calculates correctly', () {
      final bird = Bird(
        id: 'bird-age',
        flockId: 'flock-123',
        name: 'Young Hen',
        hatchDate: DateTime.now().subtract(const Duration(days: 100)),
        createdAt: DateTime.now(),
      );

      expect(bird.ageInDays, 100);
    });

    test('ageInWeeks calculates correctly', () {
      final bird = Bird(
        id: 'bird-age',
        flockId: 'flock-123',
        name: 'Young Hen',
        hatchDate: DateTime.now().subtract(const Duration(days: 21)),
        createdAt: DateTime.now(),
      );

      expect(bird.ageInWeeks, 3);
    });

    test('ageInDays returns null when hatchDate is null', () {
      final bird = Bird(
        id: 'bird-unknown-age',
        flockId: 'flock-123',
        name: 'Unknown Age',
        createdAt: DateTime.now(),
      );

      expect(bird.ageInDays, isNull);
      expect(bird.ageInWeeks, isNull);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = Bird.create(
        flockId: 'flock-123',
        name: 'Roundtrip Bird',
        breed: 'Leghorn',
        hatchDate: DateTime(2023, 1, 1),
        eggColor: 'White',
      );

      final map = original.toMap();
      final restored = Bird.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.breed, original.breed);
      expect(restored.eggColor, original.eggColor);
    });
  });
}
