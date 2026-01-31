import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/enums.dart';
import '../repositories/expense_repository.dart';
import 'egg_provider.dart';

/// Repository provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

// ==================== EXPENSE PROVIDERS ====================

/// Async notifier for managing expenses
class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    final repository = ref.read(expenseRepositoryProvider);
    return repository.getAllExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.insertExpense(expense);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  Future<void> updateExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.updateExpense(expense);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  Future<void> deleteExpense(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.deleteExpense(id);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  void _invalidateFinancialProviders() {
    ref.invalidate(monthExpensesProvider);
    ref.invalidate(monthIncomeProvider);
    ref.invalidate(costPerEggProvider);
    ref.invalidate(profitLossProvider);
    ref.invalidate(expensesByCategoryProvider);
  }
}

/// Provider for all expenses
final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});

// ==================== INCOME PROVIDERS ====================

/// Async notifier for managing income
class IncomeNotifier extends AsyncNotifier<List<Income>> {
  @override
  Future<List<Income>> build() async {
    return _fetchIncome();
  }

  Future<List<Income>> _fetchIncome() async {
    final repository = ref.read(expenseRepositoryProvider);
    return repository.getAllIncome();
  }

  Future<void> addIncome(Income income) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.insertIncome(income);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  Future<void> updateIncome(Income income) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.updateIncome(income);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  Future<void> deleteIncome(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.deleteIncome(id);
    ref.invalidateSelf();
    _invalidateFinancialProviders();
  }

  void _invalidateFinancialProviders() {
    ref.invalidate(monthExpensesProvider);
    ref.invalidate(monthIncomeProvider);
    ref.invalidate(costPerEggProvider);
    ref.invalidate(profitLossProvider);
  }
}

/// Provider for all income
final incomeProvider = AsyncNotifierProvider<IncomeNotifier, List<Income>>(() {
  return IncomeNotifier();
});

// ==================== DATE RANGE HELPERS ====================

/// Date range options for financial reports
enum FinanceDateRange {
  thisMonth('This Month'),
  last90Days('Last 90 Days'),
  thisYear('This Year'),
  allTime('All Time');

  final String displayName;
  const FinanceDateRange(this.displayName);

  (DateTime start, DateTime end) get dates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (this) {
      case FinanceDateRange.thisMonth:
        return (DateTime(now.year, now.month, 1), today);
      case FinanceDateRange.last90Days:
        return (DateTime(now.year, now.month, now.day - 90), today);
      case FinanceDateRange.thisYear:
        return (DateTime(now.year, 1, 1), today);
      case FinanceDateRange.allTime:
        return (DateTime(2000, 1, 1), today);
    }
  }
}

/// Finance date range notifier
class FinanceDateRangeNotifier extends Notifier<FinanceDateRange> {
  @override
  FinanceDateRange build() => FinanceDateRange.thisMonth;

  void setRange(FinanceDateRange range) => state = range;
}

/// Selected date range for finances screen
final financeDateRangeProvider =
    NotifierProvider<FinanceDateRangeNotifier, FinanceDateRange>(
        FinanceDateRangeNotifier.new);

DateTime _startOfMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

DateTime _endOfMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
}

DateTime _startOfAllTime() {
  return DateTime(2000, 1, 1); // Far enough in the past
}

// ==================== FINANCIAL SUMMARY PROVIDERS ====================

/// Total expenses for selected date range
final selectedRangeExpensesProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  final range = ref.watch(financeDateRangeProvider);
  final (start, end) = range.dates;
  return repository.getTotalExpenses(start, end);
});

/// Total income for selected date range
final selectedRangeIncomeProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  final range = ref.watch(financeDateRangeProvider);
  final (start, end) = range.dates;
  return repository.getTotalIncome(start, end);
});

/// Profit/loss for selected date range
final selectedRangeProfitLossProvider = FutureProvider<double>((ref) async {
  final income = await ref.watch(selectedRangeIncomeProvider.future);
  final expenses = await ref.watch(selectedRangeExpensesProvider.future);
  return income - expenses;
});

/// Cost per egg for selected date range
final selectedRangeCostPerEggProvider = FutureProvider<double?>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  final eggRepository = ref.read(eggRepositoryProvider);
  final range = ref.watch(financeDateRangeProvider);
  final (start, end) = range.dates;

  final totalExpenses = await repository.getTotalExpenses(start, end);
  final totalEggs = await eggRepository.getEggCountByDateRange(start, end);

  if (totalEggs == 0) return null;
  return totalExpenses / totalEggs;
});

/// This month's total expenses
final monthExpensesProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getTotalExpenses(_startOfMonth(), _endOfMonth());
});

/// This month's total income
final monthIncomeProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getTotalIncome(_startOfMonth(), _endOfMonth());
});

/// All-time total expenses
final totalExpensesProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getTotalExpensesAllTime();
});

/// All-time total income
final totalIncomeProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getTotalIncomeAllTime();
});

/// Cost per egg: total expenses / total eggs
final costPerEggProvider = FutureProvider<double?>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  final eggRepository = ref.read(eggRepositoryProvider);

  final totalExpenses = await repository.getTotalExpensesAllTime();
  final totalEggs = await eggRepository.getTotalEggCount();

  if (totalEggs == 0) return null;
  return totalExpenses / totalEggs;
});

/// Profit/loss: income - expenses (all time)
final profitLossProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);

  final totalIncome = await repository.getTotalIncomeAllTime();
  final totalExpenses = await repository.getTotalExpensesAllTime();

  return totalIncome - totalExpenses;
});

/// This month's profit/loss
final monthProfitLossProvider = FutureProvider<double>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);

  final income = await repository.getTotalIncome(_startOfMonth(), _endOfMonth());
  final expenses = await repository.getTotalExpenses(_startOfMonth(), _endOfMonth());

  return income - expenses;
});

/// Expenses grouped by category for this month
final expensesByCategoryProvider = FutureProvider<Map<ExpenseCategory, double>>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getExpensesByCategories(_startOfMonth(), _endOfMonth());
});

/// All-time expenses by category
final allTimeExpensesByCategoryProvider = FutureProvider<Map<ExpenseCategory, double>>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getExpensesByCategories(_startOfAllTime(), DateTime.now());
});

/// Recent expenses (last 10)
final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  return expenses.take(10).toList();
});

/// Recent income (last 10)
final recentIncomeProvider = FutureProvider<List<Income>>((ref) async {
  final income = await ref.watch(incomeProvider.future);
  return income.take(10).toList();
});

/// Get expense by ID
final expenseByIdProvider = FutureProvider.family<Expense?, String>((ref, id) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getExpenseById(id);
});

/// Get income by ID
final incomeByIdProvider = FutureProvider.family<Income?, String>((ref, id) async {
  final repository = ref.read(expenseRepositoryProvider);
  return repository.getIncomeById(id);
});

/// Break-even price per egg (expenses / eggs sold)
final breakEvenPriceProvider = FutureProvider<double?>((ref) async {
  final repository = ref.read(expenseRepositoryProvider);

  final totalExpenses = await repository.getTotalExpensesAllTime();
  final totalEggsSold = await repository.getTotalEggsSold(_startOfAllTime(), DateTime.now());

  if (totalEggsSold == 0) return null;
  return totalExpenses / totalEggsSold;
});
