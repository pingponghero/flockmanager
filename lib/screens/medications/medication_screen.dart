import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/medication_log.dart';
import '../../data/medications.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/bird_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/flock_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/trial_banner.dart' show showTrialExpiredDialog;
import '../../widgets/achievement_celebration_dialog.dart';

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
      floatingActionButton: Builder(
        builder: (context) {
          final canEdit = ref.watch(canEditProvider);
          return FloatingActionButton(
            onPressed: canEdit
                ? () => _showAddMedicationDialog(context)
                : () => showTrialExpiredDialog(context, ref),
            tooltip: 'Add Medication',
            child: const Icon(Icons.add),
          );
        },
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
      padding: pagePadding(context),
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
          padding: pagePadding(context),
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
        // Disclaimer
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reference only. Always consult a veterinarian and follow product label instructions. '
                      'Withdrawal times can vary by dosage and regulations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search medications...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MedicationCategory?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<MedicationCategory?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._getSortedCategories().map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(_categoryLabel(cat)),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            // Key changes when category changes, resetting expansion states
            key: ValueKey(_selectedCategory),
            padding: const EdgeInsets.symmetric(horizontal: 16).withSystemNavigation(context),
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
    var result = searchMedications(_searchQuery).toList();
    if (_selectedCategory != null) {
      result = result.where((m) => m.category == _selectedCategory).toList();
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<MedicationCategory> _getSortedCategories() {
    final categories = MedicationCategory.values
        .where((c) => c != MedicationCategory.other)
        .toList();
    categories.sort((a, b) => _categoryLabel(a).compareTo(_categoryLabel(b)));
    categories.add(MedicationCategory.other); // Other always last
    return categories;
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
    final isBanned = medication.isBannedOrRestricted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isBanned ? Colors.red.shade50 : null,
      child: ExpansionTile(
        leading: isBanned
            ? Icon(Icons.block, color: Colors.red.shade700, size: 20)
            : null,
        title: Text(
          medication.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBanned ? Colors.red.shade900 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medication.genericName),
            const SizedBox(height: 4),
            _LegalStatusBadge(legalStatus: medication.legalStatus),
          ],
        ),
        trailing: _buildWithdrawalBadge(context),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legal warning banner for banned/restricted medications
                if (medication.showLegalWarning) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            medication.legalWarning ??
                                (medication.legalStatus == LegalStatus.bannedInUs
                                    ? 'BANNED for use in poultry in the United States.'
                                    : 'Not permitted for use in food-producing animals.'),
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Text(
                  medication.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Treats conditions (only show if not banned)
                if (medication.treatsConditions.isNotEmpty && !isBanned) ...[
                  Text(
                    'Treats:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: medication.treatsConditions.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Dosage (only show if not banned)
                if (!isBanned) ...[
                  Text(
                    'Dosage:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(medication.dosageNotes),
                  const SizedBox(height: 12),
                ],

                // Withdrawal info
                Text(
                  'Withdrawal Periods:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _withdrawalInfoChip(
                      context,
                      'Egg: ${medication.withdrawalEggDisplay}',
                      _getWithdrawalColor(medication.withdrawalDaysEgg, medication),
                    ),
                    const SizedBox(width: 8),
                    _withdrawalInfoChip(
                      context,
                      'Meat: ${medication.withdrawalMeatDisplay}',
                      _getWithdrawalColor(medication.withdrawalDaysMeat, medication),
                    ),
                  ],
                ),

                // Withdrawal note if present
                if (medication.withdrawalNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            medication.withdrawalNote!,
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

                const SizedBox(height: 12),

                // Legal status row
                Row(
                  children: [
                    _infoChip(
                      context,
                      medication.legalStatusDisplay,
                      _getLegalStatusColor(medication.legalStatus),
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      context,
                      medication.categoryDisplay,
                      Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildWithdrawalBadge(BuildContext context) {
    if (medication.isBannedOrRestricted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'BANNED',
          style: TextStyle(
            fontSize: 10,
            color: Colors.red.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (medication.withdrawalDaysEgg == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (medication.withdrawalDaysEgg! > 0) {
      return Container(
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
      );
    }

    return null;
  }

  Color _getWithdrawalColor(int? days, Medication med) {
    if (med.isBannedOrRestricted) return Colors.red;
    if (days == null) return Colors.orange;
    if (days > 0) return Colors.amber;
    return Colors.green;
  }

  Color _getLegalStatusColor(LegalStatus status) {
    switch (status) {
      case LegalStatus.fdaApproved:
        return Colors.green;
      case LegalStatus.offLabel:
        return Colors.blue;
      case LegalStatus.prescriptionRequired:
        return Colors.purple;
      case LegalStatus.bannedInUs:
      case LegalStatus.notForFoodAnimals:
        return Colors.red;
    }
  }

  Widget _withdrawalInfoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.shade700,
        ),
      ),
    );
  }
}

/// Badge showing the legal status of a medication
class _LegalStatusBadge extends StatelessWidget {
  final LegalStatus legalStatus;

  const _LegalStatusBadge({required this.legalStatus});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (legalStatus) {
      case LegalStatus.fdaApproved:
        return 'FDA Approved';
      case LegalStatus.offLabel:
        return 'Off-Label';
      case LegalStatus.prescriptionRequired:
        return 'Rx Required';
      case LegalStatus.bannedInUs:
        return 'BANNED';
      case LegalStatus.notForFoodAnimals:
        return 'NOT FOR FOOD';
    }
  }

  (Color, IconData) _getStatusStyle() {
    switch (legalStatus) {
      case LegalStatus.fdaApproved:
        return (Colors.green.shade700, Icons.check_circle_outline);
      case LegalStatus.offLabel:
        return (Colors.blue.shade700, Icons.info_outline);
      case LegalStatus.prescriptionRequired:
        return (Colors.purple.shade700, Icons.medical_services_outlined);
      case LegalStatus.bannedInUs:
        return (Colors.red.shade700, Icons.block);
      case LegalStatus.notForFoodAnimals:
        return (Colors.red.shade700, Icons.dangerous_outlined);
    }
  }
}

// === ADD MEDICATION SHEET ===

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

  Medication? _selectedMedication;
  String? _selectedFlockId;
  String? _selectedBirdId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _withdrawalDays = 0;

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

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Add Medication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveMedication,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: ListView(
                  controller: scrollController,
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
                        return searchMedications(textEditingValue.text)
                            .where((m) => !m.isBannedOrRestricted);
                      },
                      onSelected: (med) {
                        setState(() {
                          _selectedMedication = med;
                          _nameController.text = med.name;
                          _withdrawalDays = med.withdrawalDaysEgg ?? 14; // Default to 14 if unknown
                          _dosageController.text = med.dosageNotes;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        // Sync controllers
                        if (_nameController.text.isNotEmpty && controller.text.isEmpty) {
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
                            final selectedMed = medications.where(
                                    (m) => m.name.toLowerCase() == value.toLowerCase()
                            ).firstOrNull;
                            if (selectedMed?.isBannedOrRestricted == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '⚠️ ${selectedMed!.name} is ${selectedMed.legalStatusDisplay}. '
                                        'Do not use in food-producing poultry.',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
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
                                        _LegalStatusBadge(legalStatus: med.legalStatus),
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
                    if (_selectedMedication != null && _selectedMedication!.legalWarning != null) ...[
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
                            Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 20),
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
                        return DropdownButtonFormField<String>(
                          value: _selectedFlockId,
                          decoration: const InputDecoration(
                            labelText: 'Flock',
                          ),
                          items: flocks.map((f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.name),
                          )).toList(),
                          onChanged: (v) => setState(() {
                            _selectedFlockId = v;
                            _selectedBirdId = null; // Reset bird when flock changes
                          }),
                          validator: (v) => v == null ? 'Required' : null,
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
                                  DropdownButtonFormField<String?>(
                                    value: _selectedBirdId,
                                    decoration: const InputDecoration(
                                      labelText: 'Bird (optional)',
                                      hintText: 'Entire flock if not selected',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Entire flock'),
                                      ),
                                      ...birds.map((b) => DropdownMenuItem(
                                        value: b.id,
                                        child: Text(b.name),
                                      )),
                                    ],
                                    onChanged: (v) => setState(() => _selectedBirdId = v),
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
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flock')),
      );
      return;
    }

    final medication = MedicationLog(
      id: '', // Will be generated by repository
      flockId: _selectedFlockId!,
      birdId: _selectedBirdId,
      medicationName: _nameController.text,
      dosage: _dosageController.text.isEmpty ? null : _dosageController.text,
      startDate: _startDate,
      endDate: _endDate,
      withdrawalDays: _withdrawalDays,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(medicationsProvider.notifier).addMedication(medication);

      if (mounted) {
        // Check for new achievements
        final newAchievements = await checkAndCelebrateAchievements(ref, context);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medication.medicationName} logged'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (newAchievements.isNotEmpty) {
            await AchievementCelebrationDialog.showMultiple(context, newAchievements);
            await markAchievementsAsShown(newAchievements);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
