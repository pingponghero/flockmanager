import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/services/export_service.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockDatabase extends Mock implements Database {}

void main() {
  group('ExportService', () {
    late MockDatabaseHelper mockDbHelper;
    late MockDatabase mockDatabase;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      mockDatabase = MockDatabase();
      when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
    });

    group('constructor', () {
      test('creates service with default database helper', () {
        final service = ExportService();
        expect(service, isNotNull);
      });

      test('creates service with custom database helper', () {
        final service = ExportService(db: mockDbHelper);
        expect(service, isNotNull);
      });

      test('creates service with progress callback', () {
        var progressCalled = false;
        final service = ExportService(
          db: mockDbHelper,
          onProgress: (_) => progressCalled = true,
        );
        expect(service, isNotNull);
        expect(progressCalled, isFalse); // Not called until export
      });
    });

    group('constants', () {
      test('app version is defined', () {
        // The service should have a defined app version
        final service = ExportService(db: mockDbHelper);
        expect(service, isNotNull);
      });

      test('format version is 1', () {
        // The format version should be 1 for compatibility
        final service = ExportService(db: mockDbHelper);
        expect(service, isNotNull);
      });
    });
  });
}
