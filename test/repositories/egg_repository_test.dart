import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/repositories/egg_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late EggRepository repository;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    repository = EggRepository(db: mockDbHelper);
  });

  group('EggRepository', () {
    final testEggLogMap = {
      'id': 'egg-1',
      'date': '2024-06-15T00:00:00.000',
      'flock_id': 'flock-1',
      'bird_id': null,
      'count': 3,
      'size': 'large',
      'quality': 'normal',
      'notes': null,
      'created_at': '2024-06-15T08:00:00.000',
    };

    group('getAllEggLogs', () {
      test('returns all egg logs ordered by date descending', () async {
        final eggMaps = [
          {...testEggLogMap, 'id': 'egg-1', 'date': '2024-06-15T00:00:00.000'},
          {...testEggLogMap, 'id': 'egg-2', 'date': '2024-06-14T00:00:00.000'},
        ];

        when(() => mockDatabase.query(
              'egg_logs',
              orderBy: 'date DESC, created_at DESC',
            )).thenAnswer((_) async => eggMaps);

        final logs = await repository.getAllEggLogs();

        expect(logs.length, 2);
        expect(logs[0].id, 'egg-1');
      });

      test('returns empty list when no logs', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              orderBy: 'date DESC, created_at DESC',
            )).thenAnswer((_) async => []);

        final logs = await repository.getAllEggLogs();

        expect(logs, isEmpty);
      });
    });

    group('getEggLogsByDate', () {
      test('returns logs for specific date', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              where: 'date(date) = date(?)',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'created_at DESC',
            )).thenAnswer((_) async => [testEggLogMap]);

        final logs = await repository.getEggLogsByDate(DateTime(2024, 6, 15));

        expect(logs.length, 1);
        expect(logs[0].count, 3);
      });
    });

    group('getEggLogsByDateRange', () {
      test('returns logs within date range', () async {
        final eggMaps = [testEggLogMap];

        when(() => mockDatabase.query(
              'egg_logs',
              where: 'date >= ? AND date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'date DESC, created_at DESC',
            )).thenAnswer((_) async => eggMaps);

        final logs = await repository.getEggLogsByDateRange(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 30),
        );

        expect(logs.length, 1);
      });
    });

    group('getEggLogsByFlock', () {
      test('returns logs for specific flock', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              where: 'flock_id = ?',
              whereArgs: ['flock-1'],
              orderBy: 'date DESC, created_at DESC',
            )).thenAnswer((_) async => [testEggLogMap]);

        final logs = await repository.getEggLogsByFlock('flock-1');

        expect(logs.length, 1);
        expect(logs[0].flockId, 'flock-1');
      });
    });

    group('getEggLogsByBird', () {
      test('returns logs for specific bird', () async {
        final birdEggMap = {...testEggLogMap, 'bird_id': 'bird-1'};

        when(() => mockDatabase.query(
              'egg_logs',
              where: 'bird_id = ?',
              whereArgs: ['bird-1'],
              orderBy: 'date DESC, created_at DESC',
            )).thenAnswer((_) async => [birdEggMap]);

        final logs = await repository.getEggLogsByBird('bird-1');

        expect(logs.length, 1);
        expect(logs[0].birdId, 'bird-1');
      });
    });

    group('getEggLogById', () {
      test('returns log when found', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              where: 'id = ?',
              whereArgs: ['egg-1'],
              limit: 1,
            )).thenAnswer((_) async => [testEggLogMap]);

        final log = await repository.getEggLogById('egg-1');

        expect(log, isNotNull);
        expect(log!.id, 'egg-1');
        expect(log.count, 3);
      });

      test('returns null when not found', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              where: 'id = ?',
              whereArgs: ['nonexistent'],
              limit: 1,
            )).thenAnswer((_) async => []);

        final log = await repository.getEggLogById('nonexistent');

        expect(log, isNull);
      });
    });

    group('insertEggLog', () {
      test('inserts log into database', () async {
        final log = EggLog.create(
          date: DateTime(2024, 6, 15),
          flockId: 'flock-1',
          count: 5,
        );

        when(() => mockDatabase.insert('egg_logs', any()))
            .thenAnswer((_) async => 1);

        await repository.insertEggLog(log);

        verify(() => mockDatabase.insert('egg_logs', any())).called(1);
      });
    });

    group('updateEggLog', () {
      test('updates existing log', () async {
        final log = EggLog(
          id: 'egg-1',
          date: DateTime(2024, 6, 15),
          flockId: 'flock-1',
          count: 7,
          createdAt: DateTime.now(),
        );

        when(() => mockDatabase.update(
              'egg_logs',
              any(),
              where: 'id = ?',
              whereArgs: ['egg-1'],
            )).thenAnswer((_) async => 1);

        await repository.updateEggLog(log);

        verify(() => mockDatabase.update(
              'egg_logs',
              any(),
              where: 'id = ?',
              whereArgs: ['egg-1'],
            )).called(1);
      });
    });

    group('deleteEggLog', () {
      test('deletes log from database', () async {
        when(() => mockDatabase.delete(
              'egg_logs',
              where: 'id = ?',
              whereArgs: ['egg-1'],
            )).thenAnswer((_) async => 1);

        await repository.deleteEggLog('egg-1');

        verify(() => mockDatabase.delete(
              'egg_logs',
              where: 'id = ?',
              whereArgs: ['egg-1'],
            )).called(1);
      });
    });

    group('getTotalEggCount', () {
      test('returns total eggs across all logs', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs',
            )).thenAnswer((_) async => [
              {'total': 150}
            ]);

        final count = await repository.getTotalEggCount();

        expect(count, 150);
      });

      test('returns 0 when no logs', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs',
            )).thenAnswer((_) async => [
              {'total': 0}
            ]);

        final count = await repository.getTotalEggCount();

        expect(count, 0);
      });
    });

    group('getTotalEggCountByFlock', () {
      test('returns total for specific flock', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE flock_id = ?',
              ['flock-1'],
            )).thenAnswer((_) async => [
              {'total': 75}
            ]);

        final count = await repository.getTotalEggCountByFlock('flock-1');

        expect(count, 75);
      });
    });

    group('getTotalEggCountByBird', () {
      test('returns total for specific bird', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE bird_id = ?',
              ['bird-1'],
            )).thenAnswer((_) async => [
              {'total': 25}
            ]);

        final count = await repository.getTotalEggCountByBird('bird-1');

        expect(count, 25);
      });
    });

    group('getEggCountByDateRange', () {
      test('returns count within date range', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE date >= ? AND date <= ?',
              any(),
            )).thenAnswer((_) async => [
              {'total': 42}
            ]);

        final count = await repository.getEggCountByDateRange(
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 30),
        );

        expect(count, 42);
      });
    });

    group('getEggCountByFlockAndDateRange', () {
      test('returns count for flock within date range', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE flock_id = ? AND date >= ? AND date <= ?',
              any(),
            )).thenAnswer((_) async => [
              {'total': 28}
            ]);

        final count = await repository.getEggCountByFlockAndDateRange(
          'flock-1',
          DateTime(2024, 6, 1),
          DateTime(2024, 6, 30),
        );

        expect(count, 28);
      });
    });

    group('getDailyEggCounts', () {
      test('returns map of daily counts', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              any(),
            )).thenAnswer((_) async => [
              {'day': '2024-06-15', 'total': 5},
              {'day': '2024-06-16', 'total': 3},
              {'day': '2024-06-17', 'total': 7},
            ]);

        final counts = await repository.getDailyEggCounts(
          DateTime(2024, 6, 15),
          DateTime(2024, 6, 17),
        );

        expect(counts.length, 3);
        expect(counts[DateTime(2024, 6, 15)], 5);
        expect(counts[DateTime(2024, 6, 16)], 3);
        expect(counts[DateTime(2024, 6, 17)], 7);
      });

      test('returns empty map when no logs', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              any(),
            )).thenAnswer((_) async => []);

        final counts = await repository.getDailyEggCounts(
          DateTime(2024, 6, 15),
          DateTime(2024, 6, 17),
        );

        expect(counts, isEmpty);
      });
    });

    group('getLastLoggedFlockId', () {
      test('returns most recent flock ID', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              columns: ['flock_id'],
              orderBy: 'created_at DESC',
              limit: 1,
            )).thenAnswer((_) async => [
              {'flock_id': 'flock-2'}
            ]);

        final flockId = await repository.getLastLoggedFlockId();

        expect(flockId, 'flock-2');
      });

      test('returns null when no logs', () async {
        when(() => mockDatabase.query(
              'egg_logs',
              columns: ['flock_id'],
              orderBy: 'created_at DESC',
              limit: 1,
            )).thenAnswer((_) async => []);

        final flockId = await repository.getLastLoggedFlockId();

        expect(flockId, isNull);
      });
    });

    group('getEggCountForDateAndFlock', () {
      test('returns count for specific date and flock', () async {
        when(() => mockDatabase.rawQuery(
              'SELECT COALESCE(SUM(count), 0) as total FROM egg_logs WHERE date(date) = date(?) AND flock_id = ?',
              any(),
            )).thenAnswer((_) async => [
              {'total': 4}
            ]);

        final count = await repository.getEggCountForDateAndFlock(
          DateTime(2024, 6, 15),
          'flock-1',
        );

        expect(count, 4);
      });
    });
  });
}
