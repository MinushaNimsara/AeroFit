import 'dart:async';

import 'package:image_picker/image_picker.dart';

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.name,
    required this.calories,
  });

  final String name;
  final int calories;
}

/// Mock AI food vision — replace with real API when ready.
class MealAnalyzerService {
  const MealAnalyzerService();

  Future<MealAnalysisResult> analyzeFoodFromImage(XFile image) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const MealAnalysisResult(
      name: 'Grilled Chicken & Rice',
      calories: 450,
    );
  }
}
