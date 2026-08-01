/// A single exercise chosen while building a coach routine — either linked
/// to the bundled exercise library catalog (`exerciseId` set) or a freeform
/// custom entry (`exerciseId` null).
class RoutineExerciseSelection {
  const RoutineExerciseSelection({required this.name, this.exerciseId});

  final String name;
  final String? exerciseId;

  Map<String, dynamic> toMap() => {
        'name': name,
        if (exerciseId != null && exerciseId!.isNotEmpty)
          'exerciseId': exerciseId,
      };
}

class CoachWorkoutTemplate {
  const CoachWorkoutTemplate({
    required this.id,
    required this.name,
    required this.totalDays,
    required this.exercisePreview,
    required this.gymName,
  });

  final String id;
  final String name;
  final int totalDays;
  final List<String> exercisePreview;
  final String? gymName;
}
