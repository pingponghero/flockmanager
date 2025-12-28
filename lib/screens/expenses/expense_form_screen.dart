import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/enums.dart';
import '../../providers/expense_provider.dart';
import '../../providers/flock_provider.dart';

/// Form screen for adding/editing expenses
class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.feed;
  String? _selectedFlockId;
  bool _isRecurring = false;
  RecurringInterval? _recurringInterval;

  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.expenseId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromExpense(Expense expense) {
    if (_isInitialized) return;
    _isInitialized = true;

    _amountController.text = expense.amount.toStringAsFixed(2);
    _descriptionController.text = expense.description ?? '';
    _selectedDate = expense.date;
    _selectedCategory = expense.category;
    _selectedFlockId = expense.flockId;
    _isRecurring = expense.isRecurring;
    _recurringInterval = expense.recurringInterval;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      if (_isEditing) {
        final existing = await ref.read(expenseByIdProvider(widget.expenseId!).future);
        if (existing != null) {
          final updated = existing.copyWith(
            date: _selectedDate,
            amount: amount,
            category: _selectedCategory,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            flockId: _selectedFlockId,
            isRecurring: _isRecurring,
            recurringInterval: _isRecurring ? _recurringInterval : null,
          );
          await ref.read(expensesProvider.notifier).updateExpense(updated);
        }
      } else {
        final expense = Expense.create(
          date: _selectedDate,
          amount: amount,
          category: _selectedCategory,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          flockId: _selectedFlockId,
          isRecurring: _isRecurring,
          recurringInterval: _isRecurring ? _recurringInterval : null,
        );
        await ref.read(expensesProvider.notifier).addExpense(expense);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flocksAsync = ref.watch(flocksProvider);

    // Load existing expense if editing
    if (_isEditing) {
      final expenseAsync = ref.watch(expenseByIdProvider(widget.expenseId!));
      expenseAsync.whenData((expense) {
        if (expense != null) {
          _initializeFromExpense(expense);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const Divider(),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., 50lb bag of layer feed',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Flock (optional)
            flocksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (flocks) {
                if (flocks.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String?>(
                  value: _selectedFlockId,
                  decoration: const InputDecoration(
                    labelText: 'Flock (optional)',
                    hintText: 'Shared expense',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Shared (all flocks)'),
                    ),
                    ...flocks.map((flock) => DropdownMenuItem(
                          value: flock.id,
                          child: Text(flock.name),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFlockId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring expense'),
              subtitle: const Text('Set up automatic reminders'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  if (value && _recurringInterval == null) {
                    _recurringInterval = RecurringInterval.monthly;
                  }
                });
              },
            ),

            // Recurring interval
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurringInterval>(
                value: _recurringInterval ?? RecurringInterval.monthly,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                ),
                items: RecurringInterval.values.map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text(interval.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _recurringInterval = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Form screen for adding/editing income
class IncomeFormScreen extends ConsumerStatefulWidget {
  final String? incomeId;

  const IncomeFormScreen({super.key, this.incomeId});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eggCountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditing => widget.incomeId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _eggCountController.dispose();
    super.dispose();
  }

  void _initializeFromIncome(Income income) {
    if (_isInitialized) return;
    _isInitialized = true;

    _amountController.text = income.amount.toStringAsFixed(2);
    _descriptionController.text = income.description ?? '';
    _eggCountController.text = income.eggCount?.toString() ?? '';
    _selectedDate = income.date;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final eggCount = _eggCountController.text.isEmpty
          ? null
          : int.tryParse(_eggCountController.text);

      if (_isEditing) {
        final existing = await ref.read(incomeByIdProvider(widget.incomeId!).future);
        if (existing != null) {
          final updated = existing.copyWith(
            date: _selectedDate,
            amount: amount,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            eggCount: eggCount,
          );
          await ref.read(incomeProvider.notifier).updateIncome(updated);
        }
      } else {
        final income = Income.create(
          date: _selectedDate,
          amount: amount,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          eggCount: eggCount,
        );
        await ref.read(incomeProvider.notifier).addIncome(income);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving income: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load existing income if editing
    if (_isEditing) {
      final incomeAsync = ref.watch(incomeByIdProvider(widget.incomeId!));
      incomeAsync.whenData((income) {
        if (income != null) {
          _initializeFromIncome(income);
        }
      });
    }

    // Calculate price per egg if both amount and egg count are entered
    double? pricePerEgg;
    if (_amountController.text.isNotEmpty && _eggCountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text);
      final eggs = int.tryParse(_eggCountController.text);
      if (amount != null && eggs != null && eggs > 0) {
        pricePerEgg = amount / eggs;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Income' : 'Record Sale'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount received',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              autofocus: !_isEditing,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Egg count
            TextFormField(
              controller: _eggCountController,
              decoration: InputDecoration(
                labelText: 'Number of eggs sold (optional)',
                helperText: pricePerEgg != null
                    ? 'That\'s \$${pricePerEgg.toStringAsFixed(2)} per egg'
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const Divider(),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Farmers market, neighbor',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
