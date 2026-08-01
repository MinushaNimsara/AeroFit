import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/domain/coach_workout_schedule.dart';
import 'package:aerofit/features/master_admin/domain/gym_trainee_progress.dart';
import 'package:aerofit/features/master_admin/providers/master_admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedGymProvider = StateProvider<CoachRegistryEntry?>((ref) => null);

final gymDetailTabProvider = StateProvider<int>((ref) => 0);

final activeGymTraineeCountProvider = StreamProvider.family<int, String>((
  ref,
  gymName,
) {
  final authorized = ref.watch(isMasterAdminAuthorizedProvider);
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(masterAdminRepositoryProvider);

  if (!authorized || auth == null || repo == null) {
    return Stream.value(0);
  }

  return repo.watchActiveGymTraineeCount(gymName);
});

final gymTraineeProgressProvider =
    StreamProvider.family<List<GymTraineeProgress>, String>((ref, gymName) {
  final authorized = ref.watch(isMasterAdminAuthorizedProvider);
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(masterAdminRepositoryProvider);

  if (!authorized || auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchGymTraineeProgress(gymName);
});

final coachWorkoutSchedulesProvider =
    StreamProvider.family<List<CoachWorkoutSchedule>, String>((ref, coachUid) {
  final authorized = ref.watch(isMasterAdminAuthorizedProvider);
  final auth = ref.watch(authStateProvider).value;
  final repo = ref.watch(masterAdminRepositoryProvider);

  if (!authorized || auth == null || repo == null) {
    return Stream.value(const []);
  }

  return repo.watchCoachWorkoutSchedules(coachUid);
});

enum ScheduleCloneStatus { idle, loading, success, error }

class ScheduleCloneState {
  const ScheduleCloneState({
    this.status = ScheduleCloneStatus.idle,
    this.message,
  });

  final ScheduleCloneStatus status;
  final String? message;
}

final scheduleCloneProvider =
    StateNotifierProvider<ScheduleCloneNotifier, ScheduleCloneState>(
  (ref) => ScheduleCloneNotifier(ref),
);

class ScheduleCloneNotifier extends StateNotifier<ScheduleCloneState> {
  ScheduleCloneNotifier(this._ref) : super(const ScheduleCloneState());

  final Ref _ref;

  void reset() => state = const ScheduleCloneState();

  Future<bool> cloneSchedule({
    required CoachRegistryEntry sourceGym,
    required CoachWorkoutSchedule schedule,
    required CoachRegistryEntry targetGym,
  }) async {
    final repo = _ref.read(masterAdminRepositoryProvider);
    if (repo == null) {
      state = const ScheduleCloneState(
        status: ScheduleCloneStatus.error,
        message: 'Firebase is not ready.',
      );
      return false;
    }

    state = const ScheduleCloneState(status: ScheduleCloneStatus.loading);

    try {
      await repo.cloneWorkoutSchedule(
        sourceCoachUid: sourceGym.uid,
        schedule: schedule,
        targetCoachUid: targetGym.uid,
        targetGymName: targetGym.gymName,
      );

      state = ScheduleCloneState(
        status: ScheduleCloneStatus.success,
        message:
            'Workout Schedule successfully duplicated to ${targetGym.gymName}!',
      );
      return true;
    } catch (e) {
      state = ScheduleCloneState(
        status: ScheduleCloneStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
