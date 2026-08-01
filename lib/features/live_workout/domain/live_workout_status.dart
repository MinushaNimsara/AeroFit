import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWorkoutStatus {
  const LiveWorkoutStatus({
    required this.isWorkingOut,
    required this.activeScheduleName,
    required this.activeRoutineName,
    required this.currentWorkout,
    required this.currentExercise,
    required this.status,
    required this.completedSets,
    required this.totalSets,
    required this.nudgeTriggered,
    this.startedAt,
    this.restStartedAt,
    this.gymName,
    this.traineeName,
    this.completedWorkouts = const [],
    this.totalExercisesInSession = 0,
  });

  final bool isWorkingOut;
  final String activeScheduleName;
  final String activeRoutineName;
  final String currentWorkout;
  final String currentExercise;
  final String status;
  final int completedSets;
  final int totalSets;
  final bool nudgeTriggered;
  final DateTime? startedAt;
  final DateTime? restStartedAt;
  final String? gymName;
  final String? traineeName;
  final List<String> completedWorkouts;
  final int totalExercisesInSession;

  bool get isSlacking => status == 'slacking';
  bool get isResting => status == 'resting';
  bool get isWorking => status == 'working';
  bool get isCompleted => status == 'completed';

  String get routineDisplayName {
    if (activeRoutineName.isNotEmpty) return activeRoutineName;
    return activeScheduleName;
  }

  String get activeExerciseLabel {
    if (currentExercise.isNotEmpty) return currentExercise;
    return currentWorkout;
  }

  bool get hasSetProgress =>
      isWorkingOut && activeExerciseLabel.isNotEmpty && totalSets > 0;

  double get setProgressFraction {
    if (totalSets <= 0) return 0;
    return (completedSets / totalSets).clamp(0.0, 1.0);
  }

  static const idle = LiveWorkoutStatus(
    isWorkingOut: false,
    activeScheduleName: '',
    activeRoutineName: '',
    currentWorkout: '',
    currentExercise: '',
    status: 'idle',
    completedSets: 0,
    totalSets: 0,
    nudgeTriggered: false,
  );

  factory LiveWorkoutStatus.fromFirestore(Map<String, dynamic> data) {
    DateTime? parseTs(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    final completed = data['completedWorkouts'];
    final scheduleName = data['activeScheduleName'] as String? ?? '';
    final routineName = data['activeRoutineName'] as String? ?? scheduleName;
    final currentWorkout = data['currentWorkout'] as String? ?? '';
    final currentExercise =
        data['currentExercise'] as String? ?? currentWorkout;

    return LiveWorkoutStatus(
      isWorkingOut: data['isWorkingOut'] as bool? ?? false,
      activeScheduleName: scheduleName.isNotEmpty ? scheduleName : routineName,
      activeRoutineName: routineName.isNotEmpty ? routineName : scheduleName,
      currentWorkout: currentWorkout,
      currentExercise: currentExercise,
      status: data['status'] as String? ?? 'idle',
      completedSets: (data['completedSets'] as num?)?.round() ?? 0,
      totalSets: (data['totalSets'] as num?)?.round() ?? 0,
      nudgeTriggered: data['nudgeTriggered'] as bool? ?? false,
      startedAt: parseTs(data['startedAt']),
      restStartedAt: parseTs(data['restStartedAt']),
      gymName: data['gymName'] as String?,
      traineeName: data['traineeName'] as String?,
      completedWorkouts: completed is List
          ? completed.map((e) => e.toString()).toList()
          : const [],
      totalExercisesInSession:
          (data['totalExercisesInSession'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isWorkingOut': isWorkingOut,
      'activeScheduleName': activeScheduleName,
      'activeRoutineName':
          activeRoutineName.isNotEmpty ? activeRoutineName : activeScheduleName,
      'currentWorkout': currentWorkout,
      'currentExercise': currentExercise.isNotEmpty ? currentExercise : currentWorkout,
      'status': status,
      'completedSets': completedSets,
      'totalSets': totalSets,
      'nudgeTriggered': nudgeTriggered,
      'gymName': gymName,
      'traineeName': traineeName,
      'completedWorkouts': completedWorkouts,
      'totalExercisesInSession': totalExercisesInSession,
    };
  }
}
