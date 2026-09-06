import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/calorie_calculator.dart';
import 'package:aerofit/features/auth/domain/sign_up_profile.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      final recovered = await _tryRecoverPartialRegistration(
        email: normalizedEmail,
        password: normalizedPassword,
        profile: profile,
      );
      if (recovered != null) {
        return recovered;
      }

      final errLower = e.toString().toLowerCase();
      if (errLower.contains('null check operator') ||
          errLower.contains('typeerror') ||
          errLower.contains('not an object')) {
        // On iOS Safari, firebase_auth_web can crash converting Firebase Auth error responses.
        throw FirebaseAuthException(
          code: 'registration-failed',
          message:
              'This email may already be in use. Switch to Sign In to log in.',
        );
      }
      throw Exception('Could not create your account: $e');
    }
  }

  Future<UserCredential> _createAccountAndProfile({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

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

    await _createTraineeProfile(
      uid: uid,
      email: email,
      profile: profile,
      displayName: displayName,
    );

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
