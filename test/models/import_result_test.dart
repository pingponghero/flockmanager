import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/import_result.dart';

void main() {
  group('ImportResult', () {
    group('factory constructors', () {
      test('failure() creates failed result with error message', () {
        final result = ImportResult.failure('Something went wrong');

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Something went wrong');
        expect(result.flocksImported, 0);
        expect(result.birdsImported, 0);
      });

      test('ok() creates successful result with counts', () {
        final result = ImportResult.ok(
          flocks: 2,
          birds: 8,
          photos: 5,
          eggLogs: 142,
          expenses: 23,
          income: 5,
          medicationLogs: 3,
          healthNotes: 12,
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.flocksImported, 2);
        expect(result.birdsImported, 8);
        expect(result.photosImported, 5);
        expect(result.eggLogsImported, 142);
        expect(result.expensesImported, 23);
        expect(result.incomeImported, 5);
        expect(result.medicationLogsImported, 3);
        expect(result.healthNotesImported, 12);
      });

      test('ok() includes warnings when provided', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 2,
          photos: 1,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
          warnings: ['Photo missing for bird Henrietta'],
        );

        expect(result.hasWarnings, isTrue);
        expect(result.warnings, contains('Photo missing for bird Henrietta'));
      });
    });

    group('summaryMessage', () {
      test('returns error message when failed', () {
        final result = ImportResult.failure('Import failed');

        expect(result.summaryMessage, 'Import failed');
      });

      test('returns "No data imported" when all counts are zero', () {
        final result = ImportResult.ok(
          flocks: 0,
          birds: 0,
          photos: 0,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
        );

        expect(result.summaryMessage, 'No data imported');
      });

      test('formats singular items correctly', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 1,
          photos: 1,
          eggLogs: 1,
          expenses: 1,
          income: 1,
          medicationLogs: 1,
          healthNotes: 1,
        );

        expect(result.summaryMessage, contains('1 flock'));
        expect(result.summaryMessage, contains('1 bird'));
        expect(result.summaryMessage, contains('1 egg log'));
        expect(result.summaryMessage, contains('1 expense'));
        expect(result.summaryMessage, contains('1 income record'));
        expect(result.summaryMessage, contains('1 medication log'));
        expect(result.summaryMessage, contains('1 health note'));
      });

      test('formats plural items correctly', () {
        final result = ImportResult.ok(
          flocks: 2,
          birds: 5,
          photos: 3,
          eggLogs: 10,
          expenses: 4,
          income: 2,
          medicationLogs: 3,
          healthNotes: 6,
        );

        expect(result.summaryMessage, contains('2 flocks'));
        expect(result.summaryMessage, contains('5 birds'));
        expect(result.summaryMessage, contains('10 egg logs'));
        expect(result.summaryMessage, contains('4 expenses'));
        expect(result.summaryMessage, contains('2 income records'));
        expect(result.summaryMessage, contains('3 medication logs'));
        expect(result.summaryMessage, contains('6 health notes'));
      });

      test('includes photo count in bird summary', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 5,
          photos: 3,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
        );

        expect(result.summaryMessage, contains('5 birds (3 with photos)'));
      });

      test('omits photo count when zero', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 5,
          photos: 0,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
        );

        expect(result.summaryMessage, isNot(contains('with photos')));
      });
    });

    group('totalRecords', () {
      test('returns sum of all imported records', () {
        final result = ImportResult.ok(
          flocks: 2,
          birds: 8,
          photos: 5,
          eggLogs: 100,
          expenses: 20,
          income: 10,
          medicationLogs: 5,
          healthNotes: 15,
        );

        // Total = 2 + 8 + 100 + 20 + 10 + 5 + 15 = 160 (photos not counted)
        expect(result.totalRecords, 160);
      });
    });

    group('hasWarnings', () {
      test('returns false when no warnings', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 1,
          photos: 0,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
        );

        expect(result.hasWarnings, isFalse);
      });

      test('returns true when warnings present', () {
        final result = ImportResult.ok(
          flocks: 1,
          birds: 1,
          photos: 0,
          eggLogs: 0,
          expenses: 0,
          income: 0,
          medicationLogs: 0,
          healthNotes: 0,
          warnings: ['Warning 1'],
        );

        expect(result.hasWarnings, isTrue);
      });
    });
  });

  group('ImportPreview', () {
    group('fromMetadata', () {
      test('parses metadata correctly', () {
        final metadata = {
          'app_version': '1.1.0',
          'export_date': '2024-01-15T10:30:00.000Z',
          'format_version': 1,
          'counts': {
            'flocks': 2,
            'birds': 8,
            'photos': 5,
            'egg_logs': 142,
            'expenses': 23,
            'income': 5,
            'medication_logs': 3,
            'health_notes': 12,
          },
        };

        final preview = ImportPreview.fromMetadata(metadata, 'backup.zip');

        expect(preview.appVersion, '1.1.0');
        expect(preview.exportDate, isNotNull);
        expect(preview.formatVersion, 1);
        expect(preview.flocksCount, 2);
        expect(preview.birdsCount, 8);
        expect(preview.photosCount, 5);
        expect(preview.eggLogsCount, 142);
        expect(preview.expensesCount, 23);
        expect(preview.incomeCount, 5);
        expect(preview.medicationLogsCount, 3);
        expect(preview.healthNotesCount, 12);
        expect(preview.filename, 'backup.zip');
      });

      test('handles missing counts gracefully', () {
        final metadata = {
          'app_version': '1.0.0',
          'format_version': 1,
        };

        final preview = ImportPreview.fromMetadata(metadata, 'backup.zip');

        expect(preview.flocksCount, 0);
        expect(preview.birdsCount, 0);
        expect(preview.photosCount, 0);
      });

      test('handles missing format_version', () {
        final metadata = {
          'app_version': '1.0.0',
        };

        final preview = ImportPreview.fromMetadata(metadata, 'backup.zip');

        expect(preview.formatVersion, 1);
      });

      test('handles invalid export_date gracefully', () {
        final metadata = {
          'export_date': 'invalid-date',
          'format_version': 1,
        };

        final preview = ImportPreview.fromMetadata(metadata, 'backup.zip');

        expect(preview.exportDate, isNull);
      });
    });

    group('legacy', () {
      test('creates preview with format_version 0', () {
        final preview = ImportPreview.legacy('old_backup.zip');

        expect(preview.formatVersion, 0);
        expect(preview.isLegacy, isTrue);
        expect(preview.filename, 'old_backup.zip');
        expect(preview.flocksCount, 0);
      });
    });

    group('isSupported', () {
      test('returns true for format_version 1', () {
        final preview = ImportPreview(
          formatVersion: 1,
          filename: 'backup.zip',
        );

        expect(preview.isSupported, isTrue);
      });

      test('returns true for format_version 0 (legacy)', () {
        final preview = ImportPreview.legacy('backup.zip');

        expect(preview.isSupported, isTrue);
      });

      test('returns false for format_version > 1', () {
        final preview = ImportPreview(
          formatVersion: 2,
          filename: 'backup.zip',
        );

        expect(preview.isSupported, isFalse);
      });
    });

    group('totalRecords', () {
      test('returns sum of all record counts', () {
        final preview = ImportPreview(
          formatVersion: 1,
          filename: 'backup.zip',
          flocksCount: 2,
          birdsCount: 8,
          photosCount: 5,
          eggLogsCount: 100,
          expensesCount: 20,
          incomeCount: 10,
          medicationLogsCount: 5,
          healthNotesCount: 15,
        );

        // Total = 2 + 8 + 100 + 20 + 10 + 5 + 15 = 160 (photos not counted)
        expect(preview.totalRecords, 160);
      });
    });
  });
}
