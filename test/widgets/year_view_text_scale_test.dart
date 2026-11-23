import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/screens/analytics/year_view_screen.dart';
import 'package:flock_manager/screens/birds/widgets/hen_years_card.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Large accessibility text must not overflow the year view (#1, cf. #70).
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final birds = [
    for (final name in ['Pearl', 'Dot'])
      Bird(id: name, flockId: 'f', name: name, acquiredDate: DateTime(today.year - 1), createdAt: DateTime(today.year - 1)),
  ];
  final builder = YearRingsBuilder(
    logs: [
      for (var d = DateTime(today.year - 1); !d.isAfter(today); d = d.add(const Duration(days: 1)))
        for (final b in birds)
          EggLog(id: '${b.id}$d', date: d, flockId: 'f', birdId: b.id, count: d.day % 3 == 0 ? 0 : 1, createdAt: d),
    ],
    birds: birds,
    events: const [],
    today: today,
    latitude: 39,
  );

  Widget app(Widget home, double scale) => ProviderScope(
        overrides: [
          yearRingsProvider.overrideWith((ref, q) async => builder.build(mode: q.mode, year: q.year)),
          yearDaysProvider.overrideWith((ref, y) async => (days: builder.buildDays(y), latitude: 39)),
          henYearRingsProvider.overrideWith((ref, id) async => builder.buildForHen(id)),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      );

  for (final scale in [1.5, 2.0]) {
    testWidgets('year view at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // At large sizes chips can sit off-screen in their scrolling row.
      Future<void> tapChip(String label) async {
        final chip = find.widgetWithText(ChoiceChip, label);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app(const YearViewScreen(), scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'rings');

      for (final view in ['Years', 'Hens']) {
        await tapChip(view);
        await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$view, scrolled');
        await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
        await tester.pumpAndSettle();
      }

      await tapChip('Years');
      await tester.tap(find.byTooltip('How this is counted'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'how-counted sheet');
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byIcon(Icons.calculate_outlined),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.byIcon(Icons.calculate_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'ring sums sheet');
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tapChip('Days');
      expect(tester.takeException(), isNull, reason: 'days');
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'days, scrolled');
    });

    testWidgets('hen card at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(Scaffold(body: SingleChildScrollView(child: HenYearsCard(bird: birds.first))), scale));
      await tester.pumpAndSettle();
      expect(find.text('Pearl’s year'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
