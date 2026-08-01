import 'package:aerofit/features/exercise_library/data/exercise_library_repository.dart';
import 'package:aerofit/features/exercise_library/domain/exercise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exerciseLibraryRepositoryProvider =
    Provider<ExerciseLibraryRepository>((ref) => ExerciseLibraryRepository());

/// Full 729-exercise catalog, loaded once from bundled JSON assets.
final exerciseLibraryProvider = FutureProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseLibraryRepositoryProvider);
  return repo.loadAll();
});

/// Sorted distinct category names, e.g. "Chest", "Back", "Cardio".
final exerciseCategoriesProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(exerciseLibraryProvider).valueOrNull ?? const [];
  final categories = exercises.map((e) => e.category).toSet().toList()..sort();
  return categories;
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final exerciseCategoryFilterProvider = StateProvider<String?>((ref) => null);
final exerciseDifficultyFilterProvider =
    StateProvider<ExerciseDifficulty?>((ref) => null);
final exerciseEquipmentFilterProvider = StateProvider<String?>((ref) => null);

/// Sorted distinct equipment names across the whole catalog, used to
/// populate the equipment filter.
final exerciseEquipmentOptionsProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(exerciseLibraryProvider).valueOrNull ?? const [];
  final equipment = <String>{};
  for (final e in exercises) {
    equipment.addAll(e.equipment);
  }
  final list = equipment.toList()..sort();
  return list;
});

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(exerciseLibraryProvider).valueOrNull ?? const [];
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(exerciseCategoryFilterProvider);
  final difficulty = ref.watch(exerciseDifficultyFilterProvider);
  final equipment = ref.watch(exerciseEquipmentFilterProvider);

  return exercises.where((exercise) {
    if (category != null && exercise.category != category) return false;
    if (difficulty != null && exercise.difficulty != difficulty) return false;
    if (equipment != null && !exercise.equipment.contains(equipment)) {
      return false;
    }
    if (query.isEmpty) return true;
    return exercise.name.toLowerCase().contains(query) ||
        exercise.primaryMuscle.toLowerCase().contains(query) ||
        exercise.tags.any((t) => t.toLowerCase().contains(query)) ||
        exercise.equipment.any((eq) => eq.toLowerCase().contains(query));
  }).toList(growable: false);
});

/// Resolves a single exercise by id (used to link alternatives/variations).
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
  final repo = ref.watch(exerciseLibraryRepositoryProvider);
  return repo.findById(id);
});
