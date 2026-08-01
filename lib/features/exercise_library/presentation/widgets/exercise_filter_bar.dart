import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExerciseFilterBar extends ConsumerWidget {
  const ExerciseFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(exerciseCategoriesProvider);
    final selectedCategory = ref.watch(exerciseCategoryFilterProvider);
    final selectedDifficulty = ref.watch(exerciseDifficultyFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            onChanged: (value) =>
                ref.read(exerciseSearchQueryProvider.notifier).state = value,
            decoration: const InputDecoration(
              hintText: 'Search exercises, muscles, equipment…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _FilterChip(
                label: 'All',
                selected: selectedCategory == null,
                onTap: () => ref
                    .read(exerciseCategoryFilterProvider.notifier)
                    .state = null,
              ),
              const SizedBox(width: 8),
              for (final category in categories) ...[
                _FilterChip(
                  label: category,
                  selected: selectedCategory == category,
                  onTap: () => ref
                      .read(exerciseCategoryFilterProvider.notifier)
                      .state = selectedCategory == category ? null : category,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final difficulty in ExerciseDifficulty.values) ...[
                _FilterChip(
                  label: _difficultyLabel(difficulty),
                  selected: selectedDifficulty == difficulty,
                  onTap: () => ref
                      .read(exerciseDifficultyFilterProvider.notifier)
                      .state = selectedDifficulty == difficulty
                          ? null
                          : difficulty,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _difficultyLabel(ExerciseDifficulty difficulty) => switch (difficulty) {
        ExerciseDifficulty.beginner => 'Beginner',
        ExerciseDifficulty.intermediate => 'Intermediate',
        ExerciseDifficulty.advanced => 'Advanced',
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : const Color(0xFF252B38),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
