/// Result of a data import operation.
class ImportResult {
  /// Whether the import completed successfully.
  final bool success;

  /// Error message if import failed.
  final String? errorMessage;

  /// Number of flocks imported.
  final int flocksImported;

  /// Number of birds imported.
  final int birdsImported;

  /// Number of photos imported.
  final int photosImported;

  /// Number of egg logs imported.
  final int eggLogsImported;

  /// Number of expenses imported.
  final int expensesImported;

  /// Number of income records imported.
  final int incomeImported;

  /// Number of medication logs imported.
  final int medicationLogsImported;

  /// Number of health notes imported.
  final int healthNotesImported;

  /// Warnings generated during import (e.g., missing photos).
  final List<String> warnings;

  const ImportResult({
    required this.success,
    this.errorMessage,
    this.flocksImported = 0,
    this.birdsImported = 0,
    this.photosImported = 0,
    this.eggLogsImported = 0,
    this.expensesImported = 0,
    this.incomeImported = 0,
    this.medicationLogsImported = 0,
    this.healthNotesImported = 0,
    this.warnings = const [],
  });

  /// Create a failed import result with an error message.
  factory ImportResult.failure(String error) {
    return ImportResult(
      success: false,
      errorMessage: error,
    );
  }

  /// Create a successful import result with counts.
  factory ImportResult.ok({
    required int flocks,
    required int birds,
    required int photos,
    required int eggLogs,
    required int expenses,
    required int income,
    required int medicationLogs,
    required int healthNotes,
    List<String> warnings = const [],
  }) {
    return ImportResult(
      success: true,
      flocksImported: flocks,
      birdsImported: birds,
      photosImported: photos,
      eggLogsImported: eggLogs,
      expensesImported: expenses,
      incomeImported: income,
      medicationLogsImported: medicationLogs,
      healthNotesImported: healthNotes,
      warnings: warnings,
    );
  }

  /// Get a human-readable summary of what was imported.
  String get summaryMessage {
    if (!success) {
      return errorMessage ?? 'Import failed';
    }

    final parts = <String>[];

    if (flocksImported > 0) {
      parts.add('$flocksImported ${flocksImported == 1 ? 'flock' : 'flocks'}');
    }
    if (birdsImported > 0) {
      final photoSuffix = photosImported > 0 ? ' ($photosImported with photos)' : '';
      parts.add('$birdsImported ${birdsImported == 1 ? 'bird' : 'birds'}$photoSuffix');
    }
    if (eggLogsImported > 0) {
      parts.add('$eggLogsImported egg ${eggLogsImported == 1 ? 'log' : 'logs'}');
    }
    if (expensesImported > 0) {
      parts.add('$expensesImported ${expensesImported == 1 ? 'expense' : 'expenses'}');
    }
    if (incomeImported > 0) {
      parts.add('$incomeImported income ${incomeImported == 1 ? 'record' : 'records'}');
    }
    if (medicationLogsImported > 0) {
      parts.add('$medicationLogsImported medication ${medicationLogsImported == 1 ? 'log' : 'logs'}');
    }
    if (healthNotesImported > 0) {
      parts.add('$healthNotesImported health ${healthNotesImported == 1 ? 'note' : 'notes'}');
    }

    if (parts.isEmpty) {
      return 'No data imported';
    }

    return 'Imported ${parts.join(', ')}';
  }

  /// Total number of records imported.
  int get totalRecords =>
      flocksImported +
      birdsImported +
      eggLogsImported +
      expensesImported +
      incomeImported +
      medicationLogsImported +
      healthNotesImported;

  /// Whether there are any warnings.
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Preview of what will be imported (from metadata).
class ImportPreview {
  /// The export date from metadata.
  final DateTime? exportDate;

  /// The app version that created the export.
  final String? appVersion;

  /// The format version of the export.
  final int formatVersion;

  /// Number of flocks in the backup.
  final int flocksCount;

  /// Number of birds in the backup.
  final int birdsCount;

  /// Number of photos in the backup.
  final int photosCount;

  /// Number of egg logs in the backup.
  final int eggLogsCount;

  /// Number of expenses in the backup.
  final int expensesCount;

  /// Number of income records in the backup.
  final int incomeCount;

  /// Number of medication logs in the backup.
  final int medicationLogsCount;

  /// Number of health notes in the backup.
  final int healthNotesCount;

  /// The filename of the backup.
  final String filename;

  const ImportPreview({
    this.exportDate,
    this.appVersion,
    this.formatVersion = 1,
    this.flocksCount = 0,
    this.birdsCount = 0,
    this.photosCount = 0,
    this.eggLogsCount = 0,
    this.expensesCount = 0,
    this.incomeCount = 0,
    this.medicationLogsCount = 0,
    this.healthNotesCount = 0,
    required this.filename,
  });

  /// Create from export_metadata.json contents.
  factory ImportPreview.fromMetadata(
    Map<String, dynamic> metadata,
    String filename,
  ) {
    final counts = metadata['counts'] as Map<String, dynamic>? ?? {};

    DateTime? exportDate;
    if (metadata['export_date'] != null) {
      try {
        exportDate = DateTime.parse(metadata['export_date'] as String);
      } catch (_) {
        // Ignore parse errors
      }
    }

    return ImportPreview(
      exportDate: exportDate,
      appVersion: metadata['app_version'] as String?,
      formatVersion: metadata['format_version'] as int? ?? 1,
      flocksCount: counts['flocks'] as int? ?? 0,
      birdsCount: counts['birds'] as int? ?? 0,
      photosCount: counts['photos'] as int? ?? 0,
      eggLogsCount: counts['egg_logs'] as int? ?? 0,
      expensesCount: counts['expenses'] as int? ?? 0,
      incomeCount: counts['income'] as int? ?? 0,
      medicationLogsCount: counts['medication_logs'] as int? ?? 0,
      healthNotesCount: counts['health_notes'] as int? ?? 0,
      filename: filename,
    );
  }

  /// Create a preview without metadata (legacy backup).
  factory ImportPreview.legacy(String filename) {
    return ImportPreview(
      formatVersion: 0,
      filename: filename,
    );
  }

  /// Whether this is a legacy backup (no metadata).
  bool get isLegacy => formatVersion == 0;

  /// Whether the format version is supported.
  bool get isSupported => formatVersion <= 1;

  /// Total record count.
  int get totalRecords =>
      flocksCount +
      birdsCount +
      eggLogsCount +
      expensesCount +
      incomeCount +
      medicationLogsCount +
      healthNotesCount;
}
