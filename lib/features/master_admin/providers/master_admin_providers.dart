import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:aerofit/features/auth/providers/user_profile_providers.dart';
import 'package:aerofit/features/master_admin/data/master_admin_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final masterAdminRepositoryProvider = Provider<MasterAdminRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return MasterAdminRepository();
});

enum CoachRegistrationStatus { idle, loading, success, error }

class CoachRegistrationState {
  const CoachRegistrationState({
    this.status = CoachRegistrationStatus.idle,
    this.message,
    this.createdCoachUid,
  });

  final CoachRegistrationStatus status;
  final String? message;
  final String? createdCoachUid;

  CoachRegistrationState copyWith({
    CoachRegistrationStatus? status,
    String? message,
    String? createdCoachUid,
    bool clearMessage = false,
    bool clearUid = false,
  }) {
    return CoachRegistrationState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      createdCoachUid:
          clearUid ? null : (createdCoachUid ?? this.createdCoachUid),
    );
  }
}

final coachRegistrationProvider =
    StateNotifierProvider<CoachRegistrationNotifier, CoachRegistrationState>(
  (ref) => CoachRegistrationNotifier(ref),
);

class CoachRegistrationNotifier extends StateNotifier<CoachRegistrationState> {
  CoachRegistrationNotifier(this._ref)
      : super(const CoachRegistrationState());

  final Ref _ref;

  void reset() {
    state = const CoachRegistrationState();
  }

  Future<void> registerGymAndCoach({
    required String gymName,
    required String coachFullName,
    required String coachEmail,
    required String coachPassword,
  }) async {
    if (!_ref.read(isMasterAdminAuthorizedProvider)) {
      state = const CoachRegistrationState(
        status: CoachRegistrationStatus.error,
        message: 'You are not authorized to register gyms.',
      );
      return;
    }

    final repo = _ref.read(masterAdminRepositoryProvider);
    if (repo == null) {
      state = const CoachRegistrationState(
        status: CoachRegistrationStatus.error,
        message: 'Firebase is not ready. Please try again.',
      );
      return;
    }

    state = const CoachRegistrationState(
      status: CoachRegistrationStatus.loading,
    );

    try {
      final uid = await repo.registerGymAndCoach(
        gymName: gymName,
        coachFullName: coachFullName,
        coachEmail: coachEmail,
        coachPassword: coachPassword,
      );

      state = CoachRegistrationState(
        status: CoachRegistrationStatus.success,
        message:
            'Gym "$gymName" and coach account for $coachFullName were created successfully.',
        createdCoachUid: uid,
      );
    } catch (e) {
      state = CoachRegistrationState(
        status: CoachRegistrationStatus.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class CoachEditState {
  const CoachEditState({
    this.isSavingProfile = false,
    this.isSendingReset = false,
    this.profileSaved = false,
    this.passwordResetSent = false,
    this.message,
    this.errorMessage,
  });

  final bool isSavingProfile;
  final bool isSendingReset;
  final bool profileSaved;
  final bool passwordResetSent;
  final String? message;
  final String? errorMessage;
}

final coachEditProvider =
    StateNotifierProvider<CoachEditNotifier, CoachEditState>(
  (ref) => CoachEditNotifier(ref),
);

class CoachEditNotifier extends StateNotifier<CoachEditState> {
  CoachEditNotifier(this._ref) : super(const CoachEditState());

  final Ref _ref;

  void reset() => state = const CoachEditState();

  void clearError() => state = CoachEditState(
        isSavingProfile: state.isSavingProfile,
        isSendingReset: state.isSendingReset,
      );

  void clearPasswordResetFlag() => state = CoachEditState(
        isSavingProfile: state.isSavingProfile,
        isSendingReset: false,
      );

  Future<void> saveCoachProfile({
    required String coachUid,
    required String gymName,
    required String coachFullName,
  }) async {
    if (!_ref.read(isMasterAdminAuthorizedProvider)) {
      state = const CoachEditState(
        errorMessage: 'You are not authorized to edit coach profiles.',
      );
      return;
    }

    final repo = _ref.read(masterAdminRepositoryProvider);
    if (repo == null) {
      state = const CoachEditState(
        errorMessage: 'Firebase is not ready. Please try again.',
      );
      return;
    }

    state = const CoachEditState(isSavingProfile: true);

    try {
      await repo.updateCoachProfile(
        coachUid: coachUid,
        gymName: gymName,
        coachFullName: coachFullName,
      );

      state = CoachEditState(
        profileSaved: true,
        message:
            'Updated ${coachFullName.trim()} and gym "${gymName.trim()}".',
      );
    } catch (e) {
      state = CoachEditState(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> triggerPasswordReset({
    required String coachEmail,
    required String coachName,
  }) async {
    if (!_ref.read(isMasterAdminAuthorizedProvider)) {
      state = const CoachEditState(
        errorMessage: 'You are not authorized to reset coach passwords.',
      );
      return;
    }

    final email = coachEmail.trim();
    if (email.isEmpty || email == '—') {
      state = const CoachEditState(
        errorMessage: 'This coach account has no email on file.',
      );
      return;
    }

    final repo = _ref.read(masterAdminRepositoryProvider);
    if (repo == null) {
      state = const CoachEditState(
        errorMessage: 'Firebase is not ready. Please try again.',
      );
      return;
    }

    state = const CoachEditState(isSendingReset: true);

    try {
      await repo.sendCoachPasswordResetEmail(email);
      state = CoachEditState(
        passwordResetSent: true,
        message: 'Password reset email sent to $email for $coachName.',
      );
    } catch (e) {
      state = CoachEditState(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final masterAdminLoginControllerProvider =
    Provider<MasterAdminLoginController>((ref) {
  return MasterAdminLoginController(ref);
});

class MasterAdminLoginController {
  MasterAdminLoginController(this._ref);

  final Ref _ref;

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo == null) {
      return 'Firebase failed to initialize. Hot restart and try again.';
    }

    try {
      final credential = await repo.signIn(email: email, password: password);
      final uid = credential.user?.uid;
      if (uid == null) {
        await repo.signOut();
        return 'Sign in failed. Please try again.';
      }

      final profileRepo = _ref.read(userProfileRepositoryProvider);
      final profile = await profileRepo?.fetchProfile(uid);
      final normalizedEmail = email.trim().toLowerCase();
      final emailAuthorized = Env.masterAdminEmail.isNotEmpty &&
          normalizedEmail == Env.masterAdminEmail.toLowerCase();
      final roleAuthorized = profile?.isMasterAdmin == true;

      if (!roleAuthorized && !emailAuthorized) {
        await repo.signOut();
        return 'Access denied. This portal is for master administrators only.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed.';
    } catch (_) {
      return 'Sign in failed. Please try again.';
    }
  }
}
