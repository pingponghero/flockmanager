import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/providers/egg_provider.dart';
import 'package:flock_manager/providers/year_rings_provider.dart';
import 'package:flock_manager/screens/analytics/widgets/year_rings_card.dart';
import 'package:flock_manager/screens/birds/widgets/bird_eggs_tab.dart';
import 'package:flock_manager/screens/birds/widgets/hen_years_card.dart';
import 'package:flock_manager/utils/year_rings.dart';
import 'package:flock_manager/widgets/year_rings_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// When the year view's entry points appear (#1).
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final pearl = Bird(id: 'p', flockId: 'f', name: 'Pearl', acquiredDate: DateTime(now.year - 1), createdAt: DateTime(now.year - 1));
  final rooster = pearl.copyWith(id: 'r', name: 'Rocky', sex: BirdSex.male);

  /// [perHen] of each day's eggs are logged to Pearl, the rest as flock totals.
  YearRingsBuilder builder({bool perHen = true, int days = 60}) => YearRingsBuilder(
        logs: [
          for (var i = days; i > 0; i--) ...[
            EggLog(id: 'p$i', date: today.subtract(Duration(days: i)), flockId: 'f', birdId: 'p', count: 1, createdAt: today),
            if (!perHen)
              EggLog(id: 'f$i', date: today.subtract(Duration(days: i)), flockId: 'f', count: 6, createdAt: today),
          ],
        ],
        birds: [pearl],
        events: const [],
        today: today,
        latitude: 39,
      );

  group('Stats card', () {
    Future<void> pumpCard(WidgetTester tester, YearRingsData data) async {
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: YearRingsCard()),
          routes: [GoRoute(path: 'analytics/year', builder: (_, _) => const Text('year view'))],
        ),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [yearRingsProvider.overrideWith((ref, q) async => data)],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('is hidden until something is logged', (tester) async {
      await pumpCard(tester, YearRingsBuilder(logs: const [], birds: const [], events: const [], today: today, latitude: 39).build());
      expect(find.text('Your year'), findsNothing);
    });

    testWidgets('shows a preview and opens the year view', (tester) async {
      await pumpCard(tester, builder().build(mode: RingMode.years));
      expect(find.text('Your year'), findsOneWidget);
      expect(find.byType(YearRingsChart), findsOneWidget);
      await tester.tap(find.text('Your year'));
      await tester.pumpAndSettle();
      expect(find.text('year view'), findsOneWidget);
    });
  });

  group('Hen card', () {
    Future<void> pumpHen(WidgetTester tester, YearRingsData data) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [henYearRingsProvider.overrideWith((ref, id) async => data)],
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: HenYearsCard(bird: pearl)))),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows her rings when her flock logs per hen', (tester) async {
      await pumpHen(tester, builder().buildForHen('p'));
      expect(find.text('Pearl’s year'), findsOneWidget);
    });

    testWidgets('stays hidden when the flock mostly logs totals', (tester) async {
      // Without this she'd show a misleading near-zero lay rate.
      await pumpHen(tester, builder(perHen: false).buildForHen('p'));
      expect(find.text('Pearl’s year'), findsNothing);
    });

    testWidgets('is not offered for roosters', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          eggLogsByBirdProvider.overrideWith((ref, id) async => [
                EggLog(id: 'x', date: today, flockId: 'f', birdId: 'r', count: 1, createdAt: today),
              ]),
          henYearRingsProvider.overrideWith((ref, id) async => builder().buildForHen('p')),
        ],
        child: MaterialApp(home: Scaffold(body: BirdEggsTab(bird: rooster))),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(HenYearsCard), findsNothing);
    });
  });
}
