import 'dart:async';

import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/domain/user_role.dart';
import 'package:aerofit/features/master_admin/domain/coach_registry_entry.dart';
import 'package:aerofit/features/master_admin/domain/coach_workout_schedule.dart';
import 'package:aerofit/features/master_admin/domain/gym_trainee_progress.dart';
import 'package:aerofit/features/master_admin/domain/platform_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class MasterAdminRepository {
  MasterAdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestore ??
      FirebaseFirestore.instanceFor(app: Firebase.app());

  Stream<PlatformAnalytics> watchPlatformAnalytics() {
    if (!FirebaseBootstrap.isReady) {
      return Stream.value(PlatformAnalytics.empty);
    }

    return _db.collection('users').snapshots().map(_aggregateAnalytics);
  }

  Stream<List<CoachRegistryEntry>> watchCoachRegistry() {
    if (!FirebaseBootstrap.isReady) {
      return Stream.value(const []);
    }

    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.coach.firestoreValue)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs.map(_parseCoachEntry).toList()
        ..sort(
          (a, b) =>
              (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
        );
      return entries;
    });
  }

  PlatformAnalytics _aggregateAnalytics(QuerySnapshot<Map<String, dynamic>> snap) {
    var activeCoaches = 0;
    var totalTrainees = 0;
    final gymKeys = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final role = data['role'] as String?;

      if (role == UserRole.coach.firestoreValue) {
        activeCoaches++;
        final gymName = (data['gymName'] as String?)?.trim();
        gymKeys.add(
          gymName != null && gymName.isNotEmpty ? gymName : doc.id,
        );
      } else if (role == UserRole.trainee.firestoreValue) {
        totalTrainees++;
      }
    }

    return PlatformAnalytics(
      totalGyms: gymKeys.length,
      activeCoaches: activeCoaches,
      totalTrainees: totalTrainees,
    );
  }

  Stream<int> watchActiveGymTraineeCount(String gymName) {
    return watchGymTraineeProgress(gymName).map((trainees) => trainees.length);
  }

  Stream<List<GymTraineeProgress>> watchGymTraineeProgress(String gymName) {
    if (!FirebaseBootstrap.isReady || gymName.trim().isEmpty) {
      return Stream.value(const []);
    }

    final normalized = gymName.trim();
    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.trainee.firestoreValue)
        .where('gymName', isEqualTo: normalized)
        .snapshots()
        .asyncExpand((snapshot) {
      if (snapshot.docs.isEmpty) {
        return Stream.value(const <GymTraineeProgress>[]);
      }
      return _mergeTraineeProgressStreams(snapshot.docs);
    });
  }

  Stream<List<GymTraineeProgress>> _mergeTraineeProgressStreams(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final controller = StreamController<List<GymTraineeProgress>>.broadcast();
    final latest = <String, GymTraineeProgress>{};
    final subscriptions = <StreamSubscription<GymTraineeProgress>>[];

    void emitSorted() {
      final list = latest.values.toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      if (!controller.isClosed) controller.add(list);
    }

    for (final doc in docs) {
      subscriptions.add(
        _watchSingleTraineeProgress(doc).listen(
          (progress) {
            latest[doc.id] = progress;
            emitSorted();
          },
          onError: controller.addError,
        ),
      );
    }

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Stream<GymTraineeProgress> _watchSingleTraineeProgress(
    QueryDocumentSnapshot<Map<String, dynamic>> userDoc,
  ) {
    final data = userDoc.data();
    final displayName = (data['displayName'] as String?)?.trim() ?? 'Trainee';
    final goal = (data['dailyCalorieGoal'] as num?)?.round() ??
        Env.dailyCalorieGoal;
    final lastWorkout = data['lastWorkoutTimestamp'];
    DateTime? lastActive;
    if (lastWorkout is Timestamp) {
      lastActive = lastWorkout.toDate();
    }

    final (start, end) = _todayRange;
    return _db
        .collection('users')
        .doc(userDoc.id)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((mealSnap) {
      final consumed = mealSnap.docs.fold<int>(
        0,
        (total, doc) => total + ((doc.data()['calories'] as num?)?.round() ?? 0),
      );

      return GymTraineeProgress(
        uid: userDoc.id,
        displayName: displayName,
        caloriesConsumed: consumed,
        calorieGoal: goal > 0 ? goal : Env.dailyCalorieGoal,
        lastActiveAt: lastActive,
      );
    });
  }

  Stream<List<CoachWorkoutSchedule>> watchCoachWorkoutSchedules(
    String coachUid,
  ) {
    if (!FirebaseBootstrap.isReady || coachUid.isEmpty) {
      return Stream.value(const []);
    }

    final templatesRef = _db
        .collection('users')
        .doc(coachUid)
        .collection('workout_templates');
    final splitsRef = _db
        .collection('users')
        .doc(coachUid)
        .collection('workout_splits');

    return templatesRef.snapshots().asyncMap((templateSnap) async {
      final schedules = templateSnap.docs
          .map(_parseWorkoutTemplate)
          .where((s) => s.name.isNotEmpty)
          .toList();

      if (schedules.isNotEmpty) return schedules;

      final splitSnap = await splitsRef.get();
      return splitSnap.docs.map(_parseWorkoutSplitAsSchedule).toList();
    });
  }

  CoachWorkoutSchedule _parseWorkoutTemplate(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final days = data['days'];
    final preview = <String>[];
    var totalDays = 0;

    if (days is List) {
      totalDays = days.length;
      for (final day in days) {
        if (day is Map) {
          final workouts = day['workouts'];
          if (workouts is List) {
            for (final workout in workouts) {
              if (workout is String && workout.trim().isNotEmpty) {
                preview.add(workout.trim());
              }
            }
          }
          final label = day['label'] as String?;
          if (label != null && label.trim().isNotEmpty && preview.isEmpty) {
            preview.add(label.trim());
          }
        }
      }
    }

    return CoachWorkoutSchedule(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Untitled Schedule',
      totalDays: totalDays > 0 ? totalDays : 1,
      workoutPreview: preview.take(6).toList(),
      sourceCollection: 'workout_templates',
    );
  }

  CoachWorkoutSchedule _parseWorkoutSplitAsSchedule(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final days = data['days'];
    var totalDays = 1;
    final preview = <String>[];

    if (days is List && days.isNotEmpty) {
      totalDays = days.length;
      for (final day in days) {
        if (day is String && day.trim().isNotEmpty) {
          preview.add(day.trim());
        }
      }
    }

    final name = (data['name'] as String?)?.trim() ?? 'Workout Split';
    if (preview.isEmpty) preview.add(name);

    return CoachWorkoutSchedule(
      id: doc.id,
      name: name,
      totalDays: totalDays,
      workoutPreview: preview.take(6).toList(),
      sourceCollection: 'workout_splits',
    );
  }

  Future<void> cloneWorkoutSchedule({
    required String sourceCoachUid,
    required CoachWorkoutSchedule schedule,
    required String targetCoachUid,
    required String targetGymName,
  }) async {
    final sourceCollection = _db
        .collection('users')
        .doc(sourceCoachUid)
        .collection(schedule.sourceCollection);

    final sourceDoc = await sourceCollection.doc(schedule.id).get();
    if (!sourceDoc.exists || sourceDoc.data() == null) {
      throw Exception('Source schedule could not be found.');
    }

    final payload = Map<String, dynamic>.from(sourceDoc.data()!);
    final targetRef = _db
        .collection('users')
        .doc(targetCoachUid)
        .collection('workout_templates')
        .doc();

    payload['id'] = targetRef.id;
    payload['name'] = '${payload['name'] ?? schedule.name} (Copy)';
    payload['gymName'] = targetGymName.trim();
    payload['clonedFromCoachUid'] = sourceCoachUid;
    payload['clonedFromScheduleId'] = schedule.id;
    payload['clonedAt'] = FieldValue.serverTimestamp();
    payload['createdAt'] = FieldValue.serverTimestamp();

    await targetRef.set(payload);
  }

  (DateTime, DateTime) get _todayRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (start, start.add(const Duration(days: 1)));
  }

  CoachRegistryEntry _parseCoachEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    DateTime? parsedCreatedAt;
    if (createdAt is Timestamp) {
      parsedCreatedAt = createdAt.toDate();
    }

    return CoachRegistryEntry(
      uid: doc.id,
      gymName: (data['gymName'] as String?)?.trim() ?? '—',
      coachName: (data['displayName'] as String?)?.trim() ?? '—',
      email: (data['email'] as String?)?.trim() ?? '—',
      createdAt: parsedCreatedAt,
    );
  }

  /// Creates a coach Auth account via a secondary Firebase app so the master
  /// admin session on the primary app stays signed in.
  Future<String> registerGymAndCoach({
    required String gymName,
    required String coachFullName,
    required String coachEmail,
    required String coachPassword,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready.');
    }

    final appName = 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final coachCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: coachEmail.trim(),
        password: coachPassword,
      );

      final coachUser = coachCred.user;
      if (coachUser == null) {
        throw Exception('Coach account was created but no user was returned.');
      }

      final uid = coachUser.uid;
      await coachUser.updateDisplayName(coachFullName.trim());

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'role': UserRole.coach.firestoreValue,
        'displayName': coachFullName.trim(),
        'email': coachEmail.trim(),
        'gymName': gymName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
      return uid;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to create coach account.');
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<void> updateCoachProfile({
    required String coachUid,
    required String gymName,
    required String coachFullName,
  }) async {
    if (!FirebaseBootstrap.isReady) {
      throw Exception('Firebase is not ready.');
    }

    final trimmedUid = coachUid.trim();
    if (trimmedUid.isEmpty) {
      throw Exception('Invalid coach account.');
    }

    final coachRef = _db.collection('users').doc(trimmedUid);
    final coachSnap = await coachRef.get();
    if (!coachSnap.exists || coachSnap.data() == null) {
      throw Exception('Coach account not found.');
    }

    final role = coachSnap.data()!['role'] as String?;
    if (role != UserRole.coach.firestoreValue) {
      throw Exception('This account is not a coach profile.');
    }

    await coachRef.set(
      {
        'displayName': coachFullName.trim(),
        'gymName': gymName.trim(),
      },
      SetOptions(merge: true),
    );
  }

  /// Firebase client SDK cannot set another user's password directly.
  /// Sends a secure password reset email so the coach can update credentials.
  Future<void> sendCoachPasswordResetEmail(String coachEmail) async {
    final email = coachEmail.trim();
    if (email.isEmpty) {
      throw Exception('Coach email is missing.');
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Could not send password reset email.');
    }
  }
}
