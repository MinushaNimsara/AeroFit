// Manually configured for aerofit-303c9 — no FlutterFire CLI required.
// Web config source: Firebase Console → Project settings → Your apps → Web
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7-Zjv0tYvxrlCmpIgJSb4Yyjj1vhPfnE',
    appId: '1:189303398586:web:fe42f84f37fab85419a283',
    messagingSenderId: '189303398586',
    projectId: 'aerofit-303c9',
    authDomain: 'aerofit-303c9.firebaseapp.com',
    databaseURL:
        'https://aerofit-303c9-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'aerofit-303c9.firebasestorage.app',
    measurementId: 'G-6R4F836N5R',
  );

  // Mobile/desktop reuse web project credentials until platform apps are added.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7-Zjv0tYvxrlCmpIgJSb4Yyjj1vhPfnE',
    appId: '1:189303398586:web:fe42f84f37fab85419a283',
    messagingSenderId: '189303398586',
    projectId: 'aerofit-303c9',
    authDomain: 'aerofit-303c9.firebaseapp.com',
    databaseURL:
        'https://aerofit-303c9-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'aerofit-303c9.firebasestorage.app',
    measurementId: 'G-6R4F836N5R',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7-Zjv0tYvxrlCmpIgJSb4Yyjj1vhPfnE',
    appId: '1:189303398586:web:fe42f84f37fab85419a283',
    messagingSenderId: '189303398586',
    projectId: 'aerofit-303c9',
    authDomain: 'aerofit-303c9.firebaseapp.com',
    databaseURL:
        'https://aerofit-303c9-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'aerofit-303c9.firebasestorage.app',
    measurementId: 'G-6R4F836N5R',
    iosBundleId: 'com.aerofit.aerofit',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = web;

  static bool get isConfigured => true;
}
