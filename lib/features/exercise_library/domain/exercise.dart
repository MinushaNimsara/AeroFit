enum ExerciseDifficulty { beginner, intermediate, advanced }

ExerciseDifficulty _parseDifficulty(dynamic raw) {
  final value = (raw is String ? raw : '').trim().toLowerCase();
  return switch (value) {
    'advanced' => ExerciseDifficulty.advanced,
    'intermediate' => ExerciseDifficulty.intermediate,
    _ => ExerciseDifficulty.beginner,
  };
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Object>()
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

/// A single entry from the bundled 729-exercise reference library
/// (`assets/data/exercises/*.json`). Purely static/local data — not stored
/// in Firestore. Trainee splits and coach routines reference exercises by
/// [id] so images/instructions can be resolved back to this catalog.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscle,
    required this.difficulty,
    required this.equipment,
    required this.image,
    required this.secondaryMuscles,
    required this.exerciseType,
    required this.movementPattern,
    required this.forceType,
    required this.planeOfMotion,
    required this.unilateral,
    required this.trainingGoals,
    required this.instructions,
    required this.coachNote,
    required this.tips,
    required this.commonMistakes,
    required this.benefits,
    required this.safetyNotes,
    required this.alternativeExercises,
    required this.variations,
    required this.startingPosition,
    required this.endingPosition,
    required this.tags,
  });

  final String id;
  final String name;
  final String category;
  final String primaryMuscle;
  final ExerciseDifficulty difficulty;
  final List<String> equipment;
  final String image;
  final List<String> secondaryMuscles;
  final String exerciseType;
  final String movementPattern;
  final String forceType;
  final String planeOfMotion;
  final bool unilateral;
  final List<String> trainingGoals;
  final List<String> instructions;
  final String coachNote;
  final List<String> tips;
  final List<String> commonMistakes;
  final List<String> benefits;
  final List<String> safetyNotes;
  final List<String> alternativeExercises;
  final List<String> variations;
  final String startingPosition;
  final String endingPosition;
  final List<String> tags;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      primaryMuscle: (json['primaryMuscle'] as String? ?? '').trim(),
      difficulty: _parseDifficulty(json['difficulty']),
      equipment: _stringList(json['equipment']),
      image: (json['image'] as String? ?? '').trim(),
      secondaryMuscles: _stringList(json['secondaryMuscles']),
      exerciseType: (json['exerciseType'] as String? ?? '').trim(),
      movementPattern: (json['movementPattern'] as String? ?? '').trim(),
      forceType: (json['forceType'] as String? ?? '').trim(),
      planeOfMotion: (json['planeOfMotion'] as String? ?? '').trim(),
      unilateral: json['unilateral'] == true,
      trainingGoals: _stringList(json['trainingGoals']),
      instructions: _stringList(json['instructions']),
      coachNote: (json['coachNote'] as String? ?? '').trim(),
      tips: _stringList(json['tips']),
      commonMistakes: _stringList(json['commonMistakes']),
      benefits: _stringList(json['benefits']),
      safetyNotes: _stringList(json['safetyNotes']),
      alternativeExercises: _stringList(json['alternativeExercises']),
      variations: _stringList(json['variations']),
      startingPosition: (json['startingPosition'] as String? ?? '').trim(),
      endingPosition: (json['endingPosition'] as String? ?? '').trim(),
      tags: _stringList(json['tags']),
    );
  }

  String get difficultyLabel => switch (difficulty) {
        ExerciseDifficulty.beginner => 'Beginner',
        ExerciseDifficulty.intermediate => 'Intermediate',
        ExerciseDifficulty.advanced => 'Advanced',
      };

  String get equipmentSummary =>
      equipment.isEmpty ? 'Bodyweight' : equipment.join(', ');
}
