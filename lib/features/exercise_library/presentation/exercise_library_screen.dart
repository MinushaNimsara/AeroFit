import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_filter_bar.dart';
import 'package:aerofit/features/exercise_library/presentation/widgets/exercise_list_card.dart';
import 'package:aerofit/features/exercise_library/providers/exercise_library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(exerciseLibraryProvider);
    final filtered = ref.watch(filteredExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
      ),
      body: libraryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load the exercise library: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (all) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const ExerciseFilterBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      '${filtered.length} of ${all.length} exercises',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyState(totalCount: all.length)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              return ExerciseListCard(
                                exercise: exercise,
                                onTap: () => context
                                    .push('/workouts/exercise/${exercise.id}'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises match your filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or clear a filter. There are $totalCount exercises in the library.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
