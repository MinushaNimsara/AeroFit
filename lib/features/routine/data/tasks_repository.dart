import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class TasksRepository {
  TasksRepository({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  Stream<List<RoutineTask>> watchTasks(String uid) {
    return _tasksRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RoutineTask.fromFirestore).toList(),
        );
  }

  Future<void> addTask({
    required String uid,
    required String title,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final doc = _tasksRef(uid).doc();
    await doc.set({
      'id': doc.id,
      'title': trimmed,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCompleted({
    required String uid,
    required String taskId,
    required bool isCompleted,
  }) {
    return _tasksRef(uid).doc(taskId).update({'isCompleted': isCompleted});
  }

  Future<void> deleteTask({
    required String uid,
    required String taskId,
  }) {
    return _tasksRef(uid).doc(taskId).delete();
  }
}
