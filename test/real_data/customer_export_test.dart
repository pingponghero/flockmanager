// Runs against a real customer export (kept out of git:
// see test/fixtures/README.md). Every test skips when the export isn't
// present, so this file passes for everyone else and in CI.
//
//   flutter test test/real_data

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/screens/analytics/year_view_screen.dart';
import 'package:flock_manager/services/import_service.dart';
import 'package:flock_manager/utils/light_laying_loop.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/export_fixture.dart';

const _name = 'customer_2026-06-03';

void main() {
  final skip = ExportFixture.skipUnless(_name);
  late ExportFixture fx;
  late YearRingsBuilder builder;

  setUpAll(() {
    if (skip != null) return;
    fx = ExportFixture.load(_name);
    builder = YearRingsBuilder(
      logs: fx.eggLogs,
      birds: fx.birds,
      events: fx.statusEvents,
      today: fx.exportDate!,
      latitude: 39,
    );
  });

  group('real export ($_name)', () {
    test('loads everything the export says it holds', () {
      expect(fx.birds, hasLength(35));
      expect(fx.eggLogs, hasLength(2139));
      expect(fx.statusEvents, hasLength(51));
    }, skip: skip);

    test('the app still accepts this 1.1.0 export', () async {
      final archive = Archive();
      for (final f in fx.dir.listSync(recursive: true).whereType<File>()) {
        final rel = f.path.substring(fx.dir.path.length + 1);
        archive.addFile(ArchiveFile.bytes(rel, f.readAsBytesSync()));
      }
      final tmp = await Directory.systemTemp.createTemp('real_export');
      addTearDown(() => tmp.delete(recursive: true));
      final zip = File('${tmp.path}/export.zip')..writeAsBytesSync(ZipEncoder().encode(archive));

      final preview = await ImportService().getPreview(zip);
      expect(preview.appVersion, '1.1.0');
      expect(preview.birdsCount, 35);
      expect(preview.eggLogsCount, 2139);
    }, skip: skip);

    test('every year has a plausible headcount and lay rate', () {
      // Every 'active' event in this export is dated at import time, after
      // real deaths; the year view must read past that (#88).
      final data = builder.build(mode: RingMode.years);
      expect(data.implausibleWeeks, 0);
      expect(data.colorScale, RingColorScale.layRate);
      for (final ring in data.rings.where((r) => r.knownDays >= 300)) {
        expect(ring.averageHens, inInclusiveRange(5, 20), reason: ring.label);
        expect(ring.layRate, inInclusiveRange(0.3, 0.8), reason: ring.label);
      }
    }, skip: skip);

    test('full years trace a light-and-laying loop', () {
      final data = builder.build(mode: RingMode.years);
      final full = data.rings.where((r) => r.knownDays >= 300).toList();
      expect(full, isNotEmpty);
      for (final ring in full) {
        final loop = buildLightLayingLoop(ring, data.weeklyDaylight);
        expect(loop, isNotNull, reason: ring.label);
        expect(loop!.sameLight, isNotNull, reason: ring.label);
      }
    }, skip: skip);

    test('every hen, year and day builds', () {
      for (final bird in fx.birds) {
        builder.buildForHen(bird.id);
      }
      final years = builder.build(mode: RingMode.years).availableYears;
      for (final year in years) {
        final days = builder.buildDays(year);
        expect(days.length, DateTime(year, 12, 31).difference(DateTime(year)).inDays + 1);
        builder.build(mode: RingMode.hens, year: year);
      }
    }, skip: skip);

    testWidgets('the year view renders it at 2x text', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          yearRingsProvider.overrideWith((ref, q) async => builder.build(mode: q.mode, year: q.year)),
          yearDaysProvider.overrideWith((ref, y) async => (days: builder.buildDays(y), latitude: 39)),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const YearViewScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, skip: skip != null);
  });
}
