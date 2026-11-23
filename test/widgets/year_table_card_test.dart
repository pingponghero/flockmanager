import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/screens/analytics/widgets/year_table_card.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two hens, logged per hen from the April before last to today.
YearRingsData _data() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(today.year - 2, 4, 1);
  final birds = [
    for (final id in ['a', 'b'])
      Bird(
        id: id,
        flockId: 'f',
        name: id,
        acquiredDate: start,
        createdAt: start,
      ),
  ];
  return YearRingsBuilder(
    logs: [
      for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1)))
        for (final b in birds)
          EggLog(
            id: '${b.id}$d',
            date: d,
            flockId: 'f',
            birdId: b.id,
            count: d.day % 3 == 0 ? 0 : 1,
            createdAt: d,
          ),
    ],
    birds: birds,
    events: const [],
    today: today,
    latitude: 39,
  ).build(mode: RingMode.years);
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('combined rings: lay rate is total eggs over total hen-days', () {
    final rings = _data().rings;
    final all = RingSeries.combined('All', rings);
    expect(all.eggs, rings.fold<int>(0, (s, r) => s + r.eggs));
    expect(all.knownDays, rings.fold<int>(0, (s, r) => s + r.knownDays));
    expect(
      all.layRate,
      closeTo(
        rings.fold<int>(0, (s, r) => s + r.rateEggs) /
            rings.fold<int>(0, (s, r) => s + r.henDays),
        1e-9,
      ),
    );
  });

  testWidgets('a row per year, an All row, and tapping selects', (
    tester,
  ) async {
    final data = _data();
    final year = DateTime.now().year;
    int? picked;
    await tester.pumpWidget(
      _app(
        YearTableCard(
          data: data,
          selected: data.rings.length - 1,
          onSelect: (i) => picked = i,
        ),
      ),
    );

    for (final r in data.rings) {
      expect(find.text(r.label), findsOneWidget);
    }
    expect(find.text('All'), findsOneWidget);
    for (final h in ['Eggs', 'Lay rate', 'Avg hens', 'Days']) {
      expect(find.text(h), findsOneWidget);
    }
    expect(
      find.text(
        'Compare lay rate: ${year - 2} started in April and $year is still going.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('${year - 1}'));
    expect(picked, data.rings.length - 2);

    await tester.tap(find.byTooltip('Show the sums for $year'));
    await tester.pumpAndSettle();
    expect(find.text('Eggs per day'), findsOneWidget);
  });

  testWidgets('no year selected: no sums button', (tester) async {
    await tester.pumpWidget(
      _app(YearTableCard(data: _data(), selected: null, onSelect: (_) {})),
    );
    expect(find.byIcon(Icons.calculate_outlined), findsNothing);
  });

  for (final scale in [1.5, 2.0, 3.0]) {
    testWidgets('fits a narrow phone at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          YearTableCard(data: _data(), selected: 0, onSelect: (_) {}),
          scale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Lay rate'), findsOneWidget);
      if (scale >= 2) expect(find.text('Avg hens'), findsNothing);
    });
  }
}
