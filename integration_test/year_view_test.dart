// On-device check of the year view (#1): runs the real app on a simulator
// and walks Stats → Your year → Years, the info sheets, and Days.
//
// Run on demand against a booted iOS simulator:
//   xcrun simctl list devices booted          # find the device id
//   flutter test integration_test/year_view_test.dart -d <device-id>
//
// To take screenshots, pause at each step and capture from another terminal:
//   flutter test integration_test/year_view_test.dart -d <device-id> \
//     --dart-define=PAUSE_SECONDS=4
//   # on each "STEP <name>" line:
//   xcrun simctl io <device-id> screenshot <name>.png
//
// WARNING: this replaces the app's data with the debug sample data. Only run
// it on a simulator, never on a phone with real flock data.
//
// If a "Sign in to Apple Account" prompt covers the screen, it's StoreKit
// left over from starting a trial in an earlier run; it outlives the app.
// Reboot the simulator (xcrun simctl shutdown/boot <device-id>) to clear it.
// The test pre-sets a running trial so it doesn't trigger one itself.
//
// Afterwards, regenerate the iOS build config before archiving:
//   flutter build ios --release --config-only
// Running an integration test points ios/Flutter/Generated.xcconfig at a
// temporary test target and leaves it there (see share_sheet_test.dart).

import 'package:flock_manager/app/router.dart';
import 'package:flock_manager/data/test_data.dart';
import 'package:flock_manager/main.dart' as app;
import 'package:flock_manager/screens/analytics/widgets/year_rings_card.dart';
import 'package:flock_manager/widgets/sunburst_chart.dart';
import 'package:flock_manager/widgets/year_rings_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pauseSeconds = int.fromEnvironment('PAUSE_SECONDS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('year view on device', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    // A trial already under way, as for a returning user. Starting one from
    // the welcome dialog goes through StoreKit on iOS, whose native sign-in
    // prompt the test can't see or dismiss.
    await prefs.setBool('trial_started', true);
    await prefs.setString('trial_start_date', DateTime.now().toIso8601String());
    await TestData.seedDatabase();

    app.main();

    // pumpAndSettle can wait on the app's own animations forever; pump for
    // a fixed time instead.
    Future<void> settle([int seconds = 2]) async {
      for (var i = 0; i < seconds * 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> step(String name) async {
      await settle();
      expect(tester.takeException(), isNull, reason: name);
      if (_pauseSeconds > 0) {
        // ignore: avoid_print
        print('STEP $name');
        await Future<void>.delayed(const Duration(seconds: _pauseSeconds));
        await tester.pump();
      }
    }

    await settle(4);

    // A fresh install greets the user with the trial dialog; accept it as
    // they would. It can appear a moment after launch.
    Future<void> dismissWelcome() async {
      final start = find.text('Start 14-Day Free Trial');
      if (start.evaluate().isNotEmpty) {
        await tester.tap(start);
        await settle();
      }
    }

    await dismissWelcome();

    // Stats: the "Your year" card, below the production chart.
    router.go('/analytics');
    await settle(3);
    await dismissWelcome();
    await tester.scrollUntilVisible(
      find.byType(YearRingsCard),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await step('stats-card');

    await dismissWelcome();
    await tester.tap(find.text('Your year'));
    await step('years');
    expect(find.byType(YearRingsChart), findsOneWidget);

    await tester.tap(find.byTooltip('How this is counted'));
    await step('how-counted');
    expect(find.text('How your year is counted'), findsOneWidget);
    await tester.tapAt(const Offset(200, 120)); // dismiss
    await settle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.calculate_outlined),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await step('ring-sums');
    expect(find.text('Eggs per day'), findsOneWidget);
    await tester.tapAt(const Offset(200, 120));
    await settle();

    await tester.scrollUntilVisible(
      find.text('Light and laying'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await step('loop');

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Days'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Days'));
    await step('days');
    expect(find.byType(SunburstChart), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });
}
