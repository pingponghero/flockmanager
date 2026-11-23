import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/app/status_colors.dart';
import 'package:flock_manager/app/theme.dart';
import 'package:flock_manager/providers/egg_provider.dart';
import 'package:flock_manager/providers/trial_provider.dart';
import 'package:flock_manager/screens/home/widgets/today_egg_card.dart';

/// #68: Today's eggs is the hero card on Home.
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required int today,
    required double average,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayEggCountByFlockProvider.overrideWith((ref) async => today),
          weeklyAverageEggCountProvider.overrideWith((ref) async => average),
          canEditProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.buildTheme(AppPalette.barnRed),
          home: const Scaffold(body: TodayEggCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nothing logged yet invites a tap to log, with the average',
      (tester) async {
    await pumpCard(tester, today: 0, average: 5.4);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Tap to log · avg 5.4'), findsOneWidget);
  });

  testWidgets('nothing logged and no history: plain invitation',
      (tester) async {
    await pumpCard(tester, today: 0, average: 0);

    expect(find.text("Tap to log today's eggs"), findsOneWidget);
  });

  testWidgets('logged eggs show the count and a trend vs average',
      (tester) async {
    await pumpCard(tester, today: 8, average: 5);

    expect(find.text('8'), findsOneWidget);
    expect(find.text('avg 5.0'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  test('hero text is readable on every palette in both modes', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        final primary = AppTheme.buildTheme(palette, brightness: brightness)
            .colorScheme
            .primary;
        final fg = TodayEggCard.foregroundOn(primary);
        final shaded = Color.lerp(primary, Colors.black, 0.18)!;
        // WCAG large-text threshold; the label is 16sp semibold and the
        // count is display size. Check both ends of the gradient.
        for (final bg in [primary, shaded]) {
          expect(Tone.contrastRatio(fg, bg), greaterThanOrEqualTo(3),
              reason: '${palette.name} ${brightness.name}');
        }
      }
    }
  });
}
