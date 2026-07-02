import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

/// Service for exporting app data to CSV files in a zip archive.
class ExportService {
  final DatabaseHelper _db;

  /// Callback for progress updates during export (0.0 to 1.0)
  final void Function(double progress)? onProgress;

  ExportService({DatabaseHelper? db, this.onProgress})
      : _db = db ?? DatabaseHelper.instance;

  static const String _appVersion = '1.1.0';
  static const int _formatVersion = 1;

  /// UTF-8 BOM prefix for CSV files (helps Excel recognize UTF-8)
  static const String _utf8Bom = '\uFEFF';

  /// Export all data to a zip file and return the file path.
  Future<String> exportToZip() async {
    final db = await _db.database;
    final archive = Archive();

    _reportProgress(0.0);

    // Gather counts for metadata
    final counts = <String, int>{};

    // Export flocks (always included)
    final flocksData = await db.query('flocks');
    counts['flocks'] = flocksData.length;
    final flocksBytes = createCsv(flocksData, [
      'id',
      'name',
      'description',
      'icon',
      'color',
      'is_archived',
      'created_at',
    ]);
    archive.addFile(ArchiveFile('flocks.csv', flocksBytes.length, flocksBytes));

    _reportProgress(0.1);

    // Export birds (always included) - handle photo_primary specially
    final birdsData = await db.query('birds');
    counts['birds'] = birdsData.length;

    // Track birds with photos for later processing
    final birdsWithPhotos = <Map<String, dynamic>>[];
    final processedBirdsData = birdsData.map((bird) {
      final photoPrimary = bird['photo_primary'] as String?;
      final birdId = bird['id'] as String;

      if (photoPrimary != null && photoPrimary.isNotEmpty) {
        birdsWithPhotos.add({
          'id': birdId,
          'photo_path': photoPrimary,
        });
        // Replace absolute path with relative filename
        return {
          ...bird,
          'photo_primary': 'bird_$birdId.jpg',
        };
      }
      return bird;
    }).toList();

    final birdsBytes = createCsv(processedBirdsData, [
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
    archive.addFile(ArchiveFile('birds.csv', birdsBytes.length, birdsBytes));

    _reportProgress(0.2);

    // Export egg_logs (if not empty)
    final eggLogsData = await db.query('egg_logs');
    counts['egg_logs'] = eggLogsData.length;
    if (eggLogsData.isNotEmpty) {
      final eggLogsBytes = createCsv(eggLogsData, [
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
      archive.addFile(
          ArchiveFile('egg_logs.csv', eggLogsBytes.length, eggLogsBytes));
    }

    _reportProgress(0.3);

    // Export expenses (if not empty)
    final expensesData = await db.query('expenses');
    counts['expenses'] = expensesData.length;
    if (expensesData.isNotEmpty) {
      final expensesBytes = createCsv(expensesData, [
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
      archive.addFile(
          ArchiveFile('expenses.csv', expensesBytes.length, expensesBytes));
    }

    _reportProgress(0.4);

    // Export income (if not empty)
    final incomeData = await db.query('income');
    counts['income'] = incomeData.length;
    if (incomeData.isNotEmpty) {
      final incomeBytes = createCsv(incomeData, [
        'id',
        'date',
        'amount',
        'description',
        'egg_count',
        'flock_id',
        'created_at',
      ]);
      archive.addFile(
          ArchiveFile('income.csv', incomeBytes.length, incomeBytes));
    }

    _reportProgress(0.5);

    // Export medication_logs (if not empty) - renamed from medications.csv
    final medicationLogsData = await db.query('medication_logs');
    counts['medication_logs'] = medicationLogsData.length;
    if (medicationLogsData.isNotEmpty) {
      final medicationLogsBytes = createCsv(medicationLogsData, [
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
      archive.addFile(ArchiveFile(
          'medication_logs.csv', medicationLogsBytes.length, medicationLogsBytes));
    }

    _reportProgress(0.6);

    // Export health_notes (if not empty)
    final healthNotesData = await db.query('health_notes');
    counts['health_notes'] = healthNotesData.length;
    if (healthNotesData.isNotEmpty) {
      final healthNotesBytes = createCsv(healthNotesData, [
        'id',
        'bird_id',
        'date',
        'type',
        'description',
        'created_at',
      ]);
      archive.addFile(ArchiveFile(
          'health_notes.csv', healthNotesBytes.length, healthNotesBytes));
    }

    _reportProgress(0.65);

    // Export bird_status_events — exclude events for deleted birds
    // (deleted birds are hard-deleted and should not be exported)
    final birdIds = birdsData.map((b) => b['id'] as String).toSet();
    final birdStatusEventsData = (await db.query('bird_status_events'))
        .where((e) =>
            e['status'] != 'deleted' &&
            birdIds.contains(e['bird_id'] as String))
        .toList();
    counts['bird_status_events'] = birdStatusEventsData.length;
    if (birdStatusEventsData.isNotEmpty) {
      final birdStatusEventsBytes = createCsv(birdStatusEventsData, [
        'id',
        'bird_id',
        'flock_id',
        'status',
        'event_date',
        'notes',
        'created_at',
      ]);
      archive.addFile(ArchiveFile('bird_status_events.csv',
          birdStatusEventsBytes.length, birdStatusEventsBytes));
    }

    _reportProgress(0.7);

    // Export photos
    int photoCount = 0;
    if (birdsWithPhotos.isNotEmpty) {
      final totalPhotos = birdsWithPhotos.length;
      for (var i = 0; i < birdsWithPhotos.length; i++) {
        final birdPhoto = birdsWithPhotos[i];
        final photoPath = birdPhoto['photo_path'] as String;
        final birdId = birdPhoto['id'] as String;

        try {
          final photoFile = File(photoPath);
          if (await photoFile.exists()) {
            final photoBytes = await photoFile.readAsBytes();
            archive.addFile(ArchiveFile(
                'photos/bird_$birdId.jpg', photoBytes.length, photoBytes));
            photoCount++;
          }
        } catch (e) {
          // Skip photos that can't be read
        }

        // Update progress for photos (0.7 to 0.9)
        _reportProgress(0.7 + (0.2 * (i + 1) / totalPhotos));
      }
    }
    counts['photos'] = photoCount;

    // Create metadata
    final metadata = {
      'app_version': _appVersion,
      'export_date': DateTime.now().toUtc().toIso8601String(),
      'format_version': _formatVersion,
      'counts': counts,
    };
    final metadataJson = jsonEncode(metadata);
    final metadataBytes = utf8.encode(metadataJson);
    archive.addFile(ArchiveFile(
        'export_metadata.json', metadataBytes.length, metadataBytes));

    _reportProgress(0.95);

    // Create zip file
    final zipData = ZipEncoder().encode(archive);

    // Save to temporary directory with new filename format
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final zipPath = '${tempDir.path}/flock_export_$dateStr.zip';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData);

    _reportProgress(1.0);

    return zipPath;
  }

  /// Create CSV bytes from data with UTF-8 BOM prefix
  @visibleForTesting
  List<int> createCsv(
    List<Map<String, dynamic>> rows,
    List<String> columns,
  ) {
    final buffer = StringBuffer();

    // Add UTF-8 BOM
    buffer.write(_utf8Bom);

    // Write header
    buffer.writeln(columns.map(_escapeCsv).join(','));

    // Write data rows
    for (final row in rows) {
      final values = columns.map((col) {
        final value = row[col];
        return _formatCsvValue(value);
      });
      buffer.writeln(values.join(','));
    }

    return utf8.encode(buffer.toString());
  }

  /// Format a value for CSV export
  String _formatCsvValue(dynamic value) {
    if (value == null) {
      return ''; // Empty string for nulls, never "null" text
    }

    // Handle booleans stored as integers
    if (value is int && (value == 0 || value == 1)) {
      // Check if this could be a boolean field
      return value.toString();
    }

    return _escapeCsv(value.toString());
  }

  /// Escape a value for CSV format.
  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Report progress if callback is set
  void _reportProgress(double progress) {
    onProgress?.call(progress);
  }
}
