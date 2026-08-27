import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/flock.dart';
import '../providers/flock_provider.dart';

/// A dropdown for selecting a flock, with icons and colors.
///
/// Always shown when at least one flock exists — hiding it for single-flock
/// keepers left them with no visible route to adding a second one (#15).
class FlockDropdown extends ConsumerStatefulWidget {
  final String? selectedFlockId;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool showAllOption;

  const FlockDropdown({
    super.key,
    required this.selectedFlockId,
    required this.onChanged,
    this.label = 'Flock',
    this.showAllOption = true,
  });

  @override
  ConsumerState<FlockDropdown> createState() => _FlockDropdownState();
}

class _FlockDropdownState extends ConsumerState<FlockDropdown> {
  /// Sentinel for the "Add flock…" entry. Not a selectable flock, so it can
  /// never collide with a real flock id.
  static const String _addFlockValue = '__add_flock__';

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flocksAsync = ref.watch(flocksProvider);

    return flocksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (flocks) {
        if (flocks.isEmpty) return const SizedBox.shrink();

        return DropdownMenu<String?>(
          controller: _controller,
          initialSelection: widget.selectedFlockId,
          expandedInsets: EdgeInsets.zero,
          label: Text(widget.label),
          leadingIcon: _buildLeadingIcon(flocks, widget.selectedFlockId),
          dropdownMenuEntries: [
            if (widget.showAllOption)
              const DropdownMenuEntry(
                value: null,
                label: 'All Flocks',
                leadingIcon: Icon(Icons.grid_view, size: 24),
              ),
            ...flocks.map((flock) => DropdownMenuEntry(
                  value: flock.id,
                  label: flock.name,
                  leadingIcon: _FlockIcon(flock: flock, size: 24),
                )),
            const DropdownMenuEntry(
              value: _addFlockValue,
              label: 'Add flock…',
              leadingIcon: Icon(Icons.add, size: 24),
            ),
          ],
          onSelected: (value) {
            if (value == _addFlockValue) {
              // An action, not a selection — put the field back the way it was
              // before handing off to the flock form.
              _controller.text = _labelFor(flocks, widget.selectedFlockId);
              context.go('/settings/flocks/new');
              return;
            }
            widget.onChanged(value);
          },
        );
      },
    );
  }

  String _labelFor(List<Flock> flocks, String? selectedId) {
    if (selectedId == null) {
      return widget.showAllOption ? 'All Flocks' : '';
    }
    return flocks.where((f) => f.id == selectedId).firstOrNull?.name ?? '';
  }

  Widget? _buildLeadingIcon(List<Flock> flocks, String? selectedId) {
    if (selectedId == null) {
      return const Icon(Icons.grid_view, size: 24);
    }
    final flock = flocks.where((f) => f.id == selectedId).firstOrNull;
    if (flock == null) return null;
    return _FlockIcon(flock: flock, size: 24);
  }
}

/// Displays a flock's icon with its color
class _FlockIcon extends StatelessWidget {
  final Flock flock;
  final double size;

  const _FlockIcon({required this.flock, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(flock.color);

    if (flock.icon == 'cute_hen') {
      return Image.asset(
        'assets/icons/cute_hen.png',
        width: size,
        height: size,
        color: color,
      );
    }

    return Icon(
      _parseIcon(flock.icon),
      color: color,
      size: size,
    );
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return const Color(0xFF8B4513);
    }
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF8B4513);
    }
  }

  IconData _parseIcon(String? iconName) {
    const iconMap = {
      'egg': Icons.egg,
      'egg_alt': Icons.egg_alt,
      'home': Icons.home,
      'warehouse': Icons.warehouse,
      'fence': Icons.fence,
      'grass': Icons.grass,
      'park': Icons.park,
      'forest': Icons.forest,
      'terrain': Icons.terrain,
      'wb_sunny': Icons.wb_sunny,
      'wb_twilight': Icons.wb_twilight,
      'eco': Icons.eco,
      'nature_people': Icons.nature_people,
      'local_florist': Icons.local_florist,
      'agriculture': Icons.agriculture,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'groups': Icons.groups,
      'pets': Icons.pets,
    };
    return iconMap[iconName?.toLowerCase()] ?? Icons.egg;
  }
}
