import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/providers/analytics_provider.dart';
import 'package:flock_manager/widgets/choice_chip_row.dart';

/// #62: periods are one-tap chips instead of a dropdown.
void main() {
  Future<List<AnalyticsPeriod>> pump(
    WidgetTester tester, {
    AnalyticsPeriod selected = AnalyticsPeriod.week,
    double width = 400,
  }) async {
    final picked = <AnalyticsPeriod>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ChoiceChipRow<AnalyticsPeriod>(
                values: AnalyticsPeriod.values,
                selected: selected,
                labelOf: (p) => p.shortLabel,
                onSelected: picked.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return picked;
  }

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

  testWidgets('marks only the selected period', (tester) async {
    await pump(tester, selected: AnalyticsPeriod.month);

    expect(chip(tester, 'This month').selected, isTrue);
    expect(chip(tester, '7 days').selected, isFalse);
    expect(chip(tester, 'All time').selected, isFalse);
  });

  testWidgets('tapping a chip reports that period', (tester) async {
    final picked = await pump(tester);

    await tester.tap(find.text('30 days'));
    expect(picked, [AnalyticsPeriod.last30Days]);
  });

  testWidgets('scrolls a selected chip that starts off-screen into view',
      (tester) async {
    await pump(tester, selected: AnalyticsPeriod.allTime, width: 200);

    final rowBox = tester.getRect(find.byType(ChoiceChipRow<AnalyticsPeriod>));
    final chipBox = tester.getRect(find.widgetWithText(ChoiceChip, 'All time'));
    expect(rowBox.contains(chipBox.center), isTrue);
  });
}
