import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.timestamp,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int calories;
  final String mealType;
  final String? imageUrl;
  final DateTime timestamp;

  static const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  factory MealEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['timestamp'];
    return MealEntry(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      mealType: data['mealType'] as String? ?? 'Snack',
      imageUrl: data['imageUrl'] as String?,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'calories': calories,
        'mealType': mealType,
        'imageUrl': imageUrl,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
