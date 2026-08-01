import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolved Firebase auth session for routing decisions.
class AuthSession {
  const AuthSession({
    required this.isLoading,
    required this.user,
  });

  final bool isLoading;
  final User? user;

  bool get isSignedIn => user != null;
}

AuthSession readAuthSession(Ref ref) {
  if (!FirebaseBootstrap.isReady) {
    return const AuthSession(isLoading: false, user: null);
  }

  final authAsync = ref.read(authStateProvider);
  if (authAsync.isLoading) {
    return const AuthSession(isLoading: true, user: null);
  }

  if (authAsync.hasError) {
    return const AuthSession(isLoading: false, user: null);
  }

  return AuthSession(isLoading: false, user: authAsync.valueOrNull);
}
