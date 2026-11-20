import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flock_manager/services/photo_storage.dart';

void main() {
  late Directory docs;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('photo_storage_test_');
    await PhotoStorage.initWith(docs);
  });

  tearDown(() async {
    await PhotoStorage.initWith(null);
    if (await docs.exists()) await docs.delete(recursive: true);
  });

  Future<File> writePhoto(String dirName, String name) async {
    final file = File(p.join(docs.path, dirName, name));
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    return file;
  }

  group('resolve', () {
    test('returns null for null, empty, or missing photos', () {
      expect(PhotoStorage.resolve(null), isNull);
      expect(PhotoStorage.resolve(''), isNull);
      expect(PhotoStorage.resolve('nope.jpg'), isNull);
    });

    test('resolves a stored filename in the photo directory', () async {
      final file = await writePhoto('bird_photos', 'hen.jpg');
      expect(PhotoStorage.resolve('hen.jpg')?.path, file.path);
    });

    test('recovers a stale absolute path from an old app container', () async {
      // Issue #52: the container UUID changed, so the stored path is dead
      // but the file is in the current container under the same name.
      final file = await writePhoto('bird_photos', '1719_hen.jpg');
      const stale = '/var/mobile/Containers/Data/Application/'
          'OLD-UUID/Documents/bird_photos/1719_hen.jpg';
      expect(PhotoStorage.resolve(stale)?.path, file.path);
    });

    test('falls back to the legacy import directory', () async {
      final file = await writePhoto('photos', 'bird_b1.jpg');
      // Re-point without consolidating, as if the move had failed.
      await PhotoStorage.initWith(docs, consolidate: false);
      expect(PhotoStorage.resolve('bird_b1.jpg')?.path, file.path);
    });

    test('uses the literal path when storage is not initialized', () async {
      final file = await writePhoto('elsewhere', 'hen.jpg');
      await PhotoStorage.initWith(null);
      expect(PhotoStorage.resolve(file.path)?.path, file.path);
    });
  });

  group('init', () {
    test('moves legacy import photos into the photo directory', () async {
      await writePhoto('photos', 'bird_b1.jpg');
      await PhotoStorage.initWith(docs);

      final moved = File(p.join(docs.path, 'bird_photos', 'bird_b1.jpg'));
      expect(await moved.exists(), isTrue);
      expect(
          await File(p.join(docs.path, 'photos', 'bird_b1.jpg')).exists(),
          isFalse);
      expect(PhotoStorage.resolve('bird_b1.jpg')?.path, moved.path);
    });

    test('does not overwrite a photo that already exists', () async {
      final existing = await writePhoto('bird_photos', 'bird_b1.jpg');
      await existing.writeAsBytes([9]);
      await writePhoto('photos', 'bird_b1.jpg');

      await PhotoStorage.initWith(docs);

      expect(await existing.readAsBytes(), [9]);
    });
  });

  test('save copies the file and returns only the filename', () async {
    final source = File(p.join(docs.path, 'picked.jpg'));
    await source.writeAsBytes([4, 5, 6]);

    final stored = await PhotoStorage.save(source, '123_picked.jpg');

    expect(stored, '123_picked.jpg');
    expect(p.isAbsolute(stored), isFalse);
    expect(await PhotoStorage.resolve(stored)!.readAsBytes(), [4, 5, 6]);
  });
}
