import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/live_workout/data/live_workout_repository.dart';
import 'package:aerofit/features/live_workout/domain/live_workout_status.dart';
import 'package:aerofit/features/live_workout/domain/slacking_alert.dart';
import 'package:aerofit/features/live_workout/domain/workout_session_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final liveWorkoutRepositoryProvider = Provider<LiveWorkoutRepository>((ref) {
  return LiveWorkoutRepository();
});

final liveWorkoutStatusProvider = StreamProvider<LiveWorkoutStatus>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  final repo = ref.watch(liveWorkoutRepositoryProvider);
  if (uid == null) return Stream.value(LiveWorkoutStatus.idle);
  return repo.watchLiveStatus(uid);
});

final traineeWorkoutHistoryProvider =
    StreamProvider.family<List<WorkoutSessionHistory>, String>((ref, traineeUid) {
  return ref
      .watch(liveWorkoutRepositoryProvider)
      .watchRecentWorkoutHistory(traineeUid);
});

/// Real-time live_status for a specific trainee (coach spy mode / modal).
final traineeLiveStatusProvider =
    StreamProvider.family<LiveWorkoutStatus, String>((ref, traineeUid) {
  if (traineeUid.trim().isEmpty) {
    return Stream.value(LiveWorkoutStatus.idle);
  }
  return ref.watch(liveWorkoutRepositoryProvider).watchLiveStatus(traineeUid);
});

final traineeMaxRestMinutesProvider = StreamProvider<int>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  final repo = ref.watch(liveWorkoutRepositoryProvider);
  return repo.watchMaxRestMinutesForGym(profile?.gymName);
});

final coachMaxRestMinutesProvider = StreamProvider<int>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  if (profile == null || !profile.isCoach) {
    return Stream.value(3);
  }
  final repo = ref.watch(liveWorkoutRepositoryProvider);
  return repo.watchMaxRestMinutesForGym(profile.gymName);
});

final slackingAlertsProvider = StreamProvider<List<SlackingAlert>>((ref) {
  final authUid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (authUid == null || authUid.trim().isEmpty) {
    return Stream.value(const []);
  }

  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  final repo = ref.watch(liveWorkoutRepositoryProvider);
  if (profile == null || !profile.isCoach) {
    return Stream.value(const []);
  }
  return repo.watchSlackingAlertsForCoach(profile.uid);
});

final liveWorkoutSessionIndexProvider = StateProvider<int>((ref) => 0);

final liveWorkoutControllerProvider =
    Provider<LiveWorkoutController>((ref) => LiveWorkoutController(ref));

class LiveWorkoutController {
  LiveWorkoutController(this._ref);

  final Ref _ref;

  String? get _uid => _ref.read(authStateProvider).value?.uid;

  LiveWorkoutRepository get _repo => _ref.read(liveWorkoutRepositoryProvider);

  Future<void> startSession({
    required String scheduleName,
    required String firstExercise,
    required int totalExercises,
    int totalSets = LiveWorkoutRepository.defaultSetsPerExercise,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final profile = _ref.read(userProfileStreamProvider).valueOrNull;
    _ref.read(liveWorkoutSessionIndexProvider.notifier).state = 0;
    await _repo.startWorkout(
      uid: uid,
      scheduleName: scheduleName,
      firstWorkout: firstExercise,
      totalExercises: totalExercises,
      totalSets: totalSets,
      gymName: profile?.gymName,
      traineeName: profile?.displayName,
    );
  }

  Future<void> completeSet({
    required String exerciseName,
    required int completedSets,
    required int totalSets,
    required List<String> completedExerciseIds,
    required String? nextExerciseName,
    required bool exerciseFinished,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    if (exerciseFinished) {
      final index = _ref.read(liveWorkoutSessionIndexProvider);
      _ref.read(liveWorkoutSessionIndexProvider.notifier).state = index + 1;
    }

    final nextExercise = exerciseFinished ? (nextExerciseName ?? '') : exerciseName;
    final nextSets = exerciseFinished ? 0 : completedSets;

    await _repo.updateSetProgress(
      uid: uid,
      currentExercise: nextExercise.isNotEmpty ? nextExercise : exerciseName,
      completedSets: nextSets,
      totalSets: totalSets,
      completedWorkouts: completedExerciseIds,
      status: 'resting',
      restStarted: true,
    );
  }

  Future<void> resumeWorking(String currentWorkout) async {
    final uid = _uid;
    if (uid == null) return;
    final status = _ref.read(liveWorkoutStatusProvider).valueOrNull;
    await _repo.updateSetProgress(
      uid: uid,
      currentExercise: currentWorkout,
      completedSets: status?.completedSets ?? 0,
      totalSets: status?.totalSets ?? LiveWorkoutRepository.defaultSetsPerExercise,
      completedWorkouts: status?.completedWorkouts ?? const [],
      status: 'working',
    );
  }

  Future<void> markSlacking() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.markSlacking(uid);
  }

  Future<void> sendNudge(String traineeUid) async {
    await _repo.sendNudge(traineeUid);
  }

  Future<void> acknowledgeNudge() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.clearNudge(uid);
  }

  Future<void> endSession({
    required int exercisesCompleted,
    required int totalExercises,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final status = _ref.read(liveWorkoutStatusProvider).valueOrNull;
    if (status != null && status.isWorkingOut) {
      await _repo.endWorkoutWithSummary(
        uid: uid,
        status: status,
        exercisesCompleted: exercisesCompleted,
        totalExercises: totalExercises,
      );
    } else {
      await _repo.endWorkout(uid);
    }
    _ref.read(liveWorkoutSessionIndexProvider.notifier).state = 0;
  }

  Future<void> updateCoachRestLimit(int minutes) async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.updateCoachMaxRestMinutes(coachUid: uid, minutes: minutes);
  }
}
