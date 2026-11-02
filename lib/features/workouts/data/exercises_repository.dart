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

  /// Prefer manual [GymExercise.sortOrder]; legacy docs (all 0) fall back to
  /// oldest-first timestamp so the list stays stable until the user reorders.
  static int compareBySortOrder(GymExercise a, GymExercise b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    if (byOrder != 0) return byOrder;
    return a.timestamp.compareTo(b.timestamp);
  }

  Stream<List<GymExercise>> watchTodayExercises(String uid) {
    final (start, end) = _todayRange;
    return _exercisesRef(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final exercises =
              snapshot.docs.map(GymExercise.fromFirestore).toList();
          exercises.sort(compareBySortOrder);
          return exercises;
        });
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
          exercises.sort(compareBySortOrder);
          return exercises;
        });
  }

  Future<int> _nextSortOrder({
    required String uid,
    required String splitId,
  }) async {
    final snapshot =
        await _exercisesRef(uid).where('splitId', isEqualTo: splitId).get();
    var maxOrder = -1;
    for (final doc in snapshot.docs) {
      final raw = doc.data()['sortOrder'];
      final order = raw is int
          ? raw
          : raw is num
              ? raw.toInt()
              : -1;
      if (order > maxOrder) maxOrder = order;
    }
    return maxOrder + 1;
  }

  Future<void> addExercise({
    required String uid,
    required String splitId,
    required String name,
    required String weightOrSetting,
    required String notes,
    String? imageUrl,
    String? exerciseId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || splitId.isEmpty) return;

    final sortOrder = await _nextSortOrder(uid: uid, splitId: splitId);
    final doc = _exercisesRef(uid).doc();
    await doc.set({
      'id': doc.id,
      'splitId': splitId,
      'name': trimmedName,
      'weightOrSetting': weightOrSetting.trim(),
      'notes': notes.trim(),
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      if (exerciseId != null && exerciseId.isNotEmpty) 'exerciseId': exerciseId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set(
      {'lastWorkoutTimestamp': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Persists list order as `sortOrder` 0..n-1 for [orderedIds].
  Future<void> reorderExercises({
    required String uid,
    required List<String> orderedIds,
  }) async {
    if (orderedIds.isEmpty) return;

    final batch = _firestore.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i].trim();
      if (id.isEmpty) continue;
      batch.update(_exercisesRef(uid).doc(id), {'sortOrder': i});
    }
    await batch.commit();
  }

  Future<void> deleteExercise({
    required String uid,
    required String exerciseId,
  }) {
    return _exercisesRef(uid).doc(exerciseId).delete();
  }

  /// Deletes every exercise under [splitId] — used when the whole split is
  /// removed so exercises don't get orphaned in Firestore.
  Future<void> deleteExercisesForSplit({
    required String uid,
    required String splitId,
  }) async {
    final snapshot =
        await _exercisesRef(uid).where('splitId', isEqualTo: splitId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
