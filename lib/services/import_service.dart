import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/import_result.dart';

/// Service for importing app data from a ZIP archive.
class ImportService {
  final DatabaseHelper _db;

  /// Callback for progress updates during import (0.0 to 1.0)
  final void Function(double progress)? onProgress;

  ImportService({DatabaseHelper? db, this.onProgress})
      : _db = db ?? DatabaseHelper.instance;

  static const int _supportedFormatVersion = 1;

  /// UTF-8 BOM character to strip from CSV files
  static const String _utf8Bom = '\uFEFF';

  /// Get a preview of the import from metadata without performing the import.
  Future<ImportPreview> getPreview(File zipFile) async {
    final filename = p.basename(zipFile.path);

    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Look for metadata file
      final metadataFile = archive.findFile('export_metadata.json');
      if (metadataFile == null) {
        // Legacy backup without metadata
        return ImportPreview.legacy(filename);
      }

      final metadataJson = utf8.decode(metadataFile.content as List<int>);
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;

      return ImportPreview.fromMetadata(metadata, filename);
    } catch (e) {
      throw ImportException('Failed to read backup file: $e');
    }
  }

  /// Import all data from a ZIP file.
  Future<ImportResult> importFromZip(File zipFile) async {
    _reportProgress(0.0);

    // 1. Extract ZIP to temp directory
    Directory? tempDir;
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      tempDir = await _extractToTemp(archive);
      _reportProgress(0.1);

      // 2. Validate structure and check metadata
      await _validateStructure(tempDir);
      _reportProgress(0.15);

      // 3. Parse and validate all CSVs
      final data = await _parseAllCsvs(tempDir);
      _reportProgress(0.3);

      // 4. Validate foreign key relationships
      _validateForeignKeys(data);
      _reportProgress(0.35);

      // 5. Get photo directory and prepare for photo import
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      final photosFolder = Directory('${tempDir.path}/photos');
      final hasPhotosFolder = await photosFolder.exists();

      // Track warnings
      final warnings = <String>[];

      // 6. Begin database transaction
      final db = await _db.database;

      int flocksCount = 0;
      int birdsCount = 0;
      int photosCount = 0;
      int eggLogsCount = 0;
      int expensesCount = 0;
      int incomeCount = 0;
      int medicationLogsCount = 0;
      int healthNotesCount = 0;

      await db.transaction((txn) async {
        _reportProgress(0.4);

        // 7. Delete all existing data (reverse dependency order)
        await txn.delete('health_notes');
        await txn.delete('medication_logs');
        await txn.delete('income');
        await txn.delete('expenses');
        await txn.delete('egg_logs');
        await txn.delete('bird_status_events');
        await txn.delete('bird_photos');
        await txn.delete('birds');
        await txn.delete('flocks');
        _reportProgress(0.45);

        // 8. Delete existing photo files
        if (await photoDir.exists()) {
          await for (final entity in photoDir.list()) {
            if (entity is File) {
              await entity.delete();
            }
          }
        } else {
          await photoDir.create(recursive: true);
        }
        _reportProgress(0.5);

        // 9. Insert imported data (dependency order)

        // Insert flocks
        for (final flock in data.flocks) {
          await txn.insert('flocks', flock);
          flocksCount++;
        }
        _reportProgress(0.55);

        // Insert birds (with photo paths cleared initially)
        final birdPhotoRefs = <String, String>{}; // bird_id -> relative photo filename
        for (final bird in data.birds) {
          final photoRef = bird['photo_primary'] as String?;
          if (photoRef != null && photoRef.isNotEmpty) {
            birdPhotoRefs[bird['id'] as String] = photoRef;
          }
          // Insert with empty photo_primary, we'll update after extracting photos
          await txn.insert('birds', {...bird, 'photo_primary': null});
          birdsCount++;
        }
        _reportProgress(0.6);

        // 10. Extract photos and update bird records
        if (hasPhotosFolder) {
          for (final entry in birdPhotoRefs.entries) {
            final birdId = entry.key;
            final photoFilename = entry.value;
            final sourceFile = File('${photosFolder.path}/$photoFilename');

            if (await sourceFile.exists()) {
              try {
                // Copy photo to app storage
                final destPath = '${photoDir.path}/$photoFilename';
                await sourceFile.copy(destPath);

                // Update bird record with new absolute path
                await txn.update(
                  'birds',
                  {'photo_primary': destPath},
                  where: 'id = ?',
                  whereArgs: [birdId],
                );
                photosCount++;
              } catch (e) {
                warnings.add('Failed to import photo for bird $birdId: $e');
              }
            } else {
              // Photo file missing - just log warning
              final birdName = data.birds
                  .firstWhere((b) => b['id'] == birdId)['name'] as String?;
              warnings.add(
                  "Photo missing for bird '${birdName ?? birdId}' (expected: $photoFilename)");
            }
          }
        } else if (birdPhotoRefs.isNotEmpty) {
          // No photos folder but birds have photo references
          for (final entry in birdPhotoRefs.entries) {
            final birdId = entry.key;
            final birdName = data.birds
                .firstWhere((b) => b['id'] == birdId)['name'] as String?;
            warnings.add("Photo missing for bird '${birdName ?? birdId}'");
          }
        }
        _reportProgress(0.7);

        // Insert egg logs
        for (final eggLog in data.eggLogs) {
          await txn.insert('egg_logs', eggLog);
          eggLogsCount++;
        }
        _reportProgress(0.75);

        // Insert expenses
        for (final expense in data.expenses) {
          await txn.insert('expenses', expense);
          expensesCount++;
        }
        _reportProgress(0.8);

        // Insert income
        for (final inc in data.income) {
          await txn.insert('income', inc);
          incomeCount++;
        }
        _reportProgress(0.85);

        // Insert medication logs
        for (final medLog in data.medicationLogs) {
          await txn.insert('medication_logs', medLog);
          medicationLogsCount++;
        }
        _reportProgress(0.9);

        // Insert health notes
        for (final healthNote in data.healthNotes) {
          await txn.insert('health_notes', healthNote);
          healthNotesCount++;
        }

        // Insert bird_status_events — from CSV if available, otherwise
        // reconstruct from bird created_at/status/status_date fields.
        if (data.birdStatusEvents.isNotEmpty) {
          for (final event in data.birdStatusEvents) {
            await txn.insert('bird_status_events', event);
          }
        } else {
          // Reconstruct: each bird gets an 'active' event at created_at,
          // plus a status-change event if currently non-active.
          const uuid = Uuid();
          for (final bird in data.birds) {
            final birdId = bird['id'] as String;
            final flockId = bird['flock_id'] as String;
            final createdAt = bird['created_at'] as String;
            final status = bird['status'] as String? ?? 'active';
            final statusDate = bird['status_date'] as String?;

            await txn.insert('bird_status_events', {
              'id': uuid.v4(),
              'bird_id': birdId,
              'flock_id': flockId,
              'status': 'active',
              'event_date': createdAt,
              'notes': null,
              'created_at': createdAt,
            });

            if (status != 'active' && statusDate != null) {
              await txn.insert('bird_status_events', {
                'id': uuid.v4(),
                'bird_id': birdId,
                'flock_id': flockId,
                'status': status,
                'event_date': statusDate,
                'notes': bird['status_notes'] as String?,
                'created_at': statusDate,
              });
            }
          }
        }
        _reportProgress(0.95);
      });

      // 11. Clean up temp directory
      await tempDir.delete(recursive: true);
      tempDir = null;

      _reportProgress(1.0);

      return ImportResult.ok(
        flocks: flocksCount,
        birds: birdsCount,
        photos: photosCount,
        eggLogs: eggLogsCount,
        expenses: expensesCount,
        income: incomeCount,
        medicationLogs: medicationLogsCount,
        healthNotes: healthNotesCount,
        warnings: warnings,
      );
    } catch (e) {
      // Clean up temp directory on error
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      if (e is ImportException) {
        return ImportResult.failure(e.message);
      }
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Extract ZIP archive to a temporary directory.
  Future<Directory> _extractToTemp(Archive archive) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir =
        Directory('${tempDir.path}/flock_import_${DateTime.now().millisecondsSinceEpoch}');
    await extractDir.create();

    for (final file in archive) {
      if (file.isFile) {
        final filePath = '${extractDir.path}/${file.name}';
        final outputFile = File(filePath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    }

    return extractDir;
  }

  /// Validate the ZIP structure.
  Future<void> _validateStructure(Directory tempDir) async {
    // Check for required files
    final flocksFile = File('${tempDir.path}/flocks.csv');
    final birdsFile = File('${tempDir.path}/birds.csv');

    if (!await flocksFile.exists()) {
      throw ImportException(
          'This backup is incomplete. Missing required file: flocks.csv');
    }
    if (!await birdsFile.exists()) {
      throw ImportException(
          'This backup is incomplete. Missing required file: birds.csv');
    }

    // Check metadata if present
    final metadataFile = File('${tempDir.path}/export_metadata.json');
    if (await metadataFile.exists()) {
      try {
        final metadataJson = await metadataFile.readAsString();
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        final formatVersion = metadata['format_version'] as int? ?? 1;

        if (formatVersion > _supportedFormatVersion) {
          throw ImportException(
              'This backup is from a newer version of Flock Manager. Please update the app.');
        }
      } catch (e) {
        if (e is ImportException) rethrow;
        // Ignore metadata parse errors for legacy backups
      }
    }
  }

  /// Parse all CSV files and return the data.
  Future<_ParsedData> _parseAllCsvs(Directory tempDir) async {
    final flocks = await _parseCsv(
      File('${tempDir.path}/flocks.csv'),
      'flocks.csv',
      ['id', 'name', 'description', 'icon', 'color', 'is_archived', 'created_at'],
      ['id', 'name', 'created_at'],
    );

    final birds = await _parseCsv(
      File('${tempDir.path}/birds.csv'),
      'birds.csv',
      [
        'id', 'flock_id', 'name', 'breed', 'breed_id', 'photo_primary',
        'hatch_date', 'acquired_date', 'source', 'egg_color', 'sex', 'species',
        'status', 'status_date', 'status_notes', 'notes', 'created_at'
      ],
      ['id', 'flock_id', 'name', 'created_at'],
    );

    // Optional CSVs
    List<Map<String, dynamic>> eggLogs = [];
    final eggLogsFile = File('${tempDir.path}/egg_logs.csv');
    if (await eggLogsFile.exists()) {
      eggLogs = await _parseCsv(
        eggLogsFile,
        'egg_logs.csv',
        ['id', 'date', 'flock_id', 'bird_id', 'count', 'size', 'quality', 'notes', 'created_at'],
        ['id', 'date', 'flock_id', 'count', 'created_at'],
      );
    }

    List<Map<String, dynamic>> expenses = [];
    final expensesFile = File('${tempDir.path}/expenses.csv');
    if (await expensesFile.exists()) {
      expenses = await _parseCsv(
        expensesFile,
        'expenses.csv',
        [
          'id', 'date', 'amount', 'category', 'description', 'flock_id',
          'is_recurring', 'recurring_interval', 'created_at'
        ],
        ['id', 'date', 'amount', 'category', 'created_at'],
      );
    }

    List<Map<String, dynamic>> income = [];
    final incomeFile = File('${tempDir.path}/income.csv');
    if (await incomeFile.exists()) {
      income = await _parseCsv(
        incomeFile,
        'income.csv',
        ['id', 'date', 'amount', 'description', 'egg_count', 'flock_id', 'created_at'],
        ['id', 'date', 'amount', 'created_at'],
      );
    }

    List<Map<String, dynamic>> medicationLogs = [];
    // Support both old name (medications.csv) and new name (medication_logs.csv)
    File medicationLogsFile = File('${tempDir.path}/medication_logs.csv');
    if (!await medicationLogsFile.exists()) {
      medicationLogsFile = File('${tempDir.path}/medications.csv');
    }
    if (await medicationLogsFile.exists()) {
      medicationLogs = await _parseCsv(
        medicationLogsFile,
        'medication_logs.csv',
        [
          'id', 'bird_id', 'flock_id', 'medication_name', 'dosage',
          'start_date', 'end_date', 'withdrawal_days', 'notes', 'created_at'
        ],
        ['id', 'flock_id', 'medication_name', 'start_date', 'created_at'],
      );
    }

    List<Map<String, dynamic>> healthNotes = [];
    final healthNotesFile = File('${tempDir.path}/health_notes.csv');
    if (await healthNotesFile.exists()) {
      healthNotes = await _parseCsv(
        healthNotesFile,
        'health_notes.csv',
        ['id', 'bird_id', 'date', 'type', 'description', 'created_at'],
        ['id', 'bird_id', 'date', 'type', 'description', 'created_at'],
      );
    }

    List<Map<String, dynamic>> birdStatusEvents = [];
    final birdStatusEventsFile = File('${tempDir.path}/bird_status_events.csv');
    if (await birdStatusEventsFile.exists()) {
      birdStatusEvents = await _parseCsv(
        birdStatusEventsFile,
        'bird_status_events.csv',
        ['id', 'bird_id', 'flock_id', 'status', 'event_date', 'notes', 'created_at'],
        ['id', 'bird_id', 'flock_id', 'status', 'event_date', 'created_at'],
      );
    }

    return _ParsedData(
      flocks: flocks,
      birds: birds,
      eggLogs: eggLogs,
      expenses: expenses,
      income: income,
      medicationLogs: medicationLogs,
      healthNotes: healthNotes,
      birdStatusEvents: birdStatusEvents,
    );
  }

  /// Parse a single CSV file.
  Future<List<Map<String, dynamic>>> _parseCsv(
    File file,
    String filename,
    List<String> expectedColumns,
    List<String> requiredColumns,
  ) async {
    String content = await file.readAsString();

    // Remove UTF-8 BOM if present
    if (content.startsWith(_utf8Bom)) {
      content = content.substring(1);
    }

    final lines = _parseCsvLines(content);
    if (lines.isEmpty) {
      throw ImportException('$filename is empty');
    }

    // Parse header
    final header = lines.first;

    // Validate header matches expected columns
    final headerSet = header.toSet();
    final expectedSet = expectedColumns.toSet();

    // Check for missing required columns
    for (final col in requiredColumns) {
      if (!headerSet.contains(col)) {
        throw ImportException(
            '$filename is missing required column: $col');
      }
    }

    // Parse data rows
    final results = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final row = lines[i];
      if (row.length != header.length) {
        throw ImportException(
            'Could not read $filename row ${i + 1}: column count mismatch');
      }

      final map = <String, dynamic>{};
      for (var j = 0; j < header.length; j++) {
        final colName = header[j];
        // Only include columns that we expect
        if (expectedSet.contains(colName)) {
          final value = row[j];
          map[colName] = _parseValue(colName, value, filename, i + 1);
        }
      }

      // Validate required fields are non-empty
      for (final col in requiredColumns) {
        if (map[col] == null || (map[col] is String && (map[col] as String).isEmpty)) {
          throw ImportException(
              'Could not read $filename row ${i + 1}: $col cannot be empty');
        }
      }

      results.add(map);
    }

    return results;
  }

  /// Parse CSV content into rows of columns.
  List<List<String>> _parseCsvLines(String content) {
    final lines = <List<String>>[];
    final rows = content.split('\n');

    for (final row in rows) {
      final trimmed = row.trim();
      if (trimmed.isEmpty) continue;

      final columns = _parseCsvRow(trimmed);
      lines.add(columns);
    }

    return lines;
  }

  /// Parse a single CSV row handling quotes correctly.
  List<String> _parseCsvRow(String row) {
    final columns = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < row.length) {
      final char = row[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote
          if (i + 1 < row.length && row[i + 1] == '"') {
            current.write('"');
            i += 2;
          } else {
            // End of quoted field
            inQuotes = false;
            i++;
          }
        } else {
          current.write(char);
          i++;
        }
      } else {
        if (char == '"') {
          inQuotes = true;
          i++;
        } else if (char == ',') {
          columns.add(current.toString());
          current = StringBuffer();
          i++;
        } else {
          current.write(char);
          i++;
        }
      }
    }

    // Add last column
    columns.add(current.toString());

    return columns;
  }

  /// Parse a CSV value to the appropriate type.
  dynamic _parseValue(String column, String value, String filename, int row) {
    // Empty strings become null
    if (value.isEmpty) return null;

    // Boolean fields (stored as 0/1 in SQLite)
    if (column == 'is_archived' || column == 'is_recurring') {
      if (value == '0' || value.toLowerCase() == 'false') return 0;
      if (value == '1' || value.toLowerCase() == 'true') return 1;
      throw ImportException(
          'Could not read $filename row $row: invalid boolean value for $column: $value');
    }

    // Integer fields
    if (column == 'count' || column == 'withdrawal_days' || column == 'egg_count') {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw ImportException(
            'Could not read $filename row $row: invalid integer for $column: $value');
      }
      return parsed;
    }

    // Decimal fields
    if (column == 'amount') {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw ImportException(
            'Could not read $filename row $row: invalid decimal for $column: $value');
      }
      return parsed;
    }

    // Date fields - validate format
    if (column.endsWith('_date') || column == 'date' || column == 'created_at') {
      try {
        DateTime.parse(value);
      } catch (e) {
        throw ImportException(
            'Could not read $filename row $row: invalid date format for $column: $value');
      }
      return value; // Keep as string for SQLite
    }

    // Enum fields - validate against known values
    if (column == 'status') {
      const validValues = ['active', 'deceased', 'sold', 'givenAway'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid status value: $value');
      }
    }
    if (column == 'sex') {
      const validValues = ['female', 'male', 'unknown'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid sex value: $value');
      }
    }
    if (column == 'species') {
      const validValues = ['chicken', 'duck', 'turkey', 'other'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid species value: $value');
      }
    }
    if (column == 'size') {
      const validValues = ['small', 'medium', 'large', 'jumbo'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid size value: $value');
      }
    }
    if (column == 'quality') {
      const validValues = ['normal', 'softShell', 'doubleYolk', 'fairy', 'abnormal'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid quality value: $value');
      }
    }
    if (column == 'category') {
      const validValues = ['feed', 'bedding', 'supplies', 'medical', 'equipment', 'other'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid category value: $value');
      }
    }
    if (column == 'recurring_interval') {
      const validValues = ['weekly', 'monthly'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid recurring_interval value: $value');
      }
    }
    if (column == 'type' && filename.contains('health')) {
      const validValues = ['observation', 'symptom', 'treatment', 'vetVisit', 'other'];
      if (!validValues.contains(value)) {
        throw ImportException(
            'Could not read $filename row $row: invalid health note type value: $value');
      }
    }

    return value;
  }

  /// Validate foreign key relationships in the parsed data.
  void _validateForeignKeys(_ParsedData data) {
    // Build sets of valid IDs
    final flockIds = data.flocks.map((f) => f['id'] as String).toSet();
    final birdIds = data.birds.map((b) => b['id'] as String).toSet();

    // Validate bird flock_ids
    for (final bird in data.birds) {
      final flockId = bird['flock_id'] as String;
      if (!flockIds.contains(flockId)) {
        throw ImportException(
            "birds.csv references a flock that doesn't exist: $flockId");
      }
    }

    // Validate egg_log references
    for (final eggLog in data.eggLogs) {
      final flockId = eggLog['flock_id'] as String;
      if (!flockIds.contains(flockId)) {
        throw ImportException(
            "egg_logs.csv references a flock that doesn't exist: $flockId");
      }
      final birdId = eggLog['bird_id'] as String?;
      if (birdId != null && birdId.isNotEmpty && !birdIds.contains(birdId)) {
        throw ImportException(
            "egg_logs.csv references a bird that doesn't exist: $birdId");
      }
    }

    // Validate expense references
    for (final expense in data.expenses) {
      final flockId = expense['flock_id'] as String?;
      if (flockId != null && flockId.isNotEmpty && !flockIds.contains(flockId)) {
        throw ImportException(
            "expenses.csv references a flock that doesn't exist: $flockId");
      }
    }

    // Validate medication log references
    for (final medLog in data.medicationLogs) {
      final flockId = medLog['flock_id'] as String;
      if (!flockIds.contains(flockId)) {
        throw ImportException(
            "medication_logs.csv references a flock that doesn't exist: $flockId");
      }
      final birdId = medLog['bird_id'] as String?;
      if (birdId != null && birdId.isNotEmpty && !birdIds.contains(birdId)) {
        throw ImportException(
            "medication_logs.csv references a bird that doesn't exist: $birdId");
      }
    }

    // Validate health note references
    for (final healthNote in data.healthNotes) {
      final birdId = healthNote['bird_id'] as String;
      if (!birdIds.contains(birdId)) {
        throw ImportException(
            "health_notes.csv references a bird that doesn't exist: $birdId");
      }
    }
  }

  /// Report progress if callback is set.
  void _reportProgress(double progress) {
    onProgress?.call(progress);
  }
}

/// Parsed CSV data.
class _ParsedData {
  final List<Map<String, dynamic>> flocks;
  final List<Map<String, dynamic>> birds;
  final List<Map<String, dynamic>> eggLogs;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> income;
  final List<Map<String, dynamic>> medicationLogs;
  final List<Map<String, dynamic>> healthNotes;
  final List<Map<String, dynamic>> birdStatusEvents;

  _ParsedData({
    required this.flocks,
    required this.birds,
    required this.eggLogs,
    required this.expenses,
    required this.income,
    required this.medicationLogs,
    required this.healthNotes,
    required this.birdStatusEvents,
  });
}

/// Exception thrown during import.
class ImportException implements Exception {
  final String message;
  ImportException(this.message);

  @override
  String toString() => message;
}
