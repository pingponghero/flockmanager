import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/providers/forecast_provider.dart';
import 'package:flock_manager/screens/analytics/widgets/monthly_forecast_table.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

ForecastResult _forecast() => ForecastResult(
      currentPerHenRate: 0.71,
      currentDailyRate: 5,
      projectedWeek: 35,
      projectedMonth: 150,
      projectedYear: 1834,
      activeHens: 7,
      latitude: 45,
      hasEnoughData: true,
      monthlyForecasts: [
        for (var m = 1; m <= 12; m++)
          MonthForecast(
            month: m,
            year: 2026,
            actualEggs: 120 + m,
            forecastEggs: 1100 + m, // 4 digits: the widest realistic value
            perHenRate: 0.65,
            daylightHours: 12.4,
            isActual: m < 11,
            isComplete: m < 11,
            daysRecorded: 30,
          ),
      ],
    );

/// #70: the forecast month table must fit a small phone at large
/// accessibility text sizes instead of clipping fixed-width columns.
/// Loads the SDK's bundled Roboto so widths match a real device; the
/// default test font draws every glyph as a full square.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold', 'Italic']) {
    loader.addFont(File('$dir/Roboto-$weight.ttf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRoboto);

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('fits a 320pt-wide sheet at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 1600),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: MonthlyForecastTable(
                forecast: _forecast(),
                monthNames: _months,
                currentMonth: 11,
              ),
            ),
          ),
        ),
      ));

      // An overflow would surface as a FlutterError here.
      expect(tester.takeException(), isNull);
      expect(find.text('Nov'), findsOneWidget);
            expect(find.text('1,834'), findsOneWidget);

      // Every cell stays on one line at its natural width — no wrapping
      // or squeezing, which is what fixed 48–60px columns did at 2x.
      final cells = find.descendant(
        of: find.byType(Table),
        matching: find.byType(Text),
      );
      expect(cells, findsWidgets);
      for (final element in cells.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        final text = (element.widget as Text).data;
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5),
          reason: '"$text" was squeezed at ${scale}x',
        );
      }
    });
  }
}
