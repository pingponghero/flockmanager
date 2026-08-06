import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/recipient_provider.dart';
import '../utils/snackbar_utils.dart';

/// Dropdown for picking a recipient from the directory, with an inline
/// "New recipient…" entry that creates one on the spot.
class RecipientSelector extends ConsumerWidget {
  final String? selectedRecipientId;
  final ValueChanged<String?> onChanged;

  const RecipientSelector({
    super.key,
    required this.selectedRecipientId,
    required this.onChanged,
  });

  /// Sentinel value for the "New recipient…" menu entry.
  static const _newRecipient = '__new__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);

    return recipientsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recipients) {
        return DropdownMenu<String?>(
          key: ValueKey(selectedRecipientId),
          initialSelection: selectedRecipientId,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Recipient (optional)'),
          leadingIcon: const Icon(Icons.person_outline),
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'None'),
            ...recipients.map((r) => DropdownMenuEntry(
                  value: r.id,
                  label: r.name,
                )),
            const DropdownMenuEntry(
              value: _newRecipient,
              label: 'New recipient…',
              leadingIcon: Icon(Icons.add, size: 18),
            ),
          ],
          onSelected: (value) async {
            if (value == _newRecipient) {
              final created = await showAddRecipientDialog(context, ref);
              onChanged(created);
            } else {
              onChanged(value);
            }
          },
        );
      },
    );
  }
}

/// Prompts for a recipient name, creates it, and returns the new ID
/// (null if cancelled).
Future<String?> showAddRecipientDialog(
    BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();

  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Recipient'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g., Neighbor Anna, Farmers Market',
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    ),
  );

  if (name == null || name.isEmpty) return null;

  try {
    final recipient =
        await ref.read(recipientsProvider.notifier).addRecipient(name);
    return recipient.id;
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Could not add recipient: $e');
    }
    return null;
  }
}
