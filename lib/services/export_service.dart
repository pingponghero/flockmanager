import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

/// Service for exporting app data to CSV files in a zip archive.
class ExportService {
  final DatabaseHelper _db;

  ExportService({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  /// Export all data to a zip file and return the file path.
  Future<String> exportToZip() async {
    final db = await _db.database;
    final archive = Archive();

    // Export each table
    final flocks = await _exportTable(db, 'flocks', [
      'id',
      'name',
      'description',
      'icon',
      'color',
      'is_archived',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('flocks.csv', flocks.length, flocks));

    final birds = await _exportTable(db, 'birds', [
      'id',
      'flock_id',
      'name',
      'breed',
      'breed_id',
      'photo_primary',
      'hatch_date',
      'acquired_date',
      'source',
      'egg_color',
      'sex',
      'species',
      'status',
      'status_date',
      'status_notes',
      'notes',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('birds.csv', birds.length, birds));

    final eggLogs = await _exportTable(db, 'egg_logs', [
      'id',
      'date',
      'flock_id',
      'bird_id',
      'count',
      'size',
      'quality',
      'notes',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('egg_logs.csv', eggLogs.length, eggLogs));

    final expenses = await _exportTable(db, 'expenses', [
      'id',
      'date',
      'amount',
      'category',
      'description',
      'flock_id',
      'is_recurring',
      'recurring_interval',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('expenses.csv', expenses.length, expenses));

    final income = await _exportTable(db, 'income', [
      'id',
      'date',
      'amount',
      'description',
      'egg_count',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('income.csv', income.length, income));

    final medications = await _exportTable(db, 'medication_logs', [
      'id',
      'bird_id',
      'flock_id',
      'medication_name',
      'dosage',
      'start_date',
      'end_date',
      'withdrawal_days',
      'notes',
      'created_at',
    ]);
    archive.addFile(
        ArchiveFile('medications.csv', medications.length, medications));

    final healthNotes = await _exportTable(db, 'health_notes', [
      'id',
      'bird_id',
      'date',
      'type',
      'description',
      'created_at',
    ]);
    archive.addFile(
        ArchiveFile('health_notes.csv', healthNotes.length, healthNotes));

    // Create zip file
    final zipData = ZipEncoder().encode(archive);

    // Save to temporary directory
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final zipPath = '${tempDir.path}/flock_manager_export_$dateStr.zip';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    return zipPath;
  }

  /// Export a single table to CSV bytes.
  Future<List<int>> _exportTable(
    dynamic db,
    String tableName,
    List<String> columns,
  ) async {
    final rows = await db.query(tableName);
    final buffer = StringBuffer();

    // Write header
    buffer.writeln(columns.map(_escapeCsv).join(','));

    // Write data rows
    for (final row in rows) {
      final values = columns.map((col) {
        final value = row[col];
        return _escapeCsv(value?.toString() ?? '');
      });
      buffer.writeln(values.join(','));
    }

    return utf8.encode(buffer.toString());
  }

  /// Escape a value for CSV format.
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
