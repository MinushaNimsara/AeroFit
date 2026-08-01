import 'package:cloud_firestore/cloud_firestore.dart';

class GymExercise {
  const GymExercise({
    required this.id,
    required this.name,
    required this.weightOrSetting,
    required this.notes,
    required this.timestamp,
    required this.splitId,
    this.imageUrl,
    this.exerciseId,
    this.completedDate,
  });

  final String id;
  final String name;
  final String weightOrSetting;
  final String notes;
  final String splitId;
  final String? imageUrl;
  /// Links back to the bundled exercise library catalog (see
  /// `features/exercise_library`) so the app can resolve instructions,
  /// muscle group, and category artwork. Null for freeform custom entries.
  final String? exerciseId;
  final DateTime timestamp;
  /// `YYYY-MM-DD` when last checked off; compared to today for daily reset.
  final String? completedDate;

  static String dateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  bool get isCompletedToday =>
      completedDate != null &&
      completedDate!.isNotEmpty &&
      completedDate == dateKey();

  factory GymExercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['timestamp'];
    return GymExercise(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      weightOrSetting: data['weightOrSetting'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      splitId: data['splitId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      exerciseId: data['exerciseId'] as String?,
      completedDate: data['completedDate'] as String?,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'weightOrSetting': weightOrSetting,
        'notes': notes,
        'splitId': splitId,
        'imageUrl': imageUrl,
        if (exerciseId != null) 'exerciseId': exerciseId,
        if (completedDate != null) 'completedDate': completedDate,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
