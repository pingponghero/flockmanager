import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/egg_log.dart';
import '../../models/enums.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/egg_provider.dart';
import '../../providers/flock_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/achievement_celebration_dialog.dart';

class EggLogScreen extends ConsumerStatefulWidget {
  /// If editing, pass the existing EggLog
  /// If creating with a specific date, pass the DateTime
  final Object? initialData;

  const EggLogScreen({super.key, this.initialData});

  @override
  ConsumerState<EggLogScreen> createState() => _EggLogScreenState();
}

class _EggLogScreenState extends ConsumerState<EggLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  String? _selectedFlockId;
  String? _selectedBirdId;
  EggSize? _selectedSize = EggSize.medium;
  EggQuality? _selectedQuality = EggQuality.normal;
  bool _isLoading = false;

  EggLog? _editingLog;

  @override
  void initState() {
    super.initState();

    if (widget.initialData is EggLog) {
      // Editing existing log
      _editingLog = widget.initialData as EggLog;
      _countController.text = _editingLog!.count.toString();
      _notesController.text = _editingLog!.notes ?? '';
      _date = _editingLog!.date;
      _selectedFlockId = _editingLog!.flockId;
      _selectedBirdId = _editingLog!.birdId;
      _selectedSize = _editingLog!.size;
      _selectedQuality = _editingLog!.quality;
    } else if (widget.initialData is DateTime) {
      // Creating with specific date
      _date = widget.initialData as DateTime;
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get isEditing => _editingLog != null;

  @override
  Widget build(BuildContext context) {
    final flocksAsync = ref.watch(flocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Egg Entry' : 'Log Eggs'),
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
            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMEd().format(_date)),
              onTap: _selectDate,
            ),
            const Divider(),

            // Flock selector
            flocksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (flocks) {
                if (flocks.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: pagePadding(context),
                      child: Column(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(height: 8),
                          const Text('No flocks available'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/settings/flocks/new'),
                            child: const Text('Create a Flock'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Set default flock if not set
                if (_selectedFlockId == null && flocks.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final selectedFlock = ref.read(selectedFlockIdProvider);
                    setState(() {
                      _selectedFlockId = selectedFlock ?? flocks.first.id;
                    });
                  });
                }

                return DropdownButtonFormField<String>(
                  value: _selectedFlockId,
                  decoration: const InputDecoration(
                    labelText: 'Flock *',
                    prefixIcon: Icon(Icons.grid_view),
                  ),
                  items: flocks.map((flock) {
                    return DropdownMenuItem(
                      value: flock.id,
                      child: Text(flock.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFlockId = value;
                      _selectedBirdId = null; // Reset bird when flock changes
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a flock';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Bird selector (optional)
            if (_selectedFlockId != null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final birdsAsync = ref.watch(
                    activeBirdsByFlockProvider(_selectedFlockId!),
                  );

                  return birdsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (birds) {
                      if (birds.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return DropdownButtonFormField<String?>(
                        value: _selectedBirdId,
                        decoration: InputDecoration(
                          labelText: 'Bird (optional)',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/icons/cute_hen.png',
                              width: 24,
                              height: 24,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Not specified'),
                          ),
                          ...birds.map((bird) {
                            return DropdownMenuItem(
                              value: bird.id,
                              child: Text(bird.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedBirdId = value);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Count field
            TextFormField(
              controller: _countController,
              decoration: const InputDecoration(
                labelText: 'Number of Eggs *',
                prefixIcon: Icon(Icons.egg),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a count';
                }
                final count = int.tryParse(value);
                if (count == null || count < 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Size chips
            Text('Size', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EggSize.values.map((size) {
                final isSelected = _selectedSize == size;
                return ChoiceChip(
                  label: Text(
                    size.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSize = selected ? size : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quality chips
            Text('Quality', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: EggQuality.values.map((quality) {
                final isSelected = _selectedQuality == quality;
                return ChoiceChip(
                  label: Text(
                    quality.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      _selectedQuality = selected ? quality : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Delete button (when editing)
            if (isEditing)
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Entry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flock')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final count = int.parse(_countController.text);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (isEditing) {
        final updatedLog = _editingLog!.copyWith(
          date: _date,
          flockId: _selectedFlockId!,
          birdId: _selectedBirdId,
          count: count,
          size: _selectedSize,
          quality: _selectedQuality,
          notes: notes,
        );
        await ref.read(eggLogsProvider.notifier).updateEggLog(updatedLog);
      } else {
        final newLog = EggLog.create(
          date: _date,
          flockId: _selectedFlockId!,
          birdId: _selectedBirdId,
          count: count,
          size: _selectedSize,
          quality: _selectedQuality,
          notes: notes,
        );
        await ref.read(eggLogsProvider.notifier).addEggLog(newLog);
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Entry updated' : 'Entry saved'),
          ),
        );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    if (_editingLog == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
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

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await ref.read(eggLogsProvider.notifier).deleteEggLog(_editingLog!.id);

        HapticFeedback.mediumImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry deleted')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
