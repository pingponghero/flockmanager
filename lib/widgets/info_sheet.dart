import 'package:flutter/material.dart';

/// One titled block in an [InfoSheet]: an icon, a heading, a sentence or
/// two, and optionally a worked formula with the user's own numbers.
class InfoSection {
  final IconData icon;
  final String title;
  final String body;

  /// Shown in a tinted box under [body], e.g. "898 eggs ÷ 1,630 hen-days = 55%".
  final String? formula;

  const InfoSection({
    required this.icon,
    required this.title,
    required this.body,
    this.formula,
  });
}

/// A draggable bottom sheet for the "how is this worked out" detail behind a
/// chart or number, so the screens themselves stay light. Same look as the
/// Stats forecast card's "How this forecast works" sheet.
class InfoSheet {
  InfoSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<InfoSection> sections,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Above the tab bar: from a tab's own navigator the sheet would slide
      // under it and hide its last lines.
      useRootNavigator: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, controller) {
          final theme = Theme.of(context);
          return ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              32 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final s in sections) ...[
                _Section(section: s),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final InfoSection section;
  const _Section({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(section.icon, size: 22, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (section.formula != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section.formula!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A quiet one-line notice that opens an [InfoSheet] (or anything) on tap.
class InfoNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const InfoNotice({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
              ),
              Icon(Icons.chevron_right, size: 20, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
