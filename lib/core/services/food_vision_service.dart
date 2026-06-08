import 'dart:convert';

import 'package:aerofit/core/config/env.dart';
import 'package:http/http.dart' as http;

class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.label,
  });

  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final String? label;

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      calories: (json['calories'] as num).round(),
      proteinG: (json['protein_g'] as num).toDouble(),
      carbsG: (json['carbs_g'] as num).toDouble(),
      fatsG: (json['fats_g'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }
}

/// Sends food images to your FastAPI/Flask backend or external Vision API.
class FoodVisionService {
  FoodVisionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FoodAnalysisResult> analyzeImage(List<int> imageBytes) async {
    final uri = Uri.parse(Env.foodVisionApiUrl);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: 'meal.jpg'),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Food vision API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FoodAnalysisResult.fromJson(json);
  }
}
