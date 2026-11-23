import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/app/theme.dart';
import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/egg_log.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/models/expense.dart';
import 'package:flock_manager/models/flock.dart';
import 'package:flock_manager/providers/trial_provider.dart';
import 'package:flock_manager/repositories/egg_repository.dart';
import 'package:flock_manager/repositories/finance_repository.dart';
import 'package:flock_manager/repositories/flock_repository.dart';
import 'package:flock_manager/screens/value/value_screen.dart';

/// Value screen: money figures share one font, and switching the period
/// doesn't blank the cards while the new figures load.
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory
        .setDatabasesPath(Directory.systemTemp.createTempSync('fm_value').path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  Future<void> pumpValueScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    await tester.runAsync(() async {
      final flock = Flock.create(name: 'Backyard');
      await FlockRepository().insertFlock(flock);
      await FinanceRepository().insertExpense(Expense.create(
        date: now,
        amount: 24.5,
        category: ExpenseCategory.feed,
        description: 'Layer pellets',
      ));
      await EggRepository().insertEggLog(
          EggLog.create(date: now, count: 30, flockId: flock.id));
    });

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [canEditProvider.overrideWithValue(true)],
      child: MaterialApp(
        theme: AppTheme.buildTheme(AppPalette.sage),
        home: const ValueScreen(),
      ),
    ));
    await settle(tester);
  }

  testWidgets('money figures use the platform font, not Fraunces',
      (tester) async {
    await pumpValueScreen(tester);
    expect(find.text('Your Cost'), findsOneWidget);

    // The rendered text, with theme styles merged in, as on screen.
    var checked = 0;
    for (final e in find.byType(RichText).evaluate()) {
      (e.widget as RichText).text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').contains(r'$')) {
          checked++;
          expect(span.style?.fontFamily, isNot(AppTheme.headingFontFamily),
              reason: span.text);
        }
        return true;
      });
    }
    expect(checked, greaterThan(2));
  });

  testWidgets('switching period keeps the cards on screen', (tester) async {
    await pumpValueScreen(tester);
    expect(find.text('Egg Value'), findsOneWidget);

    for (final period in ['90 days', 'This year', '30 days']) {
      await tester.tap(find.widgetWithText(ChoiceChip, period));
      // The frames straight after the tap, while the new period loads.
      for (var i = 0; i < 3; i++) {
        await tester.pump();
        expect(find.text('Egg Value'), findsOneWidget, reason: period);
        expect(find.text('Your Cost'), findsOneWidget, reason: period);
        expect(find.text('...'), findsNothing, reason: period);
      }
      await settle(tester);
    }
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
