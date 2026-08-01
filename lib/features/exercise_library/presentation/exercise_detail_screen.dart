import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_category_visual.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Details')),
      body: exerciseAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Could not load exercise: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (exercise) {
          if (exercise == null) {
            return const Center(
              child: Text(
                'Exercise not found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return _ExerciseDetailBody(exercise: exercise);
        },
      ),
    );
  }
}

class _ExerciseDetailBody extends StatelessWidget {
  const _ExerciseDetailBody({required this.exercise});

  final Exercise exercise;

  Color get _difficultyColor => switch (exercise.difficulty) {
        ExerciseDifficulty.beginner => AppColors.win,
        ExerciseDifficulty.intermediate => AppColors.warning,
        ExerciseDifficulty.advanced => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseCategoryIcon(category: exercise.category, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.category} · ${exercise.primaryMuscle}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: exercise.difficultyLabel, color: _difficultyColor),
                if (exercise.exerciseType.isNotEmpty)
                  _Badge(label: exercise.exerciseType, color: AppColors.primary),
                if (exercise.movementPattern.isNotEmpty)
                  _Badge(label: exercise.movementPattern, color: AppColors.accent),
                if (exercise.unilateral) const _Badge(label: 'Unilateral', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Equipment',
              icon: Icons.fitness_center_rounded,
              child: _ChipWrap(items: exercise.equipment.isEmpty ? const ['Bodyweight'] : exercise.equipment),
            ),
            if (exercise.secondaryMuscles.isNotEmpty)
              _Section(
                title: 'Secondary muscles',
                icon: Icons.accessibility_new_rounded,
                child: _ChipWrap(items: exercise.secondaryMuscles),
              ),
            if (exercise.trainingGoals.isNotEmpty)
              _Section(
                title: 'Training goals',
                icon: Icons.flag_rounded,
                child: _ChipWrap(items: exercise.trainingGoals),
              ),
            if (exercise.instructions.isNotEmpty)
              _Section(
                title: 'How to perform it',
                icon: Icons.format_list_numbered_rounded,
                child: _NumberedList(items: exercise.instructions),
              ),
            if (exercise.startingPosition.isNotEmpty ||
                exercise.endingPosition.isNotEmpty)
              _Section(
                title: 'Position',
                icon: Icons.swap_vert_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exercise.startingPosition.isNotEmpty)
                      _LabeledText(label: 'Start', text: exercise.startingPosition),
                    if (exercise.endingPosition.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _LabeledText(label: 'End', text: exercise.endingPosition),
                    ],
                  ],
                ),
              ),
            if (exercise.coachNote.isNotEmpty)
              _Callout(
                icon: Icons.lightbulb_rounded,
                color: AppColors.primary,
                title: "Coach's note",
                text: exercise.coachNote,
              ),
            if (exercise.tips.isNotEmpty)
              _Section(
                title: 'Tips',
                icon: Icons.tips_and_updates_rounded,
                child: _BulletList(items: exercise.tips, color: AppColors.accent),
              ),
            if (exercise.commonMistakes.isNotEmpty)
              _Section(
                title: 'Common mistakes',
                icon: Icons.error_outline_rounded,
                child: _BulletList(items: exercise.commonMistakes, color: AppColors.warning),
              ),
            if (exercise.benefits.isNotEmpty)
              _Section(
                title: 'Benefits',
                icon: Icons.favorite_rounded,
                child: _BulletList(items: exercise.benefits, color: AppColors.win),
              ),
            if (exercise.safetyNotes.isNotEmpty)
              _Section(
                title: 'Safety notes',
                icon: Icons.shield_rounded,
                child: _BulletList(items: exercise.safetyNotes, color: AppColors.danger),
              ),
            if (exercise.tags.isNotEmpty)
              _Section(
                title: 'Tags',
                icon: Icons.sell_rounded,
                child: _ChipWrap(items: exercise.tags),
              ),
            if (exercise.variations.isNotEmpty)
              _Section(
                title: 'Variations',
                icon: Icons.alt_route_rounded,
                child: _RelatedExerciseList(exerciseIds: exercise.variations),
              ),
            if (exercise.alternativeExercises.isNotEmpty)
              _Section(
                title: 'Alternative exercises',
                icon: Icons.swap_horiz_rounded,
                child: _RelatedExerciseList(exerciseIds: exercise.alternativeExercises),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252B38)),
              ),
              child: Text(
                item,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.color});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary, height: 1.4, fontSize: 14),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedExerciseList extends ConsumerWidget {
  const _RelatedExerciseList({required this.exerciseIds});

  final List<String> exerciseIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: exerciseIds.map((id) {
        final relatedAsync = ref.watch(exerciseByIdProvider(id));
        final related = relatedAsync.valueOrNull;
        final label = related?.name ?? id;
        return ActionChip(
          label: Text(label),
          backgroundColor: AppColors.surfaceElevated,
          side: const BorderSide(color: Color(0xFF252B38)),
          labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          onPressed: related == null
              ? null
              : () => context.push('/workouts/exercise/$id'),
        );
      }).toList(),
    );
  }
}
