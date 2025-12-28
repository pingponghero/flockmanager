import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/medication_log.dart';
import '../models/health_note.dart';
import '../repositories/medication_repository.dart';

/// Repository provider
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

// ==================== MEDICATION PROVIDERS ====================

/// Async notifier for managing medication logs
class MedicationsNotifier extends AsyncNotifier<List<MedicationLog>> {
  @override
  Future<List<MedicationLog>> build() async {
    return _fetchMedications();
  }

  Future<List<MedicationLog>> _fetchMedications() async {
    final repository = ref.read(medicationRepositoryProvider);
    return repository.getAllMedications();
  }

  Future<void> addMedication(MedicationLog log) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.insertMedication(log);
    ref.invalidateSelf();
    _invalidateMedicationProviders();
  }

  Future<void> updateMedication(MedicationLog log) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.updateMedication(log);
    ref.invalidateSelf();
    _invalidateMedicationProviders();
  }

  Future<void> deleteMedication(String id) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.deleteMedication(id);
    ref.invalidateSelf();
    _invalidateMedicationProviders();
  }

  void _invalidateMedicationProviders() {
    ref.invalidate(activeMedicationsProvider);
    ref.invalidate(activeWithdrawalsProvider);
    ref.invalidate(hasActiveWithdrawalProvider);
  }
}

/// Provider for all medication logs
final medicationsProvider = AsyncNotifierProvider<MedicationsNotifier, List<MedicationLog>>(() {
  return MedicationsNotifier();
});

/// Provider for active medications
final activeMedicationsProvider = FutureProvider<List<MedicationLog>>((ref) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getActiveMedications();
});

/// Provider for medications with active withdrawal
final activeWithdrawalsProvider = FutureProvider<List<MedicationLog>>((ref) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getMedicationsWithActiveWithdrawal();
});

/// Provider to check if any withdrawal is active
final hasActiveWithdrawalProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.hasActiveWithdrawal();
});

/// Provider for medications by bird
final medicationsByBirdProvider = FutureProvider.family<List<MedicationLog>, String>((ref, birdId) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getMedicationsByBird(birdId);
});

/// Provider for medications by flock
final medicationsByFlockProvider = FutureProvider.family<List<MedicationLog>, String>((ref, flockId) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getMedicationsByFlock(flockId);
});

/// Provider for a single medication by ID
final medicationByIdProvider = FutureProvider.family<MedicationLog?, String>((ref, id) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getMedicationById(id);
});

// ==================== HEALTH NOTE PROVIDERS ====================

/// Async notifier for managing health notes
class HealthNotesNotifier extends AsyncNotifier<List<HealthNote>> {
  @override
  Future<List<HealthNote>> build() async {
    return _fetchHealthNotes();
  }

  Future<List<HealthNote>> _fetchHealthNotes() async {
    final repository = ref.read(medicationRepositoryProvider);
    return repository.getAllHealthNotes();
  }

  Future<void> addHealthNote(HealthNote note) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.insertHealthNote(note);
    ref.invalidateSelf();
  }

  Future<void> updateHealthNote(HealthNote note) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.updateHealthNote(note);
    ref.invalidateSelf();
  }

  Future<void> deleteHealthNote(String id) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.deleteHealthNote(id);
    ref.invalidateSelf();
  }
}

/// Provider for all health notes
final healthNotesProvider = AsyncNotifierProvider<HealthNotesNotifier, List<HealthNote>>(() {
  return HealthNotesNotifier();
});

/// Provider for health notes by bird
final healthNotesByBirdProvider = FutureProvider.family<List<HealthNote>, String>((ref, birdId) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getHealthNotesByBird(birdId);
});

/// Provider for a single health note by ID
final healthNoteByIdProvider = FutureProvider.family<HealthNote?, String>((ref, id) async {
  final repository = ref.read(medicationRepositoryProvider);
  return repository.getHealthNoteById(id);
});
