import 'dart:async';

import 'package:aerofit/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Whether [Firebase.initializeApp] completed successfully.
///
/// Init is always bounded by a timeout so a hung network (especially flaky
/// Wi‑Fi) cannot leave the native splash on screen forever.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const Duration defaultTimeout = Duration(seconds: 8);

  static bool _attempted = false;
  static Object? lastError;

  static bool get isReady => Firebase.apps.isNotEmpty;

  /// True after [ensureInitialized] finished without a usable [Firebase] app.
  static bool get initFailed => _attempted && !isReady;

  /// Initializes Firebase at most once. Never throws; never hangs past [timeout].
  static Future<void> ensureInitialized({
    Duration timeout = defaultTimeout,
  }) async {
    if (isReady) return;
    _attempted = true;
    lastError = null;

    try {
      // Hard ceiling: some web Auth SDK futures ignore Dart .timeout().
      await Future.any<void>([
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).then((_) {}),
        Future<void>.delayed(timeout),
      ]);

      if (!isReady) {
        lastError = TimeoutException(
          'Firebase initialization timed out after ${timeout.inSeconds}s',
        );
      }

      if (kDebugMode) {
        if (isReady) {
          debugPrint(
            'Firebase initialized: ${DefaultFirebaseOptions.currentPlatform.projectId}',
          );
        } else {
          debugPrint(
            'Firebase initialization timed out after ${timeout.inSeconds}s — '
            'continuing without Firebase so splash can dismiss.',
          );
        }
      }
    } catch (e, stack) {
      lastError = e;
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $e');
        debugPrint('$stack');
      }
    }
  }
}
