import 'dart:async';

import 'package:aerofit/core/firebase/firebase_providers.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/dashboard/data/dashboard_repository.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:aerofit/features/routine/providers/tasks_providers.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DashboardRepository(firestore: firestore);
});

/// Streams [DailyStatus] — tasks, meals, and exercises update in real-time.
final dailyStatusProvider = StreamProvider<DailyStatus>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final dashRepo = ref.watch(dashboardRepositoryProvider);
  final tasksRepo = ref.watch(tasksRepositoryProvider);
  final mealsRepo = ref.watch(mealsRepositoryProvider);
  final exercisesRepo = ref.watch(exercisesRepositoryProvider);

  if (auth == null ||
      tasksRepo == null ||
      mealsRepo == null ||
      exercisesRepo == null) {
    return Stream.value(DailyStatus.demo());
  }

  final uid = auth.uid;
  ref.watch(workoutSplitsStreamProvider);
  final splitId = ref.watch(effectiveSelectedSplitIdProvider);

  return Stream.multi((controller) {
    var tasks = <RoutineTask>[];
    var meals = <MealEntry>[];
    var exercises = <GymExercise>[];

    Future<void> emitStatus() async {
      try {
        final status = await dashRepo.buildStatus(
          userId: uid,
          tasks: tasks,
          meals: meals,
          exercises: exercises,
        );
        if (!controller.isClosed) controller.add(status);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    final subTasks = tasksRepo.watchTasks(uid).listen((t) {
      tasks = t;
      unawaited(emitStatus());
    });
    final subMeals = mealsRepo.watchTodayMeals(uid).listen((m) {
      meals = m;
      unawaited(emitStatus());
    });
    StreamSubscription<List<GymExercise>>? subExercises;
    if (splitId != null && splitId.isNotEmpty) {
      subExercises = exercisesRepo
          .watchExercisesForSplit(uid, splitId)
          .listen((e) {
        exercises = e;
        unawaited(emitStatus());
      });
    } else {
      unawaited(emitStatus());
    }

    controller.onCancel = () {
      subTasks.cancel();
      subMeals.cancel();
      subExercises?.cancel();
    };
  });
});

final displayNameProvider = Provider<String>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  final name = auth?.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  return 'there';
});
