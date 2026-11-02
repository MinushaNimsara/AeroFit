import 'package:aerofit/app.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/app_update/providers/app_update_providers.dart';
import 'package:aerofit/features/auth/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

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
  } else {
    // Native only — web orientation futures can hang and block first frame.
    try {
      await Future.any<void>([
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]),
        Future<void>.delayed(const Duration(seconds: 2)),
      ]);
    } catch (_) {}
  }

  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AeroFitApp(),
    ),
  );

  await FirebaseBootstrap.ensureInitialized();
  container.invalidate(authRepositoryProvider);
  container.invalidate(authStateProvider);
  // Let Firestore client finish wiring, then retry update check.
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  container.invalidate(appUpdateRepositoryProvider);
  container.invalidate(appUpdateStatusProvider);
}
