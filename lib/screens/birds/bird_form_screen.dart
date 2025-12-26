import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/bird.dart';
import '../../providers/bird_provider.dart';
import '../../providers/flock_provider.dart';

class BirdFormScreen extends ConsumerStatefulWidget {
  final String? birdId;

  const BirdFormScreen({super.key, this.birdId});

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
  DateTime? _hatchDate;
  DateTime? _acquiredDate;
  String? _photoPath;
  bool _isLoading = false;
  bool _isInitialized = false;

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
          padding: const EdgeInsets.all(16),
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
              onChanged: (value) => setState(() => _selectedFlockId = value),
            ),
            const SizedBox(height: 16),

            // Breed field
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g., Rhode Island Red',
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
          _hatchDate = bird.hatchDate;
          _acquiredDate = bird.acquiredDate;
          _photoPath = bird.photoPrimary;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveBird() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flock')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(birdsProvider.notifier);

      if (widget.isEditing) {
        // Update existing bird
        final existingBird = ref.read(birdByIdProvider(widget.birdId!)).valueOrNull;
        if (existingBird != null) {
          final updatedBird = existingBird.copyWith(
            name: _nameController.text.trim(),
            flockId: _selectedFlockId!,
            breed: _breedController.text.trim().isEmpty
                ? null
                : _breedController.text.trim(),
            hatchDate: _hatchDate,
            acquiredDate: _acquiredDate,
            source: _sourceController.text.trim().isEmpty
                ? null
                : _sourceController.text.trim(),
            eggColor: _eggColorController.text.trim().isEmpty
                ? null
                : _eggColorController.text.trim(),
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
          hatchDate: _hatchDate,
          acquiredDate: _acquiredDate,
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          eggColor: _eggColorController.text.trim().isEmpty
              ? null
              : _eggColorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          photoPrimary: _photoPath,
        );
        await notifier.addBird(newBird);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Bird updated' : 'Bird added',
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
                    onPressed: () => context.push('/flocks/new'),
                    child: const Text('Create a Flock'),
                  ),
                ],
              ),
            ),
          );
        }

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
