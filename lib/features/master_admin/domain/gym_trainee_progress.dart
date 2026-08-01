class GymTraineeProgress {
  const GymTraineeProgress({
    required this.uid,
    required this.displayName,
    required this.caloriesConsumed,
    required this.calorieGoal,
    this.lastActiveAt,
  });

  final String uid;
  final String displayName;
  final int caloriesConsumed;
  final int calorieGoal;
  final DateTime? lastActiveAt;

  double get progress =>
      calorieGoal > 0 ? (caloriesConsumed / calorieGoal).clamp(0.0, 1.5) : 0;
}
