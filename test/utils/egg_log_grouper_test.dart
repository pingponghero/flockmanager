import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/utils/egg_log_grouper.dart';

void main() {
  group('EggLogGroup', () {
    test('isDistributed returns true when multiple logs with bird IDs', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.isDistributed, isTrue);
    });

    test('isDistributed returns false when single log with bird ID', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.isDistributed, isFalse);
    });

    test('isDistributed returns false when log has null bird ID', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: null,
          count: 5,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.isDistributed, isFalse);
    });

    test('isDistributed returns false when some logs have null bird ID', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: now,
          flockId: 'flock-123',
          birdId: null,
          count: 1,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.isDistributed, isFalse);
    });

    test('totalCount sums all log counts', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-3',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-3',
          count: 1,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.totalCount, 3);
    });

    test('displayTime returns first log createdAt', () {
      final createdAt = DateTime(2024, 1, 15, 10, 30);
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: createdAt,
        ),
      ];

      final group = EggLogGroup(
        date: DateTime(2024, 1, 15),
        flockId: 'flock-123',
        createdAt: createdAt,
        logs: logs,
      );

      expect(group.displayTime, createdAt);
    });

    test('firstLog returns first log in list', () {
      final now = DateTime.now();
      final firstLog = EggLog(
        id: 'log-first',
        date: now,
        flockId: 'flock-123',
        count: 5,
        createdAt: now,
      );
      final logs = [
        firstLog,
        EggLog(
          id: 'log-second',
          date: now,
          flockId: 'flock-123',
          count: 3,
          createdAt: now,
        ),
      ];

      final group = EggLogGroup(
        date: now,
        flockId: 'flock-123',
        createdAt: now,
        logs: logs,
      );

      expect(group.firstLog.id, 'log-first');
    });
  });

  group('groupEggLogs', () {
    test('returns empty list for empty input', () {
      final groups = groupEggLogs([]);

      expect(groups, isEmpty);
    });

    test('creates single group for single log', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          count: 5,
          createdAt: now,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 1);
      expect(groups.first.logs.length, 1);
    });

    test('groups logs with same timestamp (within 2 seconds)', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: now,
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 1);
      expect(groups.first.logs.length, 2);
      expect(groups.first.isDistributed, isTrue);
    });

    test('groups logs within 2 second window', () {
      final baseTime = DateTime(2024, 1, 15, 10, 30, 0);
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: baseTime,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: baseTime.add(const Duration(seconds: 2)),
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 1);
    });

    test('separates logs more than 2 seconds apart', () {
      final baseTime = DateTime(2024, 1, 15, 10, 30, 0);
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 3,
          createdAt: baseTime,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 2,
          createdAt: baseTime.add(const Duration(seconds: 3)),
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
    });

    test('separates logs 1 minute apart', () {
      final baseTime = DateTime(2024, 1, 15, 10, 30, 0);
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 3,
          createdAt: baseTime,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 2,
          createdAt: baseTime.add(const Duration(minutes: 1)),
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
    });

    test('separates logs with different dates', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 16), // Different date
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: now,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
    });

    test('separates logs with different flock IDs', () {
      final now = DateTime.now();
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: now,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-456', // Different flock
          birdId: 'bird-2',
          count: 1,
          createdAt: now,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
    });

    test('sorts groups by createdAt descending (most recent first)', () {
      final logs = [
        EggLog(
          id: 'log-old',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 3,
          createdAt: DateTime(2024, 1, 15, 8, 0),
        ),
        EggLog(
          id: 'log-new',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          count: 5,
          createdAt: DateTime(2024, 1, 15, 18, 0),
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
      expect(groups.first.logs.first.id, 'log-new');
      expect(groups.last.logs.first.id, 'log-old');
    });

    test('groups 3 distributed logs together', () {
      final baseTime = DateTime(2024, 1, 15, 10, 30, 0);
      final logs = [
        EggLog(
          id: 'log-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: baseTime,
        ),
        EggLog(
          id: 'log-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: baseTime,
        ),
        EggLog(
          id: 'log-3',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-3',
          count: 1,
          createdAt: baseTime,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 1);
      expect(groups.first.logs.length, 3);
      expect(groups.first.totalCount, 3);
      expect(groups.first.isDistributed, isTrue);
    });

    test('handles mixed distributed and non-distributed logs', () {
      final time1 = DateTime(2024, 1, 15, 8, 0, 0);
      final time2 = DateTime(2024, 1, 15, 18, 0, 0);

      final logs = [
        // Non-distributed flock-level log
        EggLog(
          id: 'log-flock',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: null,
          count: 5,
          createdAt: time1,
        ),
        // Distributed logs
        EggLog(
          id: 'log-dist-1',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-1',
          count: 1,
          createdAt: time2,
        ),
        EggLog(
          id: 'log-dist-2',
          date: DateTime(2024, 1, 15),
          flockId: 'flock-123',
          birdId: 'bird-2',
          count: 1,
          createdAt: time2,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);

      // Find the distributed group (most recent, so first)
      final distributedGroup = groups.firstWhere((g) => g.isDistributed);
      final flockGroup = groups.firstWhere((g) => !g.isDistributed);

      expect(distributedGroup.logs.length, 2);
      expect(distributedGroup.totalCount, 2);
      expect(flockGroup.logs.length, 1);
      expect(flockGroup.totalCount, 5);
    });

    test('correctly handles same day different times', () {
      final date = DateTime(2024, 1, 15);
      final morningTime = DateTime(2024, 1, 15, 8, 0, 0);
      final eveningTime = DateTime(2024, 1, 15, 18, 0, 0);

      final logs = [
        EggLog(
          id: 'log-morning',
          date: date,
          flockId: 'flock-123',
          count: 3,
          createdAt: morningTime,
        ),
        EggLog(
          id: 'log-evening',
          date: date,
          flockId: 'flock-123',
          count: 2,
          createdAt: eveningTime,
        ),
      ];

      final groups = groupEggLogs(logs);

      expect(groups.length, 2);
    });
  });
}
