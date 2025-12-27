import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/flock.dart';
import 'package:flock_manager/repositories/flock_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late FlockRepository repository;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    repository = FlockRepository(db: mockDbHelper);
  });

  group('FlockRepository', () {
    group('getAllFlocks', () {
      test('returns non-archived flocks by default', () async {
        final flockMaps = [
          {
            'id': 'flock-1',
            'name': 'Backyard Flock',
            'description': 'Our main flock',
            'icon': null,
            'color': null,
            'is_archived': 0,
            'created_at': '2024-01-01T00:00:00.000',
          },
          {
            'id': 'flock-2',
            'name': 'Front Yard',
            'description': null,
            'icon': null,
            'color': null,
            'is_archived': 0,
            'created_at': '2024-02-01T00:00:00.000',
          },
        ];

        when(() => mockDatabase.query(
              'flocks',
              where: 'is_archived = ?',
              whereArgs: [0],
              orderBy: 'created_at DESC',
            )).thenAnswer((_) async => flockMaps);

        final flocks = await repository.getAllFlocks();

        expect(flocks.length, 2);
        expect(flocks[0].name, 'Backyard Flock');
        expect(flocks[1].name, 'Front Yard');
        verify(() => mockDatabase.query(
              'flocks',
              where: 'is_archived = ?',
              whereArgs: [0],
              orderBy: 'created_at DESC',
            )).called(1);
      });

      test('includes archived flocks when requested', () async {
        final flockMaps = [
          {
            'id': 'flock-1',
            'name': 'Active Flock',
            'is_archived': 0,
            'created_at': '2024-01-01T00:00:00.000',
          },
          {
            'id': 'flock-2',
            'name': 'Archived Flock',
            'is_archived': 1,
            'created_at': '2023-01-01T00:00:00.000',
          },
        ];

        when(() => mockDatabase.query(
              'flocks',
              orderBy: 'created_at DESC',
            )).thenAnswer((_) async => flockMaps);

        final flocks = await repository.getAllFlocks(includeArchived: true);

        expect(flocks.length, 2);
        verify(() => mockDatabase.query(
              'flocks',
              orderBy: 'created_at DESC',
            )).called(1);
      });

      test('returns empty list when no flocks exist', () async {
        when(() => mockDatabase.query(
              'flocks',
              where: 'is_archived = ?',
              whereArgs: [0],
              orderBy: 'created_at DESC',
            )).thenAnswer((_) async => []);

        final flocks = await repository.getAllFlocks();

        expect(flocks, isEmpty);
      });
    });

    group('getFlockById', () {
      test('returns flock when found', () async {
        final flockMap = {
          'id': 'flock-123',
          'name': 'Test Flock',
          'description': 'A test flock',
          'icon': 'egg',
          'color': '#FF5733',
          'is_archived': 0,
          'created_at': '2024-01-15T10:30:00.000',
        };

        when(() => mockDatabase.query(
              'flocks',
              where: 'id = ?',
              whereArgs: ['flock-123'],
              limit: 1,
            )).thenAnswer((_) async => [flockMap]);

        final flock = await repository.getFlockById('flock-123');

        expect(flock, isNotNull);
        expect(flock!.id, 'flock-123');
        expect(flock.name, 'Test Flock');
        expect(flock.description, 'A test flock');
      });

      test('returns null when flock not found', () async {
        when(() => mockDatabase.query(
              'flocks',
              where: 'id = ?',
              whereArgs: ['nonexistent'],
              limit: 1,
            )).thenAnswer((_) async => []);

        final flock = await repository.getFlockById('nonexistent');

        expect(flock, isNull);
      });
    });

    group('insertFlock', () {
      test('inserts flock into database', () async {
        final flock = Flock.create(name: 'New Flock');

        when(() => mockDatabase.insert('flocks', any()))
            .thenAnswer((_) async => 1);

        await repository.insertFlock(flock);

        verify(() => mockDatabase.insert('flocks', any())).called(1);
      });
    });

    group('updateFlock', () {
      test('updates existing flock', () async {
        final flock = Flock(
          id: 'flock-123',
          name: 'Updated Name',
          description: 'Updated description',
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockDatabase.update(
              'flocks',
              any(),
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).thenAnswer((_) async => 1);

        await repository.updateFlock(flock);

        verify(() => mockDatabase.update(
              'flocks',
              any(),
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).called(1);
      });
    });

    group('archiveFlock', () {
      test('sets is_archived to 1', () async {
        when(() => mockDatabase.update(
              'flocks',
              {'is_archived': 1},
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).thenAnswer((_) async => 1);

        await repository.archiveFlock('flock-123');

        verify(() => mockDatabase.update(
              'flocks',
              {'is_archived': 1},
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).called(1);
      });
    });

    group('unarchiveFlock', () {
      test('sets is_archived to 0', () async {
        when(() => mockDatabase.update(
              'flocks',
              {'is_archived': 0},
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).thenAnswer((_) async => 1);

        await repository.unarchiveFlock('flock-123');

        verify(() => mockDatabase.update(
              'flocks',
              {'is_archived': 0},
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).called(1);
      });
    });

    group('deleteFlock', () {
      test('deletes flock from database', () async {
        when(() => mockDatabase.delete(
              'flocks',
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).thenAnswer((_) async => 1);

        await repository.deleteFlock('flock-123');

        verify(() => mockDatabase.delete(
              'flocks',
              where: 'id = ?',
              whereArgs: ['flock-123'],
            )).called(1);
      });
    });

    group('getBirdCount', () {
      test('returns count of active birds in flock', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM birds WHERE flock_id = ? AND status = ?',
              ['flock-123', 'active'],
            )).thenAnswer((_) async => [
              {'count': 5}
            ]);

        final count = await repository.getBirdCount('flock-123');

        expect(count, 5);
      });

      test('returns 0 when no birds in flock', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM birds WHERE flock_id = ? AND status = ?',
              ['empty-flock', 'active'],
            )).thenAnswer((_) async => [
              {'count': 0}
            ]);

        final count = await repository.getBirdCount('empty-flock');

        expect(count, 0);
      });
    });
  });
}
