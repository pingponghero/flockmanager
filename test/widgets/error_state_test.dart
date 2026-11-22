import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flock_manager/widgets/error_state.dart';

void main() {
  const rawError = 'DatabaseException(no such table: birds)';

  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  group('ErrorState (#57)', () {
    testWidgets('shows a friendly message, not the raw error',
        (tester) async {
      await pump(
        tester,
        const ErrorState(message: "Couldn't load your birds", error: rawError),
      );

      expect(find.text("Couldn't load your birds"), findsOneWidget);
      expect(find.text(rawError), findsNothing);
    });

    testWidgets('reveals the raw error only after tapping Details',
        (tester) async {
      await pump(
        tester,
        const ErrorState(message: "Couldn't load your birds", error: rawError),
      );

      await tester.tap(find.text('Details'));
      await tester.pump();
      expect(find.text(rawError), findsOneWidget);

      await tester.tap(find.text('Hide details'));
      await tester.pump();
      expect(find.text(rawError), findsNothing);
    });

    testWidgets('Retry calls onRetry', (tester) async {
      var retries = 0;
      await pump(
        tester,
        ErrorState(
          message: "Couldn't load your birds",
          error: rawError,
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('no Retry button without onRetry', (tester) async {
      await pump(
        tester,
        const ErrorState(message: "Couldn't load your birds", error: rawError),
      );
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('compact variant shows message and retry inline',
        (tester) async {
      var retries = 0;
      await pump(
        tester,
        ErrorState.compact(
          message: "Couldn't load flocks",
          error: rawError,
          onRetry: () => retries++,
        ),
      );

      expect(find.text("Couldn't load flocks"), findsOneWidget);
      expect(find.text(rawError), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });
}
