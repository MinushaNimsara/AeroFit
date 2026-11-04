import 'dart:convert';

import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/features/meals/domain/meal_ingredient.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredients,
  });

  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final List<MealIngredient> ingredients;
}

/// Vision meal analysis via Cloud Function `analyzeMeal` (preferred)
/// with optional direct Gemini fallback for local/dev.
class MealAnalyzerService {
  MealAnalyzerService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _prompt = '''
You are a nutrition analysis engine. Study the food photo and return ONE JSON object only.

REQUIRED OUTPUT SHAPE (no markdown, no prose, no extra keys):
{
  "name": "Full meal title",
  "calories": 726,
  "protein": 29.33,
  "carbs": 72.17,
  "fats": 40.33,
  "ingredients": [
    {
      "name": "Cooked Red Rice",
      "calories": 226.67,
      "quantity": 0.75,
      "unit": "cup"
    },
    {
      "name": "Omelette (single egg)",
      "calories": 180,
      "quantity": 1,
      "unit": "piece"
    }
  ]
}

RULES:
- "name" = overall meal name (String).
- "calories" = total meal calories (number).
- "protein", "carbs", "fats" = TOTAL grams for the entire meal (numbers, not percentages).
- "ingredients" = array of every visible component on the plate (minimum 2 when multiple foods are visible).
- Each ingredient MUST include "name" (String), "calories" (number), "quantity" (number), and "unit" (String such as cup, piece, tbsp, g).
- Ingredient calories should sum close to total calories.
- Do NOT return only a flat title and total calories. Always include macros and ingredients.
''';

  Future<MealAnalysisResult> analyzeFoodFromImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final mimeType = _resolveMimeType(image);
    final base64Image = base64Encode(bytes);

    if (Env.useMealCloudFunction) {
      try {
        return await _analyzeViaCloudFunction(
          base64Image: base64Image,
          mimeType: mimeType,
        );
      } on FirebaseFunctionsException catch (e) {
        if (Env.geminiApiKey.trim().isNotEmpty &&
            (e.code == 'not-found' ||
                e.code == 'unavailable' ||
                e.code == 'failed-precondition')) {
          return _analyzeViaDirectGemini(
            base64Image: base64Image,
            mimeType: mimeType,
          );
        }
        throw Exception(_mapFunctionsError(e));
      }
    }

    return _analyzeViaDirectGemini(
      base64Image: base64Image,
      mimeType: mimeType,
    );
  }

  Future<MealAnalysisResult> _analyzeViaCloudFunction({
    required String base64Image,
    required String mimeType,
  }) async {
    final callable =
        FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
      'analyzeMeal',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(<String, dynamic>{
      'imageBase64': base64Image,
      'mimeType': mimeType,
      'model': Env.geminiModel,
    });

    final data = result.data;
    if (data is! Map) {
      throw Exception('Cloud Function returned invalid meal payload');
    }
    return _parseMealJson(
      _normalizeMealJson(Map<String, dynamic>.from(data)),
    );
  }

  Future<MealAnalysisResult> _analyzeViaDirectGemini({
    required String base64Image,
    required String mimeType,
  }) async {
    if (Env.geminiApiKey.trim().isEmpty) {
      throw Exception(
        'Meal analysis is not configured. Deploy Cloud Function '
        '`analyzeMeal` (GEMINI_API_KEY secret), or for local only rebuild with '
        '--dart-define=GEMINI_API_KEY=your-key.',
      );
    }

    final response = await _requestMealAnalysis(
      base64Image: base64Image,
      mimeType: mimeType,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Meal analysis API error ${response.statusCode}: ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = _extractCandidateText(payload);
    final mealJson = _decodeMealJson(rawText);
    return _parseMealJson(mealJson);
  }

  String _mapFunctionsError(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => 'Sign in required to analyze meal photos.',
      'invalid-argument' => e.message ?? 'Invalid meal photo request.',
      'failed-precondition' =>
        'Meal analysis is not configured on the server yet.',
      'resource-exhausted' => 'Meal analysis quota exceeded. Try again later.',
      'deadline-exceeded' => 'Meal analysis timed out. Try a smaller photo.',
      _ => e.message ?? 'Meal analysis failed (${e.code}).',
    };
  }

  Future<http.Response> _requestMealAnalysis({
    required String base64Image,
    required String mimeType,
  }) async {
    final primaryModel = _normalizeModelId(Env.geminiModel);
    final fallbackModels = <String>[
      primaryModel,
      'gemini-flash-latest',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
      'gemini-flash-lite-latest',
    ];
    final seen = <String>{};
    final attempts =
        <({String apiVersion, String modelId, bool useStructuredJson})>[];
    for (final modelId in fallbackModels) {
      if (!seen.add(modelId)) continue;
      attempts.add((
        apiVersion: 'v1beta',
        modelId: modelId,
        useStructuredJson: _modelSupportsStructuredJson(modelId),
      ));
    }
    attempts.add((
      apiVersion: 'v1',
      modelId: primaryModel,
      useStructuredJson: false,
    ));

    http.Response? lastResponse;
    for (final attempt in attempts) {
      var response = await _generateContent(
        apiVersion: attempt.apiVersion,
        modelId: attempt.modelId,
        base64Image: base64Image,
        mimeType: mimeType,
        useStructuredJson: attempt.useStructuredJson,
      );
      lastResponse = response;

      if (response.statusCode == 200) {
        return response;
      }

      if (response.statusCode == 400) {
        final body = response.body;
        if (attempt.useStructuredJson &&
            (body.contains('responseMimeType') ||
                body.contains('response_mime_type'))) {
          response = await _generateContent(
            apiVersion: attempt.apiVersion,
            modelId: attempt.modelId,
            base64Image: base64Image,
            mimeType: mimeType,
            useStructuredJson: false,
          );
          lastResponse = response;
          if (response.statusCode == 200) {
            return response;
          }
        }
        if (body.toLowerCase().contains('thinking')) {
          response = await _generateContent(
            apiVersion: attempt.apiVersion,
            modelId: attempt.modelId,
            base64Image: base64Image,
            mimeType: mimeType,
            useStructuredJson: false,
            disableThinking: false,
          );
          lastResponse = response;
          if (response.statusCode == 200) {
            return response;
          }
        }
      }

      // Try the next model when this one is missing or retired for the key.
      if (_shouldTryNextModel(response.statusCode, response.body)) {
        continue;
      }
      return response;
    }

    return lastResponse ??
        http.Response('No Gemini model attempts were made.', 500);
  }

  Future<http.Response> _generateContent({
    required String apiVersion,
    required String modelId,
    required String base64Image,
    required String mimeType,
    required bool useStructuredJson,
    bool disableThinking = true,
  }) {
    final uri = _buildGenerateContentUri(
      apiVersion: apiVersion,
      modelId: modelId,
    );

    final generationConfig = <String, dynamic>{'temperature': 0.15};
    if (disableThinking) {
      // Gemini 3.x / 2.5 default to thinking; thoughts come back as the first
      // part and meal JSON parsing used to swallow them as the whole reply.
      generationConfig['thinkingConfig'] = {'thinkingBudget': 0};
    }
    if (useStructuredJson) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    return _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': Env.geminiApiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': _prompt},
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': generationConfig,
          }),
        )
        .timeout(const Duration(seconds: 60));
  }

  Uri _buildGenerateContentUri({
    required String apiVersion,
    required String modelId,
  }) {
    return Uri.https(
      'generativelanguage.googleapis.com',
      '/$apiVersion/models/$modelId:generateContent',
    );
  }

  bool _shouldTryNextModel(int statusCode, String body) {
    if (statusCode == 404) return true;
    final lower = body.toLowerCase();
    return lower.contains('no longer available') ||
        lower.contains('is not found') ||
        lower.contains('not supported');
  }

  String _normalizeModelId(String raw) {
    var model = raw.trim();
    if (model.startsWith('models/')) {
      model = model.substring('models/'.length);
    }
    if (model.endsWith(':generateContent')) {
      model = model.substring(0, model.length - ':generateContent'.length);
    }
    return model;
  }

  bool _modelSupportsStructuredJson(String model) {
    final normalized = _normalizeModelId(model).toLowerCase();
    if (normalized == 'gemini-pro' || normalized.startsWith('gemini-1.0')) {
      return false;
    }
    return normalized.contains('1.5') ||
        normalized.contains('2.0') ||
        normalized.contains('2.5') ||
        normalized.contains('3.') ||
        normalized.contains('flash-latest');
  }

  Map<String, dynamic> _decodeMealJson(String rawText) {
    final cleaned = _cleanJsonText(rawText);
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return _normalizeMealJson(decoded);
      }
      if (decoded is Map) {
        return _normalizeMealJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Fall through to object extraction.
    }

    final extracted = _extractJsonObject(cleaned);
    if (extracted != null) {
      return _normalizeMealJson(extracted);
    }

    throw Exception('AI response was not valid JSON');
  }

  Map<String, dynamic> _normalizeMealJson(Map<String, dynamic> raw) {
    var map = Map<String, dynamic>.from(raw);

    for (final wrapperKey in ['meal', 'data', 'result', 'analysis', 'food']) {
      final nested = map[wrapperKey];
      if (nested is Map) {
        map = Map<String, dynamic>.from(nested);
        break;
      }
    }

    final macros =
        map['macros'] ?? map['macro'] ?? map['nutrition'] ?? map['nutrients'];
    if (macros is Map) {
      final macroMap = Map<String, dynamic>.from(macros);
      map['protein'] ??= macroMap['protein'] ??
          macroMap['protein_g'] ??
          macroMap['proteinGrams'] ??
          macroMap['proteins'];
      map['carbs'] ??= macroMap['carbs'] ??
          macroMap['carbohydrates'] ??
          macroMap['carbohydrates_g'] ??
          macroMap['carbs_g'];
      map['fats'] ??= macroMap['fats'] ??
          macroMap['fat'] ??
          macroMap['fat_g'] ??
          macroMap['fats_g'];
    }

    map['protein'] ??=
        map['protein_g'] ?? map['proteinGrams'] ?? map['proteins'];
    map['carbs'] ??= map['carbohydrates'] ??
        map['carbohydrates_g'] ??
        map['carbs_g'] ??
        map['carbohydrate'];
    map['fats'] ??= map['fat'] ?? map['fat_g'] ?? map['fats_g'];

    map['ingredients'] ??= map['items'] ??
        map['components'] ??
        map['foods'] ??
        map['ingredient_list'];

    return map;
  }

  MealAnalysisResult _parseMealJson(Map<String, dynamic> json) {
    final name =
        _readString(json['name'] ?? json['meal_name'] ?? json['title']);
    if (name == null || name.isEmpty) {
      throw Exception('AI response missing meal name');
    }

    final calories =
        _readInt(json['calories'] ?? json['total_calories'] ?? json['kcal']);
    if (calories == null || calories < 0) {
      throw Exception('AI response missing valid calories');
    }

    var ingredients = parseMealIngredients(json['ingredients']);
    if (ingredients.isEmpty) {
      ingredients = _ingredientsFromLooseList(json['ingredients']);
    }

    var protein = _readMacro(json['protein']);
    var carbs = _readMacro(json['carbs']);
    var fats = _readMacro(json['fats']);

    final ingredientMacros = _sumIngredientMacros(ingredients);
    if (protein <= 0 && ingredientMacros.protein > 0) {
      protein = ingredientMacros.protein;
    }
    if (carbs <= 0 && ingredientMacros.carbs > 0) {
      carbs = ingredientMacros.carbs;
    }
    if (fats <= 0 && ingredientMacros.fats > 0) {
      fats = ingredientMacros.fats;
    }

    if (protein <= 0 && carbs <= 0 && fats <= 0 && calories > 0) {
      final estimated = _estimateMacrosFromCalories(calories);
      protein = estimated.protein;
      carbs = estimated.carbs;
      fats = estimated.fats;
    }

    if (ingredients.isEmpty && calories > 0) {
      ingredients = [
        MealIngredient(
          name: name,
          calories: calories.toDouble(),
          quantity: 1,
          unit: 'serving',
        ),
      ];
    }

    return MealAnalysisResult(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: ingredients,
    );
  }

  List<MealIngredient> _ingredientsFromLooseList(dynamic raw) {
    if (raw is! List) return const [];

    final results = <MealIngredient>[];
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        results.add(
          MealIngredient(
            name: entry.trim(),
            calories: 0,
            quantity: 1,
            unit: 'serving',
          ),
        );
        continue;
      }
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        if (map['name'] == null && map['item'] is String) {
          map['name'] = map['item'];
        }
        if (map['calories'] == null && map['kcal'] != null) {
          map['calories'] = map['kcal'];
        }
        results.add(MealIngredient.fromMap(map));
      }
    }
    return results
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
  }

  ({double protein, double carbs, double fats}) _sumIngredientMacros(
    List<MealIngredient> ingredients,
  ) {
    var protein = 0.0;
    var carbs = 0.0;
    var fats = 0.0;
    for (final item in ingredients) {
      protein += item.protein;
      carbs += item.carbs;
      fats += item.fats;
    }
    return (protein: protein, carbs: carbs, fats: fats);
  }

  ({double protein, double carbs, double fats}) _estimateMacrosFromCalories(
      int calories) {
    return (
      protein: (calories * 0.25) / 4,
      carbs: (calories * 0.45) / 4,
      fats: (calories * 0.30) / 9,
    );
  }

  String? _readString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  int? _readInt(dynamic value) {
    return switch (value) {
      final int v => v,
      final num v => v.round(),
      final String v => () {
          final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
          return parsed?.round();
        }(),
      _ => null,
    };
  }

  double _readMacro(dynamic value) {
    return switch (value) {
      final num v => v < 0 ? 0.0 : v.toDouble(),
      final String v => double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''))
              ?.clamp(0.0, double.infinity) ??
          0.0,
      _ => 0.0,
    };
  }

  Map<String, dynamic>? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _extractCandidateText(Map<String, dynamic> payload) {
    final candidates = payload['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('AI returned no candidates');
    }

    final content = candidates.first as Map<String, dynamic>;
    final inner = content['content'] is Map
        ? Map<String, dynamic>.from(content['content'] as Map)
        : content;
    final parts = inner['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('AI returned empty content');
    }

    final answer = StringBuffer();
    final thoughts = StringBuffer();
    for (final part in parts) {
      if (part is! Map) continue;
      final map = Map<String, dynamic>.from(part);
      final text = map['text'];
      if (text is! String || text.trim().isEmpty) continue;
      if (map['thought'] == true) {
        thoughts.write(text);
      } else {
        answer.write(text);
      }
    }

    final resolved = answer.toString().trim().isNotEmpty
        ? answer.toString()
        : thoughts.toString();
    if (resolved.trim().isEmpty) {
      throw Exception('AI returned no text response');
    }
    return resolved;
  }

  String _cleanJsonText(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(
          RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return text.trim();
  }

  void dispose() => _client.close();

  String _resolveMimeType(XFile image) {
    final mime = image.mimeType;
    if (mime != null && mime.isNotEmpty) return mime;

    final path = image.path.isNotEmpty ? image.path : image.name;
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
