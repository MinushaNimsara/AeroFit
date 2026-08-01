import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/gender.dart';

/// Mifflin-St Jeor BMR with activity multipliers for TDEE.
class CalorieCalculator {
  const CalorieCalculator._();

  static double calculateBmr({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
  }) {
    final base =
        (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  static int calculateDailyGoal({
    required Gender gender,
    required int age,
    required double weightKg,
    required double heightCm,
    required ActivityLevel activityLevel,
  }) {
    final bmr = calculateBmr(
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
    );
    return (bmr * activityLevel.multiplier).round();
  }
}
