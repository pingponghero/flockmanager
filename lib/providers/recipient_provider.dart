import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipient.dart';
import '../repositories/finance_repository.dart';
import 'expense_provider.dart';

/// Async notifier for managing the recipient directory.
class RecipientsNotifier extends AsyncNotifier<List<Recipient>> {
  @override
  Future<List<Recipient>> build() async {
    final repository = ref.read(financeRepositoryProvider);
    return repository.getAllRecipients();
  }

  /// Add a recipient and return it (so forms can select it immediately).
  Future<Recipient> addRecipient(String name, {String? notes}) async {
    final repository = ref.read(financeRepositoryProvider);
    final recipient = Recipient.create(name: name.trim(), notes: notes);
    await repository.insertRecipient(recipient);
    ref.invalidateSelf();
    return recipient;
  }

  Future<void> updateRecipient(Recipient recipient) async {
    final repository = ref.read(financeRepositoryProvider);
    await repository.updateRecipient(recipient);
    ref.invalidateSelf();
    ref.invalidate(recipientStatsProvider);
  }

  /// Delete a recipient. Income records are kept but unlinked.
  Future<void> deleteRecipient(String id) async {
    final repository = ref.read(financeRepositoryProvider);
    await repository.deleteRecipient(id);
    ref.invalidateSelf();
    ref.invalidate(recipientStatsProvider);
    ref.invalidate(incomeProvider);
  }
}

/// Provider for all recipients, ordered by name.
final recipientsProvider =
    AsyncNotifierProvider<RecipientsNotifier, List<Recipient>>(
        RecipientsNotifier.new);

/// Provider for a single recipient by ID.
final recipientByIdProvider =
    FutureProvider.family<Recipient?, String>((ref, id) async {
  final recipients = await ref.watch(recipientsProvider.future);
  for (final r in recipients) {
    if (r.id == id) return r;
  }
  return null;
});

/// Aggregated per-recipient sale/gift statistics.
final recipientStatsProvider =
    FutureProvider<Map<String, RecipientStats>>((ref) async {
  // Recompute when income changes.
  await ref.watch(incomeProvider.future);
  final repository = ref.read(financeRepositoryProvider);
  return repository.getRecipientStats();
});
