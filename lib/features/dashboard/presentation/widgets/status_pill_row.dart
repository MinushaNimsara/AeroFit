import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:aerofit/features/dashboard/presentation/widgets/daily_goal_ring.dart';
import 'package:aerofit/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Health overview grid: calories on top, routine and gym side by side.
class StatusPillRow extends StatelessWidget {
  const StatusPillRow({super.key, required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final calorieProgress = status.calorieGoal > 0
        ? status.caloriesConsumed / status.calorieGoal
        : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          StatTile(
            label: 'Daily Calorie Intake',
            icon: status.dietCloseToTarget
                ? Icons.check_rounded
                : Icons.local_fire_department_rounded,
            color: AppColors.accent,
            value: '${status.caloriesConsumed}',
            suffix: '/ ${status.calorieGoal} kcal',
            valueSize: 38,
            onTap: () => context.go('/meals'),
            trailing: DailyGoalRing(
              progress: calorieProgress,
              size: 64,
              lineWidth: 6,
              color: AppColors.accent,
              center: const Icon(
                Icons.restaurant_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Routine',
                  icon: status.routineComplete
                      ? Icons.check_rounded
                      : Icons.schedule_rounded,
                  color: AppColors.warning,
                  value: '${status.tasksCompleted}',
                  suffix: '/ ${status.tasksTotal} tasks',
                  onTap: () => context.go('/routine'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Gym',
                  icon: status.workoutComplete
                      ? Icons.check_rounded
                      : Icons.fitness_center_rounded,
                  color: AppColors.info,
                  value: '${status.gymExercisesCompleted}',
                  suffix: status.gymExercisesTotal == 0
                      ? 'No exercises'
                      : '/ ${status.gymExercisesTotal} done',
                  onTap: () => context.go('/workouts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
