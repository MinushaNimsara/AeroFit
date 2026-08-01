import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/coach/domain/coach_workout_template.dart';
import 'package:aerofit/features/coach/presentation/widgets/create_routine_dialog.dart';
import 'package:flutter/material.dart';

class CoachRoutineBuilderSection extends StatelessWidget {
  const CoachRoutineBuilderSection({
    super.key,
    required this.templates,
    required this.isLoading,
    this.error,
    required this.onCreate,
  });

  final List<CoachWorkoutTemplate> templates;
  final bool isLoading;
  final Object? error;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Workout Routine Builder',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Routine'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (error != null)
              Text(
                'Could not load routines: $error',
                style: const TextStyle(color: AppColors.danger),
              )
            else if (templates.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252B38)),
                ),
                child: Text(
                  'No workout templates yet. Create your first gym routine schedule.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF252B38)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${template.totalDays} day schedule · ${template.exercisePreview.length} exercises',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (template.exercisePreview.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: template.exercisePreview
                                .map(
                                  (exercise) => Chip(
                                    label: Text(
                                      exercise,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.12),
                                    side: BorderSide.none,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCreateRoutineDialog(BuildContext context, VoidCallback onSaved) {
  return showDialog<void>(
    context: context,
    builder: (context) => CreateRoutineDialog(onSaved: onSaved),
  );
}
