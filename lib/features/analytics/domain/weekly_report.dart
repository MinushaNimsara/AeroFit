import 'package:intl/intl.dart';

/// Metrics for a single day (Monday–Sunday of the current week).
class DayMetrics {
  const DayMetrics({
    required this.date,
    required this.taskTotal,
    required this.taskCompleted,
    required this.calories,
    required this.exerciseCount,
    required this.calorieGoal,
  });

  final DateTime date;
  final int taskTotal;
  final int taskCompleted;
  final int calories;
  final int exerciseCount;
  final int calorieGoal;

  String get dayLabel => DateFormat('EEE').format(date);

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double get routineProgress =>
      taskTotal > 0 ? taskCompleted / taskTotal : 0.0;

  double get calorieProgress => calorieGoal > 0
      ? (calories / calorieGoal).clamp(0.0, 1.0)
      : 0.0;

  bool get dietOnTarget => calories > 0 && calories <= calorieGoal;

  bool get routineComplete => taskTotal > 0 && taskCompleted == taskTotal;

  /// Combined daily score for the activity matrix bar (0–1).
  double get activityScore {
    var parts = 0.0;
    var count = 0;
    if (taskTotal > 0) {
      parts += routineProgress;
      count++;
    }
    if (calories > 0) {
      parts += dietOnTarget ? 1.0 : calorieProgress;
      count++;
    }
    if (exerciseCount > 0) {
      parts += 1.0;
      count++;
    }
    return count > 0 ? parts / count : 0.0;
  }
}

class WeeklyReport {
  const WeeklyReport({
    required this.days,
    required this.totalWorkouts,
    required this.averageCalories,
    required this.routineCompletionRate,
    required this.dietStreak,
    required this.routineStreak,
    required this.achievements,
    required this.calorieGoal,
  });

  final List<DayMetrics> days;
  final int totalWorkouts;
  final int averageCalories;
  final double routineCompletionRate;
  final int dietStreak;
  final int routineStreak;
  final List<String> achievements;
  final int calorieGoal;

  factory WeeklyReport.empty({int calorieGoal = 2000}) => WeeklyReport(
        days: _emptyWeekDays(calorieGoal),
        totalWorkouts: 0,
        averageCalories: 0,
        routineCompletionRate: 0,
        dietStreak: 0,
        routineStreak: 0,
        achievements: const [],
        calorieGoal: calorieGoal,
      );

  static List<DayMetrics> _emptyWeekDays(int goal) {
    final monday = _mondayOfWeek(DateTime.now());
    return List.generate(
      7,
      (i) => DayMetrics(
        date: monday.add(Duration(days: i)),
        taskTotal: 0,
        taskCompleted: 0,
        calories: 0,
        exerciseCount: 0,
        calorieGoal: goal,
      ),
    );
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
