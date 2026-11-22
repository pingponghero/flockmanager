import 'package:flutter/material.dart';

/// One option in a [FilterMenuChip].
class FilterMenuOption<T> {
  final T value;
  final String label;
  final Widget? icon;

  const FilterMenuOption({required this.value, required this.label, this.icon});
}

/// A compact chip that shows the current filter and opens a menu to change
/// it (#61).
///
/// When a value is selected the chip is highlighted and shows a ✕ that
/// clears the filter back to `null`, so active filters are always visible.
/// When nothing is selected it shows [anyLabel] with a dropdown arrow.
class FilterMenuChip<T> extends StatelessWidget {
  final T? value;
  final String anyLabel;
  final List<FilterMenuOption<T>> options;
  final ValueChanged<T?> onChanged;

  /// Tooltip / semantics label for the chip, e.g. "Sex".
  final String tooltip;

  const FilterMenuChip({
    super.key,
    required this.value,
    required this.anyLabel,
    required this.options,
    required this.onChanged,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.value == value).firstOrNull;
    final isFiltered = value != null && selected != null;

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: _check(value == null),
          onPressed: () => onChanged(null),
          child: Text(anyLabel),
        ),
        for (final option in options)
          MenuItemButton(
            leadingIcon: _check(option.value == value),
            trailingIcon: option.icon,
            onPressed: () => onChanged(option.value),
            child: Text(option.label),
          ),
      ],
      builder: (context, controller, _) {
        void toggle() =>
            controller.isOpen ? controller.close() : controller.open();

        return Tooltip(
          message: tooltip,
          child: InputChip(
            selected: isFiltered,
            showCheckmark: false,
            avatar: isFiltered ? selected.icon : null,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isFiltered ? selected.label : anyLabel),
                if (!isFiltered) const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
            onPressed: toggle,
            onDeleted: isFiltered ? () => onChanged(null) : null,
            deleteButtonTooltipMessage: 'Clear $tooltip filter',
          ),
        );
      },
    );
  }

  Widget _check(bool on) =>
      SizedBox(width: 18, child: on ? const Icon(Icons.check, size: 18) : null);
}
