import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/enums.dart';
import '../../providers/expense_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/flock_dropdown.dart';
import '../../widgets/trial_banner.dart' show showTrialExpiredDialog;

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finances'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          const _IncomeTab(),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final canEdit = ref.watch(canEditProvider);
          return FloatingActionButton(
            onPressed: canEdit
                ? () => _showAddDialog(context)
                : () => showTrialExpiredDialog(context, ref),
            tooltip: 'Add',
            child: const Icon(Icons.add),
          );
        },
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

class _ExpensesTab extends ConsumerWidget {
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;

  const _ExpensesTab({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final selectedRange = ref.watch(financeDateRangeProvider);
    final rangeTotalAsync = ref.watch(selectedRangeExpensesProvider);
    final costPerEggAsync = ref.watch(selectedRangeCostPerEggProvider);
    final selectedFlockId = ref.watch(selectedFlockIdProvider);

    return Column(
      children: [
        // Flock filter dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FlockDropdown(
            selectedFlockId: selectedFlockId,
            onChanged: (value) {
              ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
            },
          ),
        ),

        // Date range selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: FinanceDateRange.values.map((range) {
              final isSelected = selectedRange == range;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(range.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(financeDateRangeProvider.notifier).setRange(range);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    rangeTotalAsync.when(
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('--'),
                      data: (total) => Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost per Egg',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    costPerEggAsync.when(
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('--'),
                      data: (cost) => Text(
                        cost != null ? '\$${cost.toStringAsFixed(2)}' : 'N/A',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
              const SizedBox(width: 8),
              ...ExpenseCategory.values.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.displayName),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategoryChanged(
                        selectedCategory == category ? null : category,
                      ),
                    ),
                  )),
            ],
          ),
        ),

        // Expense list
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (expenses) {
              var filtered = expenses.toList();

              // Apply flock filter
              if (selectedFlockId != null) {
                filtered = filtered.where((e) => e.flockId == selectedFlockId).toList();
              }

              // Apply category filter
              if (selectedCategory != null) {
                filtered = filtered.where((e) => e.category == selectedCategory).toList();
              }

              if (filtered.isEmpty) {
                return Center(
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
                        selectedCategory == null
                            ? 'No expenses recorded'
                            : 'No ${selectedCategory!.displayName.toLowerCase()} expenses',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80).withSystemNavigation(context),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final expense = filtered[index];
                  return _ExpenseTile(expense: expense);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
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
            content: const Text('Are you sure you want to delete this expense?'),
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
          backgroundColor: _getCategoryColor(expense.category).withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
            size: 20,
          ),
        ),
        title: Text(expense.description ?? expense.category.displayName),
        subtitle: Text(DateFormat.yMMMd().format(expense.date)),
        trailing: Text(
          '\$${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () => context.push('/expenses/${expense.id}'),
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

class _IncomeTab extends ConsumerWidget {
  const _IncomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);
    final selectedRange = ref.watch(financeDateRangeProvider);
    final rangeTotalAsync = ref.watch(selectedRangeIncomeProvider);
    final profitLossAsync = ref.watch(selectedRangeProfitLossProvider);

    return Column(
      children: [
        // Date range selector (shared with expenses tab)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: FinanceDateRange.values.map((range) {
              final isSelected = selectedRange == range;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(range.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(financeDateRangeProvider.notifier).setRange(range);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Income',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    rangeTotalAsync.when(
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('--'),
                      data: (total) => Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profit/Loss',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    profitLossAsync.when(
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('--'),
                      data: (amount) {
                        final isProfit = amount >= 0;
                        return Text(
                          '${isProfit ? '+' : ''}\$${amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isProfit ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Income list
        Expanded(
          child: incomeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (incomeList) {
              if (incomeList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No income recorded',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track egg sales here',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80).withSystemNavigation(context),
                itemCount: incomeList.length,
                itemBuilder: (context, index) {
                  final income = incomeList[index];
                  return _IncomeTile(income: income);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IncomeTile extends ConsumerWidget {
  final Income income;

  const _IncomeTile({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
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
            content: const Text('Are you sure you want to delete this income record?'),
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
          backgroundColor: Colors.green.shade100,
          child: Icon(
            Icons.egg,
            color: Colors.green.shade700,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
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
                color: Colors.green.shade700,
              ),
        ),
        onTap: () => context.push('/expenses/income/${income.id}'),
      ),
    );
  }
}
