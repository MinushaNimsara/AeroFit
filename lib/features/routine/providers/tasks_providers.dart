import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/routine/data/tasks_repository.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksRepositoryProvider = Provider<TasksRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return TasksRepository();
});

final tasksStreamProvider = StreamProvider<List<RoutineTask>>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(tasksRepositoryProvider);

  if (auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchTasks(auth.uid);
});

/// Routine complete when there is at least one task and all are done.
final routineCompleteProvider = Provider<bool>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  if (tasks.isEmpty) return false;
  return tasks.every((t) => t.isCompleted);
});
