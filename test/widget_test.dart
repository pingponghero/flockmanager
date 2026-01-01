import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flock_manager/main.dart';
import 'package:flock_manager/screens/onboarding/onboarding_screen.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences mock before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App shows onboarding for new users', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FlockManagerApp(),
      ),
    );

    // Pump frames for async initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // New users should see onboarding welcome screen
    expect(find.textContaining('Welcome'), findsOneWidget);
  });

  testWidgets('Onboarding screen shows welcome page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pump();

    // Should show welcome text and Get Started button
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Onboarding Get Started navigates to features', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pump();

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Should show feature cards
    expect(find.text('Log eggs in 2 taps'), findsOneWidget);
  });
}
