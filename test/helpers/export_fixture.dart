import 'dart:io';

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/services/import_service.dart';

/// Loads an unzipped app export (the folder of CSVs "Export Data" produces)
/// for tests that run against real data.
///
/// Real exports live in `test/fixtures/private/`, which is git-ignored: they
/// are customers' personal data and must never be committed. Tests that use
/// one should skip when it's missing, so they pass for everyone else and in
/// CI. See `test/fixtures/README.md`.
class ExportFixture {
  final Directory dir;
  final List<Bird> birds;
  final List<EggLog> eggLogs;
  final List<BirdStatusEvent> statusEvents;
  final DateTime? exportDate;

  ExportFixture._(this.dir, this.birds, this.eggLogs, this.statusEvents, this.exportDate);

  static const privateRoot = 'test/fixtures/private';

  /// Reason to skip, or null when [name] is present.
  static String? skipUnless(String name) => Directory('$privateRoot/$name').existsSync()
      ? null
      : 'Private fixture $privateRoot/$name is not present (it is never committed).';

  static ExportFixture load(String name) {
    final dir = Directory('$privateRoot/$name');
    final meta = File('${dir.path}/export_metadata.json');
    final exportDate = meta.existsSync()
        ? DateTime.tryParse(RegExp(r'"export_date"\s*:\s*"([^"]+)"').firstMatch(meta.readAsStringSync())?.group(1) ?? '')
        : null;
    return ExportFixture._(
      dir,
      _rows(dir, 'birds.csv').map(Bird.fromMap).toList(),
      _rows(dir, 'egg_logs.csv', ints: {'count'}).map(EggLog.fromMap).toList(),
      _rows(dir, 'bird_status_events.csv').map(BirdStatusEvent.fromMap).toList(),
      exportDate?.toLocal(),
    );
  }

  /// CSV rows as maps the models' `fromMap` accept: empty cells become null
  /// and [ints] columns are parsed, as the importer does.
  static List<Map<String, dynamic>> _rows(Directory dir, String file, {Set<String> ints = const {}}) {
    final f = File('${dir.path}/$file');
    if (!f.existsSync()) return const [];
    var text = f.readAsStringSync();
    if (text.startsWith('﻿')) text = text.substring(1); // Excel-friendly BOM
    final lines = ImportService().parseCsvLines(text);
    if (lines.isEmpty) return const [];
    final header = lines.first;
    return [
      for (final row in lines.skip(1))
        {
          for (var i = 0; i < header.length; i++)
            header[i]: i >= row.length || row[i].isEmpty
                ? null
                : (ints.contains(header[i]) ? int.parse(row[i]) : row[i]),
        },
    ];
  }
}
