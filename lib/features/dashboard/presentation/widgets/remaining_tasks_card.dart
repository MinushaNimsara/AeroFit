import 'package:aerofit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RemainingTasksCard extends StatelessWidget {
  const RemainingTasksCard({
    super.key,
    required this.completed,
    required this.total,
    required this.caloriesRemaining,
    required this.calorieGoal,
  });

  final int completed;
  final int total;
  final int caloriesRemaining;
  final int calorieGoal;

  @override
  Widget build(BuildContext context) {
    final tasksLeft = (total - completed).clamp(0, total);
    final taskProgress = total > 0 ? completed / total : 0.0;
    final dietProgress =
        calorieGoal > 0 ? 1 - (caloriesRemaining / calorieGoal) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today at a glance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              icon: Icons.task_alt_rounded,
              title: 'Tasks remaining',
              value: '$tasksLeft of $total',
              progress: taskProgress,
              progressColor: AppColors.primary,
            ),
            const SizedBox(height: 14),
            _SummaryRow(
              icon: Icons.restaurant_menu_rounded,
              title: 'Calories left',
              value: '$caloriesRemaining / $calorieGoal kcal',
              progress: dietProgress.clamp(0.0, 1.0),
              progressColor: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
    required this.progressColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final double progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.ringTrack,
            color: progressColor,
          ),
        ),
      ],
    );
  }
}
