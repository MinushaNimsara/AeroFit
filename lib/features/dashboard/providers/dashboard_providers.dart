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
  // Use resolved split id only — never watch the splits AsyncValue directly,
  // or a Firestore offline error inherits into this provider and blanks the hub.
  final splitId = ref.watch(effectiveSelectedSplitIdProvider);

  return Stream.multi((controller) {
    var tasks = <RoutineTask>[];
    var meals = <MealEntry>[];
    var exercises = <GymExercise>[];
    var emittedOnce = false;

    Future<void> emitStatus() async {
      try {
        final status = await dashRepo.buildStatus(
          userId: uid,
          tasks: tasks,
          meals: meals,
          exercises: exercises,
        );
        emittedOnce = true;
        if (!controller.isClosed) controller.add(status);
      } catch (_) {
        // Never hard-fail the dashboard on Firestore/network issues.
        if (!controller.isClosed) {
          controller.add(DailyStatus.empty());
          emittedOnce = true;
        }
      }
    }

    void onStreamError(Object _, StackTrace __) {
      if (!emittedOnce && !controller.isClosed) {
        controller.add(DailyStatus.empty());
        emittedOnce = true;
      }
    }

    final subTasks = tasksRepo.watchTasks(uid).listen(
      (t) {
        tasks = t;
        unawaited(emitStatus());
      },
      onError: onStreamError,
    );
    final subMeals = mealsRepo.watchTodayMeals(uid).listen(
      (m) {
        meals = m;
        unawaited(emitStatus());
      },
      onError: onStreamError,
    );
    StreamSubscription<List<GymExercise>>? subExercises;
    if (splitId != null && splitId.isNotEmpty) {
      subExercises = exercisesRepo.watchExercisesForSplit(uid, splitId).listen(
        (e) {
          exercises = e;
          unawaited(emitStatus());
        },
        onError: onStreamError,
      );
    }

    // Immediate first paint so login → dashboard is never stuck on spinner.
    unawaited(emitStatus());

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
