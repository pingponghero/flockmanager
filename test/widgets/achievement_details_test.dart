import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flock_manager/providers/achievements_provider.dart';
import 'package:flock_manager/screens/settings/achievements_screen.dart';

Achievement _achievement({bool secret = false}) => Achievement(
      id: 'test',
      name: 'Dozen Club',
      description: '12 eggs in a single day',
      icon: Icons.egg,
      color: Colors.orange,
      category: 'Test',
      check: (_) => false,
      secret: secret,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openDetails(
    WidgetTester tester,
    Achievement achievement, {
    required bool earned,
    AchievementProgress? progress,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAchievementDetails(
                context,
                achievement: achievement,
                earned: earned,
                progress: progress,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showAchievementDetails (#43)', () {
    testWidgets('locked achievement shows its requirement and progress',
        (tester) async {
      await openDetails(tester, _achievement(),
          earned: false, progress: const AchievementProgress(7, 12));

      expect(find.text('Dozen Club'), findsOneWidget);
      expect(find.text('12 eggs in a single day'), findsOneWidget);
      expect(find.text('7 / 12'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('locked secret achievement hides name, description, progress',
        (tester) async {
      await openDetails(tester, _achievement(secret: true),
          earned: false, progress: const AchievementProgress(7, 12));

      expect(find.text('Secret achievement'), findsOneWidget);
      expect(find.text('Dozen Club'), findsNothing);
      expect(find.text('12 eggs in a single day'), findsNothing);
      expect(find.text('7 / 12'), findsNothing);
    });

    testWidgets('earned secret achievement is revealed', (tester) async {
      await openDetails(tester, _achievement(secret: true), earned: true);

      expect(find.text('Dozen Club'), findsOneWidget);
      expect(find.text('12 eggs in a single day'), findsOneWidget);
    });
  });
}
