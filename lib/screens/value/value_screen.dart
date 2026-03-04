import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/enums.dart';
import '../../models/egg_value_summary.dart';
import '../../providers/egg_value_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/flock_dropdown.dart';
import '../../widgets/trial_banner.dart' show showTrialExpiredDialog;

/// Filter options combining expense categories + income.
enum _ListFilter {
  all('All'),
  income('Income'),
  feed('Feed'),
  bedding('Bedding'),
  supplies('Supplies'),
  medical('Medical'),
  equipment('Equipment'),
  other('Other');

  final String label;
  const _ListFilter(this.label);

  ExpenseCategory? get expenseCategory {
    switch (this) {
      case _ListFilter.all:
      case _ListFilter.income:
        return null;
      case _ListFilter.feed:
        return ExpenseCategory.feed;
      case _ListFilter.bedding:
        return ExpenseCategory.bedding;
      case _ListFilter.supplies:
        return ExpenseCategory.supplies;
      case _ListFilter.medical:
        return ExpenseCategory.medical;
      case _ListFilter.equipment:
        return ExpenseCategory.equipment;
      case _ListFilter.other:
        return ExpenseCategory.other;
    }
  }

  bool get isIncomeOnly => this == _ListFilter.income;
  bool get isAll => this == _ListFilter.all;
  bool get isExpenseCategory => !isAll && !isIncomeOnly;
}

class ValueScreen extends ConsumerStatefulWidget {
  const ValueScreen({super.key});

  @override
  ConsumerState<ValueScreen> createState() => _ValueScreenState();
}

class _ValueScreenState extends ConsumerState<ValueScreen> {
  _ListFilter _selectedFilter = _ListFilter.all;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final incomeAsync = ref.watch(incomeProvider);
    final selectedRange = ref.watch(financeDateRangeProvider);
    final eggValueAsync = ref.watch(selectedRangeEggValueProvider);
    final categoryAsync = ref.watch(selectedRangeExpensesByCategoryProvider);
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final canEdit = ref.watch(canEditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Value'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider);
          ref.invalidate(incomeProvider);
          ref.invalidate(selectedRangeEggValueProvider);
          ref.invalidate(selectedRangeDailyExpensesProvider);
          ref.invalidate(selectedRangeDailyIncomeProvider);
          ref.invalidate(selectedRangeExpensesByCategoryProvider);
          await Future.wait([
            ref.read(expensesProvider.future),
            ref.read(incomeProvider.future),
            ref.read(selectedRangeEggValueProvider.future),
            ref.read(selectedRangeExpensesByCategoryProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80).withSystemNavigation(context),
          children: [
          // Flock filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FlockDropdown(
              selectedFlockId: selectedFlockId,
              onChanged: (value) {
                ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
              },
            ),
          ),

          // Period and category dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownMenu<FinanceDateRange>(
                    initialSelection: selectedRange,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Period'),
                    dropdownMenuEntries: FinanceDateRange.values
                        .map((range) => DropdownMenuEntry(
                              value: range,
                              label: range.displayName,
                            ))
                        .toList(),
                    onSelected: (value) {
                      if (value != null) {
                        ref
                            .read(financeDateRangeProvider.notifier)
                            .setRange(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownMenu<_ListFilter>(
                    initialSelection: _selectedFilter,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Category'),
                    dropdownMenuEntries: _ListFilter.values
                        .map((f) => DropdownMenuEntry(
                              value: f,
                              label: f.label,
                            ))
                        .toList(),
                    onSelected: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Hero card: Egg Value
          _EggValueCard(eggValueAsync: eggValueAsync),
          const SizedBox(height: 8),

          // Side-by-side metric cards
          _MetricCards(eggValueAsync: eggValueAsync),
          const SizedBox(height: 8),

          // Expense category breakdown
          _CategoryBreakdown(
            categoryAsync: categoryAsync,
            onCategoryTap: (category) {
              final filter = _ListFilter.values.firstWhere(
                (f) => f.expenseCategory == category,
                orElse: () => _ListFilter.all,
              );
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 16),

          // Merged chronological list
          _LineItemList(
            expensesAsync: expensesAsync,
            incomeAsync: incomeAsync,
            selectedRange: selectedRange,
            selectedFlockId: selectedFlockId,
            filter: _selectedFilter,
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: canEdit
            ? () => _showAddDialog(context)
            : () => showTrialExpiredDialog(context, ref),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Income'),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/income/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Union type for merged expense/income list items.
class _LineItem {
  final Expense? expense;
  final Income? incomeRecord;

  _LineItem.expense(Expense e)
      : expense = e,
        incomeRecord = null;

  _LineItem.income(Income i)
      : expense = null,
        incomeRecord = i;

  DateTime get date => expense?.date ?? incomeRecord!.date;
}

// ==================== Egg Value Hero Card ====================

class _EggValueCard extends StatelessWidget {
  final AsyncValue<EggValueSummary> eggValueAsync;

  const _EggValueCard({required this.eggValueAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: eggValueAsync.when(
        loading: () => Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                '...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (summary) {
          if (summary.eggCount == 0 && summary.totalExpenses == 0) {
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No activity this period',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            );
          }

          final primaryColor = Theme.of(context).colorScheme.primary;
          final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Left: label + big number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Egg Value',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${summary.eggProductionValue.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Right: value breakdown
                  if (summary.eggCount > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${summary.eggsConsumed} eggs @ \$${summary.retailPricePerDozen.toStringAsFixed(2)}/dz',
                          style: mutedStyle,
                        ),
                        if (summary.eggsSold > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${summary.eggsSold} sold @ \$${(summary.totalIncome / summary.eggsSold * 12).toStringAsFixed(2)}/dz avg',
                            style: mutedStyle,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== Side-by-side Metric Cards ====================

class _MetricCards extends StatelessWidget {
  final AsyncValue<EggValueSummary> eggValueAsync;

  const _MetricCards({required this.eggValueAsync});

  @override
  Widget build(BuildContext context) {
    return eggValueAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.eggCount == 0 && summary.totalExpenses == 0) {
          return const SizedBox.shrink();
        }

        final netCostPerDozen = summary.netCostPerDozen;
        final isPositive = summary.isBeatingTheStore;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Your Cost per Dozen
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Your Cost per Dozen',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.totalExpenses == 0 && summary.eggCount > 0
                              ? '\$0.00'
                              : netCostPerDozen != null
                                  ? '\$${netCostPerDozen.toStringAsFixed(2)}'
                                  : 'N/A',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Net Impact
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Net Impact',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isPositive ? '+' : '-'}\$${summary.netSavings.abs().toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== Category Breakdown ====================

class _CategoryBreakdown extends StatelessWidget {
  final AsyncValue<Map<ExpenseCategory, double>> categoryAsync;
  final ValueChanged<ExpenseCategory> onCategoryTap;

  const _CategoryBreakdown({
    required this.categoryAsync,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return categoryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        // Sort by amount descending
        final sorted = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final maxAmount = sorted.first.value;
        if (maxAmount == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: sorted.asMap().entries.map((indexed) {
                  final entry = indexed.value;
                  final rank = indexed.key;
                  final fraction = entry.value / maxAmount;
                  // Gradient: strongest bar gets full alpha, weakest gets lighter
                  // Range from 0.7 down to 0.25 based on rank
                  final alpha = sorted.length == 1
                      ? 0.6
                      : 0.7 - (rank / (sorted.length - 1)) * 0.45;
                  final barColor = Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: alpha);
                  return InkWell(
                    onTap: () => onCategoryTap(entry.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              entry.key.displayName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: fraction,
                                child: Container(
                                  height: 14,
                                  color: barColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

}

// ==================== Line Item List ====================

class _LineItemList extends StatelessWidget {
  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue<List<Income>> incomeAsync;
  final FinanceDateRange selectedRange;
  final String? selectedFlockId;
  final _ListFilter filter;

  const _LineItemList({
    required this.expensesAsync,
    required this.incomeAsync,
    required this.selectedRange,
    required this.selectedFlockId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    if (expensesAsync.isLoading || incomeAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (expensesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Error: ${expensesAsync.error}')),
      );
    }

    final expenses = expensesAsync.value ?? [];
    final income = incomeAsync.value ?? [];
    final (rangeStart, rangeEnd) = selectedRange.dates;

    // Filter expenses by date range, flock, category
    var filteredExpenses = expenses.where((e) {
      final d = e.date;
      return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
    }).toList();

    if (selectedFlockId != null) {
      filteredExpenses =
          filteredExpenses.where((e) => e.flockId == selectedFlockId).toList();
    }

    if (filter.isExpenseCategory) {
      filteredExpenses = filteredExpenses
          .where((e) => e.category == filter.expenseCategory)
          .toList();
    }

    // Filter income by date range
    final filteredIncome = income.where((i) {
      final d = i.date;
      return !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);
    }).toList();

    // Build merged list based on filter
    final items = <_LineItem>[
      // Show expenses unless filter is Income-only
      if (!filter.isIncomeOnly)
        ...filteredExpenses.map((e) => _LineItem.expense(e)),
      // Show income if filter is All or Income
      if (filter.isAll || filter.isIncomeOnly)
        ...filteredIncome.map((i) => _LineItem.income(i)),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No activity this period',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.map((item) {
          if (item.expense != null) {
            return _ExpenseCard(expense: item.expense!);
          } else {
            return _IncomeCard(income: item.incomeRecord!);
          }
        }).toList(),
      ),
    );
  }
}

// ==================== Card-based List Tiles ====================

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense'),
              content:
                  const Text('Are you sure you want to delete this expense?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          ref.read(expensesProvider.notifier).deleteExpense(expense.id);
          showAppSnackBar(context, 'Expense deleted');
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                _getCategoryColor(expense.category).withValues(alpha: 0.2),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 20,
            ),
          ),
          title: Text(expense.description ?? expense.category.displayName),
          subtitle: Text(DateFormat.yMMMd().format(expense.date)),
          trailing: Text(
            '-\$${expense.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          onTap: () => context.push('/expenses/${expense.id}'),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.feed:
        return Icons.grass;
      case ExpenseCategory.bedding:
        return Icons.hotel;
      case ExpenseCategory.supplies:
        return Icons.shopping_bag;
      case ExpenseCategory.medical:
        return Icons.medical_services;
      case ExpenseCategory.equipment:
        return Icons.build;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.feed:
        return Colors.green;
      case ExpenseCategory.bedding:
        return Colors.brown;
      case ExpenseCategory.supplies:
        return Colors.blue;
      case ExpenseCategory.medical:
        return Colors.red;
      case ExpenseCategory.equipment:
        return Colors.orange;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}

class _IncomeCard extends ConsumerWidget {
  final Income income;

  const _IncomeCard({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key(income.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Income'),
              content: const Text(
                  'Are you sure you want to delete this income record?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          ref.read(incomeProvider.notifier).deleteIncome(income.id);
          showAppSnackBar(context, 'Income deleted');
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.egg,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(income.description ?? 'Egg Sale'),
          subtitle: Row(
            children: [
              Text(DateFormat.yMMMd().format(income.date)),
              if (income.eggCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${income.eggCount} eggs',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
          trailing: Text(
            '+\$${income.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          onTap: () => context.push('/expenses/income/${income.id}'),
        ),
      ),
    );
  }
}
