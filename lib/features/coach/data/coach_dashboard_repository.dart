import 'dart:async';

import 'package:aerofit/core/config/env.dart';
import 'package:aerofit/core/firebase/firebase_bootstrap.dart';
import 'package:aerofit/features/auth/domain/user_profile.dart';
import 'package:aerofit/features/coach/domain/coach_trainee_member.dart';
import 'package:aerofit/features/coach/domain/coach_workout_template.dart';
import 'package:aerofit/features/coach/domain/trainee_profile_snapshot.dart';
import 'package:aerofit/features/live_workout/domain/live_workout_status.dart';
import 'package:aerofit/features/meals/domain/meal_entry.dart';
import 'package:aerofit/features/routine/domain/routine_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class CoachDashboardRepository {
  CoachDashboardRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  (DateTime, DateTime) get _todayRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (start, start.add(const Duration(days: 1)));
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _watchCoachTraineeDocs(
    String coachUid,
  ) {
    if (!FirebaseBootstrap.isReady || coachUid.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _db
        .collection('users')
        .where('coachId', isEqualTo: coachUid.trim())
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Only emits when trainees are added/removed — not on every profile field edit.
  /// Prevents the roster stream from restarting and staying stuck on loading.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _watchCoachTraineeMembership(String coachUid) {
    String? lastMembershipKey;

    return _watchCoachTraineeDocs(coachUid).where((docs) {
      final ids = docs.map((doc) => doc.id).toList()..sort();
      final key = ids.join(',');
      if (key == lastMembershipKey) return false;
      lastMembershipKey = key;
      return true;
    });
  }

  Stream<int> watchTotalMembers(String? coachUid) {
    if (coachUid == null || coachUid.trim().isEmpty) {
      return Stream.value(0);
    }
    return _watchCoachTraineeDocs(coachUid).map((docs) => docs.length);
  }

  Stream<int> watchActiveNowCount(String? coachUid) {
    if (coachUid == null || coachUid.trim().isEmpty) {
      return Stream.value(0);
    }

    return _watchCoachTraineeDocs(coachUid).asyncExpand((docs) {
      if (docs.isEmpty) return Stream.value(0);

      final controller = StreamController<int>.broadcast();
      final active = <String, bool>{};

      void emit() {
        if (!controller.isClosed) {
          controller.add(active.values.where((v) => v).length);
        }
      }

      final subs = <StreamSubscription<LiveWorkoutStatus>>[];
      for (final doc in docs) {
        subs.add(
          _watchLiveStatus(doc.id).listen(
            (status) {
              active[doc.id] = status.isWorkingOut;
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
    });
  }

  Stream<List<CoachTraineeMember>> watchCoachRoster(String? coachUid) {
    if (coachUid == null || coachUid.trim().isEmpty) {
      return Stream.value(const []);
    }

    return _watchCoachTraineeMembership(coachUid).asyncExpand((docs) {
      if (docs.isEmpty) return Stream.value(const <CoachTraineeMember>[]);

      final controller = StreamController<List<CoachTraineeMember>>.broadcast();
      final latest = <String, CoachTraineeMember>{};

      void emitSorted() {
        final list = latest.values.toList()
          ..sort(
            (a, b) => a.displayLabel
                .toLowerCase()
                .compareTo(b.displayLabel.toLowerCase()),
          );
        if (!controller.isClosed) controller.add(list);
      }

      final subs = <StreamSubscription<CoachTraineeMember>>[];

      for (final doc in docs) {
        subs.add(
          _watchSingleMember(coachUid: coachUid.trim(), userDoc: doc).listen(
            (member) {
              latest[doc.id] = member;
              emitSorted();
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
    });
  }

  Stream<CoachTraineeMember> _watchSingleMember({
    required String coachUid,
    required QueryDocumentSnapshot<Map<String, dynamic>> userDoc,
  }) async* {
    final uid = userDoc.id;
    final seedData = Map<String, dynamic>.from(userDoc.data());
    final userRef = _db.collection('users').doc(uid);
    final (start, end) = _todayRange;

    yield await _buildTraineeMember(
      uid: uid,
      coachUid: coachUid,
      seedData: seedData,
      userData: seedData,
      start: start,
      end: end,
      userRef: userRef,
      includeLiveAndMeals: false,
    );

    await for (final userSnap in userRef.snapshots()) {
      final userData = UserProfile.mergeUserData(seedData, userSnap.data());
      yield await _buildTraineeMember(
        uid: uid,
        coachUid: coachUid,
        seedData: seedData,
        userData: userData,
        start: start,
        end: end,
        userRef: userRef,
        includeLiveAndMeals: true,
      );
    }
  }

  Future<CoachTraineeMember> _buildTraineeMember({
    required String uid,
    required String coachUid,
    required Map<String, dynamic> seedData,
    required Map<String, dynamic> userData,
    required DateTime start,
    required DateTime end,
    required DocumentReference<Map<String, dynamic>> userRef,
    required bool includeLiveAndMeals,
  }) async {
    Map<String, dynamic> cacheData = const {};
    try {
      final cacheSnap = await _db
          .collection('users')
          .doc(coachUid)
          .collection('enrolled_trainees')
          .doc(uid)
          .get();
      cacheData = cacheSnap.data() ?? const {};
    } catch (_) {}

    var displayLabel = UserProfile.resolveRosterNameFromSources([
      cacheData,
      seedData,
      userData,
    ]);

    if (displayLabel.isEmpty) {
      final email =
          UserProfile.parseEmail(userData) ?? UserProfile.parseEmail(cacheData);
      final prefix = UserProfile.emailPrefix(email);
      if (prefix.isNotEmpty) displayLabel = prefix;
    }

    final goal = UserProfile.parseCalorieGoal(userData);

    var consumed = 0;
    LiveWorkoutStatus live = LiveWorkoutStatus.idle;
    String? liveLabel;

    if (includeLiveAndMeals) {
      try {
        final mealSnap = await userRef
            .collection('meals')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('timestamp', isLessThan: Timestamp.fromDate(end))
            .get();
        consumed = mealSnap.docs.fold<int>(
          0,
          (total, doc) =>
              total + ((doc.data()['calories'] as num?)?.round() ?? 0),
        );
      } catch (_) {}

      try {
        final liveSnap =
            await userRef.collection('live_status').doc('current').get();
        if (liveSnap.exists && liveSnap.data() != null) {
          live = LiveWorkoutStatus.fromFirestore(liveSnap.data()!);
          final hint =
              UserProfile.readStringField(liveSnap.data()!, 'traineeName');
          if (displayLabel.isEmpty && hint != null && hint.trim().isNotEmpty) {
            displayLabel = hint.trim();
          }
        }
      } catch (_) {}

      if (live.isWorkingOut) {
        liveLabel = live.isSlacking
            ? 'Slacking'
            : live.isResting
                ? 'Resting'
                : 'Training';
      }
    }

    return CoachTraineeMember(
      uid: uid,
      displayLabel: displayLabel,
      caloriesConsumed: consumed,
      calorieGoal: goal > 0 ? goal : Env.dailyCalorieGoal,
      isWorkingOut: live.isWorkingOut,
      liveStatusLabel: liveLabel,
    );
  }

  Stream<TraineeProfileSnapshot> watchTraineeProfile(String traineeUid) {
    final (start, end) = _todayRange;
    final userRef = _db.collection('users').doc(traineeUid);

    return userRef.snapshots().asyncExpand((userSnap) {
      if (!userSnap.exists || userSnap.data() == null) {
        return Stream.value(
          const TraineeProfileSnapshot(
            displayName: 'Trainee',
            calorieGoal: Env.dailyCalorieGoal,
            caloriesConsumed: 0,
            meals: [],
            tasks: [],
            liveStatus: LiveWorkoutStatus.idle,
          ),
        );
      }

      final userData = userSnap.data()!;
      final displayName = UserProfile.resolveRosterNameFromMap(userData);
      final goal = UserProfile.parseCalorieGoal(userData);

      final mealsStream = userRef
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .snapshots();

      final tasksStream = userRef
          .collection('tasks')
          .orderBy('createdAt', descending: false)
          .snapshots();

      final liveStream = _watchLiveStatus(traineeUid);

      return _combineLatest3(
        mealsStream,
        tasksStream,
        liveStream,
        (mealSnap, taskSnap, live) {
          final meals =
              mealSnap.docs.map(MealEntry.fromFirestore).toList(growable: false);
          final tasks =
              taskSnap.docs.map(RoutineTask.fromFirestore).toList(growable: false);
          final consumed = meals.fold<int>(0, (t, m) => t + m.calories);

          return TraineeProfileSnapshot(
            displayName: displayName,
            calorieGoal: goal > 0 ? goal : Env.dailyCalorieGoal,
            caloriesConsumed: consumed,
            meals: meals,
            tasks: tasks,
            liveStatus: live,
          );
        },
      );
    });
  }

  Stream<List<CoachWorkoutTemplate>> watchWorkoutTemplates(String coachUid) {
    if (!FirebaseBootstrap.isReady || coachUid.isEmpty) {
      return Stream.value(const []);
    }

    return _db
        .collection('users')
        .doc(coachUid)
        .collection('workout_templates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(_parseTemplate).toList(growable: false),
        );
  }

  /// A `workouts` list entry is either a legacy plain string, or a map of
  /// `{ name, exerciseId? }` when linked to the exercise library.
  static String? _workoutEntryName(dynamic workout) {
    if (workout is String) {
      final trimmed = workout.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (workout is Map) {
      final name = workout['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }

  static String? _workoutEntryExerciseId(dynamic workout) {
    if (workout is Map) {
      final id = workout['exerciseId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }
    return null;
  }

  CoachWorkoutTemplate _parseTemplate(
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
              final name = _workoutEntryName(workout);
              if (name != null) preview.add(name);
            }
          }
        }
      }
    }

    return CoachWorkoutTemplate(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Untitled Routine',
      totalDays: totalDays > 0 ? totalDays : 1,
      exercisePreview: preview.take(8).toList(),
      gymName: (data['gymName'] as String?)?.trim(),
    );
  }

  Future<void> createWorkoutTemplate({
    required String coachUid,
    required String gymName,
    required String name,
    required List<RoutineExerciseSelection> exercises,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Routine name is required.');
    }

    final cleaned = exercises.where((e) => e.name.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      throw Exception('Add at least one target exercise.');
    }

    final ref = _db
        .collection('users')
        .doc(coachUid)
        .collection('workout_templates')
        .doc();

    await ref.set({
      'id': ref.id,
      'name': trimmedName,
      'gymName': gymName.trim(),
      'days': [
        {
          'label': trimmedName,
          'workouts': cleaned.map((e) => e.toMap()).toList(),
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Copies a coach routine template into a trainee's active workout structure.
  /// Replaces any prior coach-assigned splits/exercises and updates profile alerts.
  Future<String> assignWorkoutTemplateToTrainee({
    required String coachUid,
    required String traineeUid,
    required String templateId,
  }) async {
    if (coachUid.isEmpty || traineeUid.isEmpty || templateId.isEmpty) {
      throw Exception('Invalid assignment parameters.');
    }

    final templateSnap = await _db
        .collection('users')
        .doc(coachUid)
        .collection('workout_templates')
        .doc(templateId)
        .get();

    if (!templateSnap.exists || templateSnap.data() == null) {
      throw Exception('Routine template not found.');
    }

    final data = templateSnap.data()!;
    final routineName =
        (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : 'Assigned Routine';

    final traineeSplits =
        _db.collection('users').doc(traineeUid).collection('workout_splits');
    final traineeExercises =
        _db.collection('users').doc(traineeUid).collection('exercises');

    final priorSplits = await traineeSplits.get();
    final refsToDelete = <DocumentReference<Map<String, dynamic>>>[];

    for (final splitDoc in priorSplits.docs) {
      if (splitDoc.data()['coachAssigned'] == true) {
        refsToDelete.add(splitDoc.reference);
        final exercises = await traineeExercises
            .where('splitId', isEqualTo: splitDoc.id)
            .get();
        refsToDelete.addAll(exercises.docs.map((d) => d.reference));
      }
    }

    await _commitBatchedDeletes(refsToDelete);

    final traineeTemplateRef = _db
        .collection('users')
        .doc(traineeUid)
        .collection('workout_templates')
        .doc();

    final templatePayload = Map<String, dynamic>.from(data);
    templatePayload['id'] = traineeTemplateRef.id;
    templatePayload['assignedByCoachId'] = coachUid;
    templatePayload['sourceCoachTemplateId'] = templateId;
    templatePayload['assignedAt'] = FieldValue.serverTimestamp();
    templatePayload['createdAt'] = FieldValue.serverTimestamp();

    final writeBatch = _db.batch();
    writeBatch.set(traineeTemplateRef, templatePayload);

    final days = data['days'];
    if (days is List && days.isNotEmpty) {
      for (final day in days) {
        if (day is! Map) continue;

        final rawLabel = day['label'];
        final label = rawLabel is String && rawLabel.trim().isNotEmpty
            ? rawLabel.trim()
            : routineName;

        final splitRef = traineeSplits.doc();
        writeBatch.set(splitRef, {
          'id': splitRef.id,
          'name': label,
          'createdAt': FieldValue.serverTimestamp(),
          'coachAssigned': true,
          'sourceTemplateId': templateId,
        });

        final workouts = day['workouts'];
        if (workouts is List) {
          for (final workout in workouts) {
            final workoutName = _workoutEntryName(workout);
            if (workoutName == null) continue;
            final exerciseId = _workoutEntryExerciseId(workout);

            final exerciseRef = traineeExercises.doc();
            writeBatch.set(exerciseRef, {
              'id': exerciseRef.id,
              'splitId': splitRef.id,
              'name': workoutName,
              'weightOrSetting': '',
              'notes': 'Coach assigned',
              'timestamp': Timestamp.now(),
              'coachAssigned': true,
              if (exerciseId != null) 'exerciseId': exerciseId,
            });
          }
        }
      }
    } else {
      throw Exception('Routine template has no workout days to assign.');
    }

    writeBatch.update(_db.collection('users').doc(traineeUid), {
      'activeScheduleName': routineName,
      'assignedRoutineAt': FieldValue.serverTimestamp(),
      'assignedRoutineId': traineeTemplateRef.id,
      'assignedByCoachId': coachUid,
      'newScheduleAssigned': true,
    });

    await writeBatch.commit();
    return routineName;
  }

  Future<void> _commitBatchedDeletes(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    const chunkSize = 400;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final end = (i + chunkSize < refs.length) ? i + chunkSize : refs.length;
      final batch = _db.batch();
      for (var j = i; j < end; j++) {
        batch.delete(refs[j]);
      }
      await batch.commit();
    }
  }

  Future<void> updateTraineeCalorieGoal({
    required String coachUid,
    required String traineeUid,
    required int calorieGoal,
  }) async {
    if (coachUid.isEmpty || traineeUid.isEmpty) {
      throw Exception('Invalid coach or trainee.');
    }

    final goal = calorieGoal.clamp(500, 10000);
    await _db.collection('users').doc(traineeUid).set(
      {
        'targetCalories': goal,
        'dailyCalorieGoal': goal,
      },
      SetOptions(merge: true),
    );
  }

  Stream<LiveWorkoutStatus> _watchLiveStatus(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('live_status')
        .doc('current')
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return LiveWorkoutStatus.idle;
      return LiveWorkoutStatus.fromFirestore(snap.data()!);
    });
  }
}

Stream<T> _combineLatest3<A, B, C, T>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  T Function(A, B, C) combiner,
) {
  final controller = StreamController<T>.broadcast();
  A? latestA;
  B? latestB;
  C? latestC;

  void emit() {
    if (latestA != null && latestB != null && latestC != null) {
      controller.add(combiner(latestA as A, latestB as B, latestC as C));
    }
  }

  final subA = streamA.listen((a) {
    latestA = a;
    emit();
  }, onError: controller.addError);
  final subB = streamB.listen((b) {
    latestB = b;
    emit();
  }, onError: controller.addError);
  final subC = streamC.listen((c) {
    latestC = c;
    emit();
  }, onError: controller.addError);

  controller.onCancel = () async {
    await subA.cancel();
    await subB.cancel();
    await subC.cancel();
  };

  return controller.stream;
}
