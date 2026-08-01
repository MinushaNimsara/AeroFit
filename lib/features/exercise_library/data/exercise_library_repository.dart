import 'dart:convert';

import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled 729-exercise reference catalog from
/// `assets/data/exercises/*.json` and caches it in memory for the lifetime
/// of the app. This is static reference data, so it is never fetched from
/// Firestore.
class ExerciseLibraryRepository {
  ExerciseLibraryRepository();

  static const List<String> _categoryFiles = [
    'athletic_performance',
    'back',
    'biceps',
    'calisthenics',
    'cardio',
    'chest',
    'core',
    'forearms',
    'full_body',
    'legs',
    'mobility',
    'shoulders',
    'triceps',
  ];

  List<Exercise>? _cache;
  Map<String, Exercise>? _byId;

  Future<List<Exercise>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final exercises = <Exercise>[];
    for (final file in _categoryFiles) {
      try {
        final raw = await rootBundle
            .loadString('assets/data/exercises/$file.json');
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            exercises.add(Exercise.fromJson(item));
          } else if (item is Map) {
            exercises.add(Exercise.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } catch (_) {
        // Skip a malformed/missing category file rather than failing the
        // whole library load.
      }
    }

    exercises.sort((a, b) => a.name.compareTo(b.name));
    _cache = List.unmodifiable(exercises);
    _byId = {for (final e in exercises) e.id: e};
    return _cache!;
  }

  Future<Exercise?> findById(String id) async {
    if (_byId == null) await loadAll();
    return _byId?[id];
  }
}
