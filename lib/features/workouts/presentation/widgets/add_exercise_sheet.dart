import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_category_visual.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_picker_sheet.dart';
import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum _SavePhase { idle, uploading, saving }

class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({
    super.key,
    required this.initialSplitId,
    required this.splits,
  });

  final String initialSplitId;
  final List<WorkoutSplit> splits;

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _settingsController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedSplitId;
  XFile? _pickedImage;
  Exercise? _selectedLibraryExercise;
  _SavePhase _phase = _SavePhase.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSplitId = widget.initialSplitId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _settingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFromLibrary() async {
    final exercise = await showSingleExercisePickerSheet(context);
    if (exercise != null && mounted) {
      setState(() {
        _selectedLibraryExercise = exercise;
        _nameController.text = exercise.name;
      });
    }
  }

  void _clearLibrarySelection() {
    setState(() {
      _selectedLibraryExercise = null;
      _nameController.clear();
    });
  }

  Future<void> _capturePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final uid = ref.read(authStateProvider).value?.uid;
    final exercisesRepo = ref.read(exercisesRepositoryProvider);
    if (uid == null || exercisesRepo == null) {
      setState(() => _errorMessage = 'Not signed in or Firebase unavailable.');
      return;
    }

    if (_selectedSplitId.isEmpty) {
      setState(() => _errorMessage = 'Select a workout split.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _phase = _pickedImage != null ? _SavePhase.uploading : _SavePhase.saving;
    });

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final cloudinary = ref.read(cloudinaryServiceProvider);
        imageUrl = await cloudinary.uploadImage(_pickedImage!);
        if (mounted) setState(() => _phase = _SavePhase.saving);
      }

      await exercisesRepo.addExercise(
        uid: uid,
        splitId: _selectedSplitId,
        name: _nameController.text,
        weightOrSetting: _settingsController.text,
        notes: _notesController.text,
        imageUrl: imageUrl,
        exerciseId: _selectedLibraryExercise?.id,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _phase = _SavePhase.idle;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _phase != _SavePhase.idle;
    final splitName = widget.splits
        .where((s) => s.id == _selectedSplitId)
        .map((s) => s.name)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add exercise',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (splitName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Adding to: $splitName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            if (_phase == _SavePhase.uploading) ...[
              const _UploadingBanner(),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.splits.length > 1)
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedSplitId),
                      initialValue: _selectedSplitId,
                      decoration: const InputDecoration(
                        labelText: 'Workout split',
                        prefixIcon: Icon(Icons.view_list_rounded),
                      ),
                      items: [
                        for (final split in widget.splits)
                          DropdownMenuItem(
                            value: split.id,
                            child: Text(split.name),
                          ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _selectedSplitId = v);
                              }
                            },
                    ),
                  if (widget.splits.length > 1) const SizedBox(height: 12),
                  if (_selectedLibraryExercise != null)
                    _SelectedLibraryExerciseCard(
                      exercise: _selectedLibraryExercise!,
                      onClear: isBusy ? null : _clearLibrarySelection,
                    )
                  else ...[
                    TextFormField(
                      controller: _nameController,
                      enabled: !isBusy,
                      decoration: const InputDecoration(
                        labelText: 'Exercise name',
                        hintText: 'e.g. Incline Treadmill Walk',
                        prefixIcon: Icon(Icons.fitness_center_rounded),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : _pickFromLibrary,
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text('Choose from Exercise Library'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _settingsController,
                    enabled: !isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Weight / machine settings',
                      hintText: 'Speed 5.0 / Incline 12',
                      prefixIcon: Icon(Icons.tune_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    enabled: !isBusy,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : _capturePhoto,
                    icon: Icon(
                      _pickedImage != null
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      color: _pickedImage != null
                          ? AppColors.win
                          : AppColors.primary,
                    ),
                    label: Text(
                      _pickedImage != null
                          ? 'Photo captured — tap to change'
                          : 'Capture machine photo',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: _pickedImage != null
                            ? AppColors.win.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isBusy ? null : _save,
                    child: _phase == _SavePhase.saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save exercise'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLibraryExerciseCard extends StatelessWidget {
  const _SelectedLibraryExerciseCard({
    required this.exercise,
    required this.onClear,
  });

  final Exercise exercise;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ExerciseCategoryIcon(category: exercise.category, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.category} · ${exercise.primaryMuscle}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            tooltip: 'Choose a different exercise',
          ),
        ],
      ),
    );
  }
}

class _UploadingBanner extends StatelessWidget {
  const _UploadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Uploading machine configuration photo…',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showAddExerciseSheet(
  BuildContext context, {
  required String splitId,
  required List<WorkoutSplit> splits,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AddExerciseSheet(
      initialSplitId: splitId,
      splits: splits,
    ),
  );
}
