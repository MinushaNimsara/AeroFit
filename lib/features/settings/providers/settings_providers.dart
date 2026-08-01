import 'package:aerofit/core/router/app_router.dart';
import 'package:aerofit/features/analytics/providers/analytics_providers.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/coach/providers/coach_dashboard_providers.dart';
import 'package:aerofit/features/dashboard/providers/dashboard_providers.dart';
import 'package:aerofit/features/enrollment/providers/gym_enrollment_providers.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:aerofit/features/master_admin/providers/gym_detail_providers.dart';
import 'package:aerofit/features/master_admin/providers/platform_analytics_providers.dart';
import 'package:aerofit/features/meals/providers/meals_providers.dart';
import 'package:aerofit/features/routine/providers/tasks_providers.dart';
import 'package:aerofit/features/settings/data/issue_report_service.dart';
import 'package:aerofit/features/workouts/providers/exercises_providers.dart';
import 'package:aerofit/features/workouts/providers/workout_splits_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final issueReportServiceProvider = Provider<IssueReportService>((ref) {
  final service = IssueReportService();
  ref.onDispose(service.dispose);
  return service;
});

final settingsControllerProvider =
    Provider<SettingsController>((ref) => SettingsController(ref));

class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  String? get _userEmail => _ref.read(authStateProvider).valueOrNull?.email;

  Future<void> sendPasswordResetEmail() async {
    final email = _userEmail;
    if (email == null || email.isEmpty) {
      throw Exception('No email found for the current account.');
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> submitIssueReport(String message) async {
    final email = _userEmail;
    if (email == null || email.isEmpty) {
      throw Exception('You must be signed in to report an issue.');
    }

    final service = _ref.read(issueReportServiceProvider);
    await service.submitReport(email: email, message: message);
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    final router = _ref.read(appRouterProvider);

    await repo?.signOut();
    _invalidateSessionProviders();
    router.go('/login');
  }

  void _invalidateSessionProviders() {
    _ref.invalidate(authStateProvider);
    _ref.invalidate(userProfileStreamProvider);
    _ref.invalidate(coachGymRosterProvider);
    _ref.invalidate(coachTotalMembersProvider);
    _ref.invalidate(coachActiveNowProvider);
    _ref.invalidate(coachWorkoutTemplatesProvider);
    _ref.invalidate(coachSlackingAlertsProvider);
    _ref.invalidate(coachRegistrationProvider);
    _ref.invalidate(coachEditProvider);
    _ref.invalidate(platformAnalyticsStreamProvider);
    _ref.invalidate(coachRegistryStreamProvider);
    _ref.invalidate(selectedGymProvider);
    _ref.invalidate(scheduleCloneProvider);
    _ref.invalidate(liveWorkoutStatusProvider);
    _ref.invalidate(slackingAlertsProvider);
    _ref.invalidate(dailyStatusProvider);
    _ref.invalidate(todayMealsStreamProvider);
    _ref.invalidate(todayCaloriesTotalProvider);
    _ref.invalidate(tasksStreamProvider);
    _ref.invalidate(todayExercisesStreamProvider);
    _ref.invalidate(workoutSplitsStreamProvider);
    _ref.invalidate(weeklyReportProvider);
    _ref.invalidate(enrollmentScanProvider);
    _ref.invalidate(isTraineeEnrolledProvider);
  }
}
