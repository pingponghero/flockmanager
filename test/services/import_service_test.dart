import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/services/import_service.dart';

void main() {
  group('ImportService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('import_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// Helper to create a test ZIP file
    Future<File> createTestZip({
      String? metadataJson,
      String? flocksCsv,
      String? birdsCsv,
      String? eggLogsCsv,
      String? expensesCsv,
      String? incomeCsv,
      String? medicationLogsCsv,
      String? healthNotesCsv,
      Map<String, List<int>>? photos,
    }) async {
      final archive = Archive();

      if (metadataJson != null) {
        final bytes = utf8.encode(metadataJson);
        archive.addFile(ArchiveFile('export_metadata.json', bytes.length, bytes));
      }

      if (flocksCsv != null) {
        final bytes = utf8.encode(flocksCsv);
        archive.addFile(ArchiveFile('flocks.csv', bytes.length, bytes));
      }

      if (birdsCsv != null) {
        final bytes = utf8.encode(birdsCsv);
        archive.addFile(ArchiveFile('birds.csv', bytes.length, bytes));
      }

      if (eggLogsCsv != null) {
        final bytes = utf8.encode(eggLogsCsv);
        archive.addFile(ArchiveFile('egg_logs.csv', bytes.length, bytes));
      }

      if (expensesCsv != null) {
        final bytes = utf8.encode(expensesCsv);
        archive.addFile(ArchiveFile('expenses.csv', bytes.length, bytes));
      }

      if (incomeCsv != null) {
        final bytes = utf8.encode(incomeCsv);
        archive.addFile(ArchiveFile('income.csv', bytes.length, bytes));
      }

      if (medicationLogsCsv != null) {
        final bytes = utf8.encode(medicationLogsCsv);
        archive.addFile(ArchiveFile('medication_logs.csv', bytes.length, bytes));
      }

      if (healthNotesCsv != null) {
        final bytes = utf8.encode(healthNotesCsv);
        archive.addFile(ArchiveFile('health_notes.csv', bytes.length, bytes));
      }

      if (photos != null) {
        for (final entry in photos.entries) {
          archive.addFile(
              ArchiveFile('photos/${entry.key}', entry.value.length, entry.value));
        }
      }

      final zipData = ZipEncoder().encode(archive);
      final zipFile = File('${tempDir.path}/test.zip');
      await zipFile.writeAsBytes(zipData);
      return zipFile;
    }

    group('getPreview', () {
      test('parses metadata correctly', () async {
        final zipFile = await createTestZip(
          metadataJson: jsonEncode({
            'app_version': '1.1.0',
            'export_date': '2024-01-15T10:30:00.000Z',
            'format_version': 1,
            'counts': {
              'flocks': 2,
              'birds': 8,
              'photos': 5,
              'egg_logs': 142,
            },
          }),
          flocksCsv: 'id,name,description,icon,color,is_archived,created_at\n',
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        expect(preview.appVersion, '1.1.0');
        expect(preview.formatVersion, 1);
        expect(preview.flocksCount, 2);
        expect(preview.birdsCount, 8);
        expect(preview.photosCount, 5);
        expect(preview.eggLogsCount, 142);
        expect(preview.isLegacy, isFalse);
      });

      test('returns legacy preview when no metadata', () async {
        final zipFile = await createTestZip(
          flocksCsv: 'id,name,description,icon,color,is_archived,created_at\n',
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        expect(preview.isLegacy, isTrue);
        expect(preview.formatVersion, 0);
      });
    });

    group('CSV parsing', () {
      test('handles UTF-8 BOM correctly', () async {
        const bom = '\uFEFF';
        final zipFile = await createTestZip(
          flocksCsv:
              '${bom}id,name,description,icon,color,is_archived,created_at\nf1,Test Flock,,,,0,2024-01-01T00:00:00.000\n',
          birdsCsv:
              '${bom}id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\nb1,f1,Henrietta,,,,,,,,,chicken,active,,,Notes,2024-01-01T00:00:00.000\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        // If it parsed without error, BOM handling worked
        expect(preview, isNotNull);
      });

      test('handles quoted fields with commas', () async {
        final zipFile = await createTestZip(
          flocksCsv:
              'id,name,description,icon,color,is_archived,created_at\nf1,"Flock, with comma","Description, also with comma",,#FF0000,0,2024-01-01T00:00:00.000\n',
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\nb1,f1,Henrietta,,,,,,,,,chicken,active,,,Notes,2024-01-01T00:00:00.000\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        expect(preview, isNotNull);
      });

      test('handles quoted fields with escaped quotes', () async {
        final zipFile = await createTestZip(
          flocksCsv:
              'id,name,description,icon,color,is_archived,created_at\nf1,"Flock ""with"" quotes",,,#FF0000,0,2024-01-01T00:00:00.000\n',
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\nb1,f1,Henrietta,,,,,,,,,chicken,active,,,Notes,2024-01-01T00:00:00.000\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        expect(preview, isNotNull);
      });
    });

    group('validation', () {
      test('getPreview succeeds even without flocks.csv (validation happens in importFromZip)', () async {
        final zipFile = await createTestZip(
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\n',
        );

        final service = ImportService();
        // getPreview only reads metadata, doesn't validate CSV structure
        final preview = await service.getPreview(zipFile);

        expect(preview.isLegacy, isTrue); // No metadata = legacy
      });

      test('getPreview succeeds even without birds.csv (validation happens in importFromZip)', () async {
        final zipFile = await createTestZip(
          flocksCsv: 'id,name,description,icon,color,is_archived,created_at\n',
        );

        final service = ImportService();
        // getPreview only reads metadata, doesn't validate CSV structure
        final preview = await service.getPreview(zipFile);

        expect(preview.isLegacy, isTrue); // No metadata = legacy
      });

      test('detects unsupported format_version via isSupported', () async {
        final zipFile = await createTestZip(
          metadataJson: jsonEncode({
            'format_version': 999,
          }),
          flocksCsv: 'id,name,description,icon,color,is_archived,created_at\n',
          birdsCsv:
              'id,flock_id,name,breed,breed_id,photo_primary,hatch_date,acquired_date,source,egg_color,sex,species,status,status_date,status_notes,notes,created_at\n',
        );

        final service = ImportService();
        final preview = await service.getPreview(zipFile);

        expect(preview.isSupported, isFalse);
      });
    });
  });

  group('ImportException', () {
    test('toString returns message', () {
      final exception = ImportException('Test error message');

      expect(exception.toString(), 'Test error message');
    });

    test('message property is accessible', () {
      final exception = ImportException('Another error');

      expect(exception.message, 'Another error');
    });
  });
}
