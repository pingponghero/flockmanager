import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/widgets/bird_card.dart';

void main() {
  group('BirdCard', () {
    late Bird activeBird;
    late Bird deceasedBird;

    setUp(() {
      activeBird = Bird(
        id: 'test-id-1',
        flockId: 'flock-1',
        name: 'Henrietta',
        breed: 'Rhode Island Red',
        hatchDate: DateTime.now().subtract(const Duration(days: 365)),
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      deceasedBird = Bird(
        id: 'test-id-2',
        flockId: 'flock-1',
        name: 'Clucky',
        breed: 'Leghorn',
        hatchDate: DateTime.now().subtract(const Duration(days: 730)),
        status: BirdStatus.deceased,
        statusDate: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );
    });

    testWidgets('displays bird name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      expect(find.text('Henrietta'), findsOneWidget);
    });

    testWidgets('displays breed when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      expect(find.text('Rhode Island Red'), findsOneWidget);
    });

    testWidgets('displays age in weeks for young birds', (tester) async {
      final youngBird = Bird(
        id: 'young-bird',
        flockId: 'flock-1',
        name: 'Chick',
        hatchDate: DateTime.now().subtract(const Duration(days: 21)),
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: youngBird),
          ),
        ),
      );

      expect(find.text('3 weeks'), findsOneWidget);
    });

    testWidgets('displays age in years for older birds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      // 365 days = 52 weeks = 1 year
      expect(find.text('1 year'), findsOneWidget);
    });

    testWidgets('shows status badge for non-active birds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: deceasedBird),
          ),
        ),
      );

      expect(find.text('Deceased'), findsOneWidget);
    });

    testWidgets('does not show status badge for active birds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      expect(find.text('Active'), findsNothing);
    });

    testWidgets('displays egg count when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird, eggCount: 42),
          ),
        ),
      );

      expect(find.text('42 eggs'), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(
              bird: activeBird,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BirdCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows placeholder icon when no photo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      // Placeholder is now cute_hen asset image
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('applies reduced opacity for non-active birds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: deceasedBird),
          ),
        ),
      );

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 0.6);
    });

    testWidgets('applies full opacity for active birds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: activeBird),
          ),
        ),
      );

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 1.0);
    });

    testWidgets('handles bird with no breed', (tester) async {
      final noBreadBird = Bird(
        id: 'no-breed',
        flockId: 'flock-1',
        name: 'Mystery Hen',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: noBreadBird),
          ),
        ),
      );

      expect(find.text('Mystery Hen'), findsOneWidget);
      // Should not crash, breed text should not be present
    });

    testWidgets('handles bird with no hatch date', (tester) async {
      final noAgeBird = Bird(
        id: 'no-age',
        flockId: 'flock-1',
        name: 'Unknown Age',
        breed: 'Orpington',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: noAgeBird),
          ),
        ),
      );

      expect(find.text('Unknown Age'), findsOneWidget);
      // Age should not be shown
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('shows correct icon for sold status', (tester) async {
      final soldBird = Bird(
        id: 'sold',
        flockId: 'flock-1',
        name: 'Sold Hen',
        status: BirdStatus.sold,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: soldBird),
          ),
        ),
      );

      expect(find.text('Sold'), findsOneWidget);
      expect(find.byIcon(Icons.sell), findsOneWidget);
    });

    testWidgets('shows correct icon for given away status', (tester) async {
      final givenAwayBird = Bird(
        id: 'given-away',
        flockId: 'flock-1',
        name: 'Gifted Hen',
        status: BirdStatus.givenAway,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdCard(bird: givenAwayBird),
          ),
        ),
      );

      expect(find.text('Given Away'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
    });
  });
}
