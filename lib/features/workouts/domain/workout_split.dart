import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSplit {
  const WorkoutSplit({
    required this.id,
    required this.name,
    this.createdAt,
  });

  final String id;
  final String name;
  final DateTime? createdAt;

  factory WorkoutSplit.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    return WorkoutSplit(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
