import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/dashboard/domain/daily_status.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Aggregates tasks, meals, and exercises from Cloud Firestore.
class DashboardRepository {
  DashboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _db =>
      _firestore ??
      (FirebaseBootstrap.isReady
          ? FirebaseFirestore.instanceFor(app: Firebase.app())
          : null);

  /// Builds [DailyStatus] from live task, meal, and exercise lists.
  Future<DailyStatus> buildStatus({
    required String userId,
    required List<RoutineTask> tasks,
    required List<MealEntry> meals,
    required List<GymExercise> exercises,
  }) async {
    final db = _db;
    if (db == null) {
      return DailyStatus.empty(calorieGoal: Env.dailyCalorieGoal);
    }

    var displayGoal = Env.dailyCalorieGoal;
    try {
      final userSnap = await db
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 8));
      final calorieGoal =
          (userSnap.data()?['dailyCalorieGoal'] as num?)?.round() ??
              Env.dailyCalorieGoal;
      displayGoal = calorieGoal > 0 ? calorieGoal : Env.dailyCalorieGoal;
    } catch (_) {
      // Offline / unreachable Firestore — keep local aggregates with default goal.
    }

    final tasksTotal = tasks.length;
    final tasksCompleted = tasks.where((t) => t.isCompleted).length;
    final routineComplete =
        tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

    final caloriesConsumed =
        meals.fold<int>(0, (total, m) => total + m.calories);

    // 0 kcal must NOT count as "on target" — that was showing a fake 33%.
    final dietOnTarget = displayGoal > 0 &&
        caloriesConsumed >= (displayGoal * 0.85).round() &&
        caloriesConsumed <= displayGoal;

    final gymExercisesTotal = exercises.length;
    final gymExercisesCompleted =
        exercises.where((e) => e.isCompletedToday).length;
    final workoutComplete = gymExercisesTotal > 0 &&
        gymExercisesCompleted == gymExercisesTotal;

    final goalProgress = _computeGoalProgress(
      tasksCompleted: tasksCompleted,
      tasksTotal: tasksTotal,
      caloriesConsumed: caloriesConsumed,
      calorieGoal: displayGoal,
      gymExercisesCompleted: gymExercisesCompleted,
      gymExercisesTotal: gymExercisesTotal,
    );

    return DailyStatus(
      routineComplete: routineComplete,
      dietOnTarget: dietOnTarget,
      workoutComplete: workoutComplete,
      tasksCompleted: tasksCompleted,
      tasksTotal: tasksTotal,
      caloriesConsumed: caloriesConsumed,
      calorieGoal: displayGoal,
      gymExercisesCompleted: gymExercisesCompleted,
      gymExercisesTotal: gymExercisesTotal,
      goalProgress: goalProgress,
    );
  }

  /// Equal weight for Routine / Diet / Gym. Empty pillars contribute 0.
  double _computeGoalProgress({
    required int tasksCompleted,
    required int tasksTotal,
    required int caloriesConsumed,
    required int calorieGoal,
    required int gymExercisesCompleted,
    required int gymExercisesTotal,
  }) {
    final routine =
        tasksTotal > 0 ? tasksCompleted / tasksTotal : 0.0;
    final diet = calorieGoal > 0 && caloriesConsumed > 0
        ? (caloriesConsumed.clamp(0, calorieGoal) / calorieGoal)
        : 0.0;
    final gym = gymExercisesTotal > 0
        ? gymExercisesCompleted / gymExercisesTotal
        : 0.0;
    return ((routine + diet + gym) / 3.0).clamp(0.0, 1.0);
  }
}
