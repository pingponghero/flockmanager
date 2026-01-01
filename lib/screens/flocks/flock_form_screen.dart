import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/flock.dart';
import '../../providers/flock_provider.dart';
import '../../utils/edge_insets.dart';

class FlockFormScreen extends ConsumerStatefulWidget {
  final String? flockId;

  const FlockFormScreen({super.key, this.flockId});

  bool get isEditing => flockId != null;

  @override
  ConsumerState<FlockFormScreen> createState() => _FlockFormScreenState();
}

class _FlockFormScreenState extends ConsumerState<FlockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = 'cute_hen';
  String _selectedColor = '2E7D32';
  bool _isLoading = false;
  bool _isInitialized = false;

  // Available icons for selection (null IconData means use cute_hen asset)
  static const _iconOptions = <(String, IconData?)>[
    // Custom asset
    ('cute_hen', null),
    // Eggs & food
    ('egg', Icons.egg),
    ('egg_alt', Icons.egg_alt),
    // Buildings & housing
    ('home', Icons.home),
    ('warehouse', Icons.warehouse),
    // Outdoors & nature
    ('fence', Icons.fence),
    ('grass', Icons.grass),
    ('park', Icons.park),
    ('forest', Icons.forest),
    ('terrain', Icons.terrain),
    // Weather & sun
    ('wb_sunny', Icons.wb_sunny),
    ('wb_twilight', Icons.wb_twilight),
    // Plants & nature
    ('eco', Icons.eco),
    ('nature_people', Icons.nature_people),
    ('local_florist', Icons.local_florist),
    // Farm & animals
    ('agriculture', Icons.agriculture),
    // Favorites & markers
    ('favorite', Icons.favorite),
    ('star', Icons.star),
  ];

  // Available colors for selection
  static const _colorOptions = [
    // Greens
    ('2E7D32', Color(0xFF2E7D32)), // Forest green
    ('689F38', Color(0xFF689F38)), // Light green
    ('00695C', Color(0xFF00695C)), // Teal
    // Blues
    ('0277BD', Color(0xFF0277BD)), // Light blue
    ('01579B', Color(0xFF01579B)), // Dark blue
    ('006064', Color(0xFF006064)), // Cyan dark
    // Warm colors
    ('E65100', Color(0xFFE65100)), // Orange
    ('F57C00', Color(0xFFF57C00)), // Light orange
    ('FFB300', Color(0xFFFFB300)), // Golden
    // Reds & pinks
    ('C62828', Color(0xFFC62828)), // Red
    ('880E4F', Color(0xFF880E4F)), // Dark pink
    ('B71C1C', Color(0xFFB71C1C)), // Dark red
    // Purples
    ('4527A0', Color(0xFF4527A0)), // Deep purple
    ('512DA8', Color(0xFF512DA8)), // Medium purple
    ('7B1FA2', Color(0xFF7B1FA2)), // Light purple
    // Neutrals
    ('8B4513', Color(0xFF8B4513)), // Saddle brown (barn)
    ('5D4037', Color(0xFF5D4037)), // Dark brown
    ('616161', Color(0xFF616161)), // Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load existing flock data if editing
    if (widget.isEditing && !_isInitialized) {
      return _buildLoadingState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Flock' : 'New Flock'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveFlock,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Backyard Hens',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Our main laying flock',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Icon picker
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((option) {
                final isSelected = _selectedIcon == option.$1;
                return _IconChip(
                  iconName: option.$1,
                  icon: option.$2,
                  isSelected: isSelected,
                  color: Color(int.parse('FF$_selectedColor', radix: 16)),
                  onTap: () => setState(() => _selectedIcon = option.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color picker
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((option) {
                final isSelected = _selectedColor == option.$1;
                return _ColorChip(
                  color: option.$2,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedColor = option.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Preview
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _FlockPreviewCard(
              name: _nameController.text.isEmpty ? 'Flock Name' : _nameController.text,
              description: _descriptionController.text,
              iconName: _selectedIcon,
              colorHex: _selectedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final flockAsync = ref.watch(flockByIdProvider(widget.flockId!));

    return flockAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Flock')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Edit Flock')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading flock: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (flock) {
        if (flock == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Flock')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Flock not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Initialize form with flock data
        if (!_isInitialized) {
          _nameController.text = flock.name;
          _descriptionController.text = flock.description ?? '';
          _selectedIcon = flock.icon ?? 'groups';
          _selectedColor = flock.color ?? '8B4513';
          _isInitialized = true;
          // Schedule a rebuild to show the form
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }

        return build(context);
      },
    );
  }

  Future<void> _saveFlock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(flocksProvider.notifier);

      if (widget.isEditing) {
        // Update existing flock
        final existingFlock = ref.read(flockByIdProvider(widget.flockId!)).valueOrNull;
        if (existingFlock != null) {
          final updatedFlock = existingFlock.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            icon: _selectedIcon,
            color: _selectedColor,
          );
          await notifier.updateFlock(updatedFlock);
        }
      } else {
        // Create new flock
        final newFlock = Flock.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
        );
        await notifier.addFlock(newFlock);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Flock updated' : 'Flock created',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _IconChip extends StatelessWidget {
  final String iconName;
  final IconData? icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _IconChip({
    required this.iconName,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? color : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: iconColor)
              : Image.asset(
                  'assets/icons/cute_hen.png',
                  width: 25,
                  height: 25,
                  color: iconColor,
                ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}

class _FlockPreviewCard extends StatelessWidget {
  final String name;
  final String description;
  final String iconName;
  final String colorHex;

  const _FlockPreviewCard({
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF$colorHex', radix: 16));
    final icon = _getIcon(iconName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: color, size: 24)
                    : Image.asset(
                        'assets/icons/cute_hen.png',
                        width: 25,
                        height: 25,
                        color: color,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData? _getIcon(String name) {
    // cute_hen uses asset image, not IconData
    if (name == 'cute_hen') return null;

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
      // Legacy
      'groups': Icons.groups,
      'pets': Icons.pets,
    };
    return iconMap[name] ?? Icons.egg;
  }
}
