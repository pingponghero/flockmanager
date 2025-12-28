import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/medication_log.dart';
import '../../data/medications.dart';
import '../../providers/medication_provider.dart';
import '../../providers/flock_provider.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Medications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Reference'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveMedicationsTab(),
          _HistoryTab(),
          _ReferenceTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddMedicationSheet(),
    );
  }
}

class _ActiveMedicationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeMedicationsProvider);
    final withdrawalsAsync = ref.watch(activeWithdrawalsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Withdrawal warning
        withdrawalsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (withdrawals) {
            if (withdrawals.isEmpty) return const SizedBox.shrink();
            return Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdrawal Period Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            '${withdrawals.length} medication(s) require egg withdrawal',
                            style: TextStyle(color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        Text(
          'Current Treatments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        activeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (medications) {
            if (medications.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active treatments',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: medications.map((med) => _MedicationCard(medication: med)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final MedicationLog medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasWithdrawal = medication.isWithdrawalActive;
    final daysRemaining = medication.withdrawalDaysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showMedicationDetails(context, medication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medication.medicationName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (hasWithdrawal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.egg_outlined, size: 14, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            '$daysRemaining days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${DateFormat.yMMMd().format(medication.startDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (medication.endDate != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '- ${DateFormat.yMMMd().format(medication.endDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (medication.dosage != null) ...[
                const SizedBox(height: 4),
                Text(
                  medication.dosage!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, MedicationLog medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.medicationName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Started', DateFormat.yMMMd().format(medication.startDate)),
            if (medication.endDate != null)
              _detailRow('Ended', DateFormat.yMMMd().format(medication.endDate!)),
            if (medication.dosage != null)
              _detailRow('Dosage', medication.dosage!),
            if (medication.withdrawalDays != null && medication.withdrawalDays! > 0)
              _detailRow('Withdrawal', '${medication.withdrawalDays} days'),
            if (medication.notes != null)
              _detailRow('Notes', medication.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsProvider);

    return medicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (medications) {
        if (medications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No medication history',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final med = medications[index];
            return Dismissible(
              key: Key(med.id),
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
                    title: const Text('Delete Record'),
                    content: const Text('Delete this medication record?'),
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
                ref.read(medicationsProvider.notifier).deleteMedication(med.id);
              },
              child: _MedicationCard(medication: med),
            );
          },
        );
      },
    );
  }
}

class _ReferenceTab extends StatefulWidget {
  @override
  State<_ReferenceTab> createState() => _ReferenceTabState();
}

class _ReferenceTabState extends State<_ReferenceTab> {
  String _searchQuery = '';
  MedicationCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMedications();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search medications...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              ...MedicationCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_categoryLabel(cat)),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(
                        () => _selectedCategory = _selectedCategory == cat ? null : cat,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final med = filtered[index];
              return _MedicationReferenceCard(medication: med);
            },
          ),
        ),
      ],
    );
  }

  List<Medication> _getFilteredMedications() {
    var result = searchMedications(_searchQuery);
    if (_selectedCategory != null) {
      result = result.where((m) => m.category == _selectedCategory).toList();
    }
    return result;
  }

  String _categoryLabel(MedicationCategory cat) {
    switch (cat) {
      case MedicationCategory.antibiotic:
        return 'Antibiotics';
      case MedicationCategory.antiparasitic:
        return 'Dewormers';
      case MedicationCategory.coccidiostat:
        return 'Coccidiosis';
      case MedicationCategory.antifungal:
        return 'Antifungal';
      case MedicationCategory.vitamin:
        return 'Vitamins';
      case MedicationCategory.electrolyte:
        return 'Electrolytes';
      case MedicationCategory.naturalRemedy:
        return 'Natural';
      case MedicationCategory.other:
        return 'Other';
    }
  }
}

class _MedicationReferenceCard extends StatelessWidget {
  final Medication medication;

  const _MedicationReferenceCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(medication.genericName),
        trailing: medication.hasWithdrawal
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${medication.withdrawalDaysEgg}d',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (medication.treatsConditions.isNotEmpty) ...[
                  Text(
                    'Treats:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: medication.treatsConditions.map((c) => Chip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Dosage:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(medication.dosageNotes),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip(
                      context,
                      'Egg: ${medication.withdrawalDaysEgg}d',
                      medication.withdrawalDaysEgg > 0 ? Colors.amber : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      context,
                      'Meat: ${medication.withdrawalDaysMeat}d',
                      medication.withdrawalDaysMeat > 0 ? Colors.amber : Colors.green,
                    ),
                    if (medication.prescriptionRequired) ...[
                      const SizedBox(width: 8),
                      _infoChip(context, 'Rx', Colors.blue),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color.shade700),
      ),
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}

class _AddMedicationSheet extends ConsumerStatefulWidget {
  const _AddMedicationSheet();

  @override
  ConsumerState<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends ConsumerState<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _selectedFlockId;
  int _withdrawalDays = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectMedication(Medication med) {
    setState(() {
      _nameController.text = med.name;
      _withdrawalDays = med.withdrawalDaysEgg;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flock')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final log = MedicationLog.create(
        flockId: _selectedFlockId!,
        medicationName: _nameController.text,
        dosage: _dosageController.text.isEmpty ? null : _dosageController.text,
        startDate: _startDate,
        endDate: _endDate,
        withdrawalDays: _withdrawalDays > 0 ? _withdrawalDays : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref.read(medicationsProvider.notifier).addMedication(log);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication logged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Log Medication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
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
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Quick select from reference
                      Text(
                        'Quick Select',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: medications.take(8).map((med) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(med.name),
                                  onPressed: () => _selectMedication(med),
                                ),
                              )).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
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
                          return DropdownButtonFormField<String>(
                            value: _selectedFlockId,
                            decoration: const InputDecoration(
                              labelText: 'Flock',
                            ),
                            items: flocks.map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text(f.name),
                                )).toList(),
                            onChanged: (v) => setState(() => _selectedFlockId = v),
                            validator: (v) => v == null ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

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
                              subtitle: Text(_endDate != null
                                  ? DateFormat.yMMMd().format(_endDate!)
                                  : 'Ongoing'),
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
                            child: Text(
                              'Egg Withdrawal: $_withdrawalDays days',
                              style: Theme.of(context).textTheme.titleSmall,
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
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 2,
                      ),
                    ],
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
