import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/medication_log.dart';
import '../../data/medications.dart';
import '../../providers/medication_provider.dart';
import '../../providers/trial_provider.dart';
import '../../utils/edge_insets.dart';
import '../../widgets/trial_banner.dart' show showTrialExpiredDialog;
import 'widgets/add_medication_sheet.dart';
import 'widgets/legal_status_badge.dart';

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
      builder: (context) => const AddMedicationSheet(),
    );
  }
}

class _ActiveMedicationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeMedicationsProvider);
    final withdrawalsAsync = ref.watch(activeWithdrawalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        ref.invalidate(activeMedicationsProvider);
        ref.invalidate(activeWithdrawalsProvider);
        await ref.read(activeMedicationsProvider.future);
      },
      child: ListView(
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
    ),
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

    return RefreshIndicator(
      onRefresh: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        ref.invalidate(medicationsProvider);
        await ref.read(medicationsProvider.future);
      },
      child: medicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (medications) {
        if (medications.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Column(
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
              ),
            ],
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
    ),
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
            LegalStatusBadge(legalStatus: medication.legalStatus),
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

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
