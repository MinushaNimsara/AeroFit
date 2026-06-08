import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/core/services/cloudinary_service.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/workouts/data/exercises_repository.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return ExercisesRepository();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// All exercises logged today (dashboard gym pill).
final todayExercisesStreamProvider = StreamProvider<List<GymExercise>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(exercisesRepositoryProvider);

  if (auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchTodayExercises(auth.uid);
});

final todayExerciseCountProvider = Provider<int>((ref) {
  final exercises = ref.watch(todayExercisesStreamProvider).valueOrNull ?? [];
  return exercises.length;
});

/// Exercises for the currently selected workout split.
final splitExercisesStreamProvider = StreamProvider<List<GymExercise>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(exercisesRepositoryProvider);
  final splitId = ref.watch(effectiveSelectedSplitIdProvider);

  if (auth == null || repo == null || splitId == null || splitId.isEmpty) {
    return Stream.value(const []);
  }

  return repo.watchExercisesForSplit(auth.uid, splitId);
});

/// Completion progress for the active workout split (checked off today).
final activeSplitGymProgressProvider = Provider<(int completed, int total)>((ref) {
  final exercises = ref.watch(splitExercisesStreamProvider).valueOrNull ?? [];
  final total = exercises.length;
  final completed = exercises.where((e) => e.isCompletedToday).length;
  return (completed, total);
});
