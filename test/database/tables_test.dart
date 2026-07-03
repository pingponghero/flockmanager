import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/database/tables.dart';

void main() {
  group('Tables', () {
    test('flocks table SQL is valid', () {
      expect(Tables.flocks, contains('CREATE TABLE flocks'));
      expect(Tables.flocks, contains('id TEXT PRIMARY KEY'));
      expect(Tables.flocks, contains('name TEXT NOT NULL'));
      expect(Tables.flocks, contains('is_archived INTEGER DEFAULT 0'));
      expect(Tables.flocks, contains('created_at TEXT NOT NULL'));
    });

    test('birds table SQL is valid', () {
      expect(Tables.birds, contains('CREATE TABLE birds'));
      expect(Tables.birds, contains('id TEXT PRIMARY KEY'));
      expect(Tables.birds, contains('flock_id TEXT NOT NULL'));
      expect(Tables.birds, contains('name TEXT NOT NULL'));
      expect(Tables.birds, contains('status TEXT DEFAULT'));
      expect(Tables.birds, contains('FOREIGN KEY (flock_id) REFERENCES flocks(id)'));
    });

    test('birdPhotos table SQL is valid', () {
      expect(Tables.birdPhotos, contains('CREATE TABLE bird_photos'));
      expect(Tables.birdPhotos, contains('bird_id TEXT NOT NULL'));
      expect(Tables.birdPhotos, contains('photo_path TEXT NOT NULL'));
      expect(Tables.birdPhotos, contains('FOREIGN KEY (bird_id) REFERENCES birds(id)'));
    });

    test('eggLogs table SQL is valid', () {
      expect(Tables.eggLogs, contains('CREATE TABLE egg_logs'));
      expect(Tables.eggLogs, contains('date TEXT NOT NULL'));
      expect(Tables.eggLogs, contains('flock_id TEXT NOT NULL'));
      expect(Tables.eggLogs, contains('count INTEGER NOT NULL'));
      expect(Tables.eggLogs, contains('FOREIGN KEY (flock_id) REFERENCES flocks(id)'));
    });

    test('expenses table SQL is valid', () {
      expect(Tables.expenses, contains('CREATE TABLE expenses'));
      expect(Tables.expenses, contains('amount REAL NOT NULL'));
      expect(Tables.expenses, contains('category TEXT NOT NULL'));
      expect(Tables.expenses, contains('is_recurring INTEGER DEFAULT 0'));
    });

    test('income table SQL is valid', () {
      expect(Tables.income, contains('CREATE TABLE income'));
      expect(Tables.income, contains('amount REAL NOT NULL'));
      expect(Tables.income, contains('egg_count INTEGER'));
    });

    test('medicationLogs table SQL is valid', () {
      expect(Tables.medicationLogs, contains('CREATE TABLE medication_logs'));
      expect(Tables.medicationLogs, contains('medication_name TEXT NOT NULL'));
      expect(Tables.medicationLogs, contains('withdrawal_days INTEGER'));
      expect(Tables.medicationLogs, contains('FOREIGN KEY (flock_id) REFERENCES flocks(id)'));
    });

    test('healthNotes table SQL is valid', () {
      expect(Tables.healthNotes, contains('CREATE TABLE health_notes'));
      expect(Tables.healthNotes, contains('bird_id TEXT NOT NULL'));
      expect(Tables.healthNotes, contains('type TEXT NOT NULL'));
      expect(Tables.healthNotes, contains('description TEXT NOT NULL'));
      expect(Tables.healthNotes, contains('FOREIGN KEY (bird_id) REFERENCES birds(id)'));
    });

    test('birdStatusEvents table SQL is valid', () {
      expect(Tables.birdStatusEvents, contains('CREATE TABLE bird_status_events'));
      expect(Tables.birdStatusEvents, contains('id TEXT PRIMARY KEY'));
      expect(Tables.birdStatusEvents, contains('bird_id TEXT NOT NULL'));
      expect(Tables.birdStatusEvents, contains('flock_id TEXT NOT NULL'));
      expect(Tables.birdStatusEvents, contains('status TEXT NOT NULL'));
      expect(Tables.birdStatusEvents, contains('event_date TEXT NOT NULL'));
      expect(Tables.birdStatusEvents, contains('created_at TEXT NOT NULL'));
      // Verify NO foreign key - events must survive bird deletion
      expect(Tables.birdStatusEvents, isNot(contains('FOREIGN KEY')));
    });

    test('allTables contains all 10 tables', () {
      expect(Tables.allTables.length, 10);
      expect(Tables.allTables, contains(Tables.flocks));
      expect(Tables.allTables, contains(Tables.birds));
      expect(Tables.allTables, contains(Tables.birdPhotos));
      expect(Tables.allTables, contains(Tables.eggLogs));
      expect(Tables.allTables, contains(Tables.expenses));
      expect(Tables.allTables, contains(Tables.recipients));
      expect(Tables.allTables, contains(Tables.income));
      expect(Tables.allTables, contains(Tables.medicationLogs));
      expect(Tables.allTables, contains(Tables.healthNotes));
      expect(Tables.allTables, contains(Tables.birdStatusEvents));
    });

    test('allTables has correct order for foreign key dependencies', () {
      // flocks must come before birds, egg_logs, expenses, medication_logs
      final flocksIndex = Tables.allTables.indexOf(Tables.flocks);
      final birdsIndex = Tables.allTables.indexOf(Tables.birds);
      final eggLogsIndex = Tables.allTables.indexOf(Tables.eggLogs);

      expect(flocksIndex, lessThan(birdsIndex));
      expect(flocksIndex, lessThan(eggLogsIndex));

      // birds must come before bird_photos, health_notes
      final birdPhotosIndex = Tables.allTables.indexOf(Tables.birdPhotos);
      final healthNotesIndex = Tables.allTables.indexOf(Tables.healthNotes);

      expect(birdsIndex, lessThan(birdPhotosIndex));
      expect(birdsIndex, lessThan(healthNotesIndex));

      // recipients must come before income (income.recipient_id references it)
      final recipientsIndex = Tables.allTables.indexOf(Tables.recipients);
      final incomeIndex = Tables.allTables.indexOf(Tables.income);

      expect(recipientsIndex, lessThan(incomeIndex));
    });
  });
}
