import 'package:flutter/material.dart';

import '../../data/breeds.dart';

class BreedListScreen extends StatefulWidget {
  const BreedListScreen({super.key});

  @override
  State<BreedListScreen> createState() => _BreedListScreenState();
}

class _BreedListScreenState extends State<BreedListScreen> {
  String _searchQuery = '';
  EggColor? _selectedEggColor;
  bool? _coldHardyFilter;
  bool? _goodLayerFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredBreeds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breed Guide'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search breeds...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Egg color filter
                PopupMenuButton<EggColor?>(
                  child: Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedEggColor != null) ...[
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getEggColorValue(_selectedEggColor!),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(_selectedEggColor != null
                            ? _getEggColorLabel(_selectedEggColor!)
                            : 'Egg Color'),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                    deleteIcon: _selectedEggColor != null
                        ? const Icon(Icons.close, size: 16)
                        : null,
                    onDeleted: _selectedEggColor != null
                        ? () => setState(() => _selectedEggColor = null)
                        : null,
                  ),
                  onSelected: (color) => setState(() => _selectedEggColor = color),
                  itemBuilder: (context) => [
                    PopupMenuItem<EggColor?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: _selectedEggColor == null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text('All Colors'),
                        ],
                      ),
                    ),
                    ...EggColor.values
                        .where((c) => c != EggColor.green && c != EggColor.pink)
                        .map((color) => PopupMenuItem<EggColor?>(
                          value: color,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getEggColorValue(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getEggColorLabel(color)),
                            ],
                          ),
                        )),
                  ],
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Cold Hardy'),
                  selected: _coldHardyFilter == true,
                  onSelected: (selected) => setState(
                    () => _coldHardyFilter = selected ? true : null,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Good Layers'),
                  selected: _goodLayerFilter == true,
                  onSelected: (selected) => setState(
                    () => _goodLayerFilter = selected ? true : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} breeds',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_selectedEggColor != null ||
                    _coldHardyFilter != null ||
                    _goodLayerFilter != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedEggColor = null;
                      _coldHardyFilter = null;
                      _goodLayerFilter = null;
                    }),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),

          // Breed list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final breed = filtered[index];
                return _BreedCard(breed: breed);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Breed> _getFilteredBreeds() {
    var result = searchBreeds(_searchQuery);

    if (_selectedEggColor != null) {
      result = result.where((b) => b.eggColor == _selectedEggColor).toList();
    }

    if (_coldHardyFilter == true) {
      result = result.where((b) => b.coldHardy).toList();
    }

    if (_goodLayerFilter == true) {
      result = result.where((b) => b.eggsPerYearAvg >= 250).toList();
    }

    return result;
  }

  Color _getEggColorValue(EggColor color) {
    switch (color) {
      case EggColor.white:
        return Colors.white;
      case EggColor.cream:
        return const Color(0xFFFFF8DC);
      case EggColor.brown:
        return const Color(0xFFD2691E);
      case EggColor.darkBrown:
        return const Color(0xFF8B4513);
      case EggColor.chocolate:
        return const Color(0xFF5D3A1A);
      case EggColor.blue:
        return const Color(0xFFADD8E6);
      case EggColor.green:
        return const Color(0xFF90EE90);
      case EggColor.olive:
        return const Color(0xFF808000);
      case EggColor.pink:
        return const Color(0xFFFFB6C1);
      case EggColor.tinted:
        return const Color(0xFFFAF0E6);
    }
  }

  String _getEggColorLabel(EggColor color) {
    switch (color) {
      case EggColor.white:
        return 'White';
      case EggColor.cream:
        return 'Cream';
      case EggColor.brown:
        return 'Brown';
      case EggColor.darkBrown:
        return 'Dark Brown';
      case EggColor.chocolate:
        return 'Chocolate';
      case EggColor.blue:
        return 'Blue';
      case EggColor.green:
        return 'Green';
      case EggColor.olive:
        return 'Olive';
      case EggColor.pink:
        return 'Pink';
      case EggColor.tinted:
        return 'Tinted';
    }
  }
}

class _BreedCard extends StatelessWidget {
  final Breed breed;

  const _BreedCard({required this.breed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getEggColorValue(breed.eggColor),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        title: Text(
          breed.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${breed.eggsPerYearMin}-${breed.eggsPerYearMax} eggs/year',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breed.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Stats grid
                Row(
                  children: [
                    Expanded(child: _stat(context, 'Egg Color', breed.eggColorDisplay)),
                    Expanded(child: _stat(context, 'Egg Size', breed.eggSize)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _stat(context, 'Eggs/Year', '${breed.eggsPerYearMin}-${breed.eggsPerYearMax}')),
                    Expanded(child: _stat(context, 'Temperament', breed.temperament)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        context,
                        'Hen Weight',
                        '${breed.weightLbsHenMin}-${breed.weightLbsHenMax} lbs',
                      ),
                    ),
                    Expanded(
                      child: _stat(
                        context,
                        'Rooster Weight',
                        '${breed.weightLbsRoosterMin}-${breed.weightLbsRoosterMax} lbs',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Traits
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _trait(context, breed.category.name.toUpperCase(), Colors.blue),
                    if (breed.coldHardy)
                      _trait(context, 'Cold Hardy', Colors.indigo),
                    if (breed.heatTolerant)
                      _trait(context, 'Heat Tolerant', Colors.orange),
                    _trait(
                      context,
                      '${breed.broodiness.name} broodiness',
                      breed.broodiness == Broodiness.high
                          ? Colors.pink
                          : breed.broodiness == Broodiness.moderate
                              ? Colors.purple
                              : Colors.grey,
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

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _trait(BuildContext context, String label, Color color) {
    // Darken the color for text to ensure contrast
    final hsl = HSLColor.fromColor(color);
    final darkText = hsl.withLightness((hsl.lightness * 0.4).clamp(0.0, 0.4)).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
    );
  }

  Color _getEggColorValue(EggColor color) {
    switch (color) {
      case EggColor.white:
        return Colors.white;
      case EggColor.cream:
        return const Color(0xFFFFF8DC);
      case EggColor.brown:
        return const Color(0xFFD2691E);
      case EggColor.darkBrown:
        return const Color(0xFF8B4513);
      case EggColor.chocolate:
        return const Color(0xFF5D3A1A);
      case EggColor.blue:
        return const Color(0xFFADD8E6);
      case EggColor.green:
        return const Color(0xFF90EE90);
      case EggColor.olive:
        return const Color(0xFF808000);
      case EggColor.pink:
        return const Color(0xFFFFB6C1);
      case EggColor.tinted:
        return const Color(0xFFFAF0E6);
    }
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
