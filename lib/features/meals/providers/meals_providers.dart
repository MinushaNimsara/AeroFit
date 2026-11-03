import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/meals/data/meal_analyzer_service.dart';
import 'package:aerofit/features/meals/data/meals_repository.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mealsRepositoryProvider = Provider<MealsRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return MealsRepository();
});

final mealAnalyzerServiceProvider = Provider<MealAnalyzerService>((ref) {
  final service = MealAnalyzerService();
  ref.onDispose(service.dispose);
  return service;
});

final todayMealsStreamProvider = StreamProvider<List<MealEntry>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(mealsRepositoryProvider);

  if (auth == null || repo == null) {
    return Stream.value(const []);
  }

  return Stream<List<MealEntry>>.multi((controller) {
    final sub = repo.watchTodayMeals(auth.uid).listen(
      controller.add,
      onError: (_) {
        if (!controller.isClosed) controller.add(const []);
      },
    );
    controller.onCancel = sub.cancel;
  });
});

final todayCaloriesTotalProvider = Provider<int>((ref) {
  final meals = ref.watch(todayMealsStreamProvider).valueOrNull ?? [];
  return meals.fold<int>(0, (total, m) => total + m.calories);
});
