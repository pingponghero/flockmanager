import '../database/database_helper.dart';
import '../models/flock.dart';

/// Repository for flock data access operations.
class FlockRepository {
  final DatabaseHelper _db;

  FlockRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Get all non-archived flocks, ordered by creation date (newest first).
  Future<List<Flock>> getAllFlocks({bool includeArchived = false}) async {
    final db = await _db.database;

    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query(
        'flocks',
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        'flocks',
        where: 'is_archived = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
    }

    return maps.map((map) => Flock.fromMap(map)).toList();
  }

  /// Get a single flock by ID.
  Future<Flock?> getFlockById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'flocks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Flock.fromMap(maps.first);
  }

  /// Insert a new flock.
  Future<void> insertFlock(Flock flock) async {
    final db = await _db.database;

    await db.insert('flocks', flock.toMap());
  }

  /// Update an existing flock.
  Future<void> updateFlock(Flock flock) async {
    final db = await _db.database;

    await db.update(
      'flocks',
      flock.toMap(),
      where: 'id = ?',
      whereArgs: [flock.id],
    );
  }

  /// Archive a flock (soft delete).
  Future<void> archiveFlock(String id) async {
    final db = await _db.database;

    await db.update(
      'flocks',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Unarchive a flock.
  Future<void> unarchiveFlock(String id) async {
    final db = await _db.database;

    await db.update(
      'flocks',
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete a flock.
  /// Warning: This will fail if there are birds referencing this flock.
  Future<void> deleteFlock(String id) async {
    final db = await _db.database;

    await db.delete(
      'flocks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of birds in a flock.
  Future<int> getBirdCount(String flockId) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM birds WHERE flock_id = ? AND status = ?',
      [flockId, 'active'],
    );

    return result.first['count'] as int;
  }
}
