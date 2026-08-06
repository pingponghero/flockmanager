import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/enums.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/egg_provider.dart' show currencySymbolProvider;
import '../../providers/expense_provider.dart';
import '../../providers/flock_provider.dart';
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/achievement_celebration_dialog.dart';
import '../../widgets/recipient_selector.dart';

String? _currencyPrefix(WidgetRef ref) {
  final cs = ref.watch(currencySymbolProvider);
  return cs.isNotEmpty ? '$cs ' : null;
}

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
  bool _flockPrefilled = false;

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
        // Check for new achievements
        final newAchievements = await checkAndCelebrateAchievements(ref, context);
        if (mounted && newAchievements.isNotEmpty) {
          await AchievementCelebrationDialog.showMultiple(context, newAchievements);
          await markAchievementsAsShown(newAchievements);
        }

        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error saving expense: $e');
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
          padding: pagePadding(context),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: _currencyPrefix(ref),
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
            DropdownMenu<ExpenseCategory>(
              initialSelection: _selectedCategory,
              expandedInsets: EdgeInsets.zero,
              label: const Text('Category'),
              dropdownMenuEntries: ExpenseCategory.values
                  .map((category) => DropdownMenuEntry(
                        value: category,
                        label: category.displayName,
                      ))
                  .toList(),
              onSelected: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat.yMMMd().format(_selectedDate)),
                subtitle: const Text('Date'),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

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
                // Prefill when only one flock exists (matches egg logging);
                // 'Shared' stays the default with multiple flocks.
                if (!_isEditing && !_flockPrefilled && flocks.length == 1) {
                  _flockPrefilled = true;
                  _selectedFlockId ??= flocks.first.id;
                }
                return DropdownMenu<String?>(
                  initialSelection: _selectedFlockId,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Flock (optional)'),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(
                      value: null,
                      label: 'Shared (all flocks)',
                    ),
                    ...flocks.map((flock) => DropdownMenuEntry(
                          value: flock.id,
                          label: flock.name,
                        )),
                  ],
                  onSelected: (value) {
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
              DropdownMenu<RecurringInterval>(
                initialSelection: _recurringInterval ?? RecurringInterval.monthly,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Repeat'),
                dropdownMenuEntries: RecurringInterval.values
                    .map((interval) => DropdownMenuEntry(
                          value: interval,
                          label: interval.displayName,
                        ))
                    .toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() => _recurringInterval = value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Form screen for adding/editing income (egg sales) and gifts.
class IncomeFormScreen extends ConsumerStatefulWidget {
  final String? incomeId;

  /// Type preselected when creating a new record (e.g. the Record Gift
  /// action). Ignored when editing — the record's own type is used.
  final IncomeType initialType;

  const IncomeFormScreen({
    super.key,
    this.incomeId,
    this.initialType = IncomeType.sale,
  });

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eggCountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedFlockId;
  late IncomeType _type = widget.initialType;
  String? _selectedRecipientId;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _flockPrefilled = false;

  bool get _isEditing => widget.incomeId != null;
  bool get _isGift => _type == IncomeType.gift;

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
    _selectedFlockId = income.flockId;
    _type = income.type;
    _selectedRecipientId = income.recipientId;
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
      // Gifts are always zero-amount so they never touch income totals.
      final amount = _isGift ? 0.0 : double.parse(_amountController.text);
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
            flockId: _selectedFlockId,
            type: _type,
            recipientId: _selectedRecipientId,
          );
          await ref.read(incomeProvider.notifier).updateIncome(updated);
        }
      } else {
        final income = Income.create(
          date: _selectedDate,
          amount: amount,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          eggCount: eggCount,
          flockId: _selectedFlockId,
          type: _type,
          recipientId: _selectedRecipientId,
        );
        await ref.read(incomeProvider.notifier).addIncome(income);
      }

      if (mounted) {
        // Check for new achievements
        final newAchievements = await checkAndCelebrateAchievements(ref, context);
        if (mounted && newAchievements.isNotEmpty) {
          await AchievementCelebrationDialog.showMultiple(context, newAchievements);
          await markAchievementsAsShown(newAchievements);
        }

        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error saving income: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isGift ? 'Delete Gift' : 'Delete Income'),
        content: Text(_isGift
            ? 'Are you sure you want to delete this gift record?'
            : 'Are you sure you want to delete this income record?'),
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
    if (confirmed != true) return;

    await ref.read(incomeProvider.notifier).deleteIncome(widget.incomeId!);
    if (!mounted) return;
    showAppSnackBar(context, _isGift ? 'Gift deleted' : 'Income deleted');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final flocksAsync = ref.watch(flocksProvider);

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
        title: Text(_isEditing
            ? (_isGift ? 'Edit Gift' : 'Edit Income')
            : (_isGift ? 'Record Gift' : 'Record Sale')),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: _isGift ? 'Delete gift' : 'Delete income',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _delete,
            ),
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
          padding: pagePadding(context),
          children: [
            // Sale / Gift selector
            SegmentedButton<IncomeType>(
              segments: const [
                ButtonSegment(
                  value: IncomeType.sale,
                  label: Text('Sale'),
                  icon: Icon(Icons.attach_money),
                ),
                ButtonSegment(
                  value: IncomeType.gift,
                  label: Text('Gift'),
                  icon: Icon(Icons.card_giftcard),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Amount (sales only — gifts are always free)
            if (!_isGift) ...[
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount received',
                  prefixText: _currencyPrefix(ref),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (_isGift) return null;
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
            ],

            // Egg count (required for gifts so gifted-egg stats work)
            TextFormField(
              controller: _eggCountController,
              decoration: InputDecoration(
                labelText: _isGift
                    ? 'Number of eggs gifted'
                    : 'Number of eggs sold (optional)',
                helperText: !_isGift && pricePerEgg != null
                    ? 'That\'s ${ref.watch(currencySymbolProvider)}${pricePerEgg.toStringAsFixed(2)} per egg'
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (!_isGift) return null;
                final count = int.tryParse(value ?? '');
                if (count == null || count <= 0) {
                  return 'Please enter how many eggs were gifted';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Recipient
            RecipientSelector(
              selectedRecipientId: _selectedRecipientId,
              onChanged: (id) => setState(() => _selectedRecipientId = id),
            ),
            const SizedBox(height: 16),

            // Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat.yMMMd().format(_selectedDate)),
                subtitle: const Text('Date'),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: _isGift
                    ? 'e.g., Thank-you for watching the coop'
                    : 'e.g., Farmers market, neighbor',
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
                // Prefill when only one flock exists (matches egg logging);
                // 'Shared' stays the default with multiple flocks.
                if (!_isEditing && !_flockPrefilled && flocks.length == 1) {
                  _flockPrefilled = true;
                  _selectedFlockId ??= flocks.first.id;
                }
                return DropdownMenu<String?>(
                  initialSelection: _selectedFlockId,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Flock (optional)'),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(
                      value: null,
                      label: 'Shared (all flocks)',
                    ),
                    ...flocks.map((flock) => DropdownMenuEntry(
                          value: flock.id,
                          label: flock.name,
                        )),
                  ],
                  onSelected: (value) {
                    setState(() => _selectedFlockId = value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

