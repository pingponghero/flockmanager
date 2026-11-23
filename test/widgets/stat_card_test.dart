import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/screens/birds/widgets/bird_stats_row.dart';
import 'package:flock_manager/widgets/stat_card.dart';

Bird _bird({DateTime? hatch, DateTime? acquired}) => Bird(
      id: 'b',
      flockId: 'f',
      name: 'Henrietta',
      hatchDate: hatch,
      acquiredDate: acquired,
      createdAt: DateTime(2025, 6, 1),
    );

void main() {
  group('StatCard (#63)', () {
    testWidgets('stacked: icon, value and label; tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatCard(
            label: 'This Week',
            value: '35',
            icon: const Icon(Icons.calendar_view_week),
            onTap: () => taps++,
          ),
        ),
      ));

      expect(find.text('35'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      await tester.tap(find.text('35'));
      expect(taps, 1);
    });

    testWidgets('inline shows a subtitle and tints the icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatCard(
            layout: StatCardLayout.inline,
            label: 'Best Day',
            value: '9',
            subtitle: 'Jun 3, 2026',
            icon: const Icon(Icons.star),
            iconColor: Colors.amber,
          ),
        ),
      ));

      expect(find.text('Jun 3, 2026'), findsOneWidget);
      final theme = tester.widget<IconTheme>(find
          .ancestor(of: find.byIcon(Icons.star), matching: find.byType(IconTheme))
          .first);
      expect(theme.data.color, Colors.amber);
    });
  });

  group('birdAgeStat (#63)', () {
    final now = DateTime(2026, 11, 22);

    test('young birds in weeks', () {
      expect(birdAgeStat(_bird(hatch: DateTime(2026, 10, 1)), now: now),
          ('Age', '7 wk'));
    });

    test('under two years in months', () {
      expect(birdAgeStat(_bird(hatch: DateTime(2025, 8, 22)), now: now),
          ('Age', '15 mo'));
    });

    test('older birds in years and months', () {
      expect(birdAgeStat(_bird(hatch: DateTime(2023, 8, 1)), now: now),
          ('Age', '3y 3m'));
      expect(birdAgeStat(_bird(hatch: DateTime(2022, 11, 1)), now: now),
          ('Age', '4y'));
    });

    test('no hatch date: when the bird joined, honestly labelled', () {
      expect(birdAgeStat(_bird(acquired: DateTime(2024, 3, 1)), now: now),
          ('With you since', '2024'));
    });

    test('nothing known: the year it was added, not "Since"', () {
      expect(birdAgeStat(_bird(), now: now), ('Added', '2025'));
    });
  });
}
