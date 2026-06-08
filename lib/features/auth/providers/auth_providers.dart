import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return repo.authStateChanges();
});
