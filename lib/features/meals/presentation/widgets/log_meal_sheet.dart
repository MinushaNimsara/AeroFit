import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum LogMealMode { choose, analyzing, form }

class LogMealSheet extends ConsumerStatefulWidget {
  const LogMealSheet({super.key, this.startWithManual = false});

  final bool startWithManual;

  @override
  ConsumerState<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<LogMealSheet> {
  late LogMealMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _mealType = MealEntry.mealTypes.first;
  String? _pickedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.startWithManual ? LogMealMode.form : LogMealMode.choose;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  String _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 20) return 'Dinner';
    return 'Snack';
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() {
      _mode = LogMealMode.analyzing;
      _pickedImagePath = image.path;
    });

    try {
      final analyzer = ref.read(mealAnalyzerServiceProvider);
      final result = await analyzer.analyzeFoodFromImage(image);
      if (!mounted) return;

      final uid = ref.read(authStateProvider).value?.uid;
      final repo = ref.read(mealsRepositoryProvider);
      if (uid == null || repo == null) {
        throw Exception('You must be signed in to log meals.');
      }

      await repo.addMeal(
        uid: uid,
        name: result.name,
        calories: result.calories,
        mealType: _inferMealType(),
        imageUrl: image.path,
        protein: result.protein,
        carbs: result.carbs,
        fats: result.fats,
        ingredients: result.ingredients,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${result.name} — ${result.calories} kcal',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gemini analysis failed: $e')),
      );
      setState(() => _mode = LogMealMode.choose);
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateProvider).value?.uid;
    final repo = ref.read(mealsRepositoryProvider);
    if (uid == null || repo == null) return;

    setState(() => _isSaving = true);
    try {
      await repo.addMeal(
        uid: uid,
        name: _nameController.text,
        calories: int.parse(_caloriesController.text),
        mealType: _mealType,
        imageUrl: _pickedImagePath,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
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
            'Log meal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          switch (_mode) {
            LogMealMode.choose => _ChooseMode(
                onCamera: () => _pickAndAnalyze(ImageSource.camera),
                onGallery: () => _pickAndAnalyze(ImageSource.gallery),
                onManual: () => setState(() => _mode = LogMealMode.form),
              ),
            LogMealMode.analyzing => const _AnalyzingView(),
            LogMealMode.form => _MealForm(
                formKey: _formKey,
                nameController: _nameController,
                caloriesController: _caloriesController,
                mealType: _mealType,
                onMealTypeChanged: (v) => setState(() => _mealType = v),
                isSaving: _isSaving,
                onSave: _saveMeal,
                imagePath: _pickedImagePath,
              ),
          },
        ],
      ),
    );
  }
}

class _ChooseMode extends StatelessWidget {
  const _ChooseMode({
    required this.onCamera,
    required this.onGallery,
    required this.onManual,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionTile(
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Gemini AI estimates calories from your plate',
          onTap: onCamera,
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Pick a meal photo for Gemini AI analysis',
          onTap: onGallery,
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: Icons.edit_note_rounded,
          title: 'Manual Entry',
          subtitle: 'Enter name and calories yourself',
          onTap: onManual,
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: const Column(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'AI is analyzing your meal plate…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Identifying food, macros, and ingredients',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealForm extends StatelessWidget {
  const _MealForm({
    required this.formKey,
    required this.nameController,
    required this.caloriesController,
    required this.mealType,
    required this.onMealTypeChanged,
    required this.isSaving,
    required this.onSave,
    this.imagePath,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final String mealType;
  final ValueChanged<String> onMealTypeChanged;
  final bool isSaving;
  final VoidCallback onSave;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePath != null) ...[
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Analyzed by Gemini AI',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Meal name',
              prefixIcon: Icon(Icons.restaurant_rounded),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a meal name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: caloriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Calories (kcal)',
              prefixIcon: Icon(Icons.local_fire_department_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter calories';
              if (int.tryParse(v) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(mealType),
            initialValue: mealType,
            decoration: const InputDecoration(
              labelText: 'Meal type',
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
            items: [
              for (final type in MealEntry.mealTypes)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: (v) {
              if (v != null) onMealTypeChanged(v);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save meal'),
          ),
        ],
      ),
    );
  }
}

void showLogMealSheet(BuildContext context, {bool manual = false}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => LogMealSheet(startWithManual: manual),
  );
}
