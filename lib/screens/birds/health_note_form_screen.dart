import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/health_note.dart';
import '../../providers/bird_provider.dart';
import '../../providers/medication_provider.dart';
import '../../utils/snackbar_utils.dart';

/// Form screen for creating or editing a health note.
class HealthNoteFormScreen extends ConsumerStatefulWidget {
  final String birdId;
  final String? noteId; // null for new note

  const HealthNoteFormScreen({
    super.key,
    required this.birdId,
    this.noteId,
  });

  @override
  ConsumerState<HealthNoteFormScreen> createState() => _HealthNoteFormScreenState();
}

class _HealthNoteFormScreenState extends ConsumerState<HealthNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  HealthNoteType _selectedType = HealthNoteType.observation;
  bool _isLoading = false;
  bool _isDeleting = false;
  HealthNote? _existingNote;

  bool get isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadExistingNote();
    }
  }

  Future<void> _loadExistingNote() async {
    setState(() => _isLoading = true);
    try {
      final note = await ref.read(healthNoteByIdProvider(widget.noteId!).future);
      if (note != null && mounted) {
        setState(() {
          _existingNote = note;
          _selectedDate = note.date;
          _selectedType = note.type;
          _descriptionController.text = note.description;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (isEditing && _existingNote != null) {
        // Update existing note
        final updated = HealthNote(
          id: _existingNote!.id,
          birdId: widget.birdId,
          date: _selectedDate,
          type: _selectedType,
          description: _descriptionController.text.trim(),
          createdAt: _existingNote!.createdAt,
        );
        await ref.read(healthNotesProvider.notifier).updateHealthNote(updated);
      } else {
        // Create new note
        final note = HealthNote.create(
          birdId: widget.birdId,
          date: _selectedDate,
          type: _selectedType,
          description: _descriptionController.text.trim(),
        );
        await ref.read(healthNotesProvider.notifier).addHealthNote(note);
      }

      // Invalidate the bird-specific provider to refresh the list
      ref.invalidate(healthNotesByBirdProvider(widget.birdId));

      if (mounted) {
        context.pop();
        showAppSnackBar(context, isEditing ? 'Note updated' : 'Note added');
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this health note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(healthNotesProvider.notifier).deleteHealthNote(widget.noteId!);
      ref.invalidate(healthNotesByBirdProvider(widget.birdId));

      if (mounted) {
        context.pop();
        showAppSnackBar(context, 'Note deleted');
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
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final birdAsync = ref.watch(birdByIdProvider(widget.birdId));
    final birdName = birdAsync.hasValue ? (birdAsync.value?.name ?? 'Bird') : 'Bird';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Health Note' : 'Add Health Note'),
        actions: [
          if (isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _delete,
            ),
        ],
      ),
      body: _isLoading && isEditing && _existingNote == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bird name (read-only)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(birdName),
                      subtitle: const Text('Bird'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat.yMMMd().format(_selectedDate)),
                      subtitle: const Text('Date'),
                      trailing: const Icon(Icons.edit),
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: HealthNoteType.values.map((type) {
                              final isSelected = type == _selectedType;
                              return ChoiceChip(
                                label: Text(type.displayName),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedType = type);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the observation...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isEditing ? 'Update Note' : 'Save Note'),
                  ),
                ],
              ),
            ),
    );
  }
}
