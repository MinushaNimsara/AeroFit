import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Email/password auth backed by the manually configured Firebase Web app.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instanceFor(app: Firebase.app()),
        _firestore = firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
      await _ensureUserProfile(user, displayName.trim());
    }

    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _ensureUserProfile(User user, String displayName) async {
    await _firestore.collection('users').doc(user.uid).set(
      {
        'displayName': displayName,
        'dailyCalorieGoal': 2000,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
