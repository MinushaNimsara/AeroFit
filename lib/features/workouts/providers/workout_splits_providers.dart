import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/workouts/data/workout_splits_repository.dart';
import 'package:aerofit/features/workouts/domain/workout_split.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workoutSplitsRepositoryProvider =
    Provider<WorkoutSplitsRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return WorkoutSplitsRepository();
});

final workoutSplitsStreamProvider = StreamProvider<List<WorkoutSplit>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(workoutSplitsRepositoryProvider);

  if (auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchSplits(auth.uid);
});

/// User's explicit split choice (persisted for dashboard + gym screen).
final selectedSplitIdProvider = StateProvider<String?>((ref) => null);

/// Resolved split id — manual selection when valid, otherwise the first split.
final effectiveSelectedSplitIdProvider = Provider<String?>((ref) {
  final splits = ref.watch(workoutSplitsStreamProvider).valueOrNull;
  if (splits == null || splits.isEmpty) return null;

  final manual = ref.watch(selectedSplitIdProvider);
  if (manual != null && splits.any((s) => s.id == manual)) {
    return manual;
  }
  return splits.first.id;
});
