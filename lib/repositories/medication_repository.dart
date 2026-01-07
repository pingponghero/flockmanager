import '../database/database_helper.dart';
import '../models/medication_log.dart';
import '../models/health_note.dart';

/// Repository for medication and health note data access operations.
class MedicationRepository {
  final DatabaseHelper _db;

  MedicationRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ==================== MEDICATION LOGS ====================

  /// Get all medication logs, ordered by start date descending.
  Future<List<MedicationLog>> getAllMedications() async {
    final db = await _db.database;

    final maps = await db.query(
      'medication_logs',
      orderBy: 'start_date DESC, created_at DESC',
    );

    return maps.map((map) => MedicationLog.fromMap(map)).toList();
  }

  /// Get active medications (end_date null or in future).
  Future<List<MedicationLog>> getActiveMedications() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'medication_logs',
      where: 'end_date IS NULL OR end_date > ?',
      whereArgs: [now],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => MedicationLog.fromMap(map)).toList();
  }

  /// Get medications by bird.
  Future<List<MedicationLog>> getMedicationsByBird(String birdId) async {
    final db = await _db.database;

    final maps = await db.query(
      'medication_logs',
      where: 'bird_id = ?',
      whereArgs: [birdId],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => MedicationLog.fromMap(map)).toList();
  }

  /// Reassign medication logs from a bird to anonymous (null bird_id).
  Future<int> reassignMedicationLogsToAnonymous(String birdId) async {
    final db = await _db.database;
    return db.update(
      'medication_logs',
      {'bird_id': null},
      where: 'bird_id = ?',
      whereArgs: [birdId],
    );
  }

  /// Reassign health notes from a bird to anonymous (null bird_id).
  Future<int> reassignHealthNotesToAnonymous(String birdId) async {
    final db = await _db.database;
    return db.update(
      'health_notes',
      {'bird_id': null},
      where: 'bird_id = ?',
      whereArgs: [birdId],
    );
  }

  /// Get medications by flock.
  Future<List<MedicationLog>> getMedicationsByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'medication_logs',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'start_date DESC',
    );

    return maps.map((map) => MedicationLog.fromMap(map)).toList();
  }

  /// Get a single medication log by ID.
  Future<MedicationLog?> getMedicationById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'medication_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MedicationLog.fromMap(maps.first);
  }

  /// Insert a new medication log.
  Future<void> insertMedication(MedicationLog log) async {
    final db = await _db.database;
    await db.insert('medication_logs', log.toMap());
  }

  /// Update an existing medication log.
  Future<void> updateMedication(MedicationLog log) async {
    final db = await _db.database;

    await db.update(
      'medication_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Delete a medication log.
  Future<void> deleteMedication(String id) async {
    final db = await _db.database;

    await db.delete(
      'medication_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get medications with active withdrawal periods.
  Future<List<MedicationLog>> getMedicationsWithActiveWithdrawal() async {
    final all = await getAllMedications();
    return all.where((m) => m.isWithdrawalActive).toList();
  }

  /// Check if any withdrawal is currently active.
  Future<bool> hasActiveWithdrawal() async {
    final active = await getMedicationsWithActiveWithdrawal();
    return active.isNotEmpty;
  }

  /// Get the soonest withdrawal end date.
  Future<DateTime?> getNextWithdrawalEnd() async {
    final active = await getMedicationsWithActiveWithdrawal();
    if (active.isEmpty) return null;

    DateTime? soonest;
    for (final med in active) {
      final end = med.withdrawalEndDate;
      if (end != null && (soonest == null || end.isBefore(soonest))) {
        soonest = end;
      }
    }
    return soonest;
  }

  // ==================== HEALTH NOTES ====================

  /// Get all health notes, ordered by date descending.
  Future<List<HealthNote>> getAllHealthNotes() async {
    final db = await _db.database;

    final maps = await db.query(
      'health_notes',
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => HealthNote.fromMap(map)).toList();
  }

  /// Get health notes by bird.
  Future<List<HealthNote>> getHealthNotesByBird(String birdId) async {
    final db = await _db.database;

    final maps = await db.query(
      'health_notes',
      where: 'bird_id = ?',
      whereArgs: [birdId],
      orderBy: 'date DESC',
    );

    return maps.map((map) => HealthNote.fromMap(map)).toList();
  }

  /// Get a single health note by ID.
  Future<HealthNote?> getHealthNoteById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'health_notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HealthNote.fromMap(maps.first);
  }

  /// Insert a new health note.
  Future<void> insertHealthNote(HealthNote note) async {
    final db = await _db.database;
    await db.insert('health_notes', note.toMap());
  }

  /// Update an existing health note.
  Future<void> updateHealthNote(HealthNote note) async {
    final db = await _db.database;

    await db.update(
      'health_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Delete a health note.
  Future<void> deleteHealthNote(String id) async {
    final db = await _db.database;

    await db.delete(
      'health_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Count distinct birds that have health notes.
  Future<int> getBirdsWithHealthNotesCount() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT bird_id) as count FROM health_notes
    ''');

    return (result.first['count'] as int?) ?? 0;
  }
}
