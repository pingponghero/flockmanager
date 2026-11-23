import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/app/theme.dart';
import 'package:flock_manager/providers/egg_provider.dart';
import 'package:flock_manager/providers/trial_provider.dart';
import 'package:flock_manager/screens/home/widgets/today_egg_card.dart';

/// #69: Today's count counts up — unless the OS asks for reduced motion.
void main() {
  Future<void> pumpCard(WidgetTester tester, {required bool reduceMotion}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayEggCountByFlockProvider.overrideWith((ref) async => 8),
          weeklyAverageEggCountProvider.overrideWith((ref) async => 6),
          canEditProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.buildTheme(AppPalette.barnRed),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reduceMotion),
              child: const Scaffold(body: TodayEggCard()),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('counts up to today\'s total', (tester) async {
    await pumpCard(tester, reduceMotion: false);
    await tester.pump(); // providers resolve
    await tester.pump(const Duration(milliseconds: 150));

    // Mid-animation: a number below the total is showing
    final mid = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => int.tryParse(t.data ?? ''))
        .whereType<int>()
        .toList();
    expect(mid, isNotEmpty);
    expect(mid.first, lessThan(8));

    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('reduced motion shows the total straight away',
      (tester) async {
    await pumpCard(tester, reduceMotion: true);
    await tester.pump();
    await tester.pump();

    expect(find.text('8'), findsOneWidget);
  });
}
