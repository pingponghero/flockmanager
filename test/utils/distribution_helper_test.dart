import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/utils/distribution_helper.dart';

void main() {
  group('shouldOfferDistribution', () {
    // Helper to create test birds
    List<Bird> createBirds(int count) {
      return List.generate(
        count,
        (i) => Bird(
          id: 'bird-$i',
          flockId: 'flock-123',
          name: 'Bird $i',
          status: BirdStatus.active,
          createdAt: DateTime.now(),
        ),
      );
    }

    test('returns true when egg count matches bird count (2 eggs, 2 birds)', () {
      final result = shouldOfferDistribution(
        eggCount: 2,
        activeBirds: createBirds(2),
        selectedFlockId: 'flock-123',
      );

      expect(result, isTrue);
    });

    test('returns true when egg count matches bird count (5 eggs, 5 birds)', () {
      final result = shouldOfferDistribution(
        eggCount: 5,
        activeBirds: createBirds(5),
        selectedFlockId: 'flock-123',
      );

      expect(result, isTrue);
    });

    test('returns true when egg count matches bird count (10 eggs, 10 birds)', () {
      final result = shouldOfferDistribution(
        eggCount: 10,
        activeBirds: createBirds(10),
        selectedFlockId: 'flock-123',
      );

      expect(result, isTrue);
    });

    test('returns false when egg count does not match bird count (3 eggs, 2 birds)', () {
      final result = shouldOfferDistribution(
        eggCount: 3,
        activeBirds: createBirds(2),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when egg count is 0', () {
      final result = shouldOfferDistribution(
        eggCount: 0,
        activeBirds: createBirds(2),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when egg count is negative', () {
      final result = shouldOfferDistribution(
        eggCount: -1,
        activeBirds: createBirds(2),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when selectedFlockId is null (All Flocks mode)', () {
      final result = shouldOfferDistribution(
        eggCount: 2,
        activeBirds: createBirds(2),
        selectedFlockId: null,
      );

      expect(result, isFalse);
    });

    test('returns false when only 1 bird (single bird does not need distribution)', () {
      final result = shouldOfferDistribution(
        eggCount: 1,
        activeBirds: createBirds(1),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when more than 10 birds (too large for practical distribution)', () {
      final result = shouldOfferDistribution(
        eggCount: 11,
        activeBirds: createBirds(11),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when 12 birds (exceeds max limit)', () {
      final result = shouldOfferDistribution(
        eggCount: 12,
        activeBirds: createBirds(12),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when no birds', () {
      final result = shouldOfferDistribution(
        eggCount: 0,
        activeBirds: [],
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });

    test('returns false when 1 egg but 2 birds (mismatch)', () {
      final result = shouldOfferDistribution(
        eggCount: 1,
        activeBirds: createBirds(2),
        selectedFlockId: 'flock-123',
      );

      expect(result, isFalse);
    });
  });

  group('createEvenDistribution', () {
    test('creates distribution with 1 egg per bird', () {
      final birds = [
        Bird(
          id: 'bird-1',
          flockId: 'flock-123',
          name: 'Henrietta',
          status: BirdStatus.active,
          createdAt: DateTime.now(),
        ),
        Bird(
          id: 'bird-2',
          flockId: 'flock-123',
          name: 'Ginger',
          status: BirdStatus.active,
          createdAt: DateTime.now(),
        ),
      ];

      final distribution = createEvenDistribution(birds);

      expect(distribution.length, 2);
      expect(distribution['bird-1'], 1);
      expect(distribution['bird-2'], 1);
    });

    test('creates distribution for 5 birds', () {
      final birds = List.generate(
        5,
        (i) => Bird(
          id: 'bird-$i',
          flockId: 'flock-123',
          name: 'Bird $i',
          status: BirdStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final distribution = createEvenDistribution(birds);

      expect(distribution.length, 5);
      for (var i = 0; i < 5; i++) {
        expect(distribution['bird-$i'], 1);
      }
    });

    test('returns empty map for empty bird list', () {
      final distribution = createEvenDistribution([]);

      expect(distribution, isEmpty);
    });

    test('creates distribution for single bird', () {
      final birds = [
        Bird(
          id: 'solo-bird',
          flockId: 'flock-123',
          name: 'Solo',
          status: BirdStatus.active,
          createdAt: DateTime.now(),
        ),
      ];

      final distribution = createEvenDistribution(birds);

      expect(distribution.length, 1);
      expect(distribution['solo-bird'], 1);
    });

    test('uses bird.id as key', () {
      final bird = Bird(
        id: 'unique-id-123',
        flockId: 'flock-456',
        name: 'Named Bird',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      final distribution = createEvenDistribution([bird]);

      expect(distribution.containsKey('unique-id-123'), isTrue);
      expect(distribution.containsKey('Named Bird'), isFalse);
    });
  });

  group('missedDaysToSpread (#47)', () {
    final oct2 = DateTime(2026, 10, 2);

    test('spreads over missed days plus the log date, oldest first', () {
      final days = missedDaysToSpread(
        logDate: oct2,
        lastLoggedDate: DateTime(2026, 9, 29),
        eggCount: 9,
        layingHens: 3,
      );
      expect(days, [
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 1),
        oct2,
      ]);
    });

    test('not offered without a missed day', () {
      for (final last in [oct2, DateTime(2026, 10, 1)]) {
        expect(
          missedDaysToSpread(
              logDate: oct2, lastLoggedDate: last, eggCount: 9, layingHens: 3),
          isEmpty,
        );
      }
    });

    test('not offered when the flock has never been logged', () {
      expect(
        missedDaysToSpread(
            logDate: oct2, lastLoggedDate: null, eggCount: 9, layingHens: 3),
        isEmpty,
      );
    });

    test('not offered when the batch fits in one day', () {
      expect(
        missedDaysToSpread(
            logDate: oct2,
            lastLoggedDate: DateTime(2026, 9, 29),
            eggCount: 3,
            layingHens: 3),
        isEmpty,
      );
    });

    test('not offered without laying hens to judge against', () {
      expect(
        missedDaysToSpread(
            logDate: oct2,
            lastLoggedDate: DateTime(2026, 9, 29),
            eggCount: 9,
            layingHens: 0),
        isEmpty,
      );
    });

    test('offered even when there are more days than eggs', () {
      expect(
        missedDaysToSpread(
            logDate: oct2,
            lastLoggedDate: DateTime(2026, 9, 25), // 6 missed, 7 days
            eggCount: 5,
            layingHens: 2),
        hasLength(7),
      );
    });

    test('allows up to 7 missed days, not 8', () {
      expect(
        missedDaysToSpread(
            logDate: oct2,
            lastLoggedDate: DateTime(2026, 9, 24), // 7 missed
            eggCount: 16,
            layingHens: 2),
        hasLength(8),
      );
      expect(
        missedDaysToSpread(
            logDate: oct2,
            lastLoggedDate: DateTime(2026, 9, 23), // 8 missed
            eggCount: 18,
            layingHens: 2),
        isEmpty,
      );
    });

    test('counts calendar days across a DST change', () {
      // US DST ends Nov 1 2026; Europe Oct 25 2026
      final days = missedDaysToSpread(
        logDate: DateTime(2026, 11, 3),
        lastLoggedDate: DateTime(2026, 10, 31),
        eggCount: 9,
        layingHens: 2,
      );
      expect(days, [
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
      ]);
    });
  });

  group('spreadEvenly (#47)', () {
    final days = [
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
    ];

    test('splits evenly', () {
      expect(spreadEvenly(9, days).values, [3, 3, 3]);
    });

    test('gives the remainder to the earliest days', () {
      expect(spreadEvenly(10, days).values, [4, 3, 3]);
      expect(spreadEvenly(11, days).values, [4, 4, 3]);
    });

    test('gives 0 to the latest days when eggs are fewer than days', () {
      final week = [for (var d = 0; d < 7; d++) DateTime(2026, 9, 26 + d)];
      expect(spreadEvenly(5, week).values, [1, 1, 1, 1, 1, 0, 0]);
    });

    test('keeps every egg', () {
      for (var n = 3; n < 40; n++) {
        expect(spreadEvenly(n, days).values.fold(0, (a, b) => a + b), n);
      }
    });
  });
}
