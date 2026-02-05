import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/repositories/bird_status_event_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDatabase;
  late BirdStatusEventRepository repository;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    repository = BirdStatusEventRepository(db: mockDbHelper);
  });

  group('BirdStatusEventRepository', () {
    final testEventMap = {
      'id': 'event-1',
      'bird_id': 'bird-1',
      'flock_id': 'flock-1',
      'status': 'active',
      'event_date': '2024-01-15T00:00:00.000',
      'notes': null,
      'created_at': '2024-01-15T10:00:00.000',
    };

    group('insertEvent', () {
      test('inserts event into database', () async {
        final event = BirdStatusEvent.create(
          birdId: 'bird-1',
          flockId: 'flock-1',
          status: 'active',
          eventDate: DateTime(2024, 1, 15),
        );

        when(() => mockDatabase.insert('bird_status_events', any()))
            .thenAnswer((_) async => 1);

        await repository.insertEvent(event);

        verify(() => mockDatabase.insert('bird_status_events', any())).called(1);
      });
    });

    group('getEventsByBird', () {
      test('returns events for specific bird ordered by date descending', () async {
        final eventMaps = [
          {...testEventMap, 'id': 'event-2', 'event_date': '2024-06-15T00:00:00.000', 'status': 'deceased'},
          {...testEventMap, 'id': 'event-1', 'event_date': '2024-01-15T00:00:00.000', 'status': 'active'},
        ];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'bird_id = ?',
              whereArgs: ['bird-1'],
              orderBy: 'event_date DESC',
            )).thenAnswer((_) async => eventMaps);

        final events = await repository.getEventsByBird('bird-1');

        expect(events.length, 2);
        expect(events[0].status, 'deceased');
        expect(events[1].status, 'active');
      });

      test('returns empty list when no events for bird', () async {
        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'bird_id = ?',
              whereArgs: ['nonexistent'],
              orderBy: 'event_date DESC',
            )).thenAnswer((_) async => []);

        final events = await repository.getEventsByBird('nonexistent');

        expect(events, isEmpty);
      });
    });

    group('getEventsByFlock', () {
      test('returns events for specific flock', () async {
        final eventMaps = [testEventMap];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'flock_id = ?',
              whereArgs: ['flock-1'],
              orderBy: 'event_date DESC',
            )).thenAnswer((_) async => eventMaps);

        final events = await repository.getEventsByFlock('flock-1');

        expect(events.length, 1);
        expect(events[0].flockId, 'flock-1');
      });
    });

    group('getAllEvents', () {
      test('returns all events ordered by date descending', () async {
        final eventMaps = [
          {...testEventMap, 'id': 'event-1', 'flock_id': 'flock-1'},
          {...testEventMap, 'id': 'event-2', 'flock_id': 'flock-2'},
        ];

        when(() => mockDatabase.query(
              'bird_status_events',
              orderBy: 'event_date DESC',
            )).thenAnswer((_) async => eventMaps);

        final events = await repository.getAllEvents();

        expect(events.length, 2);
      });
    });

    group('getEventsInDateRange', () {
      test('returns events within date range for specific flock', () async {
        final eventMaps = [testEventMap];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'flock_id = ? AND event_date >= ? AND event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => eventMaps);

        final events = await repository.getEventsInDateRange(
          'flock-1',
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        expect(events.length, 1);
      });

      test('returns events within date range for all flocks when flockId is null', () async {
        final eventMaps = [testEventMap];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'event_date >= ? AND event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => eventMaps);

        final events = await repository.getEventsInDateRange(
          null,
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        expect(events.length, 1);
      });
    });

    group('getActiveCountOnDate', () {
      test('returns count of active birds on specific date for flock', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              any(),
            )).thenAnswer((_) async => [{'count': 5}]);

        final count = await repository.getActiveCountOnDate(
          'flock-1',
          DateTime(2024, 6, 15),
        );

        expect(count, 5);
      });

      test('returns count of active birds on specific date for all flocks', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              any(),
            )).thenAnswer((_) async => [{'count': 12}]);

        final count = await repository.getActiveCountOnDate(
          null,
          DateTime(2024, 6, 15),
        );

        expect(count, 12);
      });

      test('returns 0 when no birds are active', () async {
        when(() => mockDatabase.rawQuery(
              any(),
              any(),
            )).thenAnswer((_) async => [{'count': null}]);

        final count = await repository.getActiveCountOnDate(
          'flock-1',
          DateTime(2024, 6, 15),
        );

        expect(count, 0);
      });
    });
  });
}
