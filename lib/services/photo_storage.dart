import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/bird.dart';

extension BirdPhoto on Bird {
  /// This bird's photo file, or null if it has none or the file is missing.
  File? get photoFile => PhotoStorage.resolve(photoPrimary);
}

/// Owns where bird photos live on disk and how they are referenced.
///
/// The database stores only a photo's **filename** (e.g. `1719_img.jpg`),
/// never an absolute path. On iOS the app's data container path can change
/// on app update or restore, which made absolute paths saved before 2.6.1
/// point to a folder that no longer exists (issue #52). Resolving the
/// filename against the current documents directory at read time keeps
/// photos working across those moves.
class PhotoStorage {
  PhotoStorage._();

  /// Directory (under Documents) that holds all bird photos.
  static const String photosDirName = 'bird_photos';

  /// Directories earlier versions wrote photos to. CSV import used
  /// `Documents/photos` before 2.6.1. Files there are moved into
  /// [photosDirName] at startup and still checked as a fallback.
  static const List<String> legacyDirNames = ['photos'];

  static Directory? _documentsDir;

  /// Cache the documents directory and move photos out of legacy
  /// directories. Call once at startup, before any photo is shown.
  static Future<void> init() async {
    _documentsDir = await getApplicationDocumentsDirectory();
    await _consolidateLegacyDirs();
  }

  /// Point storage at [documentsDir] instead of the platform directory.
  @visibleForTesting
  static Future<void> initWith(Directory? documentsDir,
      {bool consolidate = true}) async {
    _documentsDir = documentsDir;
    if (documentsDir != null && consolidate) await _consolidateLegacyDirs();
  }

  static Future<Directory> _documents() async =>
      _documentsDir ??= await getApplicationDocumentsDirectory();

  /// The photo directory, created if needed.
  static Future<Directory> photosDir() async {
    final dir = Directory(p.join((await _documents()).path, photosDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copy [source] into the photo directory as [fileName] and return the
  /// value to store in the database (the filename).
  static Future<String> save(File source, String fileName) async {
    final name = p.basename(fileName);
    await source.copy(p.join((await photosDir()).path, name));
    return name;
  }

  /// The value to store in the database for a photo reference: its
  /// filename. Accepts legacy absolute paths.
  static String toStoredName(String pathOrName) => p.basename(pathOrName);

  /// Resolve a stored photo reference to a file that exists, or null.
  ///
  /// Accepts both filenames and legacy absolute paths: the filename is
  /// looked up in the current photo directory, then legacy directories,
  /// then the literal path as a last resort.
  static File? resolve(String? stored) {
    if (stored == null || stored.isEmpty) return null;

    final docs = _documentsDir;
    if (docs != null) {
      final name = p.basename(stored);
      for (final dirName in [photosDirName, ...legacyDirNames]) {
        final file = File(p.join(docs.path, dirName, name));
        if (file.existsSync()) return file;
      }
    }

    if (p.isAbsolute(stored)) {
      final file = File(stored);
      if (file.existsSync()) return file;
    }
    return null;
  }

  /// Move files from legacy directories into the photo directory. Best
  /// effort: anything left behind is still found by [resolve].
  static Future<void> _consolidateLegacyDirs() async {
    try {
      final docs = await _documents();
      for (final dirName in legacyDirNames) {
        final legacy = Directory(p.join(docs.path, dirName));
        if (!await legacy.exists()) continue;
        final target = await photosDir();
        await for (final entity in legacy.list()) {
          if (entity is! File) continue;
          final dest = p.join(target.path, p.basename(entity.path));
          if (await File(dest).exists()) continue;
          await entity.rename(dest);
        }
      }
    } catch (e) {
      debugPrint('Photo directory consolidation failed: $e');
    }
  }
}
