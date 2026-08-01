class CoachWorkoutSchedule {
  const CoachWorkoutSchedule({
    required this.id,
    required this.name,
    required this.totalDays,
    required this.workoutPreview,
    required this.sourceCollection,
  });

  final String id;
  final String name;
  final int totalDays;
  final List<String> workoutPreview;
  final String sourceCollection;
}
