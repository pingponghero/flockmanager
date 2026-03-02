import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../data/breeds.dart';
import '../../models/bird.dart';
import '../../models/enums.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/bird_provider.dart';
import '../../utils/edge_insets.dart';
import '../../utils/snackbar_utils.dart';
import '../../providers/flock_provider.dart';
import '../../widgets/achievement_celebration_dialog.dart';

class BirdFormScreen extends ConsumerStatefulWidget {
  final String? birdId;
  final bool openPhoto;

  const BirdFormScreen({super.key, this.birdId, this.openPhoto = false});

  bool get isEditing => birdId != null;

  @override
  ConsumerState<BirdFormScreen> createState() => _BirdFormScreenState();
}

class _BirdFormScreenState extends ConsumerState<BirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _sourceController = TextEditingController();
  final _eggColorController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedFlockId;
  String? _selectedBreedId;
  BirdSex _selectedSex = BirdSex.female;
  BirdSpecies _selectedSpecies = BirdSpecies.chicken;
  DateTime? _hatchDate;
  DateTime? _acquiredDate;
  String? _photoPath;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _lastGeneratedName;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _sourceController.dispose();
    _eggColorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load existing bird data if editing
    if (widget.isEditing && !_isInitialized) {
      return _buildLoadingState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Bird' : 'Add Bird'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBird,
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
            // Photo section
            _PhotoSection(
              photoPath: _photoPath,
              onPhotoTap: _selectPhoto,
            ),
            const SizedBox(height: 24),

            // Basic info section
            _SectionHeader(title: 'Basic Info'),
            const SizedBox(height: 12),

            // Name field (required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., Henrietta',
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

            // Flock dropdown (required)
            _FlockDropdown(
              selectedFlockId: _selectedFlockId,
              onChanged: (value) {
                setState(() => _selectedFlockId = value);
                _generateDefaultName(flockId: value);
              },
            ),
            const SizedBox(height: 16),

            // Species dropdown
            DropdownButtonFormField<BirdSpecies>(
              value: _selectedSpecies,
              decoration: const InputDecoration(
                labelText: 'Species',
              ),
              items: BirdSpecies.values.map((species) {
                return DropdownMenuItem(
                  value: species,
                  child: Text(species.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSpecies = value);
                  _generateDefaultName();
                }
              },
            ),
            const SizedBox(height: 16),

            // Sex dropdown
            DropdownButtonFormField<BirdSex>(
              value: _selectedSex,
              decoration: const InputDecoration(
                labelText: 'Sex',
              ),
              items: BirdSex.values.map((sex) {
                return DropdownMenuItem(
                  value: sex,
                  child: Text(sex.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSex = value);
                  _generateDefaultName();
                }
              },
            ),
            const SizedBox(height: 16),

            // Breed field with autocomplete (for chickens) or free text
            if (_selectedSpecies == BirdSpecies.chicken)
              _BreedAutocomplete(
                controller: _breedController,
                onBreedSelected: (breed) {
                  setState(() {
                    _selectedBreedId = breed?.id;
                    if (breed != null) {
                      _eggColorController.text = breed.eggColorDisplay;
                    }
                  });
                },
              )
            else
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Breed',
                  hintText: 'e.g., ${_selectedSpecies == BirdSpecies.duck ? 'Pekin, Khaki Campbell' : _selectedSpecies == BirdSpecies.turkey ? 'Bourbon Red, Bronze' : 'Enter breed'}',
                ),
                textCapitalization: TextCapitalization.words,
              ),
            const SizedBox(height: 24),

            // Dates section
            _SectionHeader(title: 'Dates'),
            const SizedBox(height: 12),

            // Hatch date
            _DateField(
              label: 'Hatch Date',
              value: _hatchDate,
              onChanged: (date) => setState(() => _hatchDate = date),
            ),
            const SizedBox(height: 16),

            // Acquired date
            _DateField(
              label: 'Acquired Date',
              value: _acquiredDate,
              onChanged: (date) => setState(() => _acquiredDate = date),
            ),
            const SizedBox(height: 24),

            // Details section
            _SectionHeader(title: 'Details'),
            const SizedBox(height: 12),

            // Source field
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'e.g., Local farm, Hatchery',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Egg color field
            TextFormField(
              controller: _eggColorController,
              decoration: const InputDecoration(
                labelText: 'Expected Egg Color',
                hintText: 'e.g., Brown, White, Blue',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any additional notes...',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final birdAsync = ref.watch(birdByIdProvider(widget.birdId!));

    return birdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Bird')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Edit Bird')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading bird: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (bird) {
        if (bird == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Bird')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bird not found'),
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

        // Initialize form with bird data
        if (!_isInitialized) {
          _nameController.text = bird.name;
          _breedController.text = bird.breed ?? '';
          _sourceController.text = bird.source ?? '';
          _eggColorController.text = bird.eggColor ?? '';
          _notesController.text = bird.notes ?? '';
          _selectedFlockId = bird.flockId;
          _selectedBreedId = bird.breedId;
          _selectedSex = bird.sex;
          _selectedSpecies = bird.species;
          _hatchDate = bird.hatchDate;
          _acquiredDate = bird.acquiredDate;
          _photoPath = bird.photoPrimary;
          _isInitialized = true;
          // Schedule a rebuild to show the form
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
            if (mounted && widget.openPhoto) {
              _selectPhoto();
            }
          });
        }

        return build(context);
      },
    );
  }

  Future<void> _generateDefaultName({String? flockId}) async {
    if (widget.isEditing) return;

    final effectiveFlockId = flockId ?? _selectedFlockId;
    if (effectiveFlockId == null) return;

    // Only overwrite if empty or matches our last generated name
    final currentName = _nameController.text.trim();
    if (currentName.isNotEmpty && currentName != _lastGeneratedName) return;

    final birds =
        await ref.read(birdsByFlockProvider(effectiveFlockId).future);
    final number = birds.length + 1;

    String name;
    if (_selectedSpecies == BirdSpecies.chicken) {
      name = switch (_selectedSex) {
        BirdSex.male => 'Rooster $number',
        BirdSex.unknown => 'Chicken $number',
        _ => 'Hen $number',
      };
    } else if (_selectedSpecies == BirdSpecies.duck) {
      name = 'Duck $number';
    } else if (_selectedSpecies == BirdSpecies.turkey) {
      name = 'Turkey $number';
    } else {
      name = 'Bird $number';
    }

    _nameController.text = name;
    _lastGeneratedName = name;
  }

  Future<void> _selectPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Copy to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/bird_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final savedPath = '${photosDir.path}/$fileName';
      await File(pickedFile.path).copy(savedPath);

      setState(() => _photoPath = savedPath);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Error selecting photo: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _saveBird() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFlockId == null) {
      showAppSnackBar(context, 'Please select a flock');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(birdsProvider.notifier);

      if (widget.isEditing) {
        // Update existing bird
        final existingBird = ref.read(birdByIdProvider(widget.birdId!)).value;
        if (existingBird != null) {
          final updatedBird = existingBird.copyWith(
            name: _nameController.text.trim(),
            flockId: _selectedFlockId!,
            breed: _breedController.text.trim().isEmpty
                ? null
                : _breedController.text.trim(),
            breedId: _selectedSpecies == BirdSpecies.chicken ? _selectedBreedId : null,
            hatchDate: _hatchDate,
            acquiredDate: _acquiredDate,
            source: _sourceController.text.trim().isEmpty
                ? null
                : _sourceController.text.trim(),
            eggColor: _eggColorController.text.trim().isEmpty
                ? null
                : _eggColorController.text.trim(),
            sex: _selectedSex,
            species: _selectedSpecies,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            photoPrimary: _photoPath,
          );
          await notifier.updateBird(updatedBird);
        }
      } else {
        // Create new bird
        final newBird = Bird.create(
          flockId: _selectedFlockId!,
          name: _nameController.text.trim(),
          breed: _breedController.text.trim().isEmpty
              ? null
              : _breedController.text.trim(),
          breedId: _selectedSpecies == BirdSpecies.chicken ? _selectedBreedId : null,
          photoPrimary: _photoPath,
          hatchDate: _hatchDate,
          acquiredDate: _acquiredDate,
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          eggColor: _eggColorController.text.trim().isEmpty
              ? null
              : _eggColorController.text.trim(),
          sex: _selectedSex,
          species: _selectedSpecies,
          status: _selectedSex == BirdSex.male ? BirdStatus.inactive : BirdStatus.active,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await notifier.addBird(newBird);
      }

      if (mounted) {
        showAppSnackBar(
          context,
          widget.isEditing ? 'Bird updated' : 'Bird added',
        );

        // Check for new achievements
        final newAchievements = await checkAndCelebrateAchievements(ref, context);
        if (mounted && newAchievements.isNotEmpty) {
          await AchievementCelebrationDialog.showMultiple(context, newAchievements);
          await markAchievementsAsShown(newAchievements);
        }

        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Error: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPhotoTap;

  const _PhotoSection({
    required this.photoPath,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPhotoTap,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoPath != null && File(photoPath!).existsSync()
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photoPath!), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: const Text(
                          'Tap to change',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FlockDropdown extends ConsumerWidget {
  final String? selectedFlockId;
  final ValueChanged<String?> onChanged;

  const _FlockDropdown({
    required this.selectedFlockId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flocksAsync = ref.watch(flocksProvider);

    return flocksAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Text('Error loading flocks: $error'),
      data: (flocks) {
        if (flocks.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text('No flocks available'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/settings/flocks/new'),
                    child: const Text('Create a Flock'),
                  ),
                ],
              ),
            ),
          );
        }

        // Single flock: auto-select and show as label
        if (flocks.length == 1) {
          final flock = flocks.first;
          if (selectedFlockId != flock.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onChanged(flock.id);
            });
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  flock.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Text(
                  'Flock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // Multiple flocks: show dropdown
        return DropdownButtonFormField<String>(
          value: selectedFlockId,
          decoration: const InputDecoration(
            labelText: 'Flock *',
          ),
          items: flocks.map((flock) {
            return DropdownMenuItem(
              value: flock.id,
              child: Text(flock.name),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null) {
              return 'Please select a flock';
            }
            return null;
          },
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.calendar_today),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: Text(
          value != null ? dateFormat.format(value!) : 'Not set',
          style: value != null
              ? null
              : TextStyle(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}

class _BreedAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<Breed?> onBreedSelected;

  const _BreedAutocomplete({
    required this.controller,
    required this.onBreedSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Breed>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Breed>.empty();
        }
        return searchBreeds(textEditingValue.text).take(5);
      },
      displayStringForOption: (breed) => breed.name,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Sync with external controller
        if (controller.text.isNotEmpty && textController.text.isEmpty) {
          textController.text = controller.text;
        }
        textController.addListener(() {
          if (controller.text != textController.text) {
            controller.text = textController.text;
          }
        });

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Breed',
            hintText: 'Start typing to search...',
          ),
          textCapitalization: TextCapitalization.words,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 350),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final breed = options.elementAt(index);
                  return ListTile(
                    title: Text(breed.name),
                    subtitle: Text(
                      '${breed.eggColorDisplay} eggs • ${breed.eggsPerYearAvg}/yr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    dense: true,
                    onTap: () => onSelected(breed),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (breed) {
        controller.text = breed.name;
        onBreedSelected(breed);
      },
    );
  }
}
