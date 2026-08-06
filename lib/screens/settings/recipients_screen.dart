import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipient.dart';
import '../../providers/egg_provider.dart' show currencySymbolProvider;
import '../../providers/recipient_provider.dart';
import '../../repositories/finance_repository.dart' show RecipientStats;
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/recipient_selector.dart' show showAddRecipientDialog;

/// Manages the directory of sale/gift recipients with per-recipient stats.
class RecipientsScreen extends ConsumerWidget {
  const RecipientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);
    final stats = ref.watch(recipientStatsProvider).value ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Recipients')),
      body: recipientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (recipients) {
          if (recipients.isEmpty) {
            return Center(
              child: Padding(
                padding: pagePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recipients yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add the people you sell or gift eggs to, '
                      'then pick them when recording a sale or gift.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: pagePadding(context),
            itemCount: recipients.length,
            itemBuilder: (context, index) {
              final recipient = recipients[index];
              return _RecipientCard(
                recipient: recipient,
                stats: stats[recipient.id],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddRecipientDialog(context, ref),
        tooltip: 'Add Recipient',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _RecipientCard extends ConsumerWidget {
  final Recipient recipient;
  final RecipientStats? stats;

  const _RecipientCard({required this.recipient, this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = ref.watch(currencySymbolProvider);
    final s = stats;

    final parts = <String>[];
    if (s != null) {
      if (s.eggsSold > 0) {
        parts.add('${s.eggsSold} eggs sold ($cs${s.totalIncome.toStringAsFixed(2)})');
      } else if (s.totalIncome > 0) {
        parts.add('$cs${s.totalIncome.toStringAsFixed(2)} in sales');
      }
      if (s.eggsGifted > 0) parts.add('${s.eggsGifted} eggs gifted');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            recipient.name.isNotEmpty ? recipient.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(recipient.name),
        subtitle: Text(parts.isEmpty ? 'No sales or gifts yet' : parts.join(' · ')),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'rename') {
              _showRenameDialog(context, ref);
            } else if (action == 'delete') {
              _showDeleteDialog(context, ref);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: recipient.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Recipient'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(recipientsProvider.notifier)
                    .updateRecipient(recipient.copyWith(name: name));
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipient'),
        content: Text(
          'Delete "${recipient.name}"? Sales and gifts recorded for them '
          'are kept but will no longer be linked to a recipient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(recipientsProvider.notifier).deleteRecipient(recipient.id);
              Navigator.pop(context);
              showAppSnackBar(context, '${recipient.name} deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
