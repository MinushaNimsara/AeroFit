import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/enrollment/data/gym_enrollment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gymEnrollmentRepositoryProvider = Provider<GymEnrollmentRepository>((ref) {
  return GymEnrollmentRepository();
});

enum EnrollmentScanStatus { idle, processing, success, error }

class EnrollmentScanState {
  const EnrollmentScanState({
    this.status = EnrollmentScanStatus.idle,
    this.message,
    this.traineeName,
    this.gymName,
  });

  final EnrollmentScanStatus status;
  final String? message;
  final String? traineeName;
  final String? gymName;
}

final enrollmentScanProvider =
    StateNotifierProvider<EnrollmentScanNotifier, EnrollmentScanState>(
  (ref) => EnrollmentScanNotifier(ref),
);

class EnrollmentScanNotifier extends StateNotifier<EnrollmentScanState> {
  EnrollmentScanNotifier(this._ref) : super(const EnrollmentScanState());

  final Ref _ref;

  void reset() => state = const EnrollmentScanState();

  Future<void> enrollFromQr(String rawCode) async {
    final coachProfile = _ref.read(userProfileStreamProvider).valueOrNull;

    if (coachProfile == null || !coachProfile.isCoach) {
      state = const EnrollmentScanState(
        status: EnrollmentScanStatus.error,
        message: 'You must be signed in as a coach to enroll members.',
      );
      return;
    }

    if (coachProfile.uid.trim().isEmpty) {
      state = const EnrollmentScanState(
        status: EnrollmentScanStatus.error,
        message: 'Your coach session is invalid. Sign in again.',
      );
      return;
    }

    state = const EnrollmentScanState(status: EnrollmentScanStatus.processing);

    try {
      final traineeUid = _parseTraineeUid(rawCode);
      final repo = _ref.read(gymEnrollmentRepositoryProvider);
      final trainee = await repo.enrollTrainee(
        traineeUid: traineeUid,
        coach: coachProfile,
      );

      final gymName = coachProfile.gymName?.trim();
      final gymLabel = gymName != null && gymName.isNotEmpty
          ? gymName
          : 'your gym network';
      state = EnrollmentScanState(
        status: EnrollmentScanStatus.success,
        traineeName: trainee.displayName,
        gymName: gymName,
        message:
            'Successfully enrolled ${trainee.displayName} into $gymLabel!',
      );
    } on FirebaseException catch (e) {
      state = EnrollmentScanState(
        status: EnrollmentScanStatus.error,
        message: e.message ?? 'Enrollment failed (${e.code}).',
      );
    } catch (e) {
      state = EnrollmentScanState(
        status: EnrollmentScanStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _parseTraineeUid(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) throw Exception('Empty QR code.');
    if (trimmed.contains('/')) {
      return trimmed.split('/').last.trim();
    }
    return trimmed;
  }
}

/// True when the trainee has joined a gym network.
final isTraineeEnrolledProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  if (profile == null || !profile.isTrainee) return false;
  return profile.isEnrolledInGym;
});
