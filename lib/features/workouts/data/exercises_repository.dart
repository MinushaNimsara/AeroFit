import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ExercisesRepository {
  ExercisesRepository({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _exercisesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('exercises');

  (DateTime, DateTime) _dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (start, start.add(const Duration(days: 1)));
  }

  (DateTime, DateTime) get _todayRange => _dayRange(DateTime.now());

  Stream<List<GymExercise>> watchTodayExercises(String uid) {
    final (start, end) = _todayRange;
    return _exercisesRef(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(GymExercise.fromFirestore).toList(),
        );
  }

  Stream<List<GymExercise>> watchExercisesForSplit(
    String uid,
    String splitId,
  ) {
    return _exercisesRef(uid)
        .where('splitId', isEqualTo: splitId)
        .snapshots()
        .map((snapshot) {
          final exercises =
              snapshot.docs.map(GymExercise.fromFirestore).toList();
          exercises.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return exercises;
        });
  }

  Future<void> addExercise({
    required String uid,
    required String splitId,
    required String name,
    required String weightOrSetting,
    required String notes,
    String? imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || splitId.isEmpty) return;

    final doc = _exercisesRef(uid).doc();
    await doc.set({
      'id': doc.id,
      'splitId': splitId,
      'name': trimmedName,
      'weightOrSetting': weightOrSetting.trim(),
      'notes': notes.trim(),
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set(
      {'lastWorkoutTimestamp': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteExercise({
    required String uid,
    required String exerciseId,
  }) {
    return _exercisesRef(uid).doc(exerciseId).delete();
  }

  Future<void> setExerciseCompletedToday({
    required String uid,
    required String exerciseId,
    required bool completed,
  }) {
    return _exercisesRef(uid).doc(exerciseId).update({
      'completedDate':
          completed ? GymExercise.dateKey() : FieldValue.delete(),
    });
  }
}
