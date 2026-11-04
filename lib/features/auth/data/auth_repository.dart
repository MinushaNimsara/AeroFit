import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aerofit/features/auth/domain/activity_level.dart';
import 'package:aerofit/features/auth/domain/calorie_calculator.dart';
import 'package:aerofit/features/auth/domain/gender.dart';
import 'package:aerofit/features/auth/domain/sign_up_profile.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:aerofit/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Email/password (+ Google) auth backed by Firebase Auth.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _firestoreTimeout = Duration(seconds: 8);
  // Phone networks here are often 200–600ms RTT; keep headroom for Auth + reCAPTCHA.
  static const _authTimeout = Duration(seconds: 45);
  static const _restTimeout = Duration(seconds: 20);
  static const _signInTimeout = Duration(seconds: 30);
  static const _gisTimeout = Duration(seconds: 28);
  static const _networkRetryDelay = Duration(milliseconds: 700);

  static const _googleNetworkMessage =
      "Can't reach Google on this network. Try mobile data, or another Wi‑Fi.";

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Identity Toolkit key: Android app key on Android, Web key elsewhere (incl. browsers).
  static String get _identityToolkitApiKey {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return DefaultFirebaseOptions.android.apiKey;
    }
    return DefaultFirebaseOptions.web.apiKey;
  }

  /// REST IdP `requestUri` — real origin on web, localhost for native recover.
  static String get _restRequestUri =>
      kIsWeb ? Uri.base.origin : 'http://localhost';

  /// Prefer REST-first / REST recover on Android + Web (Play Integrity / browser hangs).
  static bool get _preferRestAuth =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(_authTimeout);
      await _syncIdentityBestEffort(credential.user ?? _auth.currentUser);
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      // Auth SDK can hang (attestation / flaky network) — REST then session recover.
      if (_preferRestAuth) {
        await _signInViaRest(email: normalizedEmail, password: password);
        return await _requireSignIn(
          email: normalizedEmail,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<void> _signInViaRest({
    required String email,
    required String password,
  }) async {
    final apiKey = _identityToolkitApiKey;
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(_restTimeout);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Could not reach Firebase Auth. Check your internet.',
      );
    }

    if (response.statusCode == 200) return;

    final rawMsg =
        (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
            'LOGIN_FAILED';
    if (rawMsg.contains('EMAIL_NOT_FOUND') ||
        rawMsg.contains('INVALID_PASSWORD') ||
        rawMsg.contains('INVALID_LOGIN_CREDENTIALS')) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Incorrect email or password.',
      );
    }
    if (rawMsg.contains('USER_DISABLED')) {
      throw FirebaseAuthException(
        code: 'user-disabled',
        message: 'This account has been disabled.',
      );
    }
    if (rawMsg.contains('TOO_MANY_ATTEMPTS')) {
      throw FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many attempts. Please try again later.',
      );
    }
    throw FirebaseAuthException(
      code: 'network-request-failed',
      message: 'Sign in failed: $rawMsg',
    );
  }

  /// Web OAuth client id — [GoogleSignIn.clientId] on web and
  /// [GoogleSignIn.serverClientId] on Android so Firebase gets an ID token.
  /// From google-services.json `oauth_client` type 3.
  ///
  /// Do **not** pass [serverClientId] on web — `google_sign_in_web` asserts
  /// it must be null (debug builds crash before the picker opens).
  static const _googleWebClientId =
      '189303398586-nbum19rkc9lh4dr5qd5qeus906t0iis8.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb ? _googleWebClientId : null,
    serverClientId: kIsWeb ? null : _googleWebClientId,
  );

  static FirebaseAuthException _googleNetworkError([Object? cause]) {
    if (cause != null) {
      debugPrint('Google Sign-In network failure: $cause');
    }
    return FirebaseAuthException(
      code: 'network-request-failed',
      message: _googleNetworkMessage,
    );
  }

  /// True for DNS / socket / http client failures (web + Android). Avoids
  /// importing `dart:io` (not available on web).
  static bool _isTransientNetworkFailure(Object error) {
    if (error is TimeoutException) return true;
    if (error is http.ClientException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection reset') ||
        text.contains('connection refused') ||
        text.contains('connection timed out') ||
        text.contains('connection closed') ||
        text.contains('network_error') ||
        text.contains('network error') ||
        text.contains('err_connection') ||
        text.contains('err_name_not_resolved') ||
        text.contains('xmlhttprequest error');
  }

  Future<T> _withNetworkRetry<T>(Future<T> Function() action) async {
    bool shouldRetry(Object e) {
      if (e is FirebaseAuthException) {
        return e.code == 'network-request-failed';
      }
      return _isTransientNetworkFailure(e);
    }

    try {
      return await action();
    } catch (e) {
      if (!shouldRetry(e)) rethrow;
      await Future<void>.delayed(_networkRetryDelay);
      try {
        return await action();
      } catch (retryError) {
        if (retryError is FirebaseAuthException) rethrow;
        if (_isTransientNetworkFailure(retryError)) {
          throw _googleNetworkError(retryError);
        }
        rethrow;
      }
    }
  }

  Future<GoogleSignInAccount> _obtainGoogleAccount() async {
    Future<GoogleSignInAccount> once() async {
      try {
        final account = await _googleSignIn.signIn().timeout(_gisTimeout);
        if (account == null) {
          throw FirebaseAuthException(
            code: 'aborted-by-user',
            message: 'Google Sign-In was cancelled.',
          );
        }
        return account;
      } on TimeoutException {
        throw _googleNetworkError('GIS signIn timeout');
      }
    }

    try {
      return await once();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'network-request-failed') rethrow;
      await Future<void>.delayed(_networkRetryDelay);
      return once();
    } catch (e) {
      if (!_isTransientNetworkFailure(e)) rethrow;
      await Future<void>.delayed(_networkRetryDelay);
      try {
        return await once();
      } catch (retryError) {
        if (retryError is FirebaseAuthException) rethrow;
        if (_isTransientNetworkFailure(retryError)) {
          throw _googleNetworkError(retryError);
        }
        rethrow;
      }
    }
  }

  Future<GoogleSignInAuthentication> _googleAuthentication(
    GoogleSignInAccount account,
  ) async {
    try {
      return await account.authentication.timeout(_gisTimeout);
    } on TimeoutException {
      throw _googleNetworkError('GIS authentication timeout');
    }
  }

  /// Web: Firebase GIS popup (idToken). Android: Play Services GIS + REST recover.
  ///
  /// Do not use `google_sign_in` `signIn()` on web — it only returns an access
  /// token, then hits People API (no Firebase idToken). That is the
  /// "loads after account pick, then network error" path.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    return _signInWithGoogleNative();
  }

  Future<UserCredential> _signInWithGoogleWeb() async {
    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      provider.setCustomParameters(const {'prompt': 'select_account'});
      final credential = await _auth
          .signInWithPopup(provider)
          .timeout(const Duration(seconds: 90));
      final user = credential.user ?? _auth.currentUser;
      if (user != null) await _ensureTraineeProfileExists(user);
      return credential;
    } on TimeoutException {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message:
            'Google Sign-In timed out. Close extra Google windows and try again.',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (_isTransientNetworkFailure(e)) {
        throw _googleNetworkError(e);
      }
      rethrow;
    }
  }

  Future<UserCredential> _signInWithGoogleNative() async {
    try {
      final account = await _obtainGoogleAccount();

      final googleAuth = await _googleAuthentication(account);
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: kIsWeb
              ? 'Google did not return an ID token. Check Firebase Authorized domains and the Web OAuth client id.'
              : 'Google did not return an ID token. In Firebase Console → Project settings → Your Android app: add SHA-1 and SHA-256, then download a fresh google-services.json.',
        );
      }

      final oauth = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );

      // Prefer native credential first. Calling REST IdP *before* credential
      // can leave the Auth SDK wedged on some Honor/Huawei builds.
      try {
        final userCredential = await _auth
            .signInWithCredential(oauth)
            .timeout(const Duration(seconds: 18));
        final user = userCredential.user ?? _auth.currentUser;
        if (user != null) await _ensureTraineeProfileExists(user);
        return userCredential;
      } on TimeoutException {
        // Fall through to REST + email-session recover.
      } on FirebaseAuthException {
        // Fall through — REST path still validates the Google token.
      }

      final rest = await _signInWithGoogleIdTokenViaRest(idToken);
      final email = (rest['email'] as String?)?.trim().isNotEmpty == true
          ? (rest['email'] as String).trim()
          : (account.email.trim());
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'auth-sdk-hang',
          message:
              'Google OK via REST but no email returned to finish the session.',
        );
      }

      // Fresh Google tokens after REST (previous idToken may be spent).
      final refreshed = await _googleAuthentication(account);
      final retryToken = refreshed.idToken ?? idToken;
      final retryOauth = GoogleAuthProvider.credential(
        accessToken: refreshed.accessToken ?? googleAuth.accessToken,
        idToken: retryToken,
      );
      try {
        final userCredential = await _auth
            .signInWithCredential(retryOauth)
            .timeout(const Duration(seconds: 12));
        final user = userCredential.user ?? _auth.currentUser;
        if (user != null) await _ensureTraineeProfileExists(user);
        return userCredential;
      } on TimeoutException {
        // Continue — email session recover below.
      } on FirebaseAuthException {
        // Continue.
      }

      // Last resort: enable email/password on this Google account via REST,
      // then use email sign-in (works when credential path hangs).
      final firebaseIdToken = rest['idToken'] as String?;
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'auth-sdk-hang',
          message:
              'Google OK but Firebase Auth hung and no session token to recover.',
        );
      }
      final tempPassword = _randomPassword();
      await _setPasswordViaRest(
        idToken: firebaseIdToken,
        password: tempPassword,
      );
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: tempPassword)
          .timeout(_signInTimeout);
      final user = userCredential.user ?? _auth.currentUser;
      if (user != null) await _ensureTraineeProfileExists(user);
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      final code = e.code;
      final details = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
      if (code == 'sign_in_canceled' ||
          code == 'sign_in_cancelled' ||
          details.contains('canceled') ||
          details.contains('cancelled')) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Google Sign-In was cancelled.',
        );
      }
      // Common: ApiException: 10 / DEVELOPER_ERROR → SHA-1 / OAuth client mismatch.
      if (details.contains('10') ||
          details.contains('developer_error') ||
          details.contains('api_exception: 10')) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message:
              'Google Sign-In config error (code 10). Add SHA-1 + SHA-256 in Firebase, download fresh google-services.json, rebuild.',
        );
      }
      if (details.contains('7') ||
          details.contains('network') ||
          _isTransientNetworkFailure(e)) {
        throw _googleNetworkError(e);
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Google Sign-In failed ($code): ${e.message ?? e}',
      );
    } catch (e) {
      if (_isTransientNetworkFailure(e)) {
        throw _googleNetworkError(e);
      }
      rethrow;
    }
  }

  String _randomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
    final rng = Random.secure();
    return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _setPasswordViaRest({
    required String idToken,
    required String password,
  }) async {
    await _withNetworkRetry(() async {
      final apiKey = _identityToolkitApiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
      );
      late final http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'idToken': idToken,
                'password': password,
                'returnSecureToken': true,
              }),
            )
            .timeout(_restTimeout);
      } on TimeoutException {
        throw _googleNetworkError('accounts:update timeout');
      }

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw FirebaseAuthException(
          code: 'auth-sdk-hang',
          message: 'Could not finish Google session recover (bad server reply).',
        );
      }
      if (response.statusCode == 200) return;
      final rawMsg =
          (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
              'UPDATE_FAILED';
      throw FirebaseAuthException(
        code: 'auth-sdk-hang',
        message: 'Google session recover failed: $rawMsg',
      );
    });
  }

  Future<Map<String, dynamic>> _signInWithGoogleIdTokenViaRest(
    String idToken,
  ) async {
    return _withNetworkRetry(() async {
      final apiKey = _identityToolkitApiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey',
      );
      late final http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'postBody':
                    'id_token=${Uri.encodeQueryComponent(idToken)}&providerId=google.com',
                'requestUri': _restRequestUri,
                'returnIdpCredential': true,
                'returnSecureToken': true,
              }),
            )
            .timeout(_restTimeout);
      } on TimeoutException {
        throw _googleNetworkError('signInWithIdp timeout');
      }

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: _googleNetworkMessage,
        );
      }

      if (response.statusCode == 200) return body;

      final rawMsg =
          (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
              'GOOGLE_SIGNIN_FAILED';
      if (rawMsg.contains('OPERATION_NOT_ALLOWED')) {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Google Sign-In is not enabled in Firebase Console.',
        );
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Google Sign-In rejected by Firebase: $rawMsg',
      );
    });
  }

  Future<void> _syncIdentityBestEffort(User? user) async {
    if (user == null) return;
    try {
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
      if (payload.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true))
          .timeout(_firestoreTimeout);
    } catch (_) {
      // Never block auth on Firestore / network failures.
    }
  }

  Future<void> _ensureTraineeProfileExists(User user) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(_firestoreTimeout);
      if (doc.exists && doc.data() != null) {
        await _syncIdentityBestEffort(user);
        return;
      }

      final email = user.email?.trim() ?? '';
      final displayName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : UserProfile.emailPrefix(email);

      await _createTraineeProfile(
        uid: user.uid,
        email: email,
        profile: const SignUpProfile(
          displayName: '',
          gender: Gender.male,
          age: 25,
          heightCm: 170,
          weightKg: 70,
          activityLevel: ActivityLevel.sedentary,
        ),
        displayName: displayName,
      );
    } catch (_) {
      // Profile can sync later when network recovers.
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password;

    // Android Play Integrity / web Auth SDK can hang on createUser.
    // Prefer Identity Toolkit REST first on Android + Web.
    if (_preferRestAuth) {
      try {
        return await _signUpViaRest(
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
          if (recovered != null) return recovered;
        }
        rethrow;
      } catch (_) {
        // Fall through to native SDK path.
      }
    }

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
        if (recovered != null) return recovered;
        throw FirebaseAuthException(
          code: 'email-already-in-use',
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
      if (recovered != null) return recovered;

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
        return await _requireSignIn(
          email: normalizedEmail,
          password: normalizedPassword,
        );
      }

      try {
        return await _signUpViaRest(
          email: normalizedEmail,
          password: normalizedPassword,
          profile: profile,
        );
      } on FirebaseAuthException {
        rethrow;
      } catch (restErr) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Registration could not be completed: $restErr',
        );
      }
    }
  }

  Future<UserCredential> _requireSignIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_signInTimeout);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      final current = _auth.currentUser;
      if (current != null) {
        // Session already live — synthesize via re-auth attempt once more.
        try {
          return await _auth
              .signInWithEmailAndPassword(email: email, password: password)
              .timeout(_signInTimeout);
        } catch (_) {}
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Account exists but sign-in failed. Try Sign In. ($e)',
      );
    }
  }

  Future<UserCredential> _signUpViaRest({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    final apiKey = _identityToolkitApiKey;
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(_restTimeout);

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Server returned an unexpected response. Please try again.',
      );
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
      }
      if (rawMsg.startsWith('WEAK_PASSWORD')) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use at least 6 characters.',
        );
      }
      if (rawMsg.startsWith('INVALID_EMAIL')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      }
      if (rawMsg.startsWith('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        throw FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many attempts. Please try again later.',
        );
      }
      if (rawMsg.contains('OPERATION_NOT_ALLOWED')) {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message:
              'Email/password sign-up is disabled in Firebase Console.',
        );
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed: $rawMsg',
      );
    }

    final uid = body['localId'] as String?;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Account was created but no user id was returned.',
      );
    }

    final displayName = profile.displayName.trim().isNotEmpty
        ? profile.displayName.trim()
        : UserProfile.emailPrefix(email);

    final credential = await _requireSignIn(email: email, password: password);
    final resolvedUid = credential.user?.uid ?? _auth.currentUser?.uid ?? uid;

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

    return credential;
  }

  Future<UserCredential> _createAccountAndProfile({
    required String email,
    required String password,
    required SignUpProfile profile,
  }) async {
    UserCredential credential;
    try {
      credential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(_authTimeout);
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

        return await _requireSignIn(email: email, password: password);
      }
      if (createErr is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Sign up failed: $createErr',
      );
    }

    final uid = credential.user?.uid ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Account was created but no user session was returned.',
      );
    }

    try {
      await (credential.user ?? _auth.currentUser)?.getIdToken(true);
    } catch (_) {}

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
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(_signInTimeout);
      final uid = credential.user?.uid ?? _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;

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
      } catch (_) {}
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
    ).timeout(_firestoreTimeout);
  }
}
