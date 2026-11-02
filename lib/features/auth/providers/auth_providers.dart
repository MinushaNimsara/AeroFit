import 'dart:async';

import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!FirebaseBootstrap.isReady) return null;
  return AuthRepository();
});

/// Auth session stream. The first event is bounded so [AsyncLoading] cannot
/// stick forever if Firebase Auth stalls; later events pass through unchanged.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (repo == null) return Stream.value(null);
  return _authStateChangesWithFirstEventTimeout(repo);
});

Stream<User?> _authStateChangesWithFirstEventTimeout(AuthRepository repo) {
  final upstream = repo.authStateChanges();
  late final StreamController<User?> controller;
  StreamSubscription<User?>? sub;
  Timer? firstEventTimer;
  var gotFirst = false;

  controller = StreamController<User?>(
    onListen: () {
      firstEventTimer = Timer(const Duration(seconds: 12), () {
        if (gotFirst || controller.isClosed) return;
        gotFirst = true;
        controller.add(FirebaseAuth.instance.currentUser);
      });

      sub = upstream.listen(
        (user) {
          gotFirst = true;
          firstEventTimer?.cancel();
          if (!controller.isClosed) controller.add(user);
        },
        onError: (Object error, StackTrace stack) {
          gotFirst = true;
          firstEventTimer?.cancel();
          if (!controller.isClosed) controller.addError(error, stack);
        },
        onDone: () {
          firstEventTimer?.cancel();
          if (!controller.isClosed) controller.close();
        },
      );
    },
    onCancel: () async {
      firstEventTimer?.cancel();
      await sub?.cancel();
    },
  );

  return controller.stream;
}

/// True while sign-up is writing the Firestore profile (blocks premature redirects).
final authRegistrationInProgressProvider = StateProvider<bool>((ref) => false);
