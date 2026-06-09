import 'package:aerofit/app.dart';
import 'package:aerofit/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    GoogleFonts.config.allowRuntimeFetching = false;
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
