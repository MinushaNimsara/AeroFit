import 'dart:async';

import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:aerofit/features/live_workout/domain/live_workout_status.dart';
import 'package:aerofit/features/live_workout/domain/slacking_alert.dart';
import 'package:aerofit/features/live_workout/domain/workout_session_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class LiveWorkoutRepository {
  LiveWorkoutRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const defaultSetsPerExercise = 4;

  FirebaseFirestore get _db =>
      _firestore ??
      FirebaseFirestore.instanceFor(app: Firebase.app());

  static const _statusDocId = 'current';

  DocumentReference<Map<String, dynamic>> _statusRef(String uid) =>
      _db.collection('users').doc(uid).collection('live_status').doc(_statusDocId);

  Stream<LiveWorkoutStatus> watchLiveStatus(String uid) {
    if (!FirebaseBootstrap.isReady) return Stream.value(LiveWorkoutStatus.idle);

    return _statusRef(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return LiveWorkoutStatus.idle;
      return LiveWorkoutStatus.fromFirestore(snap.data()!);
    });
  }

  Stream<List<WorkoutSessionHistory>> watchRecentWorkoutHistory(
    String traineeUid, {
    int limit = 3,
  }) {
    if (!FirebaseBootstrap.isReady || traineeUid.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _db
        .collection('users')
        .doc(traineeUid)
        .collection('workout_history')
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(WorkoutSessionHistory.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<int> watchMaxRestMinutesForGym(String? gymName) {
    if (!FirebaseBootstrap.isReady || gymName == null || gymName.trim().isEmpty) {
      return Stream.value(3);
    }

    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.coach.firestoreValue)
        .where('gymName', isEqualTo: gymName.trim())
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return 3;
      return (snap.docs.first.data()['maxRestMinutes'] as num?)?.round() ?? 3;
    });
  }

  Future<void> updateCoachMaxRestMinutes({
    required String coachUid,
    required int minutes,
  }) async {
    await _db.collection('users').doc(coachUid).set(
      {'maxRestMinutes': minutes.clamp(1, 15)},
      SetOptions(merge: true),
    );
  }

  Future<void> startWorkout({
    required String uid,
    required String scheduleName,
    required String firstWorkout,
    required int totalExercises,
    int totalSets = defaultSetsPerExercise,
    String? gymName,
    String? traineeName,
  }) async {
    await _statusRef(uid).set({
      'isWorkingOut': true,
      'activeScheduleName': scheduleName,
      'activeRoutineName': scheduleName,
      'currentWorkout': firstWorkout,
      'currentExercise': firstWorkout,
      'status': 'working',
      'completedSets': 0,
      'totalSets': totalSets.clamp(1, 20),
      'totalExercisesInSession': totalExercises,
      'nudgeTriggered': false,
      'gymName': gymName,
      'traineeName': traineeName,
      'completedWorkouts': <String>[],
      'startedAt': FieldValue.serverTimestamp(),
      'restStartedAt': null,
    });
    await _db.collection('users').doc(uid).set(
      {'lastWorkoutTimestamp': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> updateSetProgress({
    required String uid,
    required String currentExercise,
    required int completedSets,
    required int totalSets,
    required List<String> completedWorkouts,
    required String status,
    bool restStarted = false,
  }) async {
    final updates = <String, dynamic>{
      'currentExercise': currentExercise,
      'currentWorkout': currentExercise,
      'completedSets': completedSets,
      'totalSets': totalSets,
      'completedWorkouts': completedWorkouts,
      'status': status,
      'isWorkingOut': true,
      'nudgeTriggered': false,
    };
    if (restStarted) {
      updates['restStartedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'working') {
      updates['restStartedAt'] = null;
    }
    await _statusRef(uid).set(updates, SetOptions(merge: true));
    if (status == 'working') {
      await _db.collection('users').doc(uid).set(
        {'lastWorkoutTimestamp': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> updateWorkoutProgress({
    required String uid,
    required String currentWorkout,
    required List<String> completedWorkouts,
    required String status,
    bool restStarted = false,
  }) async {
    await updateSetProgress(
      uid: uid,
      currentExercise: currentWorkout,
      completedSets: 0,
      totalSets: defaultSetsPerExercise,
      completedWorkouts: completedWorkouts,
      status: status,
      restStarted: restStarted,
    );
  }

  Future<void> markSlacking(String uid) async {
    await _statusRef(uid).set(
      {'status': 'slacking', 'isWorkingOut': true},
      SetOptions(merge: true),
    );
  }

  Future<void> sendNudge(String traineeUid) async {
    await _statusRef(traineeUid).set(
      {'nudgeTriggered': true},
      SetOptions(merge: true),
    );
  }

  Future<void> clearNudge(String uid) async {
    await _statusRef(uid).set(
      {'nudgeTriggered': false},
      SetOptions(merge: true),
    );
  }

  Future<void> endWorkout(String uid) async {
    await _statusRef(uid).set(
      {
        'isWorkingOut': false,
        'status': 'idle',
        'currentWorkout': '',
        'currentExercise': '',
        'completedSets': 0,
        'restStartedAt': null,
        'nudgeTriggered': false,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> endWorkoutWithSummary({
    required String uid,
    required LiveWorkoutStatus status,
    required int exercisesCompleted,
    required int totalExercises,
  }) async {
    final startedAt = status.startedAt;
    final endedAt = DateTime.now();
    final durationMinutes = startedAt == null
        ? 0
        : endedAt.difference(startedAt).inMinutes.clamp(0, 24 * 60);

    final historyRef =
        _db.collection('users').doc(uid).collection('workout_history').doc();

    final batch = _db.batch();
    batch.set(historyRef, {
      'id': historyRef.id,
      'routineName': status.routineDisplayName,
      'exercisesCompleted': exercisesCompleted,
      'totalExercises': totalExercises,
      'durationMinutes': durationMinutes,
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _statusRef(uid),
      {
        'isWorkingOut': false,
        'status': 'completed',
        'currentWorkout': '',
        'currentExercise': '',
        'completedSets': 0,
        'restStartedAt': null,
        'nudgeTriggered': false,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<List<SlackingAlert>> watchSlackingAlertsForCoach(String? coachUid) {
    if (!FirebaseBootstrap.isReady || coachUid == null || coachUid.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _db
        .collection('users')
        .where('coachId', isEqualTo: coachUid.trim())
        .snapshots()
        .asyncExpand((snapshot) {
      if (snapshot.docs.isEmpty) {
        return Stream.value(const <SlackingAlert>[]);
      }
      return _mergeSlackingStreams(snapshot.docs);
    });
  }

  Stream<List<SlackingAlert>> _mergeSlackingStreams(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> traineeDocs,
  ) {
    final controller = StreamController<List<SlackingAlert>>.broadcast();
    final latest = <String, SlackingAlert?>{};
    final subs = <StreamSubscription<SlackingAlert?>>[];

    void emit() {
      final alerts = latest.values
          .whereType<SlackingAlert>()
          .toList()
        ..sort((a, b) => a.traineeName.compareTo(b.traineeName));
      if (!controller.isClosed) controller.add(alerts);
    }

    for (final doc in traineeDocs) {
      final name = (doc.data()['displayName'] as String?)?.trim() ?? 'Trainee';
      subs.add(
        watchLiveStatus(doc.id).map((status) {
          if (!status.isSlacking) return null;
          return SlackingAlert(
            traineeUid: doc.id,
            traineeName: status.traineeName ?? name,
            workoutName: status.activeExerciseLabel,
            scheduleName: status.activeScheduleName,
            since: status.restStartedAt ?? status.startedAt,
          );
        }).listen(
          (alert) {
            latest[doc.id] = alert;
            emit();
          },
          onError: controller.addError,
        ),
      );
    }

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }
}
