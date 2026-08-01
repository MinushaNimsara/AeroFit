import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSessionHistory {
  const WorkoutSessionHistory({
    required this.id,
    required this.routineName,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.durationMinutes,
    required this.endedAt,
    this.startedAt,
  });

  final String id;
  final String routineName;
  final int exercisesCompleted;
  final int totalExercises;
  final int durationMinutes;
  final DateTime endedAt;
  final DateTime? startedAt;

  factory WorkoutSessionHistory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? parseTs(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return WorkoutSessionHistory(
      id: data['id'] as String? ?? doc.id,
      routineName: (data['routineName'] as String?)?.trim() ?? '',
      exercisesCompleted: (data['exercisesCompleted'] as num?)?.round() ?? 0,
      totalExercises: (data['totalExercises'] as num?)?.round() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.round() ?? 0,
      startedAt: parseTs(data['startedAt']),
      endedAt: parseTs(data['endedAt']) ?? DateTime.now(),
    );
  }
}
