import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class WorkoutSplitsRepository {
  WorkoutSplitsRepository({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _splitsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('workout_splits');

  Stream<List<WorkoutSplit>> watchSplits(String uid) {
    return _splitsRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(WorkoutSplit.fromFirestore).toList(),
        );
  }

  Future<String> createSplit({
    required String uid,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Split name cannot be empty');
    }

    final doc = _splitsRef(uid).doc();
    await doc.set({
      'id': doc.id,
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deleteSplit({
    required String uid,
    required String splitId,
  }) {
    return _splitsRef(uid).doc(splitId).delete();
  }
}
