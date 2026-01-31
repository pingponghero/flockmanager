import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/egg_log.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../widgets/egg_quick_log.dart';

class EggHistoryScreen extends ConsumerStatefulWidget {
  const EggHistoryScreen({super.key});

  @override
  ConsumerState<EggHistoryScreen> createState() => _EggHistoryScreenState();
}

class _EggHistoryScreenState extends ConsumerState<EggHistoryScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final selectedFlockId = ref.watch(selectedFlockIdProvider);
    final flocksAsync = ref.watch(flocksProvider);

    // Calculate date range for current month view
    final startOfMonth = _currentMonth;
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final dateRange = DateRange(startOfMonth, endOfMonth);

    final dailyCountsAsync = ref.watch(dailyEggCountsProvider(dateRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Today',
          ),
        ],
      ),
      body: dailyCountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (dailyCounts) => ListView(
          children: [
            // Flock filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: flocksAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (flocks) => DropdownMenu<String?>(
                  initialSelection: selectedFlockId,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Flock'),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry(
                      value: null,
                      label: 'All Flocks',
                    ),
                    ...flocks.map((flock) => DropdownMenuEntry(
                          value: flock.id,
                          label: flock.name,
                        )),
                  ],
                  onSelected: (value) {
                    ref.read(selectedFlockIdProvider.notifier).selectFlock(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Month navigation
            _MonthNavigation(
              currentMonth: _currentMonth,
              onPreviousMonth: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                    1,
                  );
                  _selectedDate = null;
                });
              },
              onNextMonth: () {
                final now = DateTime.now();
                final nextMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  1,
                );
                if (nextMonth.isBefore(DateTime(now.year, now.month + 1, 1))) {
                  setState(() {
                    _currentMonth = nextMonth;
                    _selectedDate = null;
                  });
                }
              },
            ),
            // Calendar
            _CalendarGrid(
              currentMonth: _currentMonth,
              dailyCounts: dailyCounts,
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
            const Divider(height: 1),
            // Day details
            if (_selectedDate != null)
              _DayDetailsInline(
                date: _selectedDate!,
                onLogDeleted: () {
                  ref.invalidate(dailyEggCountsProvider(dateRange));
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Select a day to view details',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final log = await showEggQuickLog(context);
          if (log != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  log.count == 0
                      ? 'Logged: No eggs collected'
                      : 'Logged: ${log.count} egg${log.count == 1 ? '' : 's'}',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Edit',
                  onPressed: () => context.push('/eggs/log', extra: log),
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }
}

class _MonthNavigation extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _MonthNavigation({
    required this.currentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        currentMonth.year == now.year && currentMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousMonth,
          ),
          Text(
            DateFormat.yMMMM().format(currentMonth),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isCurrentMonth ? null : onNextMonth,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final Map<DateTime, int> dailyCounts;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.currentMonth,
    required this.dailyCounts,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // First day of month and total days
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: daysOfWeek
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 42, // 6 weeks max
            itemBuilder: (context, index) {
              final dayOffset = index - firstWeekday;

              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = dayOffset + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final count = dailyCounts[date] ?? 0;
              final isSelected = selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day;
              final isToday = _isToday(date);
              final isFuture = date.isAfter(DateTime.now());

              return _DayCell(
                day: day,
                count: count,
                isSelected: isSelected,
                isToday: isToday,
                isFuture: isFuture,
                onTap: isFuture ? null : () => onDateSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int count;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Color coding based on count
    Color backgroundColor;
    Color textColor;

    if (isFuture) {
      backgroundColor = Colors.transparent;
      textColor = colorScheme.onSurface.withValues(alpha: 0.3);
    } else if (isSelected) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (count == 0) {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    } else if (count <= 2) {
      backgroundColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else if (count <= 5) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade900;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (!isFuture && count > 0)
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.onPrimary : textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailsInline extends ConsumerWidget {
  final DateTime date;
  final VoidCallback onLogDeleted;

  const _DayDetailsInline({
    required this.date,
    required this.onLogDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(eggLogsByDateProvider(date));

    return logsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Error: $error')),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.egg_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No eggs logged on ${DateFormat.MMMd().format(date)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/eggs/log', extra: date),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
          );
        }

        final totalCount = logs.fold<int>(0, (sum, log) => sum + log.count);

        return Column(
          children: [
            // Summary header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMEd().format(date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$totalCount egg${totalCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logs list (inline, not in a nested ListView)
            ...logs.map((log) => Dismissible(
                  key: Key(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Entry?'),
                            content: Text(
                                'Delete ${log.count} egg${log.count == 1 ? '' : 's'} entry?'),
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
                        ) ??
                        false;
                  },
                  onDismissed: (direction) async {
                    await ref.read(eggLogsProvider.notifier).deleteEggLog(log.id);
                    onLogDeleted();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Entry deleted')),
                      );
                    }
                  },
                  child: _EggLogTile(
                    log: log,
                    onEdit: () => context.push('/eggs/log', extra: log),
                  ),
                )),
            // Add some bottom padding for FAB clearance
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _EggLogTile extends ConsumerWidget {
  final EggLog log;
  final VoidCallback onEdit;

  const _EggLogTile({
    required this.log,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flockAsync = ref.watch(flockByIdProvider(log.flockId));

    final subtitleParts = [
      if (log.size != null) log.size!.displayName,
      if (log.quality != null) log.quality!.displayName,
      if (log.notes != null) log.notes,
    ];

    return ListTile(
      onTap: onEdit,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${log.count}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: flockAsync.when(
        loading: () => const Text('Loading...'),
        error: (error, stack) => const Text('Unknown Flock'),
        data: (flock) => Text(flock?.name ?? 'Unknown Flock'),
      ),
      subtitle: subtitleParts.isNotEmpty ? Text(subtitleParts.join(' • ')) : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
