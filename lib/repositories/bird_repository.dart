import '../database/database_helper.dart';
import '../models/bird.dart';
import '../models/enums.dart';

/// Repository for bird data access operations.
class BirdRepository {
  final DatabaseHelper _db;

  BirdRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Get all birds, ordered by name.
  Future<List<Bird>> getAllBirds() async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Bird.fromMap(map)).toList();
  }

  /// Get all birds in a specific flock, ordered by name.
  Future<List<Bird>> getBirdsByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Bird.fromMap(map)).toList();
  }

  /// Get all active birds, ordered by name.
  Future<List<Bird>> getActiveBirds() async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      where: 'status = ?',
      whereArgs: [BirdStatus.active.name],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Bird.fromMap(map)).toList();
  }

  /// Get all active birds in a specific flock, ordered by name.
  Future<List<Bird>> getActiveBirdsByFlock(String flockId) async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      where: 'flock_id = ? AND status = ?',
      whereArgs: [flockId, BirdStatus.active.name],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Bird.fromMap(map)).toList();
  }

  /// Get birds by status, ordered by name.
  Future<List<Bird>> getBirdsByStatus(BirdStatus status) async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Bird.fromMap(map)).toList();
  }

  /// Get a single bird by ID.
  Future<Bird?> getBirdById(String id) async {
    final db = await _db.database;

    final maps = await db.query(
      'birds',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Bird.fromMap(maps.first);
  }

  /// Insert a new bird.
  Future<void> insertBird(Bird bird) async {
    final db = await _db.database;

    await db.insert('birds', bird.toMap());
  }

  /// Update an existing bird.
  Future<void> updateBird(Bird bird) async {
    final db = await _db.database;

    await db.update(
      'birds',
      bird.toMap(),
      where: 'id = ?',
      whereArgs: [bird.id],
    );
  }

  /// Update a bird's status with optional notes.
  Future<void> updateBirdStatus(
    String id,
    BirdStatus status,
    String? notes,
  ) async {
    final db = await _db.database;

    await db.update(
      'birds',
      {
        'status': status.name,
        'status_date': DateTime.now().toIso8601String(),
        'status_notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete a bird.
  /// Warning: This will fail if there are records referencing this bird.
  Future<void> deleteBird(String id) async {
    final db = await _db.database;

    await db.delete(
      'birds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of birds in a flock by status.
  Future<Map<BirdStatus, int>> getBirdCountsByStatus(String flockId) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      '''
      SELECT status, COUNT(*) as count
      FROM birds
      WHERE flock_id = ?
      GROUP BY status
      ''',
      [flockId],
    );

    final counts = <BirdStatus, int>{};
    for (final row in result) {
      final statusName = row['status'] as String;
      final count = row['count'] as int;
      final status = BirdStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => BirdStatus.active,
      );
      counts[status] = count;
    }
    return counts;
  }
}
