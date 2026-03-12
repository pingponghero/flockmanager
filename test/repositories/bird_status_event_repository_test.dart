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

    group('deleteEvent', () {
      test('undo: inserts status event then deletes it by ID', () async {
        // Simulate a status change: insert a "deceased" event
        final event = BirdStatusEvent.create(
          birdId: 'bird-1',
          flockId: 'flock-1',
          status: 'deceased',
          eventDate: DateTime(2024, 6, 15),
          notes: 'Found in coop',
        );

        when(() => mockDatabase.insert('bird_status_events', any()))
            .thenAnswer((_) async => 1);

        await repository.insertEvent(event);

        verify(() => mockDatabase.insert('bird_status_events', any())).called(1);

        // Simulate undo: delete the event using the same ID
        when(() => mockDatabase.delete(
              'bird_status_events',
              where: 'id = ?',
              whereArgs: [event.id],
            )).thenAnswer((_) async => 1);

        await repository.deleteEvent(event.id);

        verify(() => mockDatabase.delete(
              'bird_status_events',
              where: 'id = ?',
              whereArgs: [event.id],
            )).called(1);
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

    group('flockSizeOnDate (static binary search)', () {
      // This is the core lookup used by the forecast engine to compute
      // bird-days. These tests ensure the step function is interpreted
      // correctly at boundaries, between events, and outside the range.

      final timeline = <({DateTime date, int count})>[
        (date: DateTime(2024, 1, 1), count: 2),
        (date: DateTime(2024, 2, 7), count: 11),
        (date: DateTime(2024, 6, 15), count: 10),
      ];

      test('returns 0 before any events', () {
        final count = BirdStatusEventRepository.flockSizeOnDate(
          timeline,
          DateTime(2023, 12, 31),
        );
        expect(count, 0);
      });

      test('returns count on exact first date', () {
        final count = BirdStatusEventRepository.flockSizeOnDate(
          timeline,
          DateTime(2024, 1, 1),
        );
        expect(count, 2);
      });

      test('holds steady between change points', () {
        // Between Jan 1 (2 hens) and Feb 7 (11 hens) → should still be 2
        final count = BirdStatusEventRepository.flockSizeOnDate(
          timeline,
          DateTime(2024, 1, 20),
        );
        expect(count, 2);
      });

      test('returns count on exact change date', () {
        final count = BirdStatusEventRepository.flockSizeOnDate(
          timeline,
          DateTime(2024, 2, 7),
        );
        expect(count, 11);
      });

      test('returns latest count after last event', () {
        final count = BirdStatusEventRepository.flockSizeOnDate(
          timeline,
          DateTime(2024, 12, 31),
        );
        expect(count, 10);
      });

      test('handles single-entry timeline', () {
        final single = <({DateTime date, int count})>[
          (date: DateTime(2024, 3, 1), count: 5),
        ];
        expect(
          BirdStatusEventRepository.flockSizeOnDate(single, DateTime(2024, 2, 28)),
          0,
        );
        expect(
          BirdStatusEventRepository.flockSizeOnDate(single, DateTime(2024, 3, 1)),
          5,
        );
        expect(
          BirdStatusEventRepository.flockSizeOnDate(single, DateTime(2024, 9, 1)),
          5,
        );
      });

      test('handles empty timeline', () {
        final empty = <({DateTime date, int count})>[];
        expect(
          BirdStatusEventRepository.flockSizeOnDate(empty, DateTime(2024, 6, 1)),
          0,
        );
      });
    });

    group('flockSizeOnDate — bird-days scenario', () {
      // Simulates the user's actual scenario: 2 hens from Jan 1, 9 added Feb 7.
      // Verifies the bird-days sum matches expectations.

      final timeline = <({DateTime date, int count})>[
        (date: DateTime(2026, 1, 1), count: 2),
        (date: DateTime(2026, 2, 7), count: 11),
      ];

      test('January has 2 hens every day → 62 bird-days', () {
        var birdDays = 0;
        for (var d = 1; d <= 31; d++) {
          birdDays += BirdStatusEventRepository.flockSizeOnDate(
            timeline,
            DateTime(2026, 1, d),
          );
        }
        expect(birdDays, 31 * 2); // 62
      });

      test('February has mixed flock size → correct bird-days', () {
        // Feb 1-6: 2 hens (6 days × 2 = 12)
        // Feb 7-28: 11 hens (22 days × 11 = 242)
        // Total: 254
        var birdDays = 0;
        for (var d = 1; d <= 28; d++) {
          birdDays += BirdStatusEventRepository.flockSizeOnDate(
            timeline,
            DateTime(2026, 2, d),
          );
        }
        expect(birdDays, 6 * 2 + 22 * 11); // 254
      });

      test('per-hen rate is correct for January (39 eggs, 2 hens)', () {
        // User had 39 eggs in January with 2 hens all month
        const janEggs = 39;
        const janBirdDays = 31 * 2; // 62
        final rate = janEggs / janBirdDays;
        // 39/62 ≈ 0.629 — well below the 0.95 biological ceiling
        expect(rate, closeTo(0.629, 0.001));
        expect(rate, lessThan(0.95));
      });

      test('mid-month snapshot would give wrong rate for January', () {
        // This is the bug the timeline approach fixes.
        // If we used mid-January (Jan 15) snapshot: 2 hens → correct.
        // But if we used mid-February snapshot for Feb: 11 hens.
        // For a hypothetical scenario where flock changed mid-Jan:
        // e.g., 2 hens Jan 1-14, 11 hens Jan 15-31
        final badTimeline = <({DateTime date, int count})>[
          (date: DateTime(2026, 1, 1), count: 2),
          (date: DateTime(2026, 1, 15), count: 11),
        ];

        // Mid-month snapshot (Jan 15) would say 11 hens
        final midMonthSnapshot = BirdStatusEventRepository.flockSizeOnDate(
          badTimeline,
          DateTime(2026, 1, 15),
        );
        expect(midMonthSnapshot, 11); // snapshot overestimates!

        // Actual bird-days: 14×2 + 17×11 = 28 + 187 = 215
        var actualBirdDays = 0;
        for (var d = 1; d <= 31; d++) {
          actualBirdDays += BirdStatusEventRepository.flockSizeOnDate(
            badTimeline,
            DateTime(2026, 1, d),
          );
        }
        expect(actualBirdDays, 14 * 2 + 17 * 11); // 215

        // With 39 eggs:
        // Snapshot approach: 39 / (11 * 31) = 0.114 (underestimates rate)
        // Timeline approach: 39 / 215 = 0.181 (accurate)
        const eggs = 39;
        final snapshotRate = eggs / (midMonthSnapshot * 31);
        final timelineRate = eggs / actualBirdDays;
        expect(snapshotRate, closeTo(0.114, 0.001));
        expect(timelineRate, closeTo(0.181, 0.001));
        // Timeline rate is higher (correct) because it accounts for
        // the period when fewer hens were producing.
      });
    });

    group('getFlockSizeTimeline', () {
      // Tests the DB-backed timeline builder with mocked queries.

      test('builds timeline from events for a specific flock', () async {
        // Scenario: bird-1 added active Jan 1, bird-2 added active Feb 7,
        // bird-1 deceased Jun 15.
        final eventMaps = [
          {
            'id': 'e1', 'bird_id': 'bird-1', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2024-01-01T00:00:00.000',
            'notes': null, 'created_at': '2024-01-01T00:00:00.000',
          },
          {
            'id': 'e2', 'bird_id': 'bird-2', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2024-02-07T00:00:00.000',
            'notes': null, 'created_at': '2024-02-07T00:00:00.000',
          },
          {
            'id': 'e3', 'bird_id': 'bird-1', 'flock_id': 'f1',
            'status': 'deceased', 'event_date': '2024-06-15T00:00:00.000',
            'notes': null, 'created_at': '2024-06-15T00:00:00.000',
          },
        ];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'flock_id = ? AND event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => eventMaps);

        final timeline = await repository.getFlockSizeTimeline(
          'f1',
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        // Jan 1: bird-1 active → 1
        // Feb 7: bird-2 active → 2
        // Jun 15: bird-1 deceased → 1
        expect(timeline.length, 3);
        expect(timeline[0].date, DateTime(2024, 1, 1));
        expect(timeline[0].count, 1);
        expect(timeline[1].date, DateTime(2024, 2, 7));
        expect(timeline[1].count, 2);
        expect(timeline[2].date, DateTime(2024, 6, 15));
        expect(timeline[2].count, 1);
      });

      test('builds timeline for all flocks when flockId is null', () async {
        final eventMaps = [
          {
            'id': 'e1', 'bird_id': 'bird-1', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2024-01-01T00:00:00.000',
            'notes': null, 'created_at': '2024-01-01T00:00:00.000',
          },
          {
            'id': 'e2', 'bird_id': 'bird-2', 'flock_id': 'f2',
            'status': 'active', 'event_date': '2024-01-01T00:00:00.000',
            'notes': null, 'created_at': '2024-01-01T00:00:00.000',
          },
        ];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => eventMaps);

        final timeline = await repository.getFlockSizeTimeline(
          null,
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        // Both events on same day → merged, 2 active birds
        expect(timeline.length, 1);
        expect(timeline[0].count, 2);
      });

      test('establishes initial state from pre-start events', () async {
        // Events before the requested start establish baseline
        final eventMaps = [
          {
            'id': 'e1', 'bird_id': 'bird-1', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2023-06-01T00:00:00.000',
            'notes': null, 'created_at': '2023-06-01T00:00:00.000',
          },
          {
            'id': 'e2', 'bird_id': 'bird-2', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2023-09-01T00:00:00.000',
            'notes': null, 'created_at': '2023-09-01T00:00:00.000',
          },
          {
            'id': 'e3', 'bird_id': 'bird-3', 'flock_id': 'f1',
            'status': 'active', 'event_date': '2024-03-01T00:00:00.000',
            'notes': null, 'created_at': '2024-03-01T00:00:00.000',
          },
        ];

        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'flock_id = ? AND event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => eventMaps);

        final timeline = await repository.getFlockSizeTimeline(
          'f1',
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        // Start: 2 birds already active (from 2023 events)
        // Mar 1: third bird → 3
        expect(timeline.length, 2);
        expect(timeline[0].date, DateTime(2024, 1, 1));
        expect(timeline[0].count, 2); // baseline from pre-start events
        expect(timeline[1].date, DateTime(2024, 3, 1));
        expect(timeline[1].count, 3);
      });

      test('returns empty count when no events', () async {
        when(() => mockDatabase.query(
              'bird_status_events',
              where: 'flock_id = ? AND event_date <= ?',
              whereArgs: any(named: 'whereArgs'),
              orderBy: 'event_date ASC',
            )).thenAnswer((_) async => []);

        final timeline = await repository.getFlockSizeTimeline(
          'f1',
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        );

        expect(timeline.length, 1);
        expect(timeline[0].count, 0);
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
