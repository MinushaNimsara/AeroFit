import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/meals/domain/meal_ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class MealsRepository {
  MealsRepository({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _mealsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('meals');

  (DateTime, DateTime) get _todayRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (start, start.add(const Duration(days: 1)));
  }

  Stream<List<MealEntry>> watchTodayMeals(String uid) {
    final (start, end) = _todayRange;
    return _mealsRef(uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MealEntry.fromFirestore).toList(),
        );
  }

  Future<void> addMeal({
    required String uid,
    required String name,
    required int calories,
    required String mealType,
    String? imageUrl,
    double protein = 0,
    double carbs = 0,
    double fats = 0,
    List<MealIngredient> ingredients = const [],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || calories < 0) return;

    final doc = _mealsRef(uid).doc();
    await doc.set({
      'id': doc.id,
      'name': trimmed,
      'calories': calories,
      'mealType': mealType,
      'imageUrl': imageUrl,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'ingredients': ingredients.map((item) => item.toMap()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMeal({
    required String uid,
    required String mealId,
  }) {
    return _mealsRef(uid).doc(mealId).delete();
  }
}
