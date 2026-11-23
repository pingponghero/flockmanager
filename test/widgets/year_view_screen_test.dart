import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/screens/analytics/year_view_screen.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flock_manager/widgets/sunburst_chart.dart';
import 'package:flock_manager/widgets/year_rings_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two hens logged individually through 2025 and most of this year.
YearRingsBuilder _builder({int latitude = 39}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final birds = [
    Bird(id: 'a', flockId: 'f', name: 'Pearl', acquiredDate: DateTime(2024), createdAt: DateTime(2024)),
    Bird(id: 'b', flockId: 'f', name: 'Dot', acquiredDate: DateTime(2024, 6), createdAt: DateTime(2024)),
  ];
  final logs = <EggLog>[
    for (var d = DateTime(today.year - 1, 1, 1); !d.isAfter(today); d = d.add(const Duration(days: 1))) ...[
      EggLog(id: 'a$d', date: d, flockId: 'f', birdId: 'a', count: d.day % 3 == 0 ? 0 : 1, createdAt: d),
      EggLog(id: 'b$d', date: d, flockId: 'f', birdId: 'b', count: d.day % 2, createdAt: d),
    ],
  ];
  return YearRingsBuilder(logs: logs, birds: birds, events: const [], today: today, latitude: latitude);
}

void main() {
  testWidgets('opens on hens for per-hen loggers and switches views', (tester) async {
    final builder = _builder();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        yearRingsProvider.overrideWith((ref, q) async => builder.build(mode: q.mode, year: q.year)),
        yearDaysProvider.overrideWith((ref, year) async => (days: builder.buildDays(year), latitude: 39)),
      ],
      child: const MaterialApp(home: YearViewScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(YearRingsChart), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Hens'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Hens')).selected,
      isTrue,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Days'));
    await tester.pumpAndSettle();
    expect(find.byType(SunburstChart), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Years'));
    await tester.pumpAndSettle();
    expect(find.byType(YearRingsChart), findsOneWidget);

    // The detail lives in a bottom sheet, not on the screen.
    await tester.tap(find.byTooltip('How this is counted'));
    await tester.pumpAndSettle();
    expect(find.text('How your year is counted'), findsOneWidget);
    expect(find.text('Lay rate'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no light-and-laying card near the equator', (tester) async {
    Future<void> pumpAt(int latitude) async {
      final builder = _builder(latitude: latitude);
      await tester.pumpWidget(ProviderScope(
        key: ValueKey(latitude),
        overrides: [
          yearRingsProvider.overrideWith((ref, q) async => builder.build(mode: RingMode.years, year: q.year)),
          yearDaysProvider.overrideWith((ref, year) async => (days: builder.buildDays(year), latitude: latitude)),
        ],
        child: const MaterialApp(home: YearViewScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
    }

    await pumpAt(39);
    expect(find.text('Light and laying'), findsOneWidget);
    await pumpAt(0);
    expect(find.text('Light and laying'), findsNothing);
  });
}
