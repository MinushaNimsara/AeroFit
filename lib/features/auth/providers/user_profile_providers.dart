import 'dart:async';

import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/data/user_profile_repository.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return UserProfileRepository();
});

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  final repo = ref.watch(userProfileRepositoryProvider);

  if (auth == null || repo == null) {
    return Stream.value(null);
  }

  unawaited(
    repo.syncAuthIdentityFields(
      uid: auth.uid,
      email: auth.email,
      authDisplayName: auth.displayName,
    ),
  );

  return repo.watchProfile(auth.uid);
});

final dailyCalorieGoalProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  return profile?.dailyCalorieGoal ?? Env.dailyCalorieGoal;
});

/// True when the signed-in user is authorized as platform master admin.
final isMasterAdminAuthorizedProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  if (profile?.isMasterAdmin == true) return true;

  final email = ref.watch(authStateProvider).valueOrNull?.email?.trim();
  if (email == null || Env.masterAdminEmail.isEmpty) return false;
  return email.toLowerCase() == Env.masterAdminEmail.toLowerCase();
});
