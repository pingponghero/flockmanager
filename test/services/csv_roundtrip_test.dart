import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/services/export_service.dart';
import 'package:flock_manager/services/import_service.dart';

void main() {
  group('ImportService.parseCsvLines', () {
    final service = ImportService();

    test('parses simple rows', () {
      final rows = service.parseCsvLines('a,b,c\n1,2,3\n');
      expect(rows, [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('keeps quoted newlines inside a single field', () {
      final rows =
          service.parseCsvLines('id,notes\n1,"line one\nline two"\n2,plain\n');
      expect(rows, [
        ['id', 'notes'],
        ['1', 'line one\nline two'],
        ['2', 'plain'],
      ]);
    });

    test('keeps quoted CRLF newlines inside a single field', () {
      final rows = service
          .parseCsvLines('id,notes\r\n1,"line one\r\nline two"\r\n2,plain\r\n');
      expect(rows, [
        ['id', 'notes'],
        ['1', 'line one\r\nline two'],
        ['2', 'plain'],
      ]);
    });

    test('handles escaped quotes and commas in quoted fields', () {
      final rows =
          service.parseCsvLines('id,notes\n1,"say ""hi"", then leave"\n');
      expect(rows, [
        ['id', 'notes'],
        ['1', 'say "hi", then leave'],
      ]);
    });

    test('handles multiline field combined with quotes and commas', () {
      final rows = service.parseCsvLines(
          'id,notes,x\n1,"a ""b"",\nc",tail\n');
      expect(rows, [
        ['id', 'notes', 'x'],
        ['1', 'a "b",\nc', 'tail'],
      ]);
    });

    test('skips blank lines and handles missing trailing newline', () {
      final rows = service.parseCsvLines('a,b\n\n1,2');
      expect(rows, [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('preserves empty columns', () {
      final rows = service.parseCsvLines('a,b,c\n1,,3\n');
      expect(rows[1], ['1', '', '3']);
    });
  });

  group('export/import CSV round-trip', () {
    test('multiline text fields survive a full round-trip', () {
      final exportService = ExportService();
      final importService = ImportService();

      final rows = <Map<String, dynamic>>[
        {
          'id': 'e1',
          'notes': 'first line\nsecond line\nthird, with comma',
          'count': 5,
        },
        {
          'id': 'e2',
          'notes': 'has "quotes" and\r\nwindows newline',
          'count': 3,
        },
        {'id': 'e3', 'notes': null, 'count': 1},
      ];

      final bytes = exportService.createCsv(rows, ['id', 'notes', 'count']);
      var content = utf8.decode(bytes);
      // Strip BOM as the import pipeline does
      if (content.startsWith('﻿')) content = content.substring(1);

      final parsed = importService.parseCsvLines(content);

      expect(parsed.length, 4); // header + 3 rows
      expect(parsed[0], ['id', 'notes', 'count']);
      expect(parsed[1], ['e1', 'first line\nsecond line\nthird, with comma', '5']);
      expect(parsed[2], ['e2', 'has "quotes" and\r\nwindows newline', '3']);
      expect(parsed[3], ['e3', '', '1']);
    });

    test('every row keeps the header column count', () {
      final exportService = ExportService();
      final importService = ImportService();

      final rows = <Map<String, dynamic>>[
        {'id': 'x', 'description': 'multi\nline\ntext', 'amount': 9.5},
      ];

      final bytes =
          exportService.createCsv(rows, ['id', 'description', 'amount']);
      var content = utf8.decode(bytes);
      if (content.startsWith('﻿')) content = content.substring(1);

      final parsed = importService.parseCsvLines(content);
      for (final row in parsed) {
        expect(row.length, parsed.first.length);
      }
    });
  });
}
