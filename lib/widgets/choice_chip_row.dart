import 'package:flutter/material.dart';

/// A horizontally scrolling row of single-select [ChoiceChip]s (#62).
///
/// One tap to change, and every option is visible at a glance, which suits
/// short lists like time periods better than a dropdown. The selected chip
/// is scrolled into view on first build.
class ChoiceChipRow<T> extends StatefulWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const ChoiceChipRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<ChoiceChipRow<T>> createState() => _ChoiceChipRowState<T>();
}

class _ChoiceChipRowState<T> extends State<ChoiceChipRow<T>> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      child: Row(
        children: [
          for (final (i, value) in widget.values.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              key: value == widget.selected ? _selectedKey : null,
              label: Text(widget.labelOf(value)),
              selected: value == widget.selected,
              onSelected: (_) => widget.onSelected(value),
            ),
          ],
        ],
      ),
    );
  }
}
