import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flock_manager/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FlockManagerApp(),
      ),
    );

    // Allow the router to settle
    await tester.pumpAndSettle();

    // Verify that the home screen is displayed
    expect(find.text('Flock Manager'), findsOneWidget);
  });
}
