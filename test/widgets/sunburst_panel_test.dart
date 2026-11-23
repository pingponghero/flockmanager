import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/screens/analytics/widgets/sunburst_panel.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flock_manager/widgets/sunburst_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// The sunburst's readout follows the slider (#1).
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final year = today.year;

  // A month of logs (3 a day) ending 10 days ago, then a long gap to today.
  final logged = today.subtract(const Duration(days: 20));
  final logs = [
    for (var i = 40; i >= 10; i--)
      EggLog(id: '$i', date: today.subtract(Duration(days: i)), flockId: 'f', count: 3, createdAt: today),
  ];

  Future<void> pumpPanel(WidgetTester tester, {int latitude = 39}) async {
    final days = YearRingsBuilder(logs: logs, birds: const [], events: const [], today: today, latitude: latitude)
        .buildDays(year);
    await tester.pumpWidget(ProviderScope(
      overrides: [yearDaysProvider.overrideWith((ref, y) async => (days: days, latitude: latitude))],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SunburstPanel(year: year)))),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> moveTo(WidgetTester tester, DateTime date) async {
    tester.widget<Slider>(find.byType(Slider)).onChanged!(dayOfYear(date).toDouble());
    await tester.pumpAndSettle();
  }

  String md(DateTime d) => DateFormat.MMMd().format(d);

  testWidgets('opens on today', (tester) async {
    await pumpPanel(tester);
    expect(find.text(md(today)), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('not logged yet'), findsOneWidget); // today is inside the gap
  });

  testWidgets('a logged day shows its eggs', (tester) async {
    if (logged.year != year) return; // early January: the fixture spans New Year
    await pumpPanel(tester);
    await moveTo(tester, logged);
    expect(find.text(md(logged)), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a day ahead shows a forecast', (tester) async {
    final ahead = today.add(const Duration(days: 5));
    if (ahead.year != year) return; // late December: no days ahead this year
    await pumpPanel(tester);
    await moveTo(tester, ahead);
    expect(find.text('Forecast'), findsNWidgets(2)); // legend + the day's badge
    expect(find.text('eggs expected'), findsOneWidget);
  });

  testWidgets('a day before logging began says so', (tester) async {
    final before = today.subtract(const Duration(days: 60));
    if (before.year != year) return;
    await pumpPanel(tester);
    await moveTo(tester, before);
    expect(find.text('not logged'), findsOneWidget);
  });

  testWidgets('turns the egg for the southern hemisphere', (tester) async {
    await pumpPanel(tester, latitude: -35);
    expect(tester.widget<SunburstChart>(find.byType(SunburstChart)).southernHemisphere, isTrue);
  });
}
