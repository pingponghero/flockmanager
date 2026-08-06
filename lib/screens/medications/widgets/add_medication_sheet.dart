import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/medications.dart';
import '../../../models/medication_log.dart';
import '../../../providers/achievements_provider.dart';
import '../../../providers/bird_provider.dart';
import '../../../providers/flock_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/achievement_celebration_dialog.dart';
import 'legal_status_badge.dart';

class AddMedicationSheet extends ConsumerStatefulWidget {
  /// When set, the sheet edits this medication log instead of creating one.
  final MedicationLog? existing;

  const AddMedicationSheet({super.key, this.existing});

  @override
  ConsumerState<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  Medication? _selectedMedication;
  String? _selectedFlockId;
  String? _selectedBirdId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _withdrawalDays = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.medicationName;
      _dosageController.text = existing.dosage ?? '';
      _notesController.text = existing.notes ?? '';
      _selectedFlockId = existing.flockId;
      _selectedBirdId = existing.birdId;
      _startDate = existing.startDate;
      _endDate = existing.endDate;
      _withdrawalDays = existing.withdrawalDays ?? 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flocksAsync = ref.watch(flocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete medication',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteMedication,
            ),
          TextButton(onPressed: _saveMedication, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medication selector with autocomplete
            Autocomplete<Medication>(
              displayStringForOption: (med) => med.name,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  // Filter out banned medications from suggestions
                  return medications.where((m) => !m.isBannedOrRestricted);
                }
                return searchMedications(
                  textEditingValue.text,
                ).where((m) => !m.isBannedOrRestricted);
              },
              onSelected: (med) {
                setState(() {
                  _selectedMedication = med;
                  _nameController.text = med.name;
                  _withdrawalDays =
                      med.withdrawalDaysEgg ?? 14; // Default to 14 if unknown
                  _dosageController.text = med.dosageNotes;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                // Sync controllers
                if (_nameController.text.isNotEmpty &&
                    controller.text.isEmpty) {
                  controller.text = _nameController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Medication *',
                    hintText: 'Search or enter medication name',
                  ),
                  onChanged: (value) {
                    _nameController.text = value;
                    // Check if medication is banned
                    final selectedMed = medications
                        .where(
                          (m) => m.name.toLowerCase() == value.toLowerCase(),
                        )
                        .firstOrNull;
                    if (selectedMed?.isBannedOrRestricted == true) {
                      showAppSnackBar(
                        context,
                        '⚠️ ${selectedMed!.name} is ${selectedMed.legalStatusDisplay}. '
                        'Do not use in food-producing poultry.',
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      );
                    }
                  },
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: MediaQuery.of(context).size.width - 64,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final med = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(med.name),
                            subtitle: Row(
                              children: [
                                Text(med.genericName),
                                const SizedBox(width: 8),
                                LegalStatusBadge(legalStatus: med.legalStatus),
                              ],
                            ),
                            trailing: _buildWithdrawalBadge(med),
                            onTap: () => onSelected(med),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // Warning if selected medication has issues
            if (_selectedMedication != null &&
                _selectedMedication!.legalWarning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedMedication!.legalWarning!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            flocksAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (flocks) {
                if (flocks.isEmpty) {
                  return const Text('Create a flock first');
                }
                if (_selectedFlockId == null && flocks.length == 1) {
                  _selectedFlockId = flocks.first.id;
                }
                return DropdownMenu<String>(
                  initialSelection: _selectedFlockId,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Flock'),
                  dropdownMenuEntries: flocks
                      .map((f) => DropdownMenuEntry(value: f.id, label: f.name))
                      .toList(),
                  onSelected: (v) => setState(() {
                    _selectedFlockId = v;
                    _selectedBirdId = null;
                  }),
                );
              },
            ),
            const SizedBox(height: 16),

            // Bird selector (optional - for individual bird treatment)
            if (_selectedFlockId != null)
              Consumer(
                builder: (context, ref, child) {
                  final birdsAsync = ref.watch(
                    activeBirdsByFlockProvider(_selectedFlockId!),
                  );
                  return birdsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (birds) {
                      if (birds.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownMenu<String?>(
                            initialSelection: _selectedBirdId,
                            expandedInsets: EdgeInsets.zero,
                            label: const Text('Bird (optional)'),
                            dropdownMenuEntries: [
                              const DropdownMenuEntry(
                                value: null,
                                label: 'Entire flock',
                              ),
                              ...birds.map(
                                (b) => DropdownMenuEntry(
                                  value: b.id,
                                  label: b.name,
                                ),
                              ),
                            ],
                            onSelected: (v) =>
                                setState(() => _selectedBirdId = v),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),

            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (optional)',
                hintText: 'e.g., 2 tsp per gallon',
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End Date'),
                    subtitle: Text(
                      _endDate != null
                          ? DateFormat.yMMMd().format(_endDate!)
                          : 'Ongoing',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      setState(() => _endDate = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Egg Withdrawal: $_withdrawalDays days',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_selectedMedication?.withdrawalDaysEgg == null)
                        Text(
                          'No established withdrawal - using conservative estimate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              value: _withdrawalDays.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '$_withdrawalDays days',
              onChanged: (v) => setState(() => _withdrawalDays = v.round()),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildWithdrawalBadge(Medication med) {
    if (med.withdrawalDaysEgg == null) {
      return Text(
        '?',
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (med.withdrawalDaysEgg! > 0) {
      return Text(
        '${med.withdrawalDaysEgg}d',
        style: TextStyle(
          color: Colors.amber.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return null;
  }

  Future<void> _deleteMedication() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Delete the record for ${existing.medicationName}?'),
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

    await ref.read(medicationsProvider.notifier).deleteMedication(existing.id);
    await ref
        .read(notificationSettingsProvider.notifier)
        .onMedicationDeleted(existing.id);

    if (mounted) {
      Navigator.pop(context);
      showAppSnackBar(context, '${existing.medicationName} deleted');
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFlockId == null) {
      showAppSnackBar(context, 'Please select a flock');
      return;
    }

    final medication = _isEditing
        ? widget.existing!.copyWith(
            flockId: _selectedFlockId!,
            birdId: _selectedBirdId,
            medicationName: _nameController.text,
            dosage: _dosageController.text.isEmpty
                ? null
                : _dosageController.text,
            startDate: _startDate,
            endDate: _endDate,
            withdrawalDays: _withdrawalDays,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          )
        : MedicationLog.create(
            flockId: _selectedFlockId!,
            birdId: _selectedBirdId,
            medicationName: _nameController.text,
            dosage: _dosageController.text.isEmpty
                ? null
                : _dosageController.text,
            startDate: _startDate,
            endDate: _endDate,
            withdrawalDays: _withdrawalDays,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

    try {
      if (_isEditing) {
        await ref
            .read(medicationsProvider.notifier)
            .updateMedication(medication);
      } else {
        await ref.read(medicationsProvider.notifier).addMedication(medication);
      }

      // (Re)schedule end-of-treatment / withdrawal notifications
      await ref
          .read(notificationSettingsProvider.notifier)
          .onMedicationSaved(medication);

      if (mounted) {
        // Check for new achievements
        final newAchievements = await checkAndCelebrateAchievements(
          ref,
          context,
        );

        if (mounted) {
          Navigator.pop(context);
          showAppSnackBar(
            context,
            _isEditing
                ? '${medication.medicationName} updated'
                : '${medication.medicationName} logged',
          );

          if (newAchievements.isNotEmpty) {
            await AchievementCelebrationDialog.showMultiple(
              context,
              newAchievements,
            );
            await markAchievementsAsShown(newAchievements);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: $e');
      }
    }
  }
}
