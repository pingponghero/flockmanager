import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bird.dart';
import '../models/enums.dart';
import '../repositories/bird_repository.dart';
import 'flock_provider.dart';

/// Repository provider
final birdRepositoryProvider = Provider<BirdRepository>((ref) {
  return BirdRepository();
});

/// Async notifier for managing birds list
class BirdsNotifier extends AsyncNotifier<List<Bird>> {
  @override
  Future<List<Bird>> build() async {
    return _fetchBirds();
  }

  Future<List<Bird>> _fetchBirds() async {
    final repository = ref.read(birdRepositoryProvider);
    return repository.getAllBirds();
  }

  /// Add a new bird
  Future<void> addBird(Bird bird) async {
    final repository = ref.read(birdRepositoryProvider);
    await repository.insertBird(bird);
    ref.invalidateSelf();
    // Also invalidate the flock bird count
    ref.invalidate(flockBirdCountProvider(bird.flockId));
  }

  /// Update an existing bird
  Future<void> updateBird(Bird bird) async {
    final repository = ref.read(birdRepositoryProvider);
    await repository.updateBird(bird);
    ref.invalidateSelf();
  }

  /// Update a bird's status
  Future<void> updateBirdStatus(
    String id,
    BirdStatus status,
    String? notes,
  ) async {
    final repository = ref.read(birdRepositoryProvider);

    // Get the bird to find its flock
    final bird = await repository.getBirdById(id);

    await repository.updateBirdStatus(id, status, notes);
    ref.invalidateSelf();

    // Also invalidate the flock bird count if status changed to/from active
    if (bird != null) {
      ref.invalidate(flockBirdCountProvider(bird.flockId));
    }
  }

  /// Delete a bird permanently
  Future<void> deleteBird(String id) async {
    final repository = ref.read(birdRepositoryProvider);

    // Get the bird to find its flock
    final bird = await repository.getBirdById(id);

    await repository.deleteBird(id);
    ref.invalidateSelf();

    // Also invalidate the flock bird count
    if (bird != null) {
      ref.invalidate(flockBirdCountProvider(bird.flockId));
    }
  }

  /// Refresh the birds list
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for all birds list
final birdsProvider = AsyncNotifierProvider<BirdsNotifier, List<Bird>>(() {
  return BirdsNotifier();
});

/// Provider for birds in a specific flock
final birdsByFlockProvider =
    FutureProvider.family<List<Bird>, String>((ref, flockId) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getBirdsByFlock(flockId);
});

/// Provider for active birds only
final activeBirdsProvider = FutureProvider<List<Bird>>((ref) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getActiveBirds();
});

/// Provider for active birds in a specific flock
final activeBirdsByFlockProvider =
    FutureProvider.family<List<Bird>, String>((ref, flockId) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getActiveBirdsByFlock(flockId);
});

/// Provider for birds filtered by status
final birdsByStatusProvider =
    FutureProvider.family<List<Bird>, BirdStatus>((ref, status) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getBirdsByStatus(status);
});

/// Provider for a single bird by ID
final birdByIdProvider =
    FutureProvider.family<Bird?, String>((ref, id) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getBirdById(id);
});

/// Provider for birds filtered by selected flock context
/// If selectedFlockId is null, returns all birds; otherwise returns birds for that flock
final filteredBirdsProvider = FutureProvider<List<Bird>>((ref) async {
  final selectedFlockId = ref.watch(selectedFlockIdProvider);
  final repository = ref.read(birdRepositoryProvider);

  if (selectedFlockId == null) {
    return repository.getAllBirds();
  } else {
    return repository.getBirdsByFlock(selectedFlockId);
  }
});

/// Provider for bird counts by status in a flock
final birdCountsByStatusProvider =
    FutureProvider.family<Map<BirdStatus, int>, String>((ref, flockId) async {
  final repository = ref.read(birdRepositoryProvider);
  return repository.getBirdCountsByStatus(flockId);
});

// ==================== FUN FEATURES ====================

/// Fun titles for Chicken of the Week (rotates with the bird)
const _chickenOfTheWeekTitles = [
  'Flock Favorite',
  'Coop Celebrity',
  'Featured Friend',
  "This Week's Star",
  'Feathered VIP',
  'Top Hen',
  'Clucky Champion',
];

/// Chicken of the Week - cycles through active birds by ID (fair rotation)
final chickenOfTheWeekProvider = FutureProvider<({Bird bird, String title})?>(
  (ref) async {
    final birds = await ref.watch(activeBirdsProvider.future);
    if (birds.isEmpty) return null;

    // Sort by ID for consistent, fair rotation
    final sortedBirds = [...birds]..sort((a, b) => a.id.compareTo(b.id));

    // Use week number to cycle through birds
    final now = DateTime.now();
    final weekOfYear = ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor();

    // Pick bird based on week (cycles through all birds)
    final birdIndex = weekOfYear % sortedBirds.length;
    final titleIndex = weekOfYear % _chickenOfTheWeekTitles.length;

    return (
      bird: sortedBirds[birdIndex],
      title: _chickenOfTheWeekTitles[titleIndex],
    );
  },
);

/// Birds with birthdays coming up (within next 7 days) or today
final upcomingBirthdaysProvider = FutureProvider<List<({Bird bird, int daysUntil, int age})>>(
  (ref) async {
    final birds = await ref.watch(activeBirdsProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final birthdays = <({Bird bird, int daysUntil, int age})>[];

    for (final bird in birds) {
      if (bird.hatchDate == null) continue;

      // Calculate this year's birthday
      var birthdayThisYear = DateTime(
        now.year,
        bird.hatchDate!.month,
        bird.hatchDate!.day,
      );

      // If birthday already passed this year, check next year
      if (birthdayThisYear.isBefore(today)) {
        birthdayThisYear = DateTime(
          now.year + 1,
          bird.hatchDate!.month,
          bird.hatchDate!.day,
        );
      }

      final daysUntil = birthdayThisYear.difference(today).inDays;

      // Include if within next 7 days
      if (daysUntil <= 7) {
        final age = birthdayThisYear.year - bird.hatchDate!.year;
        birthdays.add((bird: bird, daysUntil: daysUntil, age: age));
      }
    }

    // Sort by days until birthday
    birthdays.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

    return birthdays;
  },
);
