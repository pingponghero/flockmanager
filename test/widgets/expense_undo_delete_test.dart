import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flock_manager/database/database_helper.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/models/expense.dart';
import 'package:flock_manager/providers/trial_provider.dart';
import 'package:flock_manager/repositories/finance_repository.dart';
import 'package:flock_manager/screens/value/value_screen.dart';

/// #65: swiping an expense away deletes it immediately and Undo restores it,
/// instead of a confirmation dialog first.
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory
        .setDatabasesPath(Directory.systemTemp.createTempSync('fm_undo').path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  testWidgets('swipe deletes without a dialog; Undo brings it back',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final expense = Expense.create(
      date: DateTime.now(),
      amount: 24.5,
      category: ExpenseCategory.feed,
      description: 'Layer pellets',
    );
    final repo = FinanceRepository();
    await tester.runAsync(() => repo.insertExpense(expense));

    // Tall enough that the transaction list below the hero cards is built
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [canEditProvider.overrideWithValue(true)],
      child: const MaterialApp(home: ValueScreen()),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settle();
    expect(find.text('Layer pellets'), findsOneWidget);

    await tester.drag(find.text('Layer pellets'), const Offset(-600, 0));
    await settle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Layer pellets'), findsNothing);
    expect(find.text('Expense deleted'), findsOneWidget);
    final afterDelete =
        await tester.runAsync(() => repo.getExpenseById(expense.id));
    expect(afterDelete, isNull);

    // Let the snackbar finish sliding in; it ignores taps while animating.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Undo'));
    await settle();

    final restored =
        await tester.runAsync(() => repo.getExpenseById(expense.id));
    expect(restored?.amount, 24.5, reason: 'restored in the database');
    expect(find.text('Layer pellets'), findsOneWidget);
  });
}
