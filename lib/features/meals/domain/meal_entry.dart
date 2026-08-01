import 'package:aerofit/features/meals/domain/meal_ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.timestamp,
    this.imageUrl,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.ingredients = const [],
  });

  final String id;
  final String name;
  final int calories;
  final String mealType;
  final String? imageUrl;
  final DateTime timestamp;
  final double protein;
  final double carbs;
  final double fats;
  final List<MealIngredient> ingredients;

  static const mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  bool get hasMacroBreakdown => protein > 0 || carbs > 0 || fats > 0;

  bool get hasIngredients => ingredients.isNotEmpty;

  List<MealIngredient> get displayIngredients {
    if (ingredients.isNotEmpty) return ingredients;
    if (name.trim().isEmpty && calories <= 0) return const [];
    return [
      MealIngredient(
        name: name.trim().isEmpty ? 'Meal total' : name.trim(),
        calories: calories.toDouble(),
        quantity: 1,
        unit: 'serving',
      ),
    ];
  }

  factory MealEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MealEntry.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory MealEntry.fromMap(Map<String, dynamic> data, {String? id}) {
    final ts = data['timestamp'];

    return MealEntry(
      id: data['id'] as String? ?? id ?? '',
      name: data['name'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      mealType: data['mealType'] as String? ?? 'Snack',
      imageUrl: data['imageUrl'] as String?,
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      protein: _readMacro(data['protein']),
      carbs: _readMacro(data['carbs']),
      fats: _readMacro(data['fats']),
      ingredients: parseMealIngredients(data['ingredients']),
    );
  }

  static double _readMacro(dynamic value) {
    return switch (value) {
      final num v => v < 0 ? 0.0 : v.toDouble(),
      final String v => double.tryParse(v)?.clamp(0.0, double.infinity) ?? 0.0,
      _ => 0.0,
    };
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'calories': calories,
        'mealType': mealType,
        'imageUrl': imageUrl,
        'timestamp': Timestamp.fromDate(timestamp),
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
      };
}

/// Daily macro targets derived from calorie goal (30/40/30 split).
class MealMacroGoals {
  const MealMacroGoals({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatsGrams,
  });

  final double proteinGrams;
  final double carbsGrams;
  final double fatsGrams;

  factory MealMacroGoals.fromCalorieGoal(int calorieGoal) {
    final goal = calorieGoal > 0 ? calorieGoal : 2000;
    return MealMacroGoals(
      proteinGrams: (goal * 0.30) / 4,
      carbsGrams: (goal * 0.40) / 4,
      fatsGrams: (goal * 0.30) / 9,
    );
  }
}
