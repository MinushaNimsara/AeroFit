import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/gender.dart';

class SignUpProfile {
  const SignUpProfile({
    required this.displayName,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
  });

  final String displayName;
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
}
