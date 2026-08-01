import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class GymEnrollmentRepository {
  GymEnrollmentRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestore ??
      FirebaseFirestore.instanceFor(app: Firebase.app());

  /// Enrolls a trainee under the authenticated coach using [coachId] as the
  /// primary relational key.
  Future<UserProfile> enrollTrainee({
    required String traineeUid,
    required UserProfile coach,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready.');
    }

    if (!coach.isCoach) {
      throw Exception('You must be signed in as a coach to enroll members.');
    }

    final coachUid = coach.uid.trim();
    if (coachUid.isEmpty) {
      throw Exception('Your coach session is invalid. Sign in again.');
    }

    final trimmedUid = traineeUid.trim();
    if (trimmedUid.isEmpty) {
      throw Exception('Invalid trainee QR code.');
    }
    if (trimmedUid == coachUid) {
      throw Exception('Scan the trainee Gym Pass QR, not your own account.');
    }

    final traineeRef = _db.collection('users').doc(trimmedUid);
    final traineeSnap = await traineeRef.get();

    if (!traineeSnap.exists || traineeSnap.data() == null) {
      throw Exception(
        'Trainee account not found. Ask them to sign up and open the Hub once before scanning.',
      );
    }

    final rawData = traineeSnap.data()!;
    final trainee = UserProfile.fromFirestore(trimmedUid, rawData);
    if (!trainee.isTrainee) {
      throw Exception('This QR code does not belong to a trainee account.');
    }

    final existingCoachId = trainee.coachId?.trim() ?? '';
    if (existingCoachId.isNotEmpty && existingCoachId != coachUid) {
      throw Exception(
        '${trainee.rosterLabel} is already enrolled with another coach.',
      );
    }

    final coachGymName = coach.gymName?.trim() ?? '';
    final identity = _resolveTraineeIdentity(rawData);

    if (existingCoachId == coachUid) {
      await _backfillTraineeIdentity(
        traineeRef: traineeRef,
        identity: identity,
      );
      await _upsertEnrolledTraineeCache(
        coachUid: coachUid,
        traineeUid: trimmedUid,
        identity: identity,
      );
      final updated = await traineeRef.get();
      return UserProfile.fromFirestore(trimmedUid, updated.data()!);
    }

    await traineeRef.update({
      'coachId': coachUid,
      if (coachGymName.isNotEmpty) 'gymName': coachGymName,
      'enrolledAt': FieldValue.serverTimestamp(),
      ..._identityWritePayload(identity),
    });

    await _upsertEnrolledTraineeCache(
      coachUid: coachUid,
      traineeUid: trimmedUid,
      identity: identity,
    );

    final updated = await traineeRef.get();
    return UserProfile.fromFirestore(trimmedUid, updated.data()!);
  }

  ({String displayName, String? email}) _resolveTraineeIdentity(
    Map<String, dynamic> data,
  ) {
    final resolvedName = UserProfile.resolveRosterNameFromMap(data);
    final resolvedEmail = UserProfile.parseEmail(data);
    final emailPrefix = UserProfile.emailPrefix(resolvedEmail);

    final displayName = resolvedName.isNotEmpty
        ? resolvedName
        : emailPrefix.isNotEmpty
            ? emailPrefix
            : '';

    return (displayName: displayName, email: resolvedEmail);
  }

  Map<String, dynamic> _identityWritePayload(
    ({String displayName, String? email}) identity,
  ) {
    return {
      if (identity.displayName.isNotEmpty) 'rosterDisplayName': identity.displayName,
      if (identity.displayName.isNotEmpty) 'username': identity.displayName,
      if (identity.displayName.isNotEmpty) 'displayName': identity.displayName,
      if (identity.email != null) 'email': identity.email,
    };
  }

  Future<void> _backfillTraineeIdentity({
    required DocumentReference<Map<String, dynamic>> traineeRef,
    required ({String displayName, String? email}) identity,
  }) async {
    final payload = _identityWritePayload(identity);
    if (payload.isEmpty) return;
    await traineeRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _upsertEnrolledTraineeCache({
    required String coachUid,
    required String traineeUid,
    required ({String displayName, String? email}) identity,
  }) async {
    final cacheRef = _db
        .collection('users')
        .doc(coachUid)
        .collection('enrolled_trainees')
        .doc(traineeUid);

    await cacheRef.set(
      {
        'uid': traineeUid,
        if (identity.displayName.isNotEmpty) 'displayName': identity.displayName,
        if (identity.email != null) 'email': identity.email,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
