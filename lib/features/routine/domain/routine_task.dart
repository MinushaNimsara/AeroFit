import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  factory RoutineTask.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    return RoutineTask(
      id: data['id'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
