import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/import_result.dart';

/// Dialog to show warning before importing data.
class ImportWarningDialog extends StatelessWidget {
  const ImportWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber,
        color: Colors.orange,
        size: 48,
      ),
      title: const Text('Replace All Data?'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete all existing data and replace it with the imported backup.',
          ),
          SizedBox(height: 16),
          Text(
            '\u2022 All current flocks, birds, and logs will be deleted\n'
            '\u2022 All photos will be replaced\n'
            '\u2022 This cannot be undone',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Choose Backup File...'),
        ),
      ],
    );
  }
}

/// Dialog to confirm import with counts from the backup.
class ImportConfirmationDialog extends StatelessWidget {
  final ImportPreview preview;

  const ImportConfirmationDialog({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd().add_jm();

    return AlertDialog(
      icon: const Icon(
        Icons.upload_file,
        color: Colors.blue,
        size: 48,
      ),
      title: const Text('Import Backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info
          Text(
            'From: ${preview.filename}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (preview.exportDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Exported: ${dateFormat.format(preview.exportDate!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

          const SizedBox(height: 16),

          // Legacy warning
          if (preview.isLegacy) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is a legacy backup without metadata. Counts may not be available.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Counts
          if (!preview.isLegacy) ...[
            Text(
              'Contains:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _CountItem(
              icon: Icons.grid_view,
              label: 'flocks',
              count: preview.flocksCount,
            ),
            _CountItem(
              icon: Icons.pets,
              label: 'birds',
              count: preview.birdsCount,
              suffix: preview.photosCount > 0
                  ? '(${preview.photosCount} with photos)'
                  : null,
            ),
            if (preview.eggLogsCount > 0)
              _CountItem(
                icon: Icons.egg,
                label: 'egg logs',
                count: preview.eggLogsCount,
              ),
            if (preview.expensesCount > 0)
              _CountItem(
                icon: Icons.attach_money,
                label: 'expenses',
                count: preview.expensesCount,
              ),
            if (preview.incomeCount > 0)
              _CountItem(
                icon: Icons.trending_up,
                label: 'income records',
                count: preview.incomeCount,
              ),
            if (preview.medicationLogsCount > 0)
              _CountItem(
                icon: Icons.medication,
                label: 'medication logs',
                count: preview.medicationLogsCount,
              ),
            if (preview.healthNotesCount > 0)
              _CountItem(
                icon: Icons.medical_services,
                label: 'health notes',
                count: preview.healthNotesCount,
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _CountItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String? suffix;

  const _CountItem({
    required this.icon,
    required this.label,
    required this.count,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Text(
              suffix!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog to show import progress.
class ImportProgressDialog extends StatelessWidget {
  final double progress;

  const ImportProgressDialog({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Importing data...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Dialog to show import result with warnings.
class ImportResultDialog extends StatelessWidget {
  final ImportResult result;

  const ImportResultDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        result.success ? Icons.check_circle : Icons.error,
        color: result.success ? Colors.green : Colors.red,
        size: 48,
      ),
      title: Text(result.success ? 'Import Complete' : 'Import Failed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.summaryMessage),
          if (result.hasWarnings) ...[
            const SizedBox(height: 16),
            Text(
              'Warnings:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.warnings
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    w,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}