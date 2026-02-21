import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bird.dart';
import '../models/bird_status_event.dart';
import '../models/enums.dart';
import '../repositories/bird_repository.dart';
import 'bird_status_event_provider.dart';
import 'egg_provider.dart';
import 'flock_provider.dart';
import 'medication_provider.dart';

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

  /// Invalidate all bird-related providers
  void _invalidateBirdProviders() {
    ref.invalidate(filteredBirdsProvider);
    ref.invalidate(activeBirdsProvider);
    ref.invalidate(activeBirdsByFlockProvider);
    ref.invalidate(allActiveHensProvider);
    ref.invalidate(birdsByFlockProvider);
    ref.invalidate(birdsByStatusProvider);
    ref.invalidate(birdCountsByStatusProvider);
    ref.invalidate(birdStatusEventsProvider);
    ref.invalidate(livingBirdsProvider);
  }

  /// Add a new bird
  Future<void> addBird(Bird bird) async {
    final repository = ref.read(birdRepositoryProvider);
    final eventRepository = ref.read(birdStatusEventRepositoryProvider);

    await repository.insertBird(bird);

    // Create 'active' event for the new bird
    await eventRepository.insertEvent(
      BirdStatusEvent.create(
        birdId: bird.id,
        flockId: bird.flockId,
        status: 'active',
        eventDate: bird.createdAt,
      ),
    );

    ref.invalidateSelf();
    ref.invalidate(flockBirdCountProvider(bird.flockId));
    _invalidateBirdProviders();
  }

  /// Update an existing bird
  Future<void> updateBird(Bird bird) async {
    final repository = ref.read(birdRepositoryProvider);
    await repository.updateBird(bird);
    ref.invalidateSelf();
    ref.invalidate(birdByIdProvider(bird.id));
    _invalidateBirdProviders();
  }

  /// Update a bird's status. Returns the event ID if one was created.
  Future<String?> updateBirdStatus(
    String id,
    BirdStatus status,
    String? notes, {
    DateTime? eventDate,
    bool recordEvent = true,
  }) async {
    final repository = ref.read(birdRepositoryProvider);
    final eventRepository = ref.read(birdStatusEventRepositoryProvider);
    final flockRepository = ref.read(flockRepositoryProvider);

    // Get the bird to find its flock
    final bird = await repository.getBirdById(id);

    final date = eventDate ?? DateTime.now();

    // Create event for the status change
    String? createdEventId;
    if (recordEvent && bird != null) {
      final event = BirdStatusEvent.create(
        birdId: id,
        flockId: bird.flockId,
        status: status.name,
        eventDate: date,
        notes: notes,
      );
      await eventRepository.insertEvent(event);
      createdEventId = event.id;
    }

    await repository.updateBirdStatus(id, status, notes, date);
    ref.invalidateSelf();
    ref.invalidate(birdByIdProvider(id));
    _invalidateBirdProviders();

    if (bird != null) {
      ref.invalidate(flockBirdCountProvider(bird.flockId));

      // Auto-unarchive flock if reactivating a bird in an archived flock
      if (status == BirdStatus.active) {
        final flock = await flockRepository.getFlockById(bird.flockId);
        if (flock != null && flock.isArchived) {
          await flockRepository.unarchiveFlock(bird.flockId);
          ref.invalidate(flocksProvider);
          ref.invalidate(archivedFlocksProvider);
        }
      }
    }

    return createdEventId;
  }

  /// Delete a status event (used for undo)
  Future<void> deleteStatusEvent(String eventId) async {
    final eventRepository = ref.read(birdStatusEventRepositoryProvider);
    await eventRepository.deleteEvent(eventId);
    _invalidateBirdProviders();
  }

  /// Delete a bird permanently
  Future<void> deleteBird(String id) async {
    final repository = ref.read(birdRepositoryProvider);
    final eventRepository = ref.read(birdStatusEventRepositoryProvider);

    // Get the bird to find its flock
    final bird = await repository.getBirdById(id);

    // Create 'deleted' event before deleting the bird
    if (bird != null) {
      await eventRepository.insertEvent(
        BirdStatusEvent.create(
          birdId: id,
          flockId: bird.flockId,
          status: 'deleted',
          eventDate: DateTime.now(),
        ),
      );
    }

    await repository.deleteBird(id);
    ref.invalidateSelf();
    _invalidateBirdProviders();

    if (bird != null) {
      ref.invalidate(flockBirdCountProvider(bird.flockId));
    }

    // Egg logs and medication logs were reassigned — invalidate those providers
    ref.invalidate(eggLogsProvider);
    ref.invalidate(totalEggCountByBirdProvider);
    ref.invalidate(eggLogsByBirdProvider);
    ref.invalidate(medicationsProvider);
    ref.invalidate(medicationsByBirdProvider);
    ref.invalidate(healthNotesProvider);
    ref.invalidate(healthNotesByBirdProvider);
  }

  /// Refresh the birds list
  Future<void> refresh() async {
    ref.invalidateSelf();
    _invalidateBirdProviders();
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

/// Provider for all active hens (female birds with active status).
/// Used by log-by-hen mode when no specific flock is selected.
final allActiveHensProvider = FutureProvider<List<Bird>>((ref) async {
  final repository = ref.read(birdRepositoryProvider);
  final birds = await repository.getActiveBirds();
  return birds.where((b) => b.sex != BirdSex.male).toList();
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

// ==================== FLOCK SPOTLIGHT ====================

/// All birds that are alive and in the flock (active + inactive).
/// Includes roosters (inactive by default) unlike activeBirdsProvider.
final livingBirdsProvider = FutureProvider<List<Bird>>((ref) async {
  final repository = ref.read(birdRepositoryProvider);
  final allBirds = await repository.getAllBirds();
  return allBirds
      .where((b) => b.status == BirdStatus.active || b.status == BirdStatus.inactive)
      .toList();
});

/// Persists which bird the user last viewed in the spotlight.
class FlockSpotlightNotifier extends AsyncNotifier<String?> {
  static const _key = 'flock_spotlight_bird_id';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveBird(String birdId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, birdId);
    state = AsyncData(birdId);
  }
}

final flockSpotlightBirdIdProvider =
    AsyncNotifierProvider<FlockSpotlightNotifier, String?>(() {
  return FlockSpotlightNotifier();
});

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
