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
}
