import 'package:aerofit/features/live_workout/domain/live_workout_status.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';

class TraineeProfileSnapshot {
  const TraineeProfileSnapshot({
    required this.displayName,
    required this.calorieGoal,
    required this.caloriesConsumed,
    required this.meals,
    required this.tasks,
    required this.liveStatus,
  });

  final String displayName;
  final int calorieGoal;
  final int caloriesConsumed;
  final List<MealEntry> meals;
  final List<RoutineTask> tasks;
  final LiveWorkoutStatus liveStatus;

  int get tasksCompleted => tasks.where((t) => t.isCompleted).length;

  bool get routineComplete => tasks.isNotEmpty && tasks.every((t) => t.isCompleted);
}
