import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/coach/data/coach_dashboard_repository.dart';
import 'package:aerofit/features/coach/domain/coach_trainee_member.dart';
import 'package:aerofit/features/coach/domain/coach_workout_template.dart';
import 'package:aerofit/features/coach/domain/trainee_profile_snapshot.dart';
import 'package:aerofit/features/live_workout/providers/live_workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coachDashboardRepositoryProvider =
    Provider<CoachDashboardRepository>((ref) => CoachDashboardRepository());

final coachGymNameProvider = Provider<String?>((ref) {
  return ref.watch(userProfileStreamProvider).valueOrNull?.gymName?.trim();
});

final coachUidProvider = Provider<String?>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) return null;
  return ref.watch(userProfileStreamProvider).valueOrNull?.uid;
});

final coachTotalMembersProvider = StreamProvider<int>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) {
    return Stream.value(0);
  }
  final uid = ref.watch(coachUidProvider);
  return ref.watch(coachDashboardRepositoryProvider).watchTotalMembers(uid);
});

final coachActiveNowProvider = StreamProvider<int>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) {
    return Stream.value(0);
  }
  final uid = ref.watch(coachUidProvider);
  return ref.watch(coachDashboardRepositoryProvider).watchActiveNowCount(uid);
});

final coachGymRosterProvider = StreamProvider<List<CoachTraineeMember>>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) {
    return Stream.value(const []);
  }
  final uid = ref.watch(coachUidProvider);
  return ref.watch(coachDashboardRepositoryProvider).watchCoachRoster(uid);
});

final traineeSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredCoachGymRosterProvider =
    Provider<AsyncValue<List<CoachTraineeMember>>>((ref) {
  final rosterAsync = ref.watch(coachGymRosterProvider);
  final searchQuery = ref.watch(traineeSearchQueryProvider).trim().toLowerCase();

  int compareTraineeNames(CoachTraineeMember a, CoachTraineeMember b) {
    return a.displayLabel
        .toLowerCase()
        .compareTo(b.displayLabel.toLowerCase());
  }

  return rosterAsync.when(
    data: (members) {
      final sorted = [...members]..sort(compareTraineeNames);

      if (searchQuery.isEmpty) {
        return AsyncValue.data(sorted);
      }

      final filtered = sorted
          .where(
            (trainee) => trainee.displayLabel
                .toLowerCase()
                .contains(searchQuery),
          )
          .toList(growable: false);

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final coachWorkoutTemplatesProvider =
    StreamProvider<List<CoachWorkoutTemplate>>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) {
    return Stream.value(const []);
  }
  final uid = ref.watch(coachUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(coachDashboardRepositoryProvider).watchWorkoutTemplates(uid);
});

final traineeProfileProvider =
    StreamProvider.family<TraineeProfileSnapshot, String>((ref, traineeUid) {
  return ref
      .watch(coachDashboardRepositoryProvider)
      .watchTraineeProfile(traineeUid);
});

final coachSlackingAlertsProvider = slackingAlertsProvider;

final coachRoutineControllerProvider =
    Provider<CoachRoutineController>((ref) => CoachRoutineController(ref));

final coachTraineeControllerProvider =
    Provider<CoachTraineeController>((ref) => CoachTraineeController(ref));

class CoachTraineeController {
  CoachTraineeController(this._ref);

  final Ref _ref;

  Future<void> updateTraineeCalorieGoal({
    required String traineeUid,
    required int calorieGoal,
  }) async {
    final profile = _ref.read(userProfileStreamProvider).valueOrNull;
    final coachUid = profile?.uid;
    if (profile == null || !profile.isCoach || coachUid == null) {
      throw Exception('Coach profile is not ready.');
    }

    await _ref.read(coachDashboardRepositoryProvider).updateTraineeCalorieGoal(
          coachUid: coachUid,
          traineeUid: traineeUid,
          calorieGoal: calorieGoal,
        );
  }

  Future<void> nudgeTrainee(String traineeUid) async {
    final profile = _ref.read(userProfileStreamProvider).valueOrNull;
    if (profile == null || !profile.isCoach) {
      throw Exception('Coach profile is not ready.');
    }
    await _ref.read(liveWorkoutRepositoryProvider).sendNudge(traineeUid);
  }
}

class CoachRoutineController {
  CoachRoutineController(this._ref);

  final Ref _ref;

  Future<void> createRoutine({
    required String name,
    required List<RoutineExerciseSelection> exercises,
  }) async {
    final profile = _ref.read(userProfileStreamProvider).valueOrNull;
    final gym = profile?.gymName?.trim();
    final uid = profile?.uid;
    if (profile == null || !profile.isCoach || uid == null || gym == null) {
      throw Exception('Coach profile is not ready.');
    }

    await _ref.read(coachDashboardRepositoryProvider).createWorkoutTemplate(
          coachUid: uid,
          gymName: gym,
          name: name,
          exercises: exercises,
        );
  }

  Future<String> assignRoutineToTrainee({
    required String traineeUid,
    required String templateId,
  }) async {
    final profile = _ref.read(userProfileStreamProvider).valueOrNull;
    final uid = profile?.uid;
    if (profile == null || !profile.isCoach || uid == null) {
      throw Exception('Coach profile is not ready.');
    }

    return _ref.read(coachDashboardRepositoryProvider).assignWorkoutTemplateToTrainee(
          coachUid: uid,
          traineeUid: traineeUid,
          templateId: templateId,
        );
  }
}
