import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_category_visual.dart';
import 'package:flutter/material.dart';

class ExerciseListCard extends StatelessWidget {
  const ExerciseListCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  Color get _difficultyColor => switch (exercise.difficulty) {
        ExerciseDifficulty.beginner => AppColors.win,
        ExerciseDifficulty.intermediate => AppColors.warning,
        ExerciseDifficulty.advanced => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF252B38)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExerciseCategoryIcon(category: exercise.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.category} · ${exercise.primaryMuscle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _difficultyColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            exercise.difficultyLabel,
                            style: TextStyle(
                              color: _difficultyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise.equipmentSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else
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
