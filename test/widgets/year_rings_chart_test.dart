import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flock_manager/widgets/year_rings_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

YearRingsData _twoYears() {
  final logs = [
    for (var d = DateTime(2025, 1, 1);
        d.isBefore(DateTime(2026, 11, 23));
        d = d.add(const Duration(days: 1)))
      EggLog(
        id: d.toIso8601String(),
        date: d,
        flockId: 'f1',
        count: d.month < 7 ? 4 : 2,
        createdAt: d,
      ),
  ];
  return YearRingsBuilder(
    logs: logs,
    birds: const [],
    events: const [],
    today: DateTime(2026, 11, 22),
    latitude: 39,
  ).build(mode: RingMode.years);
}

void main() {
  testWidgets('draws, describes itself, and reports the tapped ring', (tester) async {
    final data = _twoYears();
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: 300,
            child: YearRingsChart(data: data, onRingTap: (i) => tapped = i),
          ),
        ),
      ),
    ));

    expect(
      find.bySemanticsLabel(RegExp(r'^Year rings, one ring per year')),
      findsOneWidget,
    );

    // Rings sit between 22% and 80% of the radius; two rings split that band.
    // Tap the outer ring (2026) just right of centre on the horizontal axis.
    final center = tester.getCenter(find.byType(YearRingsChart));
    const radius = 150.0;
    await tester.tapAt(center + const Offset(radius * 0.66, 0));
    expect(tapped, 1);

    await tester.tapAt(center + const Offset(radius * 0.36, 0));
    expect(tapped, 0);
  });
}
