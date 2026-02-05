import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/repositories/bird_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late BirdRepository repository;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    repository = BirdRepository(db: mockDbHelper);
  });

  group('BirdRepository', () {
    final testBirdMap = {
      'id': 'bird-1',
      'flock_id': 'flock-1',
      'name': 'Henrietta',
      'breed': 'Rhode Island Red',
      'breed_id': null,
      'photo_primary': null,
      'hatch_date': '2023-03-15T00:00:00.000',
      'acquired_date': null,
      'source': 'Hatchery',
      'egg_color': 'Brown',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Very friendly',
      'created_at': '2024-01-01T00:00:00.000',
    };

    group('getAllBirds', () {
      test('returns all birds ordered by name', () async {
        final birdMaps = [
          {...testBirdMap, 'id': 'bird-1', 'name': 'Alice'},
          {...testBirdMap, 'id': 'bird-2', 'name': 'Bella'},
        ];

        when(() => mockDatabase.query(
              'birds',
              orderBy: 'name ASC',
            )).thenAnswer((_) async => birdMaps);

        final birds = await repository.getAllBirds();

        expect(birds.length, 2);
        expect(birds[0].name, 'Alice');
        expect(birds[1].name, 'Bella');
      });

      test('returns empty list when no birds', () async {
        when(() => mockDatabase.query(
              'birds',
              orderBy: 'name ASC',
            )).thenAnswer((_) async => []);

        final birds = await repository.getAllBirds();

        expect(birds, isEmpty);
      });
    });

    group('getBirdsByFlock', () {
      test('returns birds for specific flock', () async {
        final birdMaps = [testBirdMap];

        when(() => mockDatabase.query(
              'birds',
              where: 'flock_id = ?',
              whereArgs: ['flock-1'],
              orderBy: 'name ASC',
            )).thenAnswer((_) async => birdMaps);

        final birds = await repository.getBirdsByFlock('flock-1');

        expect(birds.length, 1);
        expect(birds[0].flockId, 'flock-1');
      });
    });

    group('getActiveBirds', () {
      test('returns only active birds', () async {
        final birdMaps = [testBirdMap];

        when(() => mockDatabase.query(
              'birds',
              where: 'status = ?',
              whereArgs: ['active'],
              orderBy: 'name ASC',
            )).thenAnswer((_) async => birdMaps);

        final birds = await repository.getActiveBirds();

        expect(birds.length, 1);
        expect(birds[0].status, BirdStatus.active);
      });
    });

    group('getActiveBirdsByFlock', () {
      test('returns active birds for specific flock', () async {
        final birdMaps = [testBirdMap];

        when(() => mockDatabase.query(
              'birds',
              where: 'flock_id = ? AND status = ?',
              whereArgs: ['flock-1', 'active'],
              orderBy: 'name ASC',
            )).thenAnswer((_) async => birdMaps);

        final birds = await repository.getActiveBirdsByFlock('flock-1');

        expect(birds.length, 1);
        expect(birds[0].flockId, 'flock-1');
        expect(birds[0].status, BirdStatus.active);
      });
    });

    group('getBirdsByStatus', () {
      test('returns birds with specified status', () async {
        final deceasedBirdMap = {...testBirdMap, 'status': 'deceased'};

        when(() => mockDatabase.query(
              'birds',
              where: 'status = ?',
              whereArgs: ['deceased'],
              orderBy: 'name ASC',
            )).thenAnswer((_) async => [deceasedBirdMap]);

        final birds = await repository.getBirdsByStatus(BirdStatus.deceased);

        expect(birds.length, 1);
        expect(birds[0].status, BirdStatus.deceased);
      });
    });

    group('getBirdById', () {
      test('returns bird when found', () async {
        when(() => mockDatabase.query(
              'birds',
              where: 'id = ?',
              whereArgs: ['bird-1'],
              limit: 1,
            )).thenAnswer((_) async => [testBirdMap]);

        final bird = await repository.getBirdById('bird-1');

        expect(bird, isNotNull);
        expect(bird!.id, 'bird-1');
        expect(bird.name, 'Henrietta');
      });

      test('returns null when not found', () async {
        when(() => mockDatabase.query(
              'birds',
              where: 'id = ?',
              whereArgs: ['nonexistent'],
              limit: 1,
            )).thenAnswer((_) async => []);

        final bird = await repository.getBirdById('nonexistent');

        expect(bird, isNull);
      });
    });

    group('insertBird', () {
      test('inserts bird into database', () async {
        final bird = Bird.create(flockId: 'flock-1', name: 'New Bird');

        when(() => mockDatabase.insert('birds', any()))
            .thenAnswer((_) async => 1);

        await repository.insertBird(bird);

        verify(() => mockDatabase.insert('birds', any())).called(1);
      });
    });

    group('updateBird', () {
      test('updates existing bird', () async {
        final bird = Bird(
          id: 'bird-1',
          flockId: 'flock-1',
          name: 'Updated Name',
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockDatabase.update(
              'birds',
              any(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).thenAnswer((_) async => 1);

        await repository.updateBird(bird);

        verify(() => mockDatabase.update(
              'birds',
              any(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).called(1);
      });
    });

    group('updateBirdStatus', () {
      test('updates status with notes', () async {
        when(() => mockDatabase.update(
              'birds',
              any(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).thenAnswer((_) async => 1);

        await repository.updateBirdStatus(
          'bird-1',
          BirdStatus.deceased,
          'Natural causes',
        );

        final captured = verify(() => mockDatabase.update(
              'birds',
              captureAny(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).captured;

        final updateData = captured.first as Map<String, dynamic>;
        expect(updateData['status'], 'deceased');
        expect(updateData['status_notes'], 'Natural causes');
        expect(updateData['status_date'], isNotNull);
      });

      test('updates status without notes', () async {
        when(() => mockDatabase.update(
              'birds',
              any(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).thenAnswer((_) async => 1);

        await repository.updateBirdStatus('bird-1', BirdStatus.sold, null);

        final captured = verify(() => mockDatabase.update(
              'birds',
              captureAny(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).captured;

        final updateData = captured.first as Map<String, dynamic>;
        expect(updateData['status'], 'sold');
        expect(updateData['status_notes'], isNull);
      });

      test('updates status with custom event date', () async {
        when(() => mockDatabase.update(
              'birds',
              any(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).thenAnswer((_) async => 1);

        final customDate = DateTime(2024, 3, 15);
        await repository.updateBirdStatus(
          'bird-1',
          BirdStatus.deceased,
          'Natural causes',
          customDate,
        );

        final captured = verify(() => mockDatabase.update(
              'birds',
              captureAny(),
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).captured;

        final updateData = captured.first as Map<String, dynamic>;
        expect(updateData['status'], 'deceased');
        expect(updateData['status_date'], '2024-03-15T00:00:00.000');
      });
    });

    group('deleteBird', () {
      test('deletes bird from database', () async {
        when(() => mockDatabase.delete(
              'birds',
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).thenAnswer((_) async => 1);

        await repository.deleteBird('bird-1');

        verify(() => mockDatabase.delete(
              'birds',
              where: 'id = ?',
              whereArgs: ['bird-1'],
            )).called(1);
      });
    });

    group('getBirdCountsByStatus', () {
      test('returns count map for all statuses in flock', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              ['flock-1'],
            )).thenAnswer((_) async => [
              {'status': 'active', 'count': 5},
              {'status': 'deceased', 'count': 2},
              {'status': 'sold', 'count': 1},
            ]);

        final counts = await repository.getBirdCountsByStatus('flock-1');

        expect(counts[BirdStatus.active], 5);
        expect(counts[BirdStatus.deceased], 2);
        expect(counts[BirdStatus.sold], 1);
      });

      test('returns empty map when no birds', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              ['empty-flock'],
            )).thenAnswer((_) async => []);

        final counts = await repository.getBirdCountsByStatus('empty-flock');

        expect(counts, isEmpty);
      });
    });
  });
}
