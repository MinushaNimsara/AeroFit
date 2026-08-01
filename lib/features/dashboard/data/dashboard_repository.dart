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
      return DailyStatus.demo();
    }

    final userSnap = await db.collection('users').doc(userId).get();
    final calorieGoal = (userSnap.data()?['dailyCalorieGoal'] as num?)?.round() ??
        Env.dailyCalorieGoal;
    final displayGoal = calorieGoal > 0 ? calorieGoal : Env.dailyCalorieGoal;

    final tasksTotal = tasks.length;
    final tasksCompleted = tasks.where((t) => t.isCompleted).length;
    final routineComplete =
        tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

    final caloriesConsumed =
        meals.fold<int>(0, (total, m) => total + m.calories);

    final dietOnTarget = caloriesConsumed <= displayGoal;

    final gymExercisesTotal = exercises.length;
    final gymExercisesCompleted =
        exercises.where((e) => e.isCompletedToday).length;
    final workoutComplete = gymExercisesTotal > 0 &&
        gymExercisesCompleted == gymExercisesTotal;

    final goalProgress = _computeGoalProgress(
      routineComplete: routineComplete,
      dietOnTarget: dietOnTarget,
      workoutComplete: workoutComplete,
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

  double _computeGoalProgress({
    required bool routineComplete,
    required bool dietOnTarget,
    required bool workoutComplete,
  }) {
    var score = 0.0;
    if (routineComplete) score += 0.34;
    if (dietOnTarget) score += 0.33;
    if (workoutComplete) score += 0.33;
    return score.clamp(0.0, 1.0);
  }
}
