import 'dart:convert';
import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/calorie_calculator.dart';
import 'package:aerofit/features/auth/domain/sign_up_profile.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:aerofit/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Email/password auth backed by the manually configured Firebase Web app.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    try {
      final user = credential.user ?? _auth.currentUser;
      if (user != null) {
        final authEmail = user.email?.trim();
        final authDisplayName = user.displayName?.trim();
        final resolvedName = authDisplayName != null && authDisplayName.isNotEmpty
            ? authDisplayName
            : UserProfile.emailPrefix(authEmail);

        final payload = <String, dynamic>{};
        if (authEmail != null && authEmail.isNotEmpty) {
          payload['email'] = authEmail;
        }
        if (resolvedName.isNotEmpty) {
          payload['rosterDisplayName'] = resolvedName;
          payload['username'] = resolvedName;
          payload['displayName'] = resolvedName;
        }
        if (payload.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).set(
                payload,
                SetOptions(merge: true),
              );
        }
      }
    } catch (_) {
      // Do not block sign-in if metadata syncing fails on Safari.
    }

    return credential;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password;

    try {
      return await _createAccountAndProfile(
        email: normalizedEmail,
        password: normalizedPassword,
        profile: profile,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final recovered = await _tryRecoverPartialRegistration(
          email: normalizedEmail,
          password: normalizedPassword,
          profile: profile,
        );
        if (recovered != null) {
          return recovered;
        }
        throw FirebaseAuthException(
          code: e.code,
          message:
              'This email is already registered. Switch to Sign In and log in instead.',
        );
      }
      rethrow;
    } catch (e) {
      // If client-side FlutterFire/Safari throws, first check if the account was
      // actually created on Firebase Auth and recover session & profile:
      final recovered = await _tryRecoverPartialRegistration(
        email: normalizedEmail,
        password: normalizedPassword,
        profile: profile,
      );
      if (recovered != null) {
        return recovered;
      }

      final current = _auth.currentUser;
      if (current != null && current.uid.isNotEmpty) {
        final displayName = profile.displayName.trim().isNotEmpty
            ? profile.displayName.trim()
            : UserProfile.emailPrefix(normalizedEmail);
        try {
          await _createTraineeProfile(
            uid: current.uid,
            email: normalizedEmail,
            profile: profile,
            displayName: displayName,
          );
        } catch (_) {}
        try {
          return await _auth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: normalizedPassword,
          );
        } catch (_) {}
      }

      // If not yet created, execute the fallback via Firebase Auth Identity Toolkit REST API.
      try {
        return await _signUpViaRestFallback(
          email: normalizedEmail,
          password: normalizedPassword,
          profile: profile,
        );
      } on FirebaseAuthException {
        rethrow;
      } catch (restErr) {
        if (_auth.currentUser != null) {
          try {
            return await _auth.signInWithEmailAndPassword(
              email: normalizedEmail,
              password: normalizedPassword,
            );
          } catch (_) {}
        }
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Registration could not be completed: $e',
        );
      }
    }
  }

  Future<UserCredential> _signUpViaRestFallback({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server returned an unexpected response. Please try again.');
    }

    if (response.statusCode != 200) {
      final errorMap = body['error'] as Map<String, dynamic>?;
      final rawMsg = errorMap?['message'] as String? ?? 'REGISTRATION_FAILED';

      if (rawMsg.startsWith('EMAIL_EXISTS')) {
        final recovered = await _tryRecoverPartialRegistration(
          email: email,
          password: password,
          profile: profile,
        );
        if (recovered != null) return recovered;
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message:
              'This email is already registered. Switch to Sign In and log in instead.',
        );
      } else if (rawMsg.startsWith('WEAK_PASSWORD')) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use at least 6 characters.',
        );
      } else if (rawMsg.startsWith('INVALID_EMAIL')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      } else if (rawMsg.startsWith('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many attempts. Please try again later.',
        );
      } else {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Registration failed: $rawMsg',
        );
      }
    }

    final uid = body['localId'] as String?;
    if (uid == null || uid.isEmpty) {
      throw Exception('Account was created but no user session was returned.');
    }

    final displayName = profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim()
        : UserProfile.emailPrefix(email);

    // 1. Sign in to establish active session first (required by Firestore rules)
    UserCredential? credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      // Continue if session is already active or interop failure occurs
    }

    final resolvedUid = credential?.user?.uid ?? _auth.currentUser?.uid ?? uid;

    // 2. Then write trainee profile to Firestore
    try {
      await _createTraineeProfile(
        uid: resolvedUid,
        email: email,
        profile: profile,
        displayName: displayName,
      );
    } catch (_) {
      // Continue — user is already authenticated
    }

    if (credential != null) {
      return credential;
    }

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> _createAccountAndProfile({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (createErr) {
      final current = _auth.currentUser;
      if (current != null && current.uid.isNotEmpty) {
        final displayName = profile.displayName.trim().isNotEmpty
            ? profile.displayName.trim()
            : UserProfile.emailPrefix(email);

        try {
          await _createTraineeProfile(
            uid: current.uid,
            email: email,
            profile: profile,
            displayName: displayName,
          );
        } catch (_) {}

        try {
          return await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {}
      }
      rethrow;
    }

    String? uid;
    try {
      uid = credential.user?.uid;
    } catch (_) {}
    uid ??= _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      throw Exception('Account was created but no user session was returned.');
    }

    try {
      final u = credential.user ?? _auth.currentUser;
      await u?.getIdToken(true);
    } catch (_) {
      // Continue — Firestore may still accept the active session on web/iOS Safari.
    }

    final displayName = profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim()
        : UserProfile.emailPrefix(email);

    try {
      await _createTraineeProfile(
        uid: uid,
        email: email,
        profile: profile,
        displayName: displayName,
      );
    } catch (_) {
      // Continue — user is authenticated
    }

    return credential;
  }

  Future<UserCredential?> _tryRecoverPartialRegistration({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? uid;
      try {
        uid = credential.user?.uid;
      } catch (_) {}
      uid ??= _auth.currentUser?.uid;

      if (uid == null || uid.isEmpty) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      final hasProfile = doc.exists && doc.data() != null;

      if (!hasProfile) {
        final displayName = profile.displayName.trim().isNotEmpty
            ? profile.displayName.trim()
            : UserProfile.emailPrefix(email);
        await _createTraineeProfile(
          uid: uid,
          email: email,
          profile: profile,
          displayName: displayName,
        );
      }
      return credential;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _createTraineeProfile({
    required String uid,
    required String email,
    required SignUpProfile profile,
    required String displayName,
  }) async {
    final activityLevel = ActivityLevel.values.contains(profile.activityLevel)
        ? profile.activityLevel
        : ActivityLevel.sedentary;

    final dailyCalorieGoal = CalorieCalculator.calculateDailyGoal(
      gender: profile.gender,
      age: profile.age,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      activityLevel: activityLevel,
    );

    await _firestore.collection('users').doc(uid).set(
      {
        'rosterDisplayName': displayName,
        'username': displayName,
        'displayName': displayName,
        'email': email,
        'role': UserRole.trainee.firestoreValue,
        'gender': profile.gender.firestoreValue,
        'age': profile.age,
        'height': profile.heightCm,
        'weight': profile.weightKg,
        'activityLevel': activityLevel.firestoreValue,
        'dailyCalorieGoal': dailyCalorieGoal,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
