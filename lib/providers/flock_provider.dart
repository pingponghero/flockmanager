import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/flock.dart';
import '../repositories/flock_repository.dart';

/// Repository provider
final flockRepositoryProvider = Provider<FlockRepository>((ref) {
  return FlockRepository();
});

/// Async notifier for managing flocks list
class FlocksNotifier extends AsyncNotifier<List<Flock>> {
  @override
  Future<List<Flock>> build() async {
    return _fetchFlocks();
  }

  Future<List<Flock>> _fetchFlocks() async {
    final repository = ref.read(flockRepositoryProvider);
    return repository.getAllFlocks();
  }

  /// Add a new flock
  Future<void> addFlock(Flock flock) async {
    final repository = ref.read(flockRepositoryProvider);
    await repository.insertFlock(flock);
    ref.invalidateSelf();
  }

  /// Update an existing flock
  Future<void> updateFlock(Flock flock) async {
    final repository = ref.read(flockRepositoryProvider);
    await repository.updateFlock(flock);
    ref.invalidateSelf();
  }

  /// Archive a flock
  Future<void> archiveFlock(String id) async {
    final repository = ref.read(flockRepositoryProvider);
    await repository.archiveFlock(id);

    // If archived flock was selected, clear selection
    final selectedId = ref.read(selectedFlockIdProvider);
    if (selectedId == id) {
      ref.read(selectedFlockIdProvider.notifier).clearSelection();
    }

    ref.invalidateSelf();
  }

  /// Unarchive a flock
  Future<void> unarchiveFlock(String id) async {
    final repository = ref.read(flockRepositoryProvider);
    await repository.unarchiveFlock(id);
    ref.invalidateSelf();
  }

  /// Delete a flock permanently
  Future<void> deleteFlock(String id) async {
    final repository = ref.read(flockRepositoryProvider);
    await repository.deleteFlock(id);

    // If deleted flock was selected, clear selection
    final selectedId = ref.read(selectedFlockIdProvider);
    if (selectedId == id) {
      ref.read(selectedFlockIdProvider.notifier).clearSelection();
    }

    ref.invalidateSelf();
  }

  /// Refresh the flocks list
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for the flocks list
final flocksProvider = AsyncNotifierProvider<FlocksNotifier, List<Flock>>(() {
  return FlocksNotifier();
});

/// Notifier for selected flock ID with persistence
class SelectedFlockNotifier extends Notifier<String?> {
  static const _selectedFlockKey = 'selected_flock_id';

  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_selectedFlockKey);
    if (savedId != null) {
      state = savedId;
    }
  }

  /// Select a flock
  Future<void> selectFlock(String? flockId) async {
    state = flockId;
    final prefs = await SharedPreferences.getInstance();
    if (flockId != null) {
      await prefs.setString(_selectedFlockKey, flockId);
    } else {
      await prefs.remove(_selectedFlockKey);
    }
  }

  /// Clear the selection (show all flocks)
  Future<void> clearSelection() async {
    await selectFlock(null);
  }
}

/// Provider for the currently selected flock ID
/// null means "all flocks"
final selectedFlockIdProvider =
    NotifierProvider<SelectedFlockNotifier, String?>(() {
  return SelectedFlockNotifier();
});

/// Provider for the currently selected flock object
final selectedFlockProvider = FutureProvider<Flock?>((ref) async {
  final selectedId = ref.watch(selectedFlockIdProvider);
  if (selectedId == null) return null;

  final repository = ref.read(flockRepositoryProvider);
  return repository.getFlockById(selectedId);
});

/// Provider for a single flock by ID
final flockByIdProvider = FutureProvider.family<Flock?, String>((ref, id) async {
  final repository = ref.read(flockRepositoryProvider);
  return repository.getFlockById(id);
});

/// Provider for bird count in a flock
final flockBirdCountProvider = FutureProvider.family<int, String>((ref, flockId) async {
  final repository = ref.read(flockRepositoryProvider);
  return repository.getBirdCount(flockId);
});
