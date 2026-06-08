import 'dart:async';

import 'package:aerofit/features/analytics/domain/weekly_report.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:aerofit/features/workouts/domain/gym_exercise.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsRepository {
  AnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore =
            firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  (DateTime, DateTime) get _currentWeekRange {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final nextMonday = monday.add(const Duration(days: 7));
    return (monday, nextMonday);
  }

  String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;

  Stream<WeeklyReport> watchWeeklyReport(String uid, int calorieGoal) {
    final (weekStart, weekEnd) = _currentWeekRange;

    final tasksQuery = _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('createdAt', isLessThan: Timestamp.fromDate(weekEnd));

    final mealsQuery = _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(weekEnd));

    final exercisesQuery = _firestore
        .collection('users')
        .doc(uid)
        .collection('exercises')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(weekEnd));

    return Stream.multi((controller) {
      var tasks = <RoutineTask>[];
      var meals = <MealEntry>[];
      var exercises = <GymExercise>[];

      void emit() {
        final report = _buildReport(
          tasks: tasks,
          meals: meals,
          exercises: exercises,
          calorieGoal: calorieGoal,
          weekStart: weekStart,
        );
        if (!controller.isClosed) controller.add(report);
      }

      final subTasks = tasksQuery.snapshots().listen((snap) {
        tasks = snap.docs.map(RoutineTask.fromFirestore).toList();
        emit();
      });
      final subMeals = mealsQuery.snapshots().listen((snap) {
        meals = snap.docs.map(MealEntry.fromFirestore).toList();
        emit();
      });
      final subExercises = exercisesQuery.snapshots().listen((snap) {
        exercises = snap.docs.map(GymExercise.fromFirestore).toList();
        emit();
      });

      controller.onCancel = () {
        subTasks.cancel();
        subMeals.cancel();
        subExercises.cancel();
      };
    });
  }

  WeeklyReport _buildReport({
    required List<RoutineTask> tasks,
    required List<MealEntry> meals,
    required List<GymExercise> exercises,
    required int calorieGoal,
    required DateTime weekStart,
  }) {
    final days = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final key = _dateKey(date);

      final dayTasks =
          tasks.where((t) => _dateKey(t.createdAt) == key).toList();
      final dayMeals =
          meals.where((m) => _dateKey(m.timestamp) == key).toList();
      final dayExercises =
          exercises.where((e) => _dateKey(e.timestamp) == key).toList();

      return DayMetrics(
        date: date,
        taskTotal: dayTasks.length,
        taskCompleted: dayTasks.where((t) => t.isCompleted).length,
        calories: dayMeals.fold<int>(0, (total, m) => total + m.calories),
        exerciseCount: dayExercises.length,
        calorieGoal: calorieGoal,
      );
    });

    final totalWorkouts = exercises.length;

    final daysWithMeals = days.where((d) => d.calories > 0).length;
    final totalCalories = days.fold<int>(0, (total, d) => total + d.calories);
    final averageCalories = daysWithMeals > 0
        ? (totalCalories / daysWithMeals).round()
        : 0;

    final totalTasks = days.fold<int>(0, (t, d) => t + d.taskTotal);
    final completedTasks =
        days.fold<int>(0, (t, d) => t + d.taskCompleted);
    final routineCompletionRate =
        totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    final dietStreak = _consecutiveStreak(
      days.reversed.toList(),
      (d) => d.dietOnTarget,
    );
    final routineStreak = _consecutiveStreak(
      days.reversed.toList(),
      (d) => d.routineComplete,
    );

    final achievements = _buildAchievements(
      days: days,
      dietStreak: dietStreak,
      routineStreak: routineStreak,
      totalWorkouts: totalWorkouts,
      averageCalories: averageCalories,
      calorieGoal: calorieGoal,
      routineCompletionRate: routineCompletionRate,
    );

    return WeeklyReport(
      days: days,
      totalWorkouts: totalWorkouts,
      averageCalories: averageCalories,
      routineCompletionRate: routineCompletionRate,
      dietStreak: dietStreak,
      routineStreak: routineStreak,
      achievements: achievements,
      calorieGoal: calorieGoal,
    );
  }

  int _consecutiveStreak(
    List<DayMetrics> daysNewestFirst,
    bool Function(DayMetrics) predicate,
  ) {
    var streak = 0;
    for (final day in daysNewestFirst) {
      if (day.date.isAfter(DateTime.now())) continue;
      if (predicate(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  List<String> _buildAchievements({
    required List<DayMetrics> days,
    required int dietStreak,
    required int routineStreak,
    required int totalWorkouts,
    required int averageCalories,
    required int calorieGoal,
    required double routineCompletionRate,
  }) {
    final messages = <String>[];

    if (dietStreak >= 2) {
      messages.add(
        '🔥 $dietStreak-day diet streak — staying at or under $calorieGoal kcal!',
      );
    }
    if (routineStreak >= 2) {
      messages.add(
        '✅ $routineStreak-day routine streak — all tasks crushed!',
      );
    }
    if (totalWorkouts >= 3) {
      messages.add(
        '💪 $totalWorkouts workouts logged this week — consistency wins!',
      );
    }
    if (averageCalories > 0 &&
        averageCalories <= calorieGoal &&
        averageCalories >= (calorieGoal * 0.85).round()) {
      messages.add(
        '🎯 Average intake $averageCalories kcal — right on your $calorieGoal kcal target!',
      );
    }
    if (routineCompletionRate >= 0.9 && days.any((d) => d.taskTotal > 0)) {
      messages.add(
        '📋 ${(routineCompletionRate * 100).round()}% routine completion — elite discipline!',
      );
    }
    if (messages.isEmpty) {
      messages.add(
        '🚀 Keep logging — your weekly story is just getting started!',
      );
    }

    return messages;
  }
}
