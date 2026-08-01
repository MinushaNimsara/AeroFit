import 'package:aerofit/app.dart';
import 'package:aerofit/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Keep the app portrait-only so it does not rotate against the phone lock.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  if (kIsWeb) {
    ErrorWidget.builder = (details) {
      return Material(
        color: const Color(0xFF0D0F14),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ),
      );
    };
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        debugPrint(
          'Firebase initialized: ${DefaultFirebaseOptions.web.projectId}',
        );
      }
    }
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('$stack');
    }
  }

  runApp(
    const ProviderScope(
      child: AeroFitApp(),
    ),
  );
}
