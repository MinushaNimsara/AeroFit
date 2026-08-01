import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Set<String> _identitySyncAttempted = <String>{};

  FirebaseFirestore? get _db =>
      _firestore ??
      (FirebaseBootstrap.isReady
          ? FirebaseFirestore.instanceFor(app: Firebase.app())
          : null);

  /// Mirrors Firebase Auth identity fields into Firestore so coaches can read them.
  Future<void> syncAuthIdentityFields({
    required String uid,
    String? email,
    String? authDisplayName,
  }) async {
    final db = _db;
    if (db == null || uid.trim().isEmpty) return;
    if (_identitySyncAttempted.contains(uid)) return;
    _identitySyncAttempted.add(uid);

    final trimmedEmail = email?.trim();
    final trimmedAuthName = authDisplayName?.trim();
    final resolvedName = trimmedAuthName != null && trimmedAuthName.isNotEmpty
        ? trimmedAuthName
        : UserProfile.emailPrefix(trimmedEmail);

    final payload = <String, dynamic>{};
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      payload['email'] = trimmedEmail;
    }
    if (resolvedName.isNotEmpty) {
      payload['rosterDisplayName'] = resolvedName;
      payload['username'] = resolvedName;
      payload['displayName'] = resolvedName;
    }

    if (payload.isEmpty) return;

    final docRef = db.collection('users').doc(uid);
    final existing = await docRef.get();
    final current = existing.data() ?? const <String, dynamic>{};

    final needsWrite = payload.entries.any((entry) {
      final currentValue = current[entry.key]?.toString().trim() ?? '';
      return currentValue != entry.value.toString().trim();
    });

    if (!needsWrite) return;

    await docRef.set(payload, SetOptions(merge: true));
  }

  Stream<UserProfile?> watchProfile(String uid) {
    final db = _db;
    if (db == null) return Stream.value(null);

    return db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap.id, snap.data()!);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final db = _db;
    if (db == null) return null;

    final snap = await db.collection('users').doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(snap.id, snap.data()!);
  }
}
