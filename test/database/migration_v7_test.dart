import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> createV6Database() {
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE birds (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              photo_primary TEXT
            )
          ''');
        },
      ),
    );
  }

  group('migration to v7', () {
    test('rewrites absolute photo paths to filenames', () async {
      final db = await createV6Database();
      await db.insert('birds', {
        'id': 'b1',
        'name': 'Henrietta',
        'photo_primary': '/var/mobile/Containers/Data/Application/'
            'OLD-UUID/Documents/bird_photos/1719_hen.jpg',
      });
      await db.insert('birds', {
        'id': 'b2',
        'name': 'Imported',
        'photo_primary': '/var/mobile/Containers/Data/Application/'
            'OLD-UUID/Documents/photos/bird_b2.jpg',
      });
      await db.insert('birds', {
        'id': 'b3',
        'name': 'Already relative',
        'photo_primary': 'quail.jpg',
      });
      await db.insert('birds', {'id': 'b4', 'name': 'No photo'});
      await db.insert('birds', {'id': 'b5', 'name': 'Empty', 'photo_primary': ''});

      await DatabaseHelper.instance.onUpgrade(db, 6, 7);

      final rows = {
        for (final r in await db.query('birds')) r['id']: r['photo_primary'],
      };
      expect(rows, {
        'b1': '1719_hen.jpg',
        'b2': 'bird_b2.jpg',
        'b3': 'quail.jpg',
        'b4': null,
        'b5': '',
      });

      await db.close();
    });
  });
}
