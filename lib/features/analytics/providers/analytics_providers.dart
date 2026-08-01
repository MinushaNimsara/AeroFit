import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/analytics/data/analytics_repository.dart';
import 'package:aerofit/features/analytics/domain/weekly_report.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return AnalyticsRepository();
});

/// Live weekly analytics from Firestore tasks, meals, and exercises.
final weeklyReportProvider = StreamProvider<WeeklyReport>((ref) {
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(analyticsRepositoryProvider);
  final calorieGoal = ref.watch(dailyCalorieGoalProvider);

  if (auth == null || repo == null) {
    return Stream.value(WeeklyReport.empty(calorieGoal: calorieGoal));
  }

  return repo.watchWeeklyReport(auth.uid, calorieGoal);
});
