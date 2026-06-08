/// Aggregated daily win/loss state for the dashboard hub.
class DailyStatus {
  const DailyStatus({
    required this.routineComplete,
    required this.dietOnTarget,
    required this.workoutComplete,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.gymExercisesCompleted,
    required this.gymExercisesTotal,
    required this.goalProgress,
  });

  final bool routineComplete;
  final bool dietOnTarget;
  final bool workoutComplete;
  final int tasksCompleted;
  final int tasksTotal;
  final int caloriesConsumed;
  final int calorieGoal;
  final int gymExercisesCompleted;
  final int gymExercisesTotal;
  /// 0.0 – 1.0 overall daily goal progress.
  final double goalProgress;

  bool get isDailyWin =>
      routineComplete && dietOnTarget && workoutComplete;

  int get caloriesRemaining =>
      (calorieGoal - caloriesConsumed).clamp(0, calorieGoal);

  int get tasksRemaining => (tasksTotal - tasksCompleted).clamp(0, tasksTotal);

  /// Green diet pill: within 85–100% of goal without exceeding.
  bool get dietCloseToTarget {
    if (calorieGoal <= 0) return false;
    final lower = (calorieGoal * 0.85).round();
    return caloriesConsumed >= lower && caloriesConsumed <= calorieGoal;
  }

  String get gymPillSubtitle {
    if (gymExercisesTotal == 0) return 'No exercises';
    return '$gymExercisesCompleted / $gymExercisesTotal Done';
  }

  factory DailyStatus.demo() => const DailyStatus(
        routineComplete: true,
        dietOnTarget: false,
        workoutComplete: false,
        tasksCompleted: 5,
        tasksTotal: 8,
        caloriesConsumed: 1420,
        calorieGoal: 2000,
        gymExercisesCompleted: 0,
        gymExercisesTotal: 0,
        goalProgress: 0.62,
      );
}
