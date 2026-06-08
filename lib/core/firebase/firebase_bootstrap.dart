import 'package:firebase_core/firebase_core.dart';

/// Whether [Firebase.initializeApp] completed successfully in main.dart.
class FirebaseBootstrap {
  static bool get isReady => Firebase.apps.isNotEmpty;
}
