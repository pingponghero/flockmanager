import 'dart:math' as math;

import 'package:flock_manager/screens/analytics/widgets/light_laying_loop_card.dart';
import 'package:flock_manager/utils/light_laying_loop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws the loop and states the spring/autumn comparison', (tester) async {
    final points = [
      for (var w = 0; w < 52; w++)
        LoopPoint(w, 12 + 2.6 * -_cos(w), 0.45 + 0.3 * -_cos(w) + 0.1 * _sin(w)),
    ];
    final loop = LightLayingLoop(
      label: '2026',
      points: points,
      sameLight: (rising: points[12], falling: points[38]),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LightLayingLoopCard(loop: loop, year: 2026, isCurrentYear: true),
        ),
      ),
    ));

    expect(find.text('Light and laying'), findsOneWidget);
    expect(find.textContaining('your hens laid'), findsOneWidget);
    expect(find.textContaining('in March'), findsOneWidget);
    expect(find.textContaining('in September'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('near the equator it explains instead of drawing a smear', (tester) async {
    final loop = LightLayingLoop(
      label: '2026',
      points: [for (var w = 0; w < 52; w++) LoopPoint(w, 12.05 + 0.05 * _cos(w), 0.5 + 0.2 * _sin(w))],
      sameLight: null,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LightLayingLoopCard(loop: loop, year: 2026, isCurrentYear: true)),
    ));
    expect(find.textContaining('barely changes'), findsOneWidget);
    expect(find.textContaining('one dot per week'), findsNothing);
    expect(find.byType(AspectRatio), findsNothing); // no chart
  });
}

// A smooth year: daylight peaks mid-year, laying leads it slightly.
double _cos(int w) => math.cos(w / 52 * 2 * math.pi);
double _sin(int w) => math.sin(w / 52 * 2 * math.pi);
