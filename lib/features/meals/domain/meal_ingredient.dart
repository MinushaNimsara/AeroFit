class MealIngredient {
  const MealIngredient({
    required this.name,
    required this.calories,
    required this.quantity,
    this.unit,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  final String name;
  final double calories;
  final double quantity;
  final String? unit;
  final double protein;
  final double carbs;
  final double fats;

  factory MealIngredient.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['item'] ?? map['food'] ?? map['title'];
    final name = rawName is String ? rawName.trim() : '';

    final calories = _readDouble(
      map['calories'] ?? map['kcal'] ?? map['calorie'] ?? map['energy'],
    );

    final parsedPortion = _parsePortion(map['portion'] ?? map['serving']);
    final quantity = parsedPortion?.quantity ??
        _readDouble(map['quantity'] ?? map['qty'] ?? map['amount'], fallback: 1.0);
    final unit = parsedPortion?.unit ??
        _readUnit(map['unit'] ?? map['measure'] ?? map['serving_unit']);

    return MealIngredient(
      name: name.isEmpty ? 'Ingredient' : name,
      calories: calories < 0 ? 0.0 : calories,
      quantity: quantity < 0 ? 0.0 : quantity,
      unit: unit,
      protein: _readDouble(map['protein'] ?? map['protein_g']),
      carbs: _readDouble(map['carbs'] ?? map['carbohydrates'] ?? map['carbohydrates_g']),
      fats: _readDouble(map['fats'] ?? map['fat'] ?? map['fat_g']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (protein > 0) 'protein': protein,
        if (carbs > 0) 'carbs': carbs,
        if (fats > 0) 'fats': fats,
      };

  String get portionLabel {
    final qtyText = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString().padLeft(2, '0')
        : _formatQuantity(quantity);
    if (unit != null && unit!.isNotEmpty) {
      return '$qtyText $unit';
    }
    return qtyText;
  }

  static String _formatQuantity(double value) {
    final rounded = (value * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(2);
  }

  static double _readDouble(dynamic value, {double fallback = 0.0}) {
    return switch (value) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback,
      _ => fallback,
    };
  }

  static String? _readUnit(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static ({double quantity, String? unit})? _parsePortion(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final match = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(value.trim());
    if (match == null) return null;
    final qty = double.tryParse(match.group(1) ?? '') ?? 1.0;
    final unit = match.group(2)?.trim();
    return (quantity: qty, unit: unit != null && unit.isNotEmpty ? unit : null);
  }
}

List<MealIngredient> parseMealIngredients(dynamic raw) {
  if (raw is! List) return const [];

  return raw
      .map((item) {
        if (item is Map) {
          return MealIngredient.fromMap(Map<String, dynamic>.from(item));
        }
        if (item is String && item.trim().isNotEmpty) {
          return MealIngredient(
            name: item.trim(),
            calories: 0,
            quantity: 1,
            unit: 'serving',
          );
        }
        return null;
      })
      .whereType<MealIngredient>()
      .where((item) => item.name.isNotEmpty)
      .toList(growable: false);
}
